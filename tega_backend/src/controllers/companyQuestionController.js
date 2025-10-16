import CompanyQuestion from '../models/CompanyQuestion.js';
import CompanyQuizAttempt from '../models/CompanyQuizAttempt.js';
import CompanyProgress from '../models/CompanyProgress.js';
import { parsePDFQuestions, validateQuestions } from '../utils/pdfParser.js';
import { validatePDFContent } from '../utils/pdfValidator.js';
import { parseWithAI } from '../utils/aiPdfParser.js';
import fs from 'fs/promises';
import path from 'path';

// ============ ADMIN - PDF Upload & Parsing ============

export const uploadPDF = async (req, res) => {
  try {

    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No PDF file uploaded'
      });
    }

    const { companyName } = req.body;
    if (!companyName) {
      // Clean up uploaded file
      await fs.unlink(req.file.path);
      return res.status(400).json({
        success: false,
        message: 'Company name is required'
      });
    }

    // Parse PDF (use AI if available, otherwise basic parser)
    const useAI = process.env.GEMINI_API_KEY ? true : false;
    
    const parseResult = useAI 
      ? await parseWithAI(req.file.path, companyName)
      : await parsePDFQuestions(req.file.path, companyName);

    if (!parseResult.success) {
      await fs.unlink(req.file.path);
      return res.status(400).json({
        success: false,
        message: 'Failed to parse PDF'
      });
    }

    // Validate PDF content for extraction issues
    const pdfValidation = validatePDFContent(parseResult.rawText || '', {
      numpages: parseResult.totalPages
    });

    // Validate extracted questions
    const validation = validateQuestions(parseResult.questions);


    // Clean up PDF file
    await fs.unlink(req.file.path);

    res.json({
      success: true,
      message: `Parsed ${validation.totalValid} valid questions from PDF`,
      data: {
        totalPages: parseResult.totalPages,
        totalExtracted: parseResult.questionsFound,
        validQuestions: validation.valid,
        invalidQuestions: validation.invalid,
        pdfFileName: req.file.originalname,
        method: parseResult.method || 'basic', // 'ai-gemini' or 'basic'
        // PDF content validation warnings
        contentWarnings: pdfValidation.warnings || [],
        contentErrors: pdfValidation.errors || [],
        contentIssues: pdfValidation.issues || {},
        textQuality: pdfValidation.summary?.textQuality || 100,
        recommendation: pdfValidation.summary?.recommendation || null
      }
    });
  } catch (error) {
    // Clean up file if exists
    if (req.file) {
      try {
        await fs.unlink(req.file.path);
      } catch (e) {}
    }
    res.status(500).json({
      success: false,
      message: 'Failed to process PDF',
      error: error.message
    });
  }
};

export const saveExtractedQuestions = async (req, res) => {
  try {
    const { questions, pdfFileName } = req.body;

    if (!Array.isArray(questions) || questions.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No questions provided'
      });
    }

    // Add metadata
    const questionsWithMeta = questions.map(q => ({
      ...q,
      pdfFileName,
      createdBy: req.adminId || req.admin?._id || req.user?.id
    }));

    // Insert into database
    const savedQuestions = await CompanyQuestion.insertMany(questionsWithMeta);


    res.status(201).json({
      success: true,
      message: `Successfully saved ${savedQuestions.length} questions`,
      count: savedQuestions.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to save questions',
      error: error.message
    });
  }
};

// ============ ADMIN - Company Question CRUD ============

export const createCompanyQuestion = async (req, res) => {
  try {
    const questionData = {
      ...req.body,
      uploadedFrom: 'manual',
      createdBy: req.adminId || req.admin?._id || req.user?.id
    };

    const question = new CompanyQuestion(questionData);
    await question.save();

    res.status(201).json({
      success: true,
      message: 'Question created successfully',
      question
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create question',
      error: error.message
    });
  }
};

export const getAllCompanyQuestions = async (req, res) => {
  try {
    const { companyName, category, difficulty, search, page = 1, limit = 50 } = req.query;

    const filter = {};
    if (companyName) filter.companyName = companyName;
    if (category) filter.category = category;
    if (difficulty) filter.difficulty = difficulty;
    if (search) {
      filter.$text = { $search: search };
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [questions, total] = await Promise.all([
      CompanyQuestion.find(filter)
        .skip(skip)
        .limit(parseInt(limit))
        .sort({ createdAt: -1 }),
      CompanyQuestion.countDocuments(filter)
    ]);

    res.json({
      success: true,
      questions,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch questions',
      error: error.message
    });
  }
};

export const updateCompanyQuestion = async (req, res) => {
  try {
    const question = await CompanyQuestion.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!question) {
      return res.status(404).json({
        success: false,
        message: 'Question not found'
      });
    }

    res.json({
      success: true,
      message: 'Question updated successfully',
      question
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update question',
      error: error.message
    });
  }
};

