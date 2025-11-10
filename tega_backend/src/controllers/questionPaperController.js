import QuestionPaper from '../models/QuestionPaper.js';
import Question from '../models/Question.js';
import { parseQuestionExcel, validateQuestionExcel, generateQuestionTemplate } from '../utils/excelParser.js';
import fs from 'fs';
import path from 'path';
import mongoose from 'mongoose';

// Validate questions data from frontend
const validateQuestionsData = (questionsData) => {
  try {
    if (!Array.isArray(questionsData)) {
      return { valid: false, error: 'Questions data must be an array' };
    }

    if (questionsData.length === 0) {
      return { valid: false, error: 'At least one question is required' };
    }

    for (let i = 0; i < questionsData.length; i++) {
      const question = questionsData[i];
      
      if (!question.question || typeof question.question !== 'string' || question.question.trim() === '') {
        return { valid: false, error: `Question ${i + 1}: Question text is required` };
      }
      
      if (!question.optionA || typeof question.optionA !== 'string' || question.optionA.trim() === '') {
        return { valid: false, error: `Question ${i + 1}: Option A is required` };
      }
      
      if (!question.optionB || typeof question.optionB !== 'string' || question.optionB.trim() === '') {
        return { valid: false, error: `Question ${i + 1}: Option B is required` };
      }
      
      if (!question.optionC || typeof question.optionC !== 'string' || question.optionC.trim() === '') {
        return { valid: false, error: `Question ${i + 1}: Option C is required` };
      }
      
      if (!question.optionD || typeof question.optionD !== 'string' || question.optionD.trim() === '') {
        return { valid: false, error: `Question ${i + 1}: Option D is required` };
      }
      
      if (!question.correct || !['A', 'B', 'C', 'D'].includes(question.correct)) {
        return { valid: false, error: `Question ${i + 1}: Correct answer must be A, B, C, or D` };
      }
    }

    return { valid: true };
  } catch (error) {
    return { valid: false, error: `Validation error: ${error.message}` };
  }
};

// Parse Excel file from memory buffer (no file storage)
const parseQuestionExcelFromBuffer = async (buffer, fileName, adminId, subject) => {
  try {

    // Import XLSX library
    const XLSX = await import('xlsx');
    
    // Parse Excel from buffer
    const workbook = XLSX.read(buffer, { type: 'buffer' });
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    
    // Convert to JSON
    const jsonData = XLSX.utils.sheet_to_json(worksheet);
    // Validate required columns
    const requiredColumns = ['sno', 'question', 'optionA', 'optionB', 'optionC', 'optionD', 'correct'];
    const firstRow = jsonData[0];
    
    if (!firstRow) {
      return {
        success: false,
        error: 'Excel file is empty or has no data'
      };
    }

    const missingColumns = requiredColumns.filter(col => !(col in firstRow));
    if (missingColumns.length > 0) {
      return {
        success: false,
        error: `Missing required columns: ${missingColumns.join(', ')}. Required columns: ${requiredColumns.join(', ')}`
      };
    }

    // Validate and process questions
    const questionsData = [];
    for (let i = 0; i < jsonData.length; i++) {
      const row = jsonData[i];
      
      // Skip empty rows
      if (!row.sno && !row.question) {
        continue;
      }

      // Validate required fields
      if (!row.question || !row.optionA || !row.optionB || !row.optionC || !row.optionD || !row.correct) {
        return {
          success: false,
          error: `Row ${i + 1}: Missing required fields. Each row must have question, optionA, optionB, optionC, optionD, and correct`
        };
      }

      // Validate correct answer
      if (!['A', 'B', 'C', 'D'].includes(row.correct)) {
        return {
          success: false,
          error: `Row ${i + 1}: Invalid correct answer "${row.correct}". Must be A, B, C, or D`
        };
      }

      questionsData.push({
        sno: row.sno || (i + 1),
        question: row.question.trim(),
        optionA: row.optionA.trim(),
        optionB: row.optionB.trim(),
        optionC: row.optionC.trim(),
        optionD: row.optionD.trim(),
        correct: row.correct.trim().toUpperCase()
      });
    }

    if (questionsData.length === 0) {
      return {
        success: false,
        error: 'No valid questions found in Excel file'
      };
    }

    // Save questions to database
    const result = await parseAndSaveQuestions(questionsData, adminId, subject);
    return result;

  } catch (error) {
    return {
      success: false,
      error: `Failed to parse Excel file: ${error.message}`
    };
  }
};

