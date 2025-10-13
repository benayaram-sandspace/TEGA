import Enrollment from '../models/Enrollment.js';
import Course from '../models/Course.js';
import RealTimeCourse from '../models/RealTimeCourse.js';
import RealTimeProgress from '../models/RealTimeProgress.js';
import Section from '../models/Section.js';
import Lecture from '../models/Lecture.js';
import StudentProgress from '../models/StudentProgress.js';
import UserCourse from '../models/UserCourse.js';
import mongoose from 'mongoose';

// Enroll student in course
export const enrollInCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Student authentication required'
      });
    }

    // Check if course exists - try both Course and RealTimeCourse models
    let course = await Course.findById(courseId);
    let isRealTimeCourse = false;
    
    if (!course) {
      course = await RealTimeCourse.findById(courseId);
      isRealTimeCourse = true;
    }
    
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // Check if already enrolled
    const existingEnrollment = await Enrollment.findOne({
      studentId,
      courseId
    });

    if (existingEnrollment) {
      return res.status(400).json({
        success: false,
        message: 'Already enrolled in this course'
      });
    }

    // Create enrollment
    const enrollment = new Enrollment({
      studentId,
      courseId,
      isPaid: course.isFree || course.price === 0,
      enrolledAt: new Date(),
      status: 'active'
    });

    await enrollment.save();

    // Initialize progress based on course type
    if (isRealTimeCourse) {
      // For RealTimeCourse, initialize RealTimeProgress
      const lectureProgress = [];
      
      if (course.modules && course.modules.length > 0) {
        for (const module of course.modules) {
          if (module.lectures && module.lectures.length > 0) {
            for (const lecture of module.lectures) {
              lectureProgress.push({
                lectureId: lecture._id,
                moduleId: module._id,
                completed: false,
                watchTime: 0,
                lastWatchedAt: null
              });
            }
          }
        }
      }
      
      const progress = new RealTimeProgress({
        studentId: new mongoose.Types.ObjectId(studentId),
        courseId: new mongoose.Types.ObjectId(courseId),
        lectureProgress,
        overallProgress: {
          completedLectures: 0,
          totalLectures: lectureProgress.length,
          percentageComplete: 0
        }
      });
      
      await progress.save();
      
      // Update enrollment count
      course.enrollmentCount = (course.enrollmentCount || 0) + 1;
      await course.save();
      
    } else {
      // For regular Course, initialize StudentProgress
      const sections = await Section.find({ courseId });
      const lectures = await Lecture.find({
        sectionId: { $in: sections.map(s => s._id) }
      });

      for (const lecture of lectures) {
        const progress = new StudentProgress({
          studentId,
          courseId,
          sectionId: lecture.sectionId,
          lectureId: lecture._id
        });
        await progress.save();
      }
    }

    res.status(201).json({
      success: true,
      message: 'Successfully enrolled in course',
      enrollment
    });

  } catch (error) {
    console.error('Enrollment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to enroll in course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Check enrollment status
export const checkEnrollment = async (req, res) => {
  try {
    const { courseId } = req.params;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Student authentication required'
      });
    }

    // Check if course exists - try both models
    let course = await Course.findById(courseId);
    
    if (!course) {
      course = await RealTimeCourse.findById(courseId);
    }

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // Check both Enrollment and UserCourse records
    const enrollment = await Enrollment.findOne({
      studentId,
      courseId
    });

    const userCourse = await UserCourse.findOne({
      studentId,
      courseId,
      isActive: true,
      accessExpiresAt: { $gt: new Date() }
    });


    const isEnrolled = !!(enrollment || userCourse);

    res.json({
      success: true,
      enrolled: isEnrolled,
      enrollment: enrollment || userCourse || null,
      course: {
        title: course.title,
        price: course.price,
        isFree: course.isFree
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to check enrollment',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get student's enrollments
export const getStudentEnrollments = async (req, res) => {
  try {
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Student authentication required'
      });
    }

    const enrollments = await Enrollment.getStudentEnrollments(studentId);
    const userCourses = await UserCourse.getActiveCourses(studentId);

    // Combine both enrollment types
    const allEnrollments = [...enrollments, ...userCourses];

    res.json({
      success: true,
      enrollments: allEnrollments
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get enrollments',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Check lecture access
export const checkLectureAccess = async (req, res) => {
  try {
    const { courseId, lectureId } = req.params;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Student authentication required'
      });
    }

    // Get course - try both models
    let course = await Course.findById(courseId);
    let isRealTimeCourse = false;
    
    if (!course) {
      course = await RealTimeCourse.findById(courseId);
      isRealTimeCourse = true;
    }
    
    const lecture = await Lecture.findById(lectureId);

    // If lecture not found in Lecture collection, check if it's a video in course modules
    let videoAccess = null;
    if (!lecture && course) {
      if (course.modules && Array.isArray(course.modules)) {
        for (const module of course.modules) {
          if (module.videos && Array.isArray(module.videos)) {
            const video = module.videos.find(v => v._id?.toString() === lectureId || v.id === lectureId);
            if (video) {
              videoAccess = {
                _id: video._id || video.id,
                title: video.title,
                videoUrl: video.videoLink || video.videoUrl,
                isPreview: video.isPreview || false
              };
              break;
            }
          }
        }
      }
    }

    if (!course || (!lecture && !videoAccess)) {
      return res.status(404).json({
        success: false,
        message: 'Course or lecture not found'
      });
    }

    // Check if it's the first lecture/video (always free)
    let isFirstLecture = false;
    
    if (lecture) {
      // Traditional lecture structure
      const sections = await Section.find({ courseId }).sort({ order: 1 });
      const firstSection = sections[0];
      const firstLecture = firstSection ? await Lecture.findOne({ sectionId: firstSection._id }).sort({ order: 1 }) : null;
      isFirstLecture = firstLecture && firstLecture._id.toString() === lectureId;
    } else if (videoAccess) {
      // Module-based video structure - NO module videos should be free by default
      // Only course introduction (handled separately) should be free
      isFirstLecture = false;
    }
    
    // Additional check: if it's marked as preview, it should be free
    if (lecture && lecture.isPreview) {
      isFirstLecture = true;
    } else if (videoAccess && videoAccess.isPreview) {
      isFirstLecture = true;
    }

    // Check both Enrollment and UserCourse records
    const enrollment = await Enrollment.findOne({
      studentId,
      courseId
    });

    const userCourse = await UserCourse.findOne({
      studentId,
      courseId,
      isActive: true,
      accessExpiresAt: { $gt: new Date() }
    });

    let hasAccess = false;
    let reason = '';

    if (isFirstLecture) {
      hasAccess = true;
      reason = 'First lecture is free';
    } else if (course.isFree || course.price === 0) {
      hasAccess = true;
      reason = 'Course is free';
    } else if (enrollment && enrollment.status === 'active') {
      hasAccess = true;
      reason = 'Enrolled in course';
    } else if (userCourse) {
      hasAccess = true;
      reason = 'Course purchased';
    } else {
      hasAccess = false;
      reason = 'Enrollment required';
    }


    res.json({
      success: true,
      hasAccess,
      reason,
      isFirstLecture,
      course: {
        title: course.title,
        price: course.price,
        isFree: course.isFree
      },
      enrollment: enrollment || userCourse || null,
      lecture: lecture || videoAccess
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to check lecture access',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Unenroll from course
export const unenrollFromCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Student authentication required'
      });
    }

    const enrollment = await Enrollment.findOneAndUpdate(
      { studentId, courseId },
      { status: 'cancelled' },
      { new: true }
    );

    if (!enrollment) {
      return res.status(404).json({
        success: false,
        message: 'Enrollment not found'
      });
    }

    res.json({
      success: true,
      message: 'Successfully unenrolled from course'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to unenroll from course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
