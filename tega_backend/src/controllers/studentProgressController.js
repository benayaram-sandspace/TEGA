import StudentProgress from '../models/StudentProgress.js';
import Course from '../models/Course.js';

// Get student's overall progress
export const getStudentProgress = async (req, res) => {
  try {
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Student authentication required'
      });
    }

    const progress = await StudentProgress.getStudentProgress(studentId);

    res.json({
      success: true,
      progress
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch student progress',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get student's progress for a specific course
export const getCourseProgress = async (req, res) => {
  try {
    const { courseId } = req.params;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Student authentication required'
      });
    }

    const progress = await StudentProgress.getCourseProgress(studentId, courseId);

    res.json({
      success: true,
      progress
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch course progress',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Mark lecture as completed
export const markLectureCompleted = async (req, res) => {
  try {
    const { lectureId } = req.params;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Student authentication required'
      });
    }

    // Get lecture and its course
    const Lecture = (await import('../models/Lecture.js')).default;
    const lecture = await Lecture.findById(lectureId)
      .populate('sectionId', 'courseId');
    
    if (!lecture) {
      return res.status(404).json({
        success: false,
        message: 'Lecture not found'
      });
    }

    const courseId = lecture.sectionId.courseId;

    // Find or create progress record
    let progress = await StudentProgress.findOne({
      studentId,
      courseId,
      sectionId: lecture.sectionId._id,
      lectureId
    });

    if (!progress) {
      progress = new StudentProgress({
        studentId,
        courseId,
        sectionId: lecture.sectionId._id,
        lectureId
      });
    }

    // Mark as completed
    await progress.markCompleted();

    res.json({
      success: true,
      message: 'Lecture marked as completed',
      progress
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to mark lecture as completed',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get student's learning statistics
export const getLearningStats = async (req, res) => {
  try {
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Student authentication required'
      });
    }

    const stats = await StudentProgress.aggregate([
      { $match: { studentId: studentId } },
      {
        $group: {
          _id: null,
          totalLectures: { $sum: 1 },
          completedLectures: {
            $sum: { $cond: ['$isCompleted', 1, 0] }
          },
          totalTimeSpent: { $sum: '$timeSpent' },
          coursesEnrolled: { $addToSet: '$courseId' }
        }
      },
      {
        $project: {
          _id: 0,
          totalLectures: 1,
          completedLectures: 1,
          totalTimeSpent: 1,
          coursesEnrolled: { $size: '$coursesEnrolled' },
          completionRate: {
            $multiply: [
              { $divide: ['$completedLectures', '$totalLectures'] },
              100
            ]
          }
        }
      }
    ]);

    const result = stats[0] || {
      totalLectures: 0,
      completedLectures: 0,
      totalTimeSpent: 0,
      coursesEnrolled: 0,
      completionRate: 0
    };

    res.json({
      success: true,
      stats: result
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch learning statistics',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
