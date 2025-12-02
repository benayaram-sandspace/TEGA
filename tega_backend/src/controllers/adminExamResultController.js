import ExamAttempt from '../models/ExamAttempt.js';
import Exam from '../models/Exam.js';
import Student from '../models/Student.js';

// Get all exam results for admin (grouped by exam and date)
export const getExamResultsForAdmin = async (req, res) => {
  try {
    const { examId, date, examType } = req.query;
    let query = { status: 'completed' };
    
    if (examId) {
      query.examId = examId;
    }
    
    if (date) {
      // Filter by the actual attempt date (when the exam was taken)
      const startOfDay = new Date(date);
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date(date);
      endOfDay.setHours(23, 59, 59, 999);
      // Filter by attempt date directly
      query.startTime = {
        $gte: startOfDay,
        $lte: endOfDay
      };
      
      // If examType is specified, we need to filter by exam type after population
      // We'll handle this in the grouping logic below
    }

    const examAttempts = await ExamAttempt.find(query)
      .populate('studentId', 'name email rollNumber')
      .populate('examId', 'title subject examDate')
      .populate('courseId', 'courseName')
      .sort({ createdAt: -1 });
    // Filter by exam type if specified (after population)
    let filteredAttempts = examAttempts;
    if (examType === 'tega') {
      filteredAttempts = examAttempts.filter(attempt => 
        attempt.examId && (!attempt.examId.courseId || attempt.examId.courseId === null)
      );
    } else if (examType === 'course') {
      filteredAttempts = examAttempts.filter(attempt => 
        attempt.examId && attempt.examId.courseId && attempt.examId.courseId !== null
      );
    }

    // Group results by exam and date
    const groupedResults = {};
    
    filteredAttempts.forEach(attempt => {
      // Check if examId is populated
      if (!attempt.examId) {
        return;
      }
      
      // Use the actual attempt date instead of exam scheduled date
      const attemptDate = attempt.startTime.toISOString().split('T')[0];
      const key = `${attempt.examId._id}_${attemptDate}`;
      if (!groupedResults[key]) {
        groupedResults[key] = {
          examId: attempt.examId._id,
          examTitle: attempt.examId.title || `Exam ${attempt.examId._id}`,
          examDate: attemptDate,
          courseTitle: attempt.courseId?.courseName || null,
          totalStudents: 0,
          passedStudents: 0,
          failedStudents: 0,
          totalScore: 0,
          isPublished: false,
          students: []
        };
      }
      
      groupedResults[key].totalStudents++;
      groupedResults[key].totalScore += attempt.percentage || 0;
      
      if (attempt.isPassed) {
        groupedResults[key].passedStudents++;
      } else {
        groupedResults[key].failedStudents++;
      }
      
      // Check if any result is published to set isPublished flag
      if (attempt.published) {
        groupedResults[key].isPublished = true;
      }
      
      groupedResults[key].students.push({
        _id: attempt._id,
        studentName: attempt.studentId?.name || attempt.studentId?.email,
        email: attempt.studentId?.email,
        score: attempt.score,
        totalMarks: attempt.totalMarks,
        percentage: attempt.percentage,
        isPassed: attempt.isPassed,
        published: attempt.published,
        attemptNumber: attempt.attemptNumber
      });
    });

    // Convert to array, calculate averages, and sort by exam date
    const results = Object.values(groupedResults).map(group => ({
      ...group,
      averagePercentage: group.totalStudents > 0 ? group.totalScore / group.totalStudents : 0
    })).sort((a, b) => 
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

// Publish/Unpublish results for a specific exam and date
export const publishExamResults = async (req, res) => {
  try {
    const { examId, examDate, publish = true } = req.body;
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

    const filter = {
      examId,
      status: 'completed',
      startTime: {
        $gte: startOfDay,
        $lte: endOfDay
      }
    };

    // If publishing, only update unpublished results
    // If unpublishing, only update published results
    if (publish) {
      filter.published = false;
    } else {
      filter.published = true;
    }

    let examAttempts = await ExamAttempt.find(filter);

    // If no results found with startTime filtering, try with createdAt
    if (examAttempts.length === 0) {
      const fallbackFilter = { ...filter };
      delete fallbackFilter.startTime;
      fallbackFilter.createdAt = {
        $gte: startOfDay,
        $lte: endOfDay
      };
      examAttempts = await ExamAttempt.find(fallbackFilter);
    }

    // If still no results, try without date filtering
    if (examAttempts.length === 0) {
      const noDateFilter = {
        examId,
        status: 'completed'
      };
      if (publish) {
        noDateFilter.published = false;
      } else {
        noDateFilter.published = true;
      }
      examAttempts = await ExamAttempt.find(noDateFilter);
    }



    if (examAttempts.length === 0) {
      return res.status(404).json({
        success: false,
        message: publish 
          ? 'No unpublished results found for this exam and date'
          : 'No published results found for this exam and date'
      });
    }

    // Update all attempts
    const updateData = {
      published: publish
    };

    if (publish) {
      updateData.publishedAt = new Date();
      updateData.publishedBy = adminId;
    } else {
      updateData.publishedAt = null;
      updateData.publishedBy = null;
    }

    // Try multiple update approaches to ensure we find and update the correct records
    let updateResult = await ExamAttempt.updateMany(filter, updateData);

    // If no updates with startTime filter, try with createdAt
    if (updateResult.modifiedCount === 0) {
      const fallbackFilter = { ...filter };
      delete fallbackFilter.startTime;
      fallbackFilter.createdAt = {
        $gte: startOfDay,
        $lte: endOfDay
      };
      updateResult = await ExamAttempt.updateMany(fallbackFilter, updateData);
    }

    // If still no updates, try without date filter
    if (updateResult.modifiedCount === 0) {
      const noDateFilter = {
        examId,
        status: 'completed'
      };
      if (publish) {
        noDateFilter.published = false;
      } else {
        noDateFilter.published = true;
      }
      updateResult = await ExamAttempt.updateMany(noDateFilter, updateData);
    }


    // Emit WebSocket event for real-time updates
    const io = req.app.get('io');
    if (io) {
      const eventName = publish ? 'exam-result-published' : 'exam-result-unpublished';
      io.emit(eventName, {
        examId,
        examDate,
        publishedCount: updateResult.modifiedCount,
        adminId,
        timestamp: new Date()
      });
      
      // Also emit a general exam result update event
      io.emit('exam-result-updated', {
        examId,
        examDate,
        action: publish ? 'published' : 'unpublished',
        count: updateResult.modifiedCount,
        adminId,
        timestamp: new Date()
      });
      
    }

    res.json({
      success: true,
      message: publish
        ? `Successfully published results for ${updateResult.modifiedCount} students`
        : `Successfully unpublished results for ${updateResult.modifiedCount} students`,
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



    // First, let's check what exam attempts exist for this exam
    const allAttempts = await ExamAttempt.find({
      examId,
      status: 'completed'
    }).select('_id startTime published examId status');



    // Try multiple query approaches to find published results
    let examAttempts = await ExamAttempt.find({
      examId,
      status: 'completed',
      startTime: {
        $gte: startOfDay,
        $lte: endOfDay
      },
      published: true
    });

    // If no results found with startTime filtering, try with createdAt
    if (examAttempts.length === 0) {
      examAttempts = await ExamAttempt.find({
        examId,
        status: 'completed',
        createdAt: {
          $gte: startOfDay,
          $lte: endOfDay
        },
        published: true
      });
    }

    // If still no results, try without date filtering but with published status
    if (examAttempts.length === 0) {
      examAttempts = await ExamAttempt.find({
        examId,
        status: 'completed',
        published: true
      });
    }



    if (examAttempts.length === 0) {
      // Try a fallback query without date filtering to see if there are any published results
      const fallbackAttempts = await ExamAttempt.find({
        examId,
        status: 'completed',
        published: true
      });



      return res.status(404).json({
        success: false,
        message: 'No published results found for this exam and date'
      });
    }

    // Update all attempts to unpublished using the same flexible approach
    let updateResult;
    
    // First try with startTime filter
    updateResult = await ExamAttempt.updateMany(
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

    // If no updates with startTime, try with createdAt
    if (updateResult.modifiedCount === 0) {
      updateResult = await ExamAttempt.updateMany(
        {
          examId,
          status: 'completed',
          createdAt: {
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
    }

    // If still no updates, try without date filter
    if (updateResult.modifiedCount === 0) {
      updateResult = await ExamAttempt.updateMany(
        {
          examId,
          status: 'completed',
          published: true
        },
        {
          published: false,
          publishedAt: null,
          publishedBy: null
        }
      );
    }

    // Emit WebSocket event for real-time updates
    const io = req.app.get('io');
    if (io) {
      io.emit('exam-result-unpublished', {
        examId,
        examDate,
        unpublishedCount: updateResult.modifiedCount,
        adminId,
        timestamp: new Date()
      });
      
      // Also emit a general exam result update event
      io.emit('exam-result-updated', {
        examId,
        examDate,
        action: 'unpublished',
        count: updateResult.modifiedCount,
        adminId,
        timestamp: new Date()
      });
      
    }

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

// Publish all results for a specific date and exam type
// Clear dummy exam data
export const clearDummyExamData = async (req, res) => {
  try {
    const { adminId } = req;
    // Find and delete exam attempts with dummy data
    // (score = 0, percentage = 0, or no proper exam title)
    const dummyAttempts = await ExamAttempt.find({
      status: 'completed',
      $or: [
        { score: 0 },
        { percentage: 0 },
        { percentage: { $exists: false } },
        { score: { $exists: false } }
      ]
    });
    if (dummyAttempts.length === 0) {
      return res.json({
        success: true,
        message: 'No dummy data found to clear',
        deletedCount: 0
      });
    }
    
    // Delete dummy attempts
    const result = await ExamAttempt.deleteMany({
      status: 'completed',
      $or: [
        { score: 0 },
        { percentage: 0 },
        { percentage: { $exists: false } },
        { score: { $exists: false } }
      ]
    });
    res.json({
      success: true,
      message: `Successfully cleared ${result.deletedCount} dummy exam attempts`,
      deletedCount: result.deletedCount
    });
    
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to clear dummy data'
    });
  }
};

export const publishAllResultsForDate = async (req, res) => {
  try {
    const { date, examType } = req.body;
    const { adminId } = req;
    if (!date) {
      return res.status(400).json({
        success: false,
        message: 'Date is required'
      });
    }
    
    // Get all exams conducted on this date
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);
    
    // Build exam filter
    let examFilter = {
      examDate: {
        $gte: startOfDay,
        $lte: endOfDay
      }
    };
    
    // Filter by exam type
    if (examType === 'tega') {
      examFilter.courseId = null;
    } else if (examType === 'course') {
      examFilter.courseId = { $ne: null };
    }
    
    const examsOnDate = await Exam.find(examFilter).select('_id');
    if (examsOnDate.length === 0) {
      return res.status(404).json({
        success: false,
        message: `No ${examType === 'tega' ? 'TEGA' : 'course'} exams found for this date`
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
          publishedBy: adminId
        }
      }
    );
    res.json({
      success: true,
      message: `Published ${result.modifiedCount} ${examType === 'tega' ? 'TEGA' : 'course'} exam results for ${date}`,
      publishedCount: result.modifiedCount
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to publish results for this date'
    });
  }
};
