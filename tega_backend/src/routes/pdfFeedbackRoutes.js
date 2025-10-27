import express from 'express';
import { generateExamFeedbackPDF } from '../controllers/pdfFeedbackController.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// Test route to verify authentication
router.get('/test-auth', studentAuth, (req, res) => {
  res.json({
    success: true,
    message: 'Authentication working',
    studentId: req.studentId,
    student: req.student
  });
});

// Simple test route without authentication
router.get('/test-simple', (req, res) => {
  res.json({
    success: true,
    message: 'Simple route working',
    timestamp: new Date().toISOString()
  });
});

// Debug route to check exam attempt and questions
router.get('/debug-attempt/:attemptId', studentAuth, async (req, res) => {
  try {
    const { attemptId } = req.params;
    
    // Import models
    const ExamAttempt = (await import('../models/ExamAttempt.js')).default;
    const Exam = (await import('../models/Exam.js')).default;
    const Question = (await import('../models/Question.js')).default;
    
    // Fetch exam attempt
    const examAttempt = await ExamAttempt.findById(attemptId)
      .populate('examId', 'title subject questionPaperId questions')
      .populate('studentId', 'firstName lastName email');
    
    if (!examAttempt) {
      return res.status(404).json({
        success: false,
        message: 'Exam attempt not found'
      });
    }
    
    // Try different methods to find questions
    const debugInfo = {
      examAttempt: {
        id: examAttempt._id,
        examId: examAttempt.examId._id,
        examTitle: examAttempt.examId.title,
        hasQuestionPaperId: !!examAttempt.examId.questionPaperId,
        questionPaperId: examAttempt.examId.questionPaperId,
        hasQuestionsArray: !!examAttempt.examId.questions,
        questionsArrayLength: examAttempt.examId.questions?.length || 0,
        answersCount: examAttempt.answers.size,
        answersKeys: Array.from(examAttempt.answers.keys())
      },
      questionSearchResults: {}
    };
    
    // Method 1: By examId
    const questionsByExamId = await Question.find({ examId: examAttempt.examId._id });
    debugInfo.questionSearchResults.byExamId = {
      count: questionsByExamId.length,
      questionIds: questionsByExamId.map(q => q._id)
    };
    
    // Method 2: By questionPaperId
    if (examAttempt.examId.questionPaperId) {
      const questionsByPaperId = await Question.find({ questionPaperId: examAttempt.examId.questionPaperId });
      debugInfo.questionSearchResults.byQuestionPaperId = {
        count: questionsByPaperId.length,
        questionIds: questionsByPaperId.map(q => q._id)
      };
    }
    
    // Method 3: By answered questions
    const answeredQuestionIds = Array.from(examAttempt.answers.keys());
    if (answeredQuestionIds.length > 0) {
      const answeredQuestions = await Question.find({ _id: { $in: answeredQuestionIds } });
      debugInfo.questionSearchResults.byAnsweredQuestions = {
        count: answeredQuestions.length,
        questionIds: answeredQuestions.map(q => q._id)
      };
    }
    
    res.json({
      success: true,
      debug: debugInfo
    });
    
  } catch (error) {
    console.error('Debug route error:', error);
    res.status(500).json({
      success: false,
      message: 'Debug failed',
      error: error.message
    });
  }
});

// Generate PDF feedback for exam results
router.get('/exam/:attemptId', studentAuth, generateExamFeedbackPDF);

// Generate PDF feedback for exam results (V2 - fallback route)
router.get('/exam-v2/:attemptId', studentAuth, generateExamFeedbackPDF);

export default router;
