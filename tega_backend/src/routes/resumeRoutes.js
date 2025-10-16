import express from 'express';
import multer from 'multer';
import { 
  getResume, 
  saveResume, 
  getTemplates, 
  downloadResume,
  uploadResume
} from '../controllers/resumeController.js';
import { authRequired } from '../middleware/auth.js';

const router = express.Router();

// Configure multer for memory storage (for Cloudinary upload)
const storage = multer.memoryStorage();

const upload = multer({
  storage: storage,
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/pdf' ||
        file.mimetype === 'application/msword' ||
        file.mimetype === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
      cb(null, true);
    } else {
      cb(new Error('Only PDF and Word documents are allowed'), false);
    }
  },
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  }
});

// Get or create resume for the current user
router.get('/', authRequired, getResume);

// Save resume data
router.post('/', authRequired, saveResume);

// Get available templates
router.get('/templates', authRequired, getTemplates);

// Download resume as PDF using template name
router.post('/download/:templateName', authRequired, downloadResume);

// Upload resume file
router.post('/upload', authRequired, upload.single('resume'), uploadResume);

export default router;
