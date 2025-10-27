import express from 'express';
import multer from 'multer';
import { adminAuth } from '../middleware/adminAuth.js';
import { studentAuth } from '../middleware/studentAuth.js';
import {
  uploadQuiz,
  parseExcelFile,
  getQuizByModule,
  getQuizById,
  submitQuizAttempt,
  getQuizAttempts,
  getQuizAnalytics,
  getQuizStatusForStudent,
  getBestAttempt
} from '../controllers/quizController.js';

const router = express.Router();

// Configure multer for Excel file uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    const allowedTypes = [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-excel'
    ];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only Excel files are allowed'));
    }
  },
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB
  }
});

// Admin Routes
router.post('/admin/quiz/parse-excel', adminAuth, upload.single('file'), parseExcelFile);
router.post('/admin/quiz/upload', adminAuth, upload.single('file'), uploadQuiz);
router.get('/admin/quiz/:quizId', adminAuth, getQuizById);
router.get('/admin/quiz/:quizId/analytics', adminAuth, getQuizAnalytics);

// Student Routes - Place more specific routes BEFORE generic :quizId route
router.get('/student/quiz/:quizId/status', studentAuth, getQuizStatusForStudent);
router.get('/student/quiz/:quizId/best-attempt', studentAuth, getBestAttempt);
router.get('/student/quiz/:quizId/attempts', studentAuth, getQuizAttempts);
router.post('/student/quiz/submit', studentAuth, submitQuizAttempt);
router.get('/student/quiz/:quizId', studentAuth, getQuizByModule);

export default router;
