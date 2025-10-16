import QuestionPaper from '../models/QuestionPaper.js';
import Question from '../models/Question.js';
import { parseQuestionExcel, validateQuestionExcel, generateQuestionTemplate } from '../utils/excelParser.js';
import fs from 'fs';
import path from 'path';

// Get all question papers
export const getAllQuestionPapers = async (req, res) => {
  try {
    const questionPapers = await QuestionPaper.find({ isActive: true })
      .populate('courseId', 'courseName')
      .populate('createdBy', 'username')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      questionPapers
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
    
    
    if (!courseId) {
      return res.status(400).json({
        success: false,
        message: 'Course ID is required'
      });
    }
    
    const questionPapers = await QuestionPaper.find({ 
      courseId, 
      isActive: true 
    })
    .populate('courseId', 'courseName')
    .sort({ createdAt: -1 });


    res.json({
      success: true,
      questionPapers
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch question papers'
    });
  }
};

// Upload question paper
export const uploadQuestionPaper = async (req, res) => {
  try {
    const { adminId } = req;
    const { courseId, description } = req.body;


    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const filePath = req.file.path;
    
    // Validate Excel format
    const validation = validateQuestionExcel(filePath);
    
    if (!validation.valid) {
      // Delete uploaded file
      fs.unlinkSync(filePath);
      return res.status(400).json({
        success: false,
        message: validation.error
      });
    }

    // Parse Excel and save questions
    const result = await parseQuestionExcel(filePath, null, adminId, 'General');
    
    if (!result.success) {
      // Delete uploaded file
      fs.unlinkSync(filePath);
      return res.status(400).json({
        success: false,
        message: result.error
      });
    }

    // Create question paper record
    const questionPaper = new QuestionPaper({
      name: req.file.originalname.replace(/\.[^/.]+$/, ""), // Remove extension
      description: description || 'No description provided',
      courseId,
      fileName: req.file.filename,
      originalFileName: req.file.originalname,
      filePath: filePath,
      fileSize: req.file.size,
      totalQuestions: result.totalQuestions,
      questions: result.questions.map(q => q._id),
      createdBy: adminId
    });

    await questionPaper.save();

    // Update questions with questionPaperId
    await Question.updateMany(
      { _id: { $in: result.questions.map(q => q._id) } },
      { questionPaperId: questionPaper._id }
    );

    // Delete temporary file after successful processing
    fs.unlinkSync(filePath);

    const populatedQuestionPaper = await QuestionPaper.findById(questionPaper._id)
      .populate('courseId', 'courseName')
      .populate('questions');

    res.json({
      success: true,
      message: `Successfully imported ${result.totalQuestions} questions`,
      questionPaper: populatedQuestionPaper,
      errors: result.errors
    });
  } catch (error) {
    
    // Clean up uploaded file if it exists
    if (req.file && req.file.path && fs.existsSync(req.file.path)) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (cleanupError) {
      }
    }
    
    res.status(500).json({
      success: false,
      message: 'Failed to upload question paper',
      error: error.message,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

// Delete question paper
export const deleteQuestionPaper = async (req, res) => {
  try {
    const { questionPaperId } = req.params;

    // Check if question paper is used in any exam
    const questionPaper = await QuestionPaper.findById(questionPaperId);
    if (!questionPaper) {
      return res.status(404).json({
        success: false,
        message: 'Question paper not found'
      });
    }

    if (questionPaper.usedInExams.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete question paper that is being used in exams'
      });
    }

    // Delete associated questions
    await Question.deleteMany({ questionPaperId });

    // Delete question paper
    await QuestionPaper.findByIdAndDelete(questionPaperId);

    res.json({
      success: true,
      message: 'Question paper deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete question paper'
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
