import express from 'express';
import {
  getRealTimeCourses,
  getRealTimeCourse,
  getCourseContent,
  getEnrollmentStatus,
  enrollInCourse,
  updateLectureProgress,
  submitQuiz,
  getCourseAnalytics,
  updateHeartbeat,
  getStudentProgress,
  createRealTimeCourse,
  updateRealTimeCourse,
  deleteRealTimeCourse,
  publishRealTimeCourse,
  getAllCoursesForAdmin
} from '../controllers/realTimeCourseController.js';
import { verifyStudent, verifyAdmin, optionalStudentAuth } from '../middlewares/authMiddleware.js';

const router = express.Router();

// Admin routes - CRUD operations (must come before :courseId routes)
router.get('/admin', verifyAdmin, getAllCoursesForAdmin);
router.get('/admin/all', verifyAdmin, getAllCoursesForAdmin); // Alias for backward compatibility
router.post('/', verifyAdmin, createRealTimeCourse);

// Public routes
router.get('/', getRealTimeCourses);
router.get('/:courseId', verifyStudent, getRealTimeCourse);

// Student routes (require authentication)
router.get('/:courseId/content', verifyStudent, getCourseContent);
router.get('/:courseId/enrollment-status', verifyStudent, getEnrollmentStatus);
router.post('/:courseId/enroll', verifyStudent, enrollInCourse);
router.put('/:courseId/lectures/:lectureId/progress', verifyStudent, updateLectureProgress);
router.post('/:courseId/lectures/:lectureId/quiz', verifyStudent, submitQuiz);
router.put('/:courseId/heartbeat', verifyStudent, updateHeartbeat);
router.get('/:courseId/progress', verifyStudent, getStudentProgress);

// Admin routes - course management
router.put('/:courseId', verifyAdmin, updateRealTimeCourse);
router.delete('/:courseId', verifyAdmin, deleteRealTimeCourse);
router.put('/:courseId/publish', verifyAdmin, publishRealTimeCourse);
router.get('/:courseId/analytics', verifyAdmin, getCourseAnalytics);

export default router;
