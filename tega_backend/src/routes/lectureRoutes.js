import express from 'express';
import {
  createLecture,
  getLecturesBySection,
  getLectureWithProgress,
  updateLecture,
  deleteLecture,
  updateProgress,
  submitQuizAttempt,
  upload
} from '../controllers/lectureController.js';
import { adminAuth } from '../middleware/adminAuth.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// Public routes
router.get('/section/:sectionId', getLecturesBySection);
router.get('/:lectureId', getLectureWithProgress);

// Student routes (protected)
router.put('/:lectureId/progress', studentAuth, updateProgress);
router.post('/:lectureId/quiz', studentAuth, submitQuizAttempt);

// Admin routes (protected)
router.post('/', adminAuth, upload.single('file'), createLecture);
router.put('/:lectureId', adminAuth, upload.single('file'), updateLecture);
router.delete('/:lectureId', adminAuth, deleteLecture);

export default router;
