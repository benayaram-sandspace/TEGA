import express from 'express';
import {
  getStudentProgress,
  getCourseProgress,
  markLectureCompleted,
  getLearningStats
} from '../controllers/studentProgressController.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// All routes require student authentication
router.use(studentAuth);

// Get student's overall progress
router.get('/', getStudentProgress);

// Get student's progress for a specific course
router.get('/course/:courseId', getCourseProgress);

// Mark lecture as completed
router.put('/lecture/:lectureId/complete', markLectureCompleted);

// Get learning statistics
router.get('/stats', getLearningStats);

export default router;
