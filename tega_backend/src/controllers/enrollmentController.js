import Enrollment from "../models/Enrollment.js";
import RealTimeCourse from "../models/RealTimeCourse.js";
import RealTimeProgress from "../models/RealTimeProgress.js";
// Enrollment functionality now in Enrollment model
import mongoose from "mongoose";

// Enroll student in course - CONSOLIDATED TO USE ONLY REALTIMECOURSE
export const enrollInCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: "Student authentication required",
      });
    }

    // Use only RealTimeCourse model (R2-based system)
    const course = await RealTimeCourse.findById(courseId);

    if (!course) {
      return res.status(404).json({
        success: false,
        message: "Course not found",
      });
    }

    // Check if already enrolled
    const existingEnrollment = await Enrollment.findOne({
      studentId,
      courseId,
    });

    if (existingEnrollment) {
      return res.status(400).json({
        success: false,
        message: "Already enrolled in this course",
      });
    }

    // Create enrollment
    const enrollment = new Enrollment({
      studentId,
      courseId,
      isPaid: course.isFree || course.price === 0,
      enrolledAt: new Date(),
      status: "active",
    });

    await enrollment.save();

    // Initialize RealTimeProgress for all courses
    const totalModules = course.modules?.length || 0;
    const totalLectures =
      course.modules?.reduce(
        (total, module) => total + (module.lectures?.length || 0),
        0
      ) || 0;

    const progress = new RealTimeProgress({
      studentId: new mongoose.Types.ObjectId(studentId),
      courseId: new mongoose.Types.ObjectId(courseId),
      totalModules,
      totalLectures,
      overallProgress: {
        totalModules,
        totalLectures,
        completedModules: 0,
        completedLectures: 0,
        progressPercentage: 0,
      },
    });

    await progress.save();

    // Update enrollment count
    await course.incrementEnrollment();

    res.status(201).json({
      success: true,
      message: "Successfully enrolled in course",
      enrollment,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to enroll in course",
      error: process.env.NODE_ENV === "development" ? error.message : undefined,
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
        message: "Student authentication required",
      });
    }

    // Use only RealTimeCourse model (R2-based system)
    const course = await RealTimeCourse.findById(courseId);

    if (!course) {
      return res.status(404).json({
        success: false,
        message: "Course not found",
      });
    }

    // Check both Enrollment and Enrollment records
    const enrollment = await Enrollment.findOne({
      studentId,
      courseId,
    });

    const userCourse = await Enrollment.findOne({
      studentId,
      courseId,
      isActive: true,
      accessExpiresAt: { $gt: new Date() },
    });

    const isEnrolled = !!(enrollment || userCourse);

    res.json({
      success: true,
      enrolled: isEnrolled,
      enrollment: enrollment || userCourse || null,
      course: {
        title: course.title,
        price: course.price,
        isFree: course.isFree,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to check enrollment",
      error: process.env.NODE_ENV === "development" ? error.message : undefined,
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
        message: "Student authentication required",
      });
    }
    const enrollments = await Enrollment.getStudentEnrollments(studentId);
    const userCourses = await Enrollment.getActiveCourses(studentId);
    // Combine both enrollment types
    const allEnrollments = [...enrollments, ...userCourses];
    res.json({
      success: true,
      enrollments: allEnrollments,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to get enrollments",
      error: process.env.NODE_ENV === "development" ? error.message : undefined,
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
        message: "Student authentication required",
      });
    }

    // Get course using RealTimeCourse model
    const course = await RealTimeCourse.findById(courseId);

    // Find lecture in course modules
    let lecture = null;
    let moduleIndex = -1;
    let lectureIndex = -1;

    if (course && course.modules && Array.isArray(course.modules)) {
      for (let mIdx = 0; mIdx < course.modules.length; mIdx++) {
        const module = course.modules[mIdx];
        if (module.lectures && Array.isArray(module.lectures)) {
          for (let lIdx = 0; lIdx < module.lectures.length; lIdx++) {
            if (module.lectures[lIdx].id === lectureId) {
              lecture = module.lectures[lIdx];
              moduleIndex = mIdx;
              lectureIndex = lIdx;
              break;
            }
          }
        }
        if (lecture) break;
      }
    }

    if (!course || !lecture) {
      return res.status(404).json({
        success: false,
        message: "Course or lecture not found",
      });
    }

    // Check if it's the first lecture (always free)
    const isFirstLecture = moduleIndex === 0 && lectureIndex === 0;

    // Additional check: if it's marked as preview, it should be free
    const isPreview = lecture.isPreview || false;

    // Check both Enrollment and Enrollment records
    const enrollment = await Enrollment.findOne({
      studentId,
      courseId,
    });

    const userCourse = await Enrollment.findOne({
      studentId,
      courseId,
      isActive: true,
      accessExpiresAt: { $gt: new Date() },
    });

    let hasAccess = false;
    let reason = "";

    if (isFirstLecture || isPreview) {
      hasAccess = true;
      reason = isFirstLecture
        ? "First lecture is free"
        : "Preview lecture is free";
    } else if (course.isFree || course.price === 0) {
      hasAccess = true;
      reason = "Course is free";
    } else if (enrollment && enrollment.status === "active") {
      hasAccess = true;
      reason = "Enrolled in course";
    } else if (userCourse) {
      hasAccess = true;
      reason = "Course purchased";
    } else {
      hasAccess = false;
      reason = "Enrollment required";
    }

    res.json({
      success: true,
      hasAccess,
      reason,
      isFirstLecture,
      isPreview,
      course: {
        title: course.title,
        price: course.price,
        isFree: course.isFree,
      },
      enrollment: enrollment || userCourse || null,
      lecture: {
        id: lecture.id,
        title: lecture.title,
        type: lecture.type,
        duration: lecture.duration,
        isPreview: isPreview,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to check lecture access",
      error: process.env.NODE_ENV === "development" ? error.message : undefined,
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
        message: "Student authentication required",
      });
    }

    const enrollment = await Enrollment.findOneAndUpdate(
      { studentId, courseId },
      { status: "cancelled" },
      { new: true }
    );

    if (!enrollment) {
      return res.status(404).json({
        success: false,
        message: "Enrollment not found",
      });
    }

    res.json({
      success: true,
      message: "Successfully unenrolled from course",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to unenroll from course",
      error: process.env.NODE_ENV === "development" ? error.message : undefined,
    });
  }
};
