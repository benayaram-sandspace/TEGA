import Quiz from '../models/Quiz.js';
import QuizAttempt from '../models/QuizAttempt.js';
import Student from '../models/Student.js';
import RealTimeCourse from '../models/RealTimeCourse.js';
import * as XLSX from 'xlsx';
import { uploadToR2, generateR2Key } from '../config/r2.js';

/**
 * Parse Excel file and validate structure
 */
export const parseExcelFile = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    // Parse Excel file
    const workbook = XLSX.read(req.file.buffer, { type: 'buffer' });
    const worksheet = workbook.Sheets[workbook.SheetNames[0]];
    const headers = XLSX.utils.sheet_to_json(worksheet, { header: 1 })[0];
    const jsonData = XLSX.utils.sheet_to_json(worksheet);

    // Validate headers
    const requiredHeaders = [
      'S.No', 'Question', 'Option A', 'Option B', 'Option C', 'Option D', 'Correct Option'
    ];
    
    const missingColumns = requiredHeaders.filter(col => !headers.includes(col));
    const errors = [];
    
    if (missingColumns.length > 0) {
      errors.push(`Missing columns: ${missingColumns.join(', ')}`);
    }

    // Parse and validate questions
    const questions = [];
    jsonData.forEach((row, index) => {
      const rowNum = index + 2;

      if (!row['S.No']) {
        errors.push(`Row ${rowNum}: S.No is required`);
        return;
      }

      if (!row['Question'] || row['Question'].trim().length === 0) {
        errors.push(`Row ${rowNum}: Question cannot be empty`);
        return;
      }

      ['Option A', 'Option B', 'Option C', 'Option D'].forEach(opt => {
        if (!row[opt] || row[opt].trim().length === 0) {
          errors.push(`Row ${rowNum}: ${opt} cannot be empty`);
        }
      });

      // Fix: Handle "Correct Option" with better trimming and error checking
      let correctOption = row['Correct Option'];
      
      // If not found with exact match, try to find it case-insensitively
      if (!correctOption) {
        const correctOptionKey = Object.keys(row).find(key => 
          key && key.toLowerCase().trim() === 'correct option'
        );
        correctOption = correctOptionKey ? row[correctOptionKey] : null;
      }
      
      // Trim whitespace and convert to uppercase
      if (correctOption && typeof correctOption === 'string') {
        correctOption = correctOption.trim().toUpperCase();
      }
      
      // Log for debugging
      // console.log(`Row ${rowNum} - Correct Option value:`, correctOption, `(type: ${typeof correctOption})`);
      
      if (!correctOption || !['A', 'B', 'C', 'D'].includes(correctOption)) {
        errors.push(`Row ${rowNum}: Correct Option must be A, B, C, or D (received: "${correctOption}")`);
        return;
      }

      questions.push({
        sNo: row['S.No'],
        question: row['Question'].trim(),
        optionA: row['Option A'].trim(),
        optionB: row['Option B'].trim(),
        optionC: row['Option C'].trim(),
        optionD: row['Option D'].trim(),
        correctOption: correctOption
      });
    });

    res.json({
      success: true,
      data: {
        questions,
        errors,
        totalQuestions: questions.length
      }
    });
  } catch (error) {
    // console.error('Parse Excel error:', error);
    res.status(500).json({
      success: false,
      message: 'Error parsing Excel file',
      error: error.message
    });
  }
};

/**
 * Upload quiz to R2 and save metadata to database
 */