export const deleteCompanyQuestion = async (req, res) => {
  try {
    const question = await CompanyQuestion.findByIdAndDelete(req.params.id);

    if (!question) {
      return res.status(404).json({
        success: false,
        message: 'Question not found'
      });
    }

    res.json({
      success: true,
      message: 'Question deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete question',
      error: error.message
    });
  }
};

export const getCompanyList = async (req, res) => {
  try {
    const companies = await CompanyQuestion.distinct('companyName');
    
    // Get question count for each company
    const companiesWithCount = await Promise.all(
      companies.map(async (company) => {
        const count = await CompanyQuestion.countDocuments({ 
          companyName: company,
          isActive: true
        });
        return { name: company, questionCount: count };
      })
    );

    res.json({
      success: true,
      companies: companiesWithCount.sort((a, b) => a.name.localeCompare(b.name))
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch companies',
      error: error.message
    });
  }
};

// ============ STUDENT - Quiz & Practice ============

export const getCompanyQuestions = async (req, res) => {
  try {
    const { companyName } = req.params;
    const { category, difficulty, limit = 20 } = req.query;

    const filter = {
      companyName,
      isActive: true
    };

    if (category) filter.category = category;
    if (difficulty) filter.difficulty = difficulty;

    const questions = await CompanyQuestion.find(filter)
      .select('-correctAnswer -explanation') // Hide answers initially
      .limit(parseInt(limit))
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      companyName,
      count: questions.length,
      questions
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch questions',
      error: error.message
    });
  }
};

export const submitQuizAnswer = async (req, res) => {
  try {
    const { questionId, selectedAnswer, timeTaken } = req.body;
    const studentId = req.studentId || req.student?._id || req.user?.id;

    const question = await CompanyQuestion.findById(questionId);
    if (!question) {
      return res.status(404).json({
        success: false,
        message: 'Question not found'
      });
    }

    // Check if answer is correct
    let isCorrect = false;
    if (question.questionType === 'mcq' || question.questionType === 'true-false') {
      const selectedOption = question.options.find(opt => opt._id.toString() === selectedAnswer);
      isCorrect = selectedOption && selectedOption.isCorrect;
    } else if (question.questionType === 'subjective') {
      // For subjective, do basic comparison (can be enhanced)
      isCorrect = question.correctAnswer && 
                  selectedAnswer.toLowerCase().trim() === question.correctAnswer.toLowerCase().trim();
    }

    const pointsEarned = isCorrect ? question.points : 0;

    // Update question statistics
    question.totalAttempts += 1;
    if (isCorrect) question.correctAttempts += 1;
    await question.save();

    // Update student progress
    await updateStudentProgress(studentId, question.companyName, isCorrect, pointsEarned, timeTaken);

    res.json({
      success: true,
      isCorrect,
      pointsEarned,
      explanation: question.explanation,
      correctAnswer: question.questionType === 'mcq' ? 
        question.options.find(opt => opt.isCorrect)?.text : 
        question.correctAnswer
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to submit answer',
      error: error.message
    });
  }
};

export const startQuiz = async (req, res) => {
  try {
    const { companyName, filters = {} } = req.body;
    const studentId = req.studentId || req.student?._id || req.user?.id;

    const filter = {
      companyName,
      isActive: true,
      ...filters
    };

    const questions = await CompanyQuestion.find(filter)
      .select('-correctAnswer -explanation')
      .limit(20); // Default 20 questions per quiz

    if (questions.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No questions found for this company with the selected filters'
      });
    }

    // Create quiz attempt
    const quizAttempt = new CompanyQuizAttempt({
      studentId,
      companyName,
      questions: [],
      totalQuestions: questions.length,
      filters,
      startedAt: new Date(),
      status: 'in-progress'
    });

    await quizAttempt.save();

    res.json({
      success: true,
      message: 'Quiz started',
      quizId: quizAttempt._id,
      questions,
      totalQuestions: questions.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to start quiz',
      error: error.message
    });
  }
};

