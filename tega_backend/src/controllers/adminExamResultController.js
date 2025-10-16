import ExamAttempt from '../models/ExamAttempt.js';
import Exam from '../models/Exam.js';
import Student from '../models/Student.js';

// Get all exam results for admin (grouped by exam and date)
export const getExamResultsForAdmin = async (req, res) => {
  try {
    const { examId, date } = req.query;
    
    let query = { status: 'completed' };
    
    if (examId) {
      query.examId = examId;
    }
    
    if (date) {
      // Filter by exam date
      const startOfDay = new Date(date);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(date);
      endOfDay.setHours(23, 59, 59, 999);
      
      // Get exams that were conducted on this date
      const examsOnDate = await Exam.find({
        examDate: {
          $gte: startOfDay,
          $lte: endOfDay
        }
      }).select('_id');
      
      query.examId = { $in: examsOnDate.map(exam => exam._id) };
    }

    const examAttempts = await ExamAttempt.find(query)
      .populate('studentId', 'name email rollNumber')
      .populate('examId', 'title subject examDate')
      .populate('courseId', 'courseName')
      .sort({ createdAt: -1 });

    // Group results by exam and date
    const groupedResults = {};
    
    examAttempts.forEach(attempt => {
      const examDate = attempt.examId.examDate.toISOString().split('T')[0];
      const key = `${attempt.examId._id}_${examDate}`;
      
      if (!groupedResults[key]) {
        groupedResults[key] = {
          exam: attempt.examId,
          examDate,
          totalStudents: 0,
          publishedStudents: 0,
          unpublishedStudents: 0,
          results: []
        };
      }
      
      groupedResults[key].totalStudents++;
      if (attempt.published) {
        groupedResults[key].publishedStudents++;
      } else {
        groupedResults[key].unpublishedStudents++;
      }
      
      groupedResults[key].results.push({
        _id: attempt._id,
        student: attempt.studentId,
        score: attempt.score,
        totalMarks: attempt.totalMarks,
        percentage: attempt.percentage,
        isPassed: attempt.isPassed,
        isQualified: attempt.isQualified,
        published: attempt.published,
        publishedAt: attempt.publishedAt,
        publishedBy: attempt.publishedBy,
        attemptNumber: attempt.attemptNumber,
        startTime: attempt.startTime,
        endTime: attempt.endTime
      });
    });

    // Convert to array and sort by exam date
    const results = Object.values(groupedResults).sort((a, b) => 
      new Date(b.examDate) - new Date(a.examDate)
    );

    res.json({
      success: true,
      results,
      totalExams: results.length,
      totalStudents: examAttempts.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch exam results'
    });
  }
};

// Publish results for a specific exam and date
export const publishExamResults = async (req, res) => {
  try {
    const { examId, examDate } = req.body;
    const { adminId } = req;

    if (!examId || !examDate) {
      return res.status(400).json({
        success: false,
        message: 'Exam ID and exam date are required'
      });
    }

    // Find all completed exam attempts for this exam and date
    const startOfDay = new Date(examDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(examDate);
    endOfDay.setHours(23, 59, 59, 999);

    const examAttempts = await ExamAttempt.find({
      examId,
      status: 'completed',
      startTime: {
        $gte: startOfDay,
        $lte: endOfDay
      },
      published: false
    });

    if (examAttempts.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No unpublished results found for this exam and date'
      });
    }

    // Update all attempts to published
    const updateResult = await ExamAttempt.updateMany(
      {
        examId,
        status: 'completed',
        startTime: {
          $gte: startOfDay,
          $lte: endOfDay
        },
        published: false
      },
      {
        published: true,
        publishedAt: new Date(),
        publishedBy: adminId
      }
    );

    res.json({
      success: true,
      message: `Successfully published results for ${updateResult.modifiedCount} students`,
      publishedCount: updateResult.modifiedCount,
      examId,
      examDate
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to publish exam results'
    });
  }
};

// Unpublish results for a specific exam and date
export const unpublishExamResults = async (req, res) => {
  try {
    const { examId, examDate } = req.body;
    const { adminId } = req;

    if (!examId || !examDate) {
      return res.status(400).json({
        success: false,
        message: 'Exam ID and exam date are required'
      });
    }

    // Find all published exam attempts for this exam and date
    const startOfDay = new Date(examDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(examDate);
    endOfDay.setHours(23, 59, 59, 999);

    const examAttempts = await ExamAttempt.find({
      examId,
      status: 'completed',
      startTime: {
        $gte: startOfDay,
        $lte: endOfDay
      },
      published: true
    });

    if (examAttempts.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No published results found for this exam and date'
      });
    }

    // Update all attempts to unpublished
    const updateResult = await ExamAttempt.updateMany(
      {
        examId,
        status: 'completed',
        startTime: {
          $gte: startOfDay,
          $lte: endOfDay
        },
        published: true
      },
      {
        published: false,
        publishedAt: null,
        publishedBy: null
      }
    );

    res.json({
      success: true,
      message: `Successfully unpublished results for ${updateResult.modifiedCount} students`,
      unpublishedCount: updateResult.modifiedCount,
      examId,
      examDate
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to unpublish exam results'
    });
  }
};

// Get individual student result details
export const getStudentResultDetails = async (req, res) => {
  try {
    const { attemptId } = req.params;

    const attempt = await ExamAttempt.findById(attemptId)
      .populate('studentId', 'name email rollNumber')
      .populate('examId', 'title subject examDate duration totalMarks passingMarks')
      .populate('courseId', 'courseName')
      .populate('publishedBy', 'name email');

    if (!attempt) {
      return res.status(404).json({
        success: false,
        message: 'Exam attempt not found'
      });
    }

    res.json({
      success: true,
      result: attempt
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch student result details'
    });
  }
};

// Publish all results for a specific date
export const publishAllResultsForDate = async (req, res) => {
  try {
    const { examDate } = req.body;
    
    if (!examDate) {
      return res.status(400).json({
        success: false,
        message: 'Exam date is required'
      });
    }
    
    // Get all exams conducted on this date
    const startOfDay = new Date(examDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(examDate);
    endOfDay.setHours(23, 59, 59, 999);
    
    const examsOnDate = await Exam.find({
      examDate: {
        $gte: startOfDay,
        $lte: endOfDay
      }
    }).select('_id');
    
    if (examsOnDate.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No exams found for this date'
      });
    }
    
    // Publish all results for exams on this date
    const result = await ExamAttempt.updateMany(
      {
        examId: { $in: examsOnDate.map(exam => exam._id) },
        status: 'completed',
        published: false
      },
      {
        $set: {
          published: true,
          publishedAt: new Date(),
          publishedBy: req.adminId
        }
      }
    );
    
    res.json({
      success: true,
      message: `Published ${result.modifiedCount} results for ${examDate}`,
      publishedCount: result.modifiedCount
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to publish results for this date'
    });
  }
};