export const uploadQuiz = async (req, res) => {
  try {
    const { courseId, moduleId, questionCount, passMarks } = req.body;
    const adminId = req.adminId;

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    if (!courseId || !moduleId) {
      return res.status(400).json({
        success: false,
        message: 'Course ID and Module ID are required'
      });
    }

    if (!passMarks || isNaN(parseFloat(passMarks))) {
      return res.status(400).json({
        success: false,
        message: 'Pass marks must be a valid number'
      });
    }

    const passMarksValue = parseFloat(passMarks);

    // Parse the Excel file again to get questions
    const workbook = XLSX.read(req.file.buffer, { type: 'buffer' });
    const worksheet = workbook.Sheets[workbook.SheetNames[0]];
    const jsonData = XLSX.utils.sheet_to_json(worksheet);

    const questions = jsonData.map((row, idx) => {
      // Fix: Handle "Correct Option" with better trimming and error checking
      let correctOption = row['Correct Option'];
      
      // If not found with exact match, try to find it case-insensitively
      if (!correctOption) {
        const correctOptionKey = Object.keys(row).find(key => 
          key && key.toLowerCase().trim() === 'correct option'
        );
        correctOption = correctOptionKey ? row[correctOptionKey] : null;
      }
      
      // Trim whitespace and convert to uppercase
      if (correctOption && typeof correctOption === 'string') {
        correctOption = correctOption.trim().toUpperCase();
      }
      
      return {
        sNo: row['S.No'] || idx + 1,
        question: row['Question'],
        optionA: row['Option A'],
        optionB: row['Option B'],
        optionC: row['Option C'],
        optionD: row['Option D'],
        correctOption: correctOption
      };
    });

    // Calculate total pass marks (passMarks value * number of questions)
    const totalPassMarks = passMarksValue * questions.length;

    // Upload file to R2
    const r2Key = generateR2Key(`quiz/courses/${courseId}/modules/${moduleId}`, req.file.originalname);
    
    await uploadToR2(
      req.file.buffer,
      r2Key,
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      {
        courseId,
        moduleId,
        uploadedBy: adminId,
        uploadedAt: new Date().toISOString()
      }
    );

    // Create quiz record in database
    const quiz = await Quiz.create({
      courseId,
      moduleId,
      createdBy: adminId,
      questions,
      totalQuestions: questions.length,
      totalPassMarks,
      passMarksPerQuestion: passMarksValue,
      r2Key,
      r2FileName: req.file.originalname,
      isActive: true,
      createdAt: new Date()
    });

    // ✅ NEW: Update the course module to reference this quiz
    try {
      await RealTimeCourse.findOneAndUpdate(
        { _id: courseId, 'modules._id': moduleId },
        {
          $set: {
            'modules.$.quiz': {
              id: quiz._id,
              totalQuestions: questions.length,
              passMarks: totalPassMarks,
              passMarksPerQuestion: passMarksValue
            }
          }
        },
        { new: true }
      );
      // console.log('✅ Quiz reference added to course module:', { courseId, moduleId, quizId: quiz._id });
    } catch (updateError) {
      // console.error('⚠️ Failed to update course module with quiz reference:', updateError);
      // Don't fail the entire operation if module update fails
    }

    res.json({
      success: true,
      message: 'Quiz uploaded successfully',
      data: {
        quizId: quiz._id,
        courseId,
        moduleId,
        totalQuestions: questions.length,
        totalPassMarks,
        passMarksPerQuestion: passMarksValue,
        uploadedAt: new Date().toISOString()
      }
    });
  } catch (error) {
    // console.error('Upload quiz error:', error);
    res.status(500).json({
      success: false,
      message: 'Error uploading quiz',
      error: error.message
    });
  }
};

/**
 * Get quiz by module ID
 */
export const getQuizByModule = async (req, res) => {
  try {
    const { quizId } = req.params;

    const quiz = await Quiz.findById(quizId).select('questions totalPassMarks passMarksPerQuestion');

    if (!quiz) {
      return res.status(404).json({
        success: false,
        message: 'Quiz not found'
      });
    }

    // Don't send correct answers to client - send only questions and options
    const safeQuestions = quiz.questions.map(q => ({
      sNo: q.sNo,
      question: q.question,
      optionA: q.optionA,
      optionB: q.optionB,
      optionC: q.optionC,
      optionD: q.optionD
    }));

    res.json({
      success: true,
      data: {
        quizId: quiz._id,
        questions: safeQuestions,
        totalPassMarks: quiz.totalPassMarks,
        passMarksPerQuestion: quiz.passMarksPerQuestion,
        requiredPassMarks: Math.ceil(quiz.totalPassMarks * 0.7) // Pass at 70% of total
      }
    });
  } catch (error) {
    // console.error('Get quiz error:', error);
    res.status(500).json({
      success: false,
      message: 'Error loading quiz',
      error: error.message
    });
  }
};

/**
 * Get quiz by ID (for admins to view quiz details)
 */