// Parse and save questions directly to MongoDB
const parseAndSaveQuestions = async (questionsData, adminId, subject) => {
  try {
    const savedQuestions = [];
    
    for (let i = 0; i < questionsData.length; i++) {
      const questionData = questionsData[i];
      
      // Create question object
      const question = new Question({
        sno: i + 1,
        question: questionData.question.trim(),
        optionA: questionData.optionA.trim(),
        optionB: questionData.optionB.trim(),
        optionC: questionData.optionC.trim(),
        optionD: questionData.optionD.trim(),
        correct: questionData.correct,
        options: [
          questionData.optionA.trim(),
          questionData.optionB.trim(),
          questionData.optionC.trim(),
          questionData.optionD.trim()
        ],
        correctAnswer: questionData[`option${questionData.correct}`].trim(),
        subject: subject,
        createdBy: adminId
      });
      
      const savedQuestion = await question.save();
      savedQuestions.push(savedQuestion);
    }
    
    return {
      success: true,
      questions: savedQuestions,
      totalQuestions: savedQuestions.length
    };
  } catch (error) {
    return {
      success: false,
      error: `Failed to save questions: ${error.message}`
    };
  }
};

// Get all question papers
export const getAllQuestionPapers = async (req, res) => {
  try {
    const questionPapers = await QuestionPaper.find({ isActive: true })
      .populate('courseId', 'courseName')
      .populate('createdBy', 'username')
      .sort({ createdAt: -1 });

    // Get exam usage information for each question paper
    const Exam = (await import('../models/Exam.js')).default;
    const questionPapersWithUsage = await Promise.all(
      questionPapers.map(async (paper) => {
        const usedByExams = await Exam.find({ questionPaperId: paper._id })
          .select('title examDate')
          .lean();
        
        return {
          ...paper.toObject(),
          usedByExams
        };
      })
    );

    res.json({
      success: true,
      questionPapers: questionPapersWithUsage
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch question papers'
    });
  }
};

