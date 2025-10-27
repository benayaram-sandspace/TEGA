import QuestionPaper from '../models/QuestionPaper.js';
import Question from '../models/Question.js';
import { parseQuestionExcel, validateQuestionExcel, generateQuestionTemplate } from '../utils/excelParser.js';
import fs from 'fs';
import path from 'path';
import mongoose from 'mongoose';

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
    // console.error('Error fetching question papers:', error);
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
    
    // console.log('getQuestionPapersByCourse called with courseId:', courseId);
    // console.log('courseId type:', typeof courseId);
    // console.log('courseId length:', courseId ? courseId.length : 'null/undefined');
    
    if (!courseId || courseId.trim() === '') {
      // console.log('❌ Empty or invalid courseId provided');
      return res.status(400).json({
        success: false,
        message: 'Course ID is required'
      });
    }
    
    // Validate that courseId is a valid ObjectId
    if (!mongoose.Types.ObjectId.isValid(courseId)) {
      // console.log('❌ Invalid ObjectId format for courseId:', courseId);
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
      
      // console.log('Found question papers:', questionPapers.length);
    } catch (dbError) {
      // console.error('❌ Database error in getQuestionPapersByCourse:', dbError);
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
    // console.error('Error fetching question papers by course:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch question papers',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Upload question paper
export const uploadQuestionPaper = async (req, res) => {
  try {
    const { adminId } = req;
    const { courseId, description, isTegaExamPaper } = req.body;

    // console.log('📤 Upload request received:', {
    //   adminId,
    //   courseId,
    //   courseIdType: typeof courseId,
    //   description,
    //   isTegaExamPaper,
    //   isTegaExamPaperType: typeof isTegaExamPaper,
    //   isTegaExamPaperValue: String(isTegaExamPaper),
    //   reqBody: req.body,
    //   hasFile: !!req.file,
    //   fileInfo: req.file ? {
    //     originalname: req.file.originalname,
    //     mimetype: req.file.mimetype,
    //     size: req.file.size
    //   } : null
    // });

    // Validate TEGA exam paper requirements
    if (isTegaExamPaper && courseId && courseId.trim() !== '') {
      // console.log('⚠️ Warning: TEGA exam paper should not have courseId, ignoring it');
    }

    if (!req.file) {
      // console.log('No file uploaded');
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const filePath = req.file.path;
    // console.log('File path:', filePath);
    
    // Validate Excel format
    // console.log('Starting Excel validation...');
    const validation = validateQuestionExcel(filePath);
    // console.log('Validation result:', validation);
    
    if (!validation.valid) {
      // console.log('Validation failed:', validation.error);
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
    // Convert isTegaExamPaper to boolean (handles string "true"/"false" from form data)
    const isTegaExamPaperBoolean = isTegaExamPaper === true || isTegaExamPaper === 'true';
    
    // console.log('🔍 isTegaExamPaper conversion:', {
    //   original: isTegaExamPaper,
    //   originalType: typeof isTegaExamPaper,
    //   converted: isTegaExamPaperBoolean,
    //   convertedType: typeof isTegaExamPaperBoolean
    // });
    
    const questionPaperData = {
      name: req.file.originalname.replace(/\.[^/.]+$/, ""), // Remove extension
      description: description || 'No description provided',
      isTegaExamPaper: isTegaExamPaperBoolean,
      fileName: req.file.filename,
      originalFileName: req.file.originalname,
      filePath: filePath,
      fileSize: req.file.size,
      totalQuestions: result.totalQuestions,
      questions: result.questions.map(q => q._id),
      createdBy: adminId
    };

    // Handle courseId based on exam type
    if (isTegaExamPaperBoolean) {
      // For TEGA exam papers, explicitly set courseId to null
      questionPaperData.courseId = null;
      // console.log('✅ TEGA exam paper: courseId set to null');
    } else if (courseId && courseId.trim() !== '' && courseId !== 'undefined' && courseId !== 'null') {
      // For course exam papers, set the courseId if provided and valid
      questionPaperData.courseId = courseId;
      // console.log('✅ Course exam paper: courseId set to', courseId);
    } else {
      // No valid courseId provided for course exam
      // console.log('❌ Course exam paper but no valid courseId provided');
      // Clean up uploaded file
      if (req.file && req.file.path && fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }
      return res.status(400).json({
        success: false,
        message: 'Course ID is required for course-based question papers'
      });
    }

    // console.log('🔍 Creating question paper with data:', {
    //   ...questionPaperData,
    //   questions: `${questionPaperData.questions.length} questions`
    // });

    // console.log('🔍 Validation check:', {
    //   isTegaExamPaper: questionPaperData.isTegaExamPaper,
    //   hasCourseId: !!questionPaperData.courseId,
    //   courseId: questionPaperData.courseId
    // });

    // Debug: Check if courseId is actually undefined or null
    // console.log('🔍 courseId type and value:', {
    //   type: typeof questionPaperData.courseId,
    //   value: questionPaperData.courseId,
    //   isUndefined: questionPaperData.courseId === undefined,
    //   isNull: questionPaperData.courseId === null
    // });

    const questionPaper = new QuestionPaper(questionPaperData);

    try {
      await questionPaper.save();
      // console.log('✅ Question paper saved successfully:', questionPaper._id);
    } catch (saveError) {
      // console.error('❌ Error saving question paper:', saveError);
      // Clean up uploaded file
      if (req.file && req.file.path && fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }
      throw saveError; // Re-throw to be caught by outer try-catch
    }

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
    // console.error('❌ Error uploading question paper:', error);
    // console.error('❌ Error stack:', error.stack);
    
    // Clean up uploaded file if it exists
    if (req.file && req.file.path && fs.existsSync(req.file.path)) {
      try {
        fs.unlinkSync(req.file.path);
        // console.log('✅ Cleaned up uploaded file');
      } catch (cleanupError) {
        // console.error('❌ Error cleaning up file:', cleanupError);
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

// Get TEGA exam question papers
export const getTegaExamQuestionPapers = async (req, res) => {
  try {
    const { adminId } = req;

    // console.log('🔍 getTegaExamQuestionPapers called with:', { adminId });

    const questionPapers = await QuestionPaper.find({ isTegaExamPaper: true })
      .populate('questions')
      .populate('createdBy', 'username')
      .sort({ createdAt: -1 });

    // console.log(`🔍 Found ${questionPapers.length} TEGA exam question papers`);
    if (questionPapers.length > 0) {
      // console.log('🔍 TEGA exam question papers:', questionPapers.map(p => ({ id: p._id, name: p.name, isTegaExamPaper: p.isTegaExamPaper })));
    } else {
      // console.log('🔍 No TEGA exam question papers found in database');
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
    // console.error('Error fetching TEGA exam question papers:', error);
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
    // console.error('Error generating template:', error);
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
    // console.error('Error fetching question paper details:', error);
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
    
    // console.log('deleteQuestionPaper called with questionPaperId:', questionPaperId);
    
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
      // console.log(`Deleted ${questionPaper.questions.length} questions`);
    }
    
    // Delete the question paper file if it exists
    if (questionPaper.filePath && fs.existsSync(questionPaper.filePath)) {
      fs.unlinkSync(questionPaper.filePath);
      // console.log('Deleted question paper file:', questionPaper.filePath);
    }
    
    // Delete the question paper document
    await QuestionPaper.findByIdAndDelete(questionPaperId);
    
    // console.log('Successfully deleted question paper:', questionPaperId);
    
    res.json({
      success: true,
      message: 'Question paper deleted successfully'
    });
  } catch (error) {
    // console.error('Error deleting question paper:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete question paper',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