export const getQuizById = async (req, res) => {
  try {
    const { quizId } = req.params;

    const quiz = await Quiz.findById(quizId);
    if (!quiz) {
      return res.status(404).json({
        success: false,
        message: 'Quiz not found'
      });
    }

    res.json({
      success: true,
      data: {
        id: quiz._id,
        courseId: quiz.courseId,
        moduleId: quiz.moduleId,
        totalQuestions: quiz.totalQuestions,
        totalPassMarks: quiz.totalPassMarks,
        passMarksPerQuestion: quiz.passMarksPerQuestion,
        r2Key: quiz.r2Key,
        r2FileName: quiz.r2FileName,
        createdAt: quiz.createdAt,
        updatedAt: quiz.updatedAt
      }
    });
  } catch (error) {
    // console.error('Get quiz error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching quiz',
      error: error.message
    });
  }
};

/**
 * Submit quiz attempt and calculate score
 */
export const submitQuizAttempt = async (req, res) => {
  try {
    const { quizId, courseId, moduleId, answers, timeSpent } = req.body;
    const studentId = req.studentId;

    const quiz = await Quiz.findById(quizId);

    if (!quiz) {
      return res.status(404).json({
        success: false,
        message: 'Quiz not found'
      });
    }

    // Calculate score
    let correctCount = 0;
    let score = 0;
    const attemptedCount = Object.keys(answers).length;

    Object.entries(answers).forEach(([questionIdx, selectedOption]) => {
      const question = quiz.questions[questionIdx];
      if (question && question.correctOption === selectedOption) {
        correctCount++;
        score += quiz.passMarksPerQuestion; // Use passMarksPerQuestion from quiz, not from individual question
      }
    });

    // Determine pass/fail based on percentage
    const passPercentage = (score / quiz.totalPassMarks) * 100;
    const isPassed = passPercentage >= 70; // 70% is passing mark

    // Save attempt to database
    const attempt = await QuizAttempt.create({
      studentId,
      quizId,
      courseId,
      moduleId,
      answers,
      score,
      totalMarks: quiz.totalPassMarks,
      correctAnswers: correctCount,
      totalQuestions: quiz.totalQuestions,
      attemptedQuestions: attemptedCount,
      isPassed,
      timeSpent,
      attemptedAt: new Date()
    });

    // Update student profile - mark module as completed if passed
    if (isPassed) {
      await Student.findByIdAndUpdate(
        studentId,
        { $addToSet: { 'completedModules': moduleId } },
        { new: true }
      );
    }

    res.json({
      success: true,
      data: {
        attemptId: attempt._id,
        score,
        totalMarks: quiz.totalPassMarks,
        correctAnswers: correctCount,
        totalQuestions: quiz.totalQuestions,
        attemptedQuestions: attemptedCount,
        isPassed,
        passPercentage: passPercentage.toFixed(1),
        passMarks: Math.ceil(quiz.totalPassMarks * 0.7), // Calculate required pass marks from total
        timeSpent
      }
    });
  } catch (error) {
    // console.error('Submit attempt error:', error);
    res.status(500).json({
      success: false,
      message: 'Error submitting quiz',
      error: error.message
    });
  }
};

/**
 * Get quiz attempts for a student
 */
export const getQuizAttempts = async (req, res) => {
  try {
    const { quizId } = req.params;
    const studentId = req.studentId;

    const attempts = await QuizAttempt.find({
      quizId,
      studentId
    }).sort({ attemptedAt: -1 });

    res.json({
      success: true,
      data: {
        attempts,
        totalAttempts: attempts.length,
        bestScore: attempts.length > 0 
          ? Math.max(...attempts.map(a => a.score))
          : 0
      }
    });
  } catch (error) {
    // console.error('Get attempts error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching attempts',
      error: error.message
    });
  }
};

/**
 * Get quiz analytics
 */
export const getQuizAnalytics = async (req, res) => {
  try {
    const { quizId } = req.params;

    const quiz = await Quiz.findById(quizId);
    if (!quiz) {
      return res.status(404).json({
        success: false,
        message: 'Quiz not found'
      });
    }

    const attempts = await QuizAttempt.find({ quizId });

    const totalAttempts = attempts.length;
    const passedAttempts = attempts.filter(a => a.isPassed).length;
    const avgScore = totalAttempts > 0
      ? (attempts.reduce((sum, a) => sum + a.score, 0) / totalAttempts).toFixed(2)
      : 0;

    res.json({
      success: true,
      data: {
        quizName: quiz._id,
        totalQuestions: quiz.totalQuestions,
        totalAttempts,
        passedAttempts,
        failedAttempts: totalAttempts - passedAttempts,
        passPercentage: totalAttempts > 0 ? ((passedAttempts / totalAttempts) * 100).toFixed(1) : 0,
        averageScore: avgScore,
        maxScore: attempts.length > 0 ? Math.max(...attempts.map(a => a.score)) : 0,
        minScore: attempts.length > 0 ? Math.min(...attempts.map(a => a.score)) : 0
      }
    });
  } catch (error) {
    // console.error('Get analytics error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching analytics',
      error: error.message
    });
  }
};

