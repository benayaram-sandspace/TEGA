import express from 'express';
import multer from 'multer';
import {
  getAllQuestionPapers,
  getQuestionPapersByCourse,
  uploadQuestionPaper,
  deleteQuestionPaper,
  downloadQuestionTemplate,
  getQuestionPaperDetails,
  getTegaExamQuestionPapers
} from '../controllers/questionPaperController.js';
import { adminAuth } from '../middleware/adminAuth.js';

const router = express.Router();

// Configure multer for in-memory file processing (no disk storage)
const upload = multer({
  storage: multer.memoryStorage(), // Store file in memory instead of disk
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
router.get('/admin/tega-exam', adminAuth, getTegaExamQuestionPapers);
router.get('/admin/course/:courseId', adminAuth, getQuestionPapersByCourse);
// Handle both Excel file upload and JSON data upload
router.post('/admin/upload', adminAuth, upload.single('questionPaper'), handleMulterError, uploadQuestionPaper);
router.post('/admin/upload-json', adminAuth, uploadQuestionPaper);
router.delete('/admin/:questionPaperId', adminAuth, deleteQuestionPaper);
router.get('/admin/template', adminAuth, downloadQuestionTemplate);
router.get('/admin/:questionPaperId', adminAuth, getQuestionPaperDetails);

export default router;