// Get question papers by course
export const getQuestionPapersByCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    if (!courseId || courseId.trim() === '') {
      return res.status(400).json({
        success: false,
        message: 'Course ID is required'
      });
    }
    
    // Validate that courseId is a valid ObjectId
    if (!mongoose.Types.ObjectId.isValid(courseId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid Course ID format'
      });
    }
    
    let questionPapers;
    try {
      questionPapers = await QuestionPaper.find({ 
        courseId, 
        isActive: true 
      })
      .populate('courseId', 'courseName')
      .sort({ createdAt: -1 });
    } catch (dbError) {
      return res.status(500).json({
        success: false,
        message: 'Database error while fetching question papers',
        error: process.env.NODE_ENV === 'development' ? dbError.message : undefined
      });
    }

    // Get exam usage information for each question paper
    const Exam = (await import('../models/Exam.js')).default;
    const questionPapersWithUsage = await Promise.all(
      questionPapers.map(async (paper) => {
        const usedByExams = await Exam.find({ questionPaperId: paper._id })
          .select('title examDate')
          .lean();
        
        return {
          ...paper.toObject(),
          usedByExams
        };
      })
    );

    res.json({
      success: true,
      questionPapers: questionPapersWithUsage
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch question papers',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Upload question paper - handles both Excel files and JSON data
export const uploadQuestionPaper = async (req, res) => {
  try {
    const { adminId } = req;
    const { courseId, description, isTegaExamPaper, questionsData } = req.body;


    // Validate TEGA exam paper requirements
    if (isTegaExamPaper && courseId && courseId.trim() !== '') {
    }

    let questionsToSave = [];
    let totalQuestions = 0;

    // Handle Excel file upload (in-memory processing)
    if (req.file) {
      // Process Excel file from memory buffer
      const result = await parseQuestionExcelFromBuffer(req.file.buffer, req.file.originalname, adminId, 'General');
      
      if (!result.success) {
        return res.status(400).json({
          success: false,
          message: result.error
        });
      }

      questionsToSave = result.questions;
      totalQuestions = result.totalQuestions;
    }
    // Handle JSON data upload
    else if (questionsData && Array.isArray(questionsData) && questionsData.length > 0) {
      // Validate questions data
      const validation = validateQuestionsData(questionsData);
      
      if (!validation.valid) {
        return res.status(400).json({
          success: false,
          message: validation.error
        });
      }

      // Parse and save questions directly to MongoDB
      const result = await parseAndSaveQuestions(questionsData, adminId, 'General');
      
      if (!result.success) {
        return res.status(400).json({
          success: false,
          message: result.error
        });
      }

      questionsToSave = result.questions;
      totalQuestions = result.totalQuestions;
    }
    else {
      return res.status(400).json({
        success: false,
        message: 'No file or questions data provided'
      });
    }

    // Create question paper record
    // Convert isTegaExamPaper to boolean (handles string "true"/"false" from form data)
    const isTegaExamPaperBoolean = isTegaExamPaper === true || isTegaExamPaper === 'true';
    const questionPaperData = {
      name: req.file ? req.file.originalname.replace(/\.[^/.]+$/, "") : `Question Paper ${Date.now()}`,
      description: description || 'No description provided',
      isTegaExamPaper: isTegaExamPaperBoolean,
      totalQuestions: totalQuestions,
      questions: questionsToSave.map(q => q._id),
      createdBy: adminId
    };

    // Handle courseId based on exam type
    if (isTegaExamPaperBoolean) {
      // For TEGA exam papers, explicitly set courseId to null
      questionPaperData.courseId = null;
    } else if (courseId && courseId.trim() !== '' && courseId !== 'undefined' && courseId !== 'null') {
      // For course exam papers, set the courseId if provided and valid
      questionPaperData.courseId = courseId;
    } else {
      // No valid courseId provided for course exam
      // Clean up uploaded file
      if (req.file && req.file.path && fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }
      return res.status(400).json({
        success: false,
        message: 'Course ID is required for course-based question papers'
      });
    }
    // Debug: Check if courseId is actually undefined or null
    const questionPaper = new QuestionPaper(questionPaperData);

    try {
      await questionPaper.save();
  } catch (saveError) {
      // No file cleanup needed for in-memory processing
      throw saveError; // Re-throw to be caught by outer try-catch
    }

    // Update questions with questionPaperId
    await Question.updateMany(
      { _id: { $in: questionsToSave.map(q => q._id) } },
      { questionPaperId: questionPaper._id }
    );

    const populatedQuestionPaper = await QuestionPaper.findById(questionPaper._id)
      .populate('courseId', 'courseName')
      .populate('questions');

    // Emit WebSocket event for question paper upload
    const io = req.app.get('io');
    if (io) {
      io.emit('question-paper-uploaded', {
        questionPaperId: questionPaper._id,
        questionPaperName: questionPaper.name,
        courseId: questionPaper.courseId,
        isTegaExamPaper: questionPaper.isTegaExamPaper,
        totalQuestions: totalQuestions,
        createdBy: adminId,
        timestamp: new Date()
      });
      
      // Also emit to admin-specific room
      io.to(`user-${adminId}`).emit('admin-question-paper-uploaded', {
        questionPaperId: questionPaper._id,
        questionPaperName: questionPaper.name,
        courseId: questionPaper.courseId,
        isTegaExamPaper: questionPaper.isTegaExamPaper,
        totalQuestions: totalQuestions,
        timestamp: new Date()
      });
    }

    res.json({
      success: true,
      message: `Successfully imported ${totalQuestions} questions`,
      questionPaper: populatedQuestionPaper
    });
  } catch (error) {
    
    // No file cleanup needed for in-memory processing
    
    res.status(500).json({
      success: false,
      message: 'Failed to upload question paper',
      error: error.message,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

// Get TEGA exam question papers
export const getTegaExamQuestionPapers = async (req, res) => {
  try {
    const { adminId } = req;
    const questionPapers = await QuestionPaper.find({ isTegaExamPaper: true })
      .populate('questions')
      .populate('createdBy', 'username')
      .sort({ createdAt: -1 });
    if (questionPapers.length > 0) {
    } else {
    }

    // Get exam usage information for each question paper
    const Exam = (await import('../models/Exam.js')).default;
    const questionPapersWithUsage = await Promise.all(
      questionPapers.map(async (paper) => {
        const usedByExams = await Exam.find({ questionPaperId: paper._id })
          .select('title examDate')
          .lean();
        
        return {
          ...paper.toObject(),
          usedByExams
        };
      })
    );

    res.json({
      success: true,
      questionPapers: questionPapersWithUsage
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch TEGA exam question papers'
    });
  }
};

// Download question template
export const downloadQuestionTemplate = async (req, res) => {
  try {
    const templateBuffer = generateQuestionTemplate();
    
    // Set proper headers for Excel file download
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', 'attachment; filename="Question_Paper_Template.xlsx"');
    res.setHeader('Content-Length', templateBuffer.length);
    
    res.send(templateBuffer);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to generate template'
    });
  }
};

// Get question paper details
export const getQuestionPaperDetails = async (req, res) => {
  try {
    const { questionPaperId } = req.params;

    const questionPaper = await QuestionPaper.findById(questionPaperId)
      .populate('courseId', 'courseName')
      .populate('questions')
      .populate('createdBy', 'username');

    if (!questionPaper) {
      return res.status(404).json({
        success: false,
        message: 'Question paper not found'
      });
    }

    res.json({
      success: true,
      questionPaper
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch question paper details'
    });
  }
};

// Delete question paper
export const deleteQuestionPaper = async (req, res) => {
  try {
    const { questionPaperId } = req.params;
    const { adminId } = req;
    if (!questionPaperId) {
      return res.status(400).json({
        success: false,
        message: 'Question paper ID is required'
      });
    }
    
    // Validate that questionPaperId is a valid ObjectId
    if (!mongoose.Types.ObjectId.isValid(questionPaperId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid Question paper ID format'
      });
    }
    
    // Find the question paper
    const questionPaper = await QuestionPaper.findById(questionPaperId);
    
    if (!questionPaper) {
      return res.status(404).json({
        success: false,
        message: 'Question paper not found'
      });
    }
    
    // Check if question paper is being used by any exams
    const Exam = (await import('../models/Exam.js')).default;
    const examsUsingPaper = await Exam.find({ questionPaperId: questionPaperId });
    
    if (examsUsingPaper.length > 0) {
      const examTitles = examsUsingPaper.map(exam => exam.title).join(', ');
      return res.status(400).json({
        success: false,
        message: `Cannot delete question paper. It is being used by ${examsUsingPaper.length} exam(s): ${examTitles}. Please remove it from the exams first.`,
        usedByExams: examsUsingPaper.map(exam => ({
          id: exam._id,
          title: exam.title,
          examDate: exam.examDate
        }))
      });
    }
    
    // Delete associated questions
    if (questionPaper.questions && questionPaper.questions.length > 0) {
      await Question.deleteMany({ _id: { $in: questionPaper.questions } });
    }
    
    // Delete the question paper file if it exists
    if (questionPaper.filePath && fs.existsSync(questionPaper.filePath)) {
      fs.unlinkSync(questionPaper.filePath);
    }
    
    // Delete the question paper document
    await QuestionPaper.findByIdAndDelete(questionPaperId);
    // Emit WebSocket event for question paper deletion
    const io = req.app.get('io');
    if (io) {
      io.emit('question-paper-deleted', {
        questionPaperId,
        courseId: questionPaper.courseId,
        isTegaExamPaper: questionPaper.isTegaExamPaper,
        deletedBy: adminId,
        timestamp: new Date()
      });
      io.to(`user-${adminId}`).emit('admin-question-paper-deleted', {
        questionPaperId,
        courseId: questionPaper.courseId,
        isTegaExamPaper: questionPaper.isTegaExamPaper,
        timestamp: new Date()
      });
    }
    res.json({
      success: true,
      message: 'Question paper deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete question paper',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
