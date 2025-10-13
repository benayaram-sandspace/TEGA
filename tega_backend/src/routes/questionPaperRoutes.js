import express from 'express';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import {
  getAllQuestionPapers,
  getQuestionPapersByCourse,
  uploadQuestionPaper,
  deleteQuestionPaper,
  downloadQuestionTemplate,
  getQuestionPaperDetails
} from '../controllers/questionPaperController.js';
import { adminAuth } from '../middleware/adminAuth.js';

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

// Error handling middleware for multer
const handleMulterError = (err, req, res, next) => {
  if (err) {
    return res.status(400).json({
      success: false,
      message: err.message
    });
  }
  next();
};

// Admin routes
router.get('/admin/all', adminAuth, getAllQuestionPapers);
router.get('/admin/course/:courseId', adminAuth, getQuestionPapersByCourse);
router.post('/admin/upload', adminAuth, upload.single('questionPaper'), handleMulterError, uploadQuestionPaper);
router.delete('/admin/:questionPaperId', adminAuth, deleteQuestionPaper);
router.get('/admin/template', adminAuth, downloadQuestionTemplate);
router.get('/admin/:questionPaperId', adminAuth, getQuestionPaperDetails);

export default router;