/**
 * Get quiz status for a student (attempts left, best score, pass/fail status)
 */
export const getQuizStatusForStudent = async (req, res) => {
  try {
    const { quizId } = req.params;
    const studentId = req.studentId;
    const MAX_ATTEMPTS = 3;

    // console.log('🔍 getQuizStatusForStudent called:', { quizId, studentId });

    // Verify quiz exists first
    const quiz = await Quiz.findById(quizId);
    if (!quiz) {
      // console.log('❌ Quiz not found:', quizId);
      return res.status(404).json({
        success: false,
        message: 'Quiz not found'
      });
    }

    // console.log('✅ Quiz found:', quiz._id);

    // Get all attempts for this student on this quiz
    const attempts = await QuizAttempt.find({
      quizId,
      studentId
    }).sort({ attemptedAt: -1 });

    // console.log('📊 Found attempts:', attempts.length);

    const totalAttempts = attempts.length;
    const attemptsLeft = MAX_ATTEMPTS - totalAttempts;
    const canRetake = attemptsLeft > 0;

    // Find best attempt
    let bestAttempt = null;
    if (attempts.length > 0) {
      bestAttempt = attempts.reduce((best, current) => 
        current.score > best.score ? current : best
      );
    }

    // Determine status
    let status = 'not_started'; // not_started | passed | failed
    let passStatus = null; // passed | failed

    if (attempts.length > 0) {
      // Check if any attempt passed
      const passedAttempt = attempts.find(a => a.isPassed);
      if (passedAttempt) {
        status = 'passed';
        passStatus = 'passed';
      } else {
        status = 'failed';
        passStatus = 'failed';
      }
    }

    // console.log('✅ Returning status:', { status, totalAttempts, attemptsLeft });

    res.json({
      success: true,
      data: {
        quizId,
        studentId,
        totalAttempts,
        attemptsLeft,
        canRetake,
        status, // not_started | passed | failed
        passStatus, // null | passed | failed
        bestAttempt: bestAttempt ? {
          attemptId: bestAttempt._id,
          score: bestAttempt.score,
          totalMarks: bestAttempt.totalMarks,
          correctAnswers: bestAttempt.correctAnswers,
          totalQuestions: bestAttempt.totalQuestions,
          isPassed: bestAttempt.isPassed,
          attemptedAt: bestAttempt.attemptedAt
        } : null,
        allAttempts: attempts.map(a => ({
          attemptId: a._id,
          score: a.score,
          totalMarks: a.totalMarks,
          correctAnswers: a.correctAnswers,
          totalQuestions: a.totalQuestions,
          isPassed: a.isPassed,
          attemptedAt: a.attemptedAt
        }))
      }
    });
  } catch (error) {
    // console.error('❌ Get quiz status error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching quiz status',
      error: error.message
    });
  }
};

/**
 * Get best attempt for a quiz by student
 */
export const getBestAttempt = async (req, res) => {
  try {
    const { quizId } = req.params;
    const studentId = req.studentId;

    const bestAttempt = await QuizAttempt.findOne({
      quizId,
      studentId
    }).sort({ score: -1 });

    if (!bestAttempt) {
      return res.json({
        success: true,
        data: null,
        message: 'No attempts found'
      });
    }

    res.json({
      success: true,
      data: {
        attemptId: bestAttempt._id,
        score: bestAttempt.score,
        totalMarks: bestAttempt.totalMarks,
        correctAnswers: bestAttempt.correctAnswers,
        totalQuestions: bestAttempt.totalQuestions,
        isPassed: bestAttempt.isPassed,
        attemptedAt: bestAttempt.attemptedAt
      }
    });
  } catch (error) {
    // console.error('Get best attempt error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching best attempt',
      error: error.message
    });
  }
};

export default {
  parseExcelFile,
  uploadQuiz,
  getQuizByModule,
  getQuizById,
  submitQuizAttempt,
  getQuizAttempts,
  getQuizAnalytics,
  getQuizStatusForStudent,
  getBestAttempt
};
