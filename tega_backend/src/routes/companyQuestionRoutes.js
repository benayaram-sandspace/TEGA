import express from 'express';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import {
  uploadPDF,
  saveExtractedQuestions,
  createCompanyQuestion,
  getAllCompanyQuestions,
  updateCompanyQuestion,
  deleteCompanyQuestion,
  getCompanyList,
  getCompanyQuestions,
  submitQuizAnswer,
  startQuiz,
  submitQuiz,
  getStudentProgress,
  getLeaderboard
} from '../controllers/companyQuestionController.js';
import { adminAuth } from '../middleware/adminAuth.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// Get current directory for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configure multer for PDF uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '../../uploads/pdfs'));
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'company-questions-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/pdf') {
      cb(null, true);
    } else {
      cb(new Error('Only PDF files are allowed'), false);
    }
  },
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  }
});

// ============ ADMIN ROUTES ============

// PDF Upload and Parsing
router.post('/admin/upload-pdf', adminAuth, (req, res, next) => {
  upload.single('pdf')(req, res, (err) => {
    if (err) {
      return res.status(400).json({
        success: false,
        message: err.message || 'File upload failed',
        error: err.code
      });
    }
    next();
  });
}, uploadPDF);
router.post('/admin/save-questions', adminAuth, saveExtractedQuestions);

// CRUD Operations
router.post('/admin/questions', adminAuth, createCompanyQuestion);
router.get('/admin/questions', adminAuth, getAllCompanyQuestions);
router.put('/admin/questions/:id', adminAuth, updateCompanyQuestion);
router.delete('/admin/questions/:id', adminAuth, deleteCompanyQuestion);

// Company List
router.get('/admin/companies', adminAuth, getCompanyList);

// ============ STUDENT ROUTES ============

// Get available companies
router.get('/companies', studentAuth, getCompanyList);

// Get questions for a company
router.get('/companies/:companyName/questions', studentAuth, getCompanyQuestions);

// Quiz operations
router.post('/quiz/start', studentAuth, startQuiz);
router.post('/quiz/submit-answer', studentAuth, submitQuizAnswer);
router.post('/quiz/submit', studentAuth, submitQuiz);

// Progress and Leaderboard
router.get('/progress/:companyName', studentAuth, getStudentProgress);
router.get('/leaderboard/:companyName', studentAuth, getLeaderboard);

export default router;

