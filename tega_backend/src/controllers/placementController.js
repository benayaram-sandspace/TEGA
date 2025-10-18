import PlacementQuestion from '../models/PlacementQuestion.js';
import PlacementModule from '../models/PlacementModule.js';
import PlacementProgress from '../models/PlacementProgress.js';
import MockInterview from '../models/MockInterview.js';

// ============ ADMIN - Question Management ============

export const createQuestion = async (req, res) => {
  try {
    const questionData = {
      ...req.body,
      createdBy: req.user.id
    };

    const question = new PlacementQuestion(questionData);
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

export const getAllQuestions = async (req, res) => {
  try {
    const { type, category, difficulty, topic, search } = req.query;
    
    const filter = {};
    if (type) filter.type = type;
    if (category) filter.category = category;
    if (difficulty) filter.difficulty = difficulty;
    if (topic) filter.topic = topic;
    if (search) {
      filter.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    const questions = await PlacementQuestion.find(filter)
      .populate('createdBy', 'username email')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
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

export const getQuestionById = async (req, res) => {
  try {
    const question = await PlacementQuestion.findById(req.params.id)
      .populate('createdBy', 'username email');

    if (!question) {
      return res.status(404).json({
        success: false,
        message: 'Question not found'
      });
    }

    res.json({
      success: true,
      question
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch question',
      error: error.message
    });
  }
};

export const updateQuestion = async (req, res) => {
  try {
    const question = await PlacementQuestion.findByIdAndUpdate(
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

export const deleteQuestion = async (req, res) => {
  try {
    const question = await PlacementQuestion.findByIdAndDelete(req.params.id);

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

export const bulkUploadQuestions = async (req, res) => {
  try {
    const { questions } = req.body;

    if (!Array.isArray(questions) || questions.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Please provide an array of questions'
      });
    }

    // Add createdBy to all questions
    const questionsWithCreator = questions.map(q => ({
      ...q,
      createdBy: req.user.id
    }));

    const result = await PlacementQuestion.insertMany(questionsWithCreator);

    res.status(201).json({
      success: true,
      message: `${result.length} questions uploaded successfully`,
      count: result.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to upload questions',
      error: error.message
    });
  }
};

// ============ ADMIN - Module Management ============

export const createModule = async (req, res) => {
  try {
    const moduleData = {
      ...req.body,
      createdBy: req.user.id
    };

    const module = new PlacementModule(moduleData);
    await module.save();

    res.status(201).json({
      success: true,
      message: 'Module created successfully',
      module
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create module',
      error: error.message
    });
  }
};

export const getAllModules = async (req, res) => {
  try {
    const { isActive } = req.query;
    const filter = {};
    
    if (isActive !== undefined) {
      filter.isActive = isActive === 'true';
    }

    const modules = await PlacementModule.find(filter)
      .populate('questions')
      .sort({ order: 1 });

    res.json({
      success: true,
      count: modules.length,
      modules
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch modules',
      error: error.message
    });
  }
};

export const updateModule = async (req, res) => {
  try {
    const module = await PlacementModule.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    );

    if (!module) {
      return res.status(404).json({
        success: false,
        message: 'Module not found'
      });
    }

    res.json({
      success: true,
      message: 'Module updated successfully',
      module
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update module',
      error: error.message
    });
  }
};

export const deleteModule = async (req, res) => {
  try {
    const module = await PlacementModule.findByIdAndDelete(req.params.id);

    if (!module) {
      return res.status(404).json({
        success: false,
        message: 'Module not found'
      });
    }

    res.json({
      success: true,
      message: 'Module deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete module',
      error: error.message
    });
  }
};

// ============ STUDENT - Access & Progress ============

export const getStudentModules = async (req, res) => {
  try {
    
    const studentId = req.studentId || req.student?._id || req.user?.id;
    
    if (!studentId) {
      return res.status(400).json({
        success: false,
        message: 'Student ID not found in request'
      });
    }
    
    const modules = await PlacementModule.find({ isActive: true })
      .select('-questions')
      .sort({ order: 1 });
    

    // Get student progress
    let progress = await PlacementProgress.findOne({ studentId });

    if (!progress) {
      // Create initial progress record
      progress = new PlacementProgress({
        studentId,
        moduleProgress: modules.map(m => ({
          moduleId: m._id,
          status: 'not-started',
          progress: 0
        }))
      });
      await progress.save();
    }

    // Merge modules with progress
    const modulesWithProgress = modules.map(module => {
      const moduleProgress = progress.moduleProgress.find(
        mp => mp.moduleId.toString() === module._id.toString()
      );
      
      return {
        ...module.toObject(),
        status: moduleProgress?.status || 'not-started',
        progress: moduleProgress?.progress || 0
      };
    });

    res.json({
      success: true,
      modules: modulesWithProgress,
      overallProgress: {
        assessmentCompleted: progress.assessmentCompleted,
        codingProblemsSolved: progress.codingProblemsSolved,
        mockInterviewsCompleted: progress.mockInterviewsCompleted,
        projectsCompleted: progress.projectsCompleted,
        learningStreak: progress.learningStreak,
        totalPoints: progress.totalPoints
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch modules',
      error: error.message
    });
  }
};

export const getModuleQuestions = async (req, res) => {
  try {
    const { moduleId } = req.params;
    const { difficulty, topic } = req.query;

    const module = await PlacementModule.findById(moduleId).populate('questions');

    if (!module || !module.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Module not found or inactive'
      });
    }

    let questions = module.questions;

    // Filter by difficulty and topic if provided
    if (difficulty) {
      questions = questions.filter(q => q.difficulty === difficulty);
    }
    if (topic) {
      questions = questions.filter(q => q.topic === topic);
    }

    // Remove sensitive data for students
    const sanitizedQuestions = questions.map(q => {
      const qObj = q.toObject();
      
      // For MCQ, don't send correct answers
      if (qObj.type === 'mcq' && qObj.options) {
        qObj.options = qObj.options.map(opt => ({
          text: opt.text,
          _id: opt._id
        }));
      }
      
      // For coding, hide test case outputs
      if (qObj.testCases) {
        qObj.testCases = qObj.testCases.filter(tc => !tc.isHidden).map(tc => ({
          input: tc.input,
          output: tc.output
        }));
      }
      
      delete qObj.explanation;
      return qObj;
    });

    res.json({
      success: true,
      module: {
        _id: module._id,
        title: module.title,
        description: module.description,
        moduleType: module.moduleType
      },
      questions: sanitizedQuestions
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch questions',
      error: error.message
    });
  }
};

export const submitAnswer = async (req, res) => {
  try {
    const { questionId, answer, code, language, timeTaken } = req.body;
    const studentId = req.studentId || req.student?._id || req.user?.id;

    const question = await PlacementQuestion.findById(questionId);
    if (!question) {
      return res.status(404).json({
        success: false,
        message: 'Question not found'
      });
    }

    let isCorrect = false;
    let pointsEarned = 0;
    let feedback = '';

    // Check answer based on question type
    if (question.type === 'mcq') {
      const selectedOption = question.options.find(opt => opt._id.toString() === answer);
      isCorrect = selectedOption && selectedOption.isCorrect;
      if (isCorrect) {
        pointsEarned = question.points;
        feedback = 'Correct answer!';
      } else {
        feedback = 'Incorrect answer. ' + (question.explanation || '');
      }
    } else if (question.type === 'coding') {
      // For coding, we'll mark as submitted and evaluate later
      // In a real system, you'd run the code against test cases
      pointsEarned = question.points / 2; // Partial credit for submission
      feedback = 'Code submitted for evaluation';
      isCorrect = true; // Mark as correct for now
    }

    // Update student progress
    let progress = await PlacementProgress.findOne({ studentId });
    
    if (!progress) {
      progress = new PlacementProgress({ studentId });
    }

    progress.questionAttempts.push({
      questionId,
      attemptedAt: new Date(),
      isCorrect,
      timeTaken,
      answer,
      code,
      language,
      pointsEarned
    });

    progress.totalPoints += pointsEarned;
    
    if (question.type === 'coding' && isCorrect) {
      progress.codingProblemsSolved += 1;
    }

    await progress.save();

    res.json({
      success: true,
      isCorrect,
      pointsEarned,
      feedback,
      explanation: isCorrect ? question.explanation : undefined,
      totalPoints: progress.totalPoints
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to submit answer',
      error: error.message
    });
  }
};

export const getStudentProgress = async (req, res) => {
  try {
    const studentId = req.studentId || req.student?._id || req.user?.id;
    
    let progress = await PlacementProgress.findOne({ studentId })
      .populate('moduleProgress.moduleId', 'title moduleType');

    if (!progress) {
      progress = new PlacementProgress({ studentId });
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

export const updateModuleProgress = async (req, res) => {
  try {
    const { moduleId, status, progress: progressValue } = req.body;
    const studentId = req.studentId || req.student?._id || req.user?.id;

    let progress = await PlacementProgress.findOne({ studentId });
    
    if (!progress) {
      progress = new PlacementProgress({ studentId });
    }

    const moduleProgressIndex = progress.moduleProgress.findIndex(
      mp => mp.moduleId.toString() === moduleId
    );

    if (moduleProgressIndex >= 0) {
      progress.moduleProgress[moduleProgressIndex].status = status;
      progress.moduleProgress[moduleProgressIndex].progress = progressValue;
      
      if (status === 'completed') {
        progress.moduleProgress[moduleProgressIndex].completedAt = new Date();
      } else if (status === 'in-progress' && !progress.moduleProgress[moduleProgressIndex].startedAt) {
        progress.moduleProgress[moduleProgressIndex].startedAt = new Date();
      }
    } else {
      progress.moduleProgress.push({
        moduleId,
        status,
        progress: progressValue,
        startedAt: status !== 'not-started' ? new Date() : undefined,
        completedAt: status === 'completed' ? new Date() : undefined
      });
    }

    await progress.save();

    res.json({
      success: true,
      message: 'Progress updated successfully',
      progress
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update progress',
      error: error.message
    });
  }
};

// ============ MOCK INTERVIEW ============

export const createMockInterview = async (req, res) => {
  try {
    const studentId = req.studentId || req.student?._id || req.user?.id;
    
    const interviewData = {
      ...req.body,
      studentId
    };

    const interview = new MockInterview(interviewData);
    await interview.save();

    // Update student progress
    await PlacementProgress.findOneAndUpdate(
      { studentId },
      { $inc: { mockInterviewsCompleted: 1 } }
    );

    res.status(201).json({
      success: true,
      message: 'Mock interview completed',
      interview
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to save mock interview',
      error: error.message
    });
  }
};

export const getStudentInterviews = async (req, res) => {
  try {
    const studentId = req.studentId || req.student?._id || req.user?.id;
    
    const interviews = await MockInterview.find({ studentId })
      .populate('questions.questionId')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      count: interviews.length,
      interviews
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch interviews',
      error: error.message
    });
  }
};

// ============ ADMIN - Statistics ============

export const getPlacementStats = async (req, res) => {
  try {
    const totalQuestions = await PlacementQuestion.countDocuments();
    const totalModules = await PlacementModule.countDocuments();
    const activeStudents = await PlacementProgress.countDocuments({
      lastActivityDate: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
    });

    // Calculate completion rate
    const totalStudentsWithProgress = await PlacementProgress.countDocuments();
    const completedModulesCount = await PlacementProgress.aggregate([
      { $unwind: '$moduleProgress' },
      { $match: { 'moduleProgress.status': 'completed' } },
      { $count: 'completedCount' }
    ]);
    
    const totalPossibleCompletions = totalStudentsWithProgress * totalModules;
    const completionRate = totalPossibleCompletions > 0 
      ? Math.round(((completedModulesCount[0]?.completedCount || 0) / totalPossibleCompletions) * 100)
      : 0;

    // Calculate top performer score
    const topScoreResult = await PlacementProgress.aggregate([
      { $unwind: '$questionAttempts' },
      { $group: { _id: '$studentId', maxScore: { $max: '$questionAttempts.pointsEarned' } } },
      { $sort: { maxScore: -1 } },
      { $limit: 1 }
    ]);
    const topScore = topScoreResult.length > 0 ? Math.round(topScoreResult[0].maxScore) : 0;

    // Calculate average time per assessment
    const avgTimeResult = await PlacementProgress.aggregate([
      { $unwind: '$questionAttempts' },
      { $match: { 'questionAttempts.timeTaken': { $exists: true, $gt: 0 } } },
      { $group: { _id: null, avgTime: { $avg: '$questionAttempts.timeTaken' } } }
    ]);
    const averageTime = avgTimeResult.length > 0 ? Math.round(avgTimeResult[0].avgTime) : 0;

    // Calculate average score across all attempts
    const avgScoreResult = await PlacementProgress.aggregate([
      { $unwind: '$questionAttempts' },
      { $group: { _id: null, avgScore: { $avg: '$questionAttempts.pointsEarned' } } }
    ]);
    const averageScore = avgScoreResult.length > 0 ? Math.round(avgScoreResult[0].avgScore) : 0;

    const questionsByCategory = await PlacementQuestion.aggregate([
      { $group: { _id: '$category', count: { $sum: 1 } } }
    ]);

    const questionsByDifficulty = await PlacementQuestion.aggregate([
      { $group: { _id: '$difficulty', count: { $sum: 1 } } }
    ]);

    res.json({
      success: true,
      stats: {
        totalQuestions,
        totalModules,
        activeStudents,
        completionRate,
        topScore,
        averageTime,
        averageScore,
        questionsByCategory,
        questionsByDifficulty
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch statistics',
      error: error.message
    });
  }
};

export default {
  createQuestion,
  getAllQuestions,
  getQuestionById,
  updateQuestion,
  deleteQuestion,
  bulkUploadQuestions,
  createModule,
  getAllModules,
  updateModule,
  deleteModule,
  getStudentModules,
  getModuleQuestions,
  submitAnswer,
  getStudentProgress,
  updateModuleProgress,
  createMockInterview,
  getStudentInterviews,
  getPlacementStats
};