export const submitQuiz = async (req, res) => {
  try {
    const { quizId, answers } = req.body;

    const quizAttempt = await CompanyQuizAttempt.findById(quizId);
    if (!quizAttempt) {
      return res.status(404).json({
        success: false,
        message: 'Quiz attempt not found'
      });
    }

    // Process all answers
    let correctAnswers = 0;
    let totalPoints = 0;

    for (const ans of answers) {
      const question = await CompanyQuestion.findById(ans.questionId);
      if (!question) continue;

      let isCorrect = false;
      if (question.questionType === 'mcq') {
        const selectedOption = question.options.find(opt => opt._id.toString() === ans.selectedAnswer);
        isCorrect = selectedOption && selectedOption.isCorrect;
      }

      const pointsEarned = isCorrect ? question.points : 0;
      if (isCorrect) correctAnswers++;
      totalPoints += pointsEarned;

      quizAttempt.questions.push({
        questionId: ans.questionId,
        selectedAnswer: ans.selectedAnswer,
        isCorrect,
        timeTaken: ans.timeTaken,
        pointsEarned
      });

      // Update question stats
      question.totalAttempts += 1;
      if (isCorrect) question.correctAttempts += 1;
      await question.save();
    }

    // Update quiz attempt
    quizAttempt.correctAnswers = correctAnswers;
    quizAttempt.incorrectAnswers = answers.length - correctAnswers;
    quizAttempt.earnedPoints = totalPoints;
    quizAttempt.completedAt = new Date();
    quizAttempt.status = 'completed';
    quizAttempt.totalTimeTaken = answers.reduce((sum, ans) => sum + (ans.timeTaken || 0), 0);

    await quizAttempt.save();

    // Update student progress
    await updateOverallProgress(
      quizAttempt.studentId,
      quizAttempt.companyName,
      quizAttempt._id,
      correctAnswers,
      answers.length,
      totalPoints
    );

    res.json({
      success: true,
      message: 'Quiz completed',
      results: {
        totalQuestions: answers.length,
        correctAnswers,
        incorrectAnswers: answers.length - correctAnswers,
        totalPoints,
        percentage: quizAttempt.percentage,
        timeTaken: quizAttempt.totalTimeTaken
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to submit quiz',
      error: error.message
    });
  }
};

export const getStudentProgress = async (req, res) => {
  try {
    const { companyName } = req.params;
    const studentId = req.studentId || req.student?._id || req.user?.id;

    let progress = await CompanyProgress.findOne({ studentId, companyName });

    if (!progress) {
      progress = new CompanyProgress({ studentId, companyName });
      await progress.save();
    }

    res.json({
      success: true,
      progress
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch progress',
      error: error.message
    });
  }
};

export const getLeaderboard = async (req, res) => {
  try {
    const { companyName } = req.params;
    const { limit = 10 } = req.query;

    const leaderboard = await CompanyProgress.find({ companyName })
      .sort({ totalPoints: -1, overallAccuracy: -1 })
      .limit(parseInt(limit))
      .populate('studentId', 'firstName lastName email');

    res.json({
      success: true,
      companyName,
      leaderboard
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch leaderboard',
      error: error.message
    });
  }
};

// ============ Helper Functions ============

async function updateStudentProgress(studentId, companyName, isCorrect, points, timeTaken) {
  try {
    let progress = await CompanyProgress.findOne({ studentId, companyName });

    if (!progress) {
      progress = new CompanyProgress({ studentId, companyName });
    }

    progress.totalQuestionsAttempted += 1;
    if (isCorrect) {
      progress.totalCorrect += 1;
    } else {
      progress.totalIncorrect += 1;
    }
    progress.totalPoints += points;
    progress.totalTimeSpent += timeTaken || 0;
    progress.averageTimePerQuestion = progress.totalTimeSpent / progress.totalQuestionsAttempted;
    progress.lastAttemptDate = new Date();

    if (points > progress.bestScore) {
      progress.bestScore = points;
    }

    const currentAccuracy = (progress.totalCorrect / progress.totalQuestionsAttempted) * 100;
    if (currentAccuracy > progress.bestAccuracy) {
      progress.bestAccuracy = currentAccuracy;
    }

    await progress.save();
  } catch (error) {
  }
}

async function updateOverallProgress(studentId, companyName, quizAttemptId, correct, total, points) {
  try {
    let progress = await CompanyProgress.findOne({ studentId, companyName });

    if (!progress) {
      progress = new CompanyProgress({ studentId, companyName });
    }

    progress.quizAttempts.push({
      attemptId: quizAttemptId,
      score: points,
      completedAt: new Date()
    });

    progress.averageScore = progress.quizAttempts.reduce((sum, attempt) => sum + attempt.score, 0) / progress.quizAttempts.length;

    await progress.save();
  } catch (error) {
  }
}

export default {
  uploadPDF,
  saveExtractedQuestions,
  createCompanyQuestion,
  getAllCompanyQuestions,
  updateCompanyQuestion,
  deleteCompanyQuestion,
  getCompanyList,
  getCompanyQuestions,
  submitQuizAnswer,
  startQuiz,
  submitQuiz,
  getStudentProgress,
  getLeaderboard
};

