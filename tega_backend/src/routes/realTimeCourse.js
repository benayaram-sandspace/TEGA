import express from 'express';
import {
  getRealTimeCourses,
  getRealTimeCourse,
  getCourseContent,
  getEnrollmentStatus,
  enrollInCourse,
  updateLectureProgress,
  updateLectureDuration,
  submitQuiz,
  getCourseAnalytics,
  updateHeartbeat,
  getStudentProgress,
  getAllStudentProgress,
  createRealTimeCourse,
  updateRealTimeCourse,
  deleteRealTimeCourse,
  publishRealTimeCourse,
  getAllCoursesForAdmin
} from '../controllers/realTimeCourseController.js';
import { adminAuth } from '../middleware/adminAuth.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// Admin routes - CRUD operations (must come before :courseId routes)
router.get('/admin/all', adminAuth, getAllCoursesForAdmin);
router.post('/', adminAuth, createRealTimeCourse);

// Public routes
router.get('/', getRealTimeCourses);

// Student routes (require authentication) - specific routes must come before generic ones
router.get('/progress/all', studentAuth, getAllStudentProgress); // Must come before :courseId routes
router.get('/:courseId/content', studentAuth, getCourseContent);
router.get('/:courseId/enrollment-status', studentAuth, getEnrollmentStatus);
router.get('/:courseId/progress', studentAuth, getStudentProgress); // Must come before :courseId route
router.post('/:courseId/enroll', studentAuth, enrollInCourse);
router.put('/:courseId/lectures/:lectureId/progress', studentAuth, updateLectureProgress);
router.put('/:courseId/lectures/:lectureId/duration', studentAuth, updateLectureDuration);
router.post('/:courseId/lectures/:lectureId/quiz', studentAuth, submitQuiz);
router.put('/:courseId/heartbeat', studentAuth, updateHeartbeat);
router.get('/:courseId', studentAuth, getRealTimeCourse); // Generic route must come last

// Admin routes - course management
router.put('/:courseId', adminAuth, updateRealTimeCourse);
router.delete('/:courseId', adminAuth, deleteRealTimeCourse);
router.put('/:courseId/publish', adminAuth, publishRealTimeCourse);
router.get('/:courseId/analytics', adminAuth, getCourseAnalytics);

// Admin routes - video validation and fixing (functions to be implemented)
// router.get('/:courseId/validate-videos', verifyAdmin, validateCourseVideos);
// router.post('/:courseId/fix-duplicate-videos', verifyAdmin, fixDuplicateVideos);

export default router;
