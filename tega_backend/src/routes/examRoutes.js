import express from 'express';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import {
  getAllExams,
  getAvailableExams,
  createExam,
  registerForExam,
  getExamRegistrations,
  startExam,
  saveAnswer,
  submitExam,
  getExamResults,
  getExamQuestions,
  getAllUserExamResults,
  getAllExamAttempts,
  approveRetake,
  updateExam,
  deleteExam,
  markCompletedExamsInactive,
  reactivateIncorrectlyInactiveExams,
  createExamPaymentAttempt,
  getExamPaymentAttempts
} from '../controllers/examController.js';
import { adminAuth } from '../middleware/adminAuth.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/excel/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' ||
        file.mimetype === 'application/vnd.ms-excel') {
      cb(null, true);
    } else {
      cb(new Error('Only Excel files are allowed'), false);
    }
  },
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  }
});

// Admin routes
router.get('/admin/all', adminAuth, getAllExams);
router.post('/admin/create', adminAuth, createExam);
router.put('/admin/:examId/update', adminAuth, updateExam);
router.delete('/admin/:examId/delete', adminAuth, deleteExam);
router.get('/admin/:examId/registrations', adminAuth, getExamRegistrations);
router.get('/admin/:examId/attempts', adminAuth, getAllExamAttempts);
router.post('/admin/:examId/:studentId/approve-retake', adminAuth, approveRetake);
router.post('/admin/mark-completed-inactive', adminAuth, markCompletedExamsInactive);
router.post('/admin/reactivate-incorrectly-inactive', adminAuth, reactivateIncorrectlyInactiveExams);

// Student routes
router.get('/available/:studentId', studentAuth, getAvailableExams);
router.get('/my-results', studentAuth, getAllUserExamResults); // Get all user exam results

// Exam payment attempt routes (must be before generic /:examId routes)
router.post('/payment-attempt', studentAuth, createExamPaymentAttempt);
router.get('/:examId/payment-attempts', studentAuth, getExamPaymentAttempts);

// Generic exam routes
router.post('/:examId/register', studentAuth, registerForExam);
router.get('/:examId/start', studentAuth, startExam);
router.post('/:examId/save-answer', studentAuth, saveAnswer);
router.post('/:examId/submit', studentAuth, submitExam);
router.get('/:examId/questions', studentAuth, getExamQuestions); // Get exam questions for result viewing
router.get('/:examId/results', studentAuth, getExamResults);
router.get('/:examId/result', studentAuth, getExamResults); // Alias for singular form

export default router;
