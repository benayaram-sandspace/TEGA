import express from 'express';
import { 
  generateVideoUploadUrl,
  generateDocumentUploadUrl,
  confirmVideoUpload,
  uploadCourseMaterial,
  confirmDocumentUpload,
  getMaterialsByCourse,
  getMaterialsByLecture,
  generateMaterialDownloadUrl,
  deleteMaterial,
  upload
} from '../controllers/r2UploadController.js';
import { verifyAdmin, verifyStudent } from '../middlewares/authMiddleware.js';

const router = express.Router();

// Admin routes - Video uploads
router.post('/generate-video-upload-url', verifyAdmin, generateVideoUploadUrl);
router.post('/confirm-video-upload', verifyAdmin, confirmVideoUpload);

// Admin routes - Document uploads
router.post('/generate-document-upload-url', verifyAdmin, generateDocumentUploadUrl);
router.post('/confirm-document-upload', verifyAdmin, confirmDocumentUpload);
router.post('/upload-material', verifyAdmin, upload.single('file'), uploadCourseMaterial);

// Admin routes - Material management
router.delete('/material/:materialId', verifyAdmin, deleteMaterial);

// Student/Admin routes - Material access
router.get('/materials/course/:courseId', getMaterialsByCourse);
router.get('/materials/lecture/:lectureId', getMaterialsByLecture);
router.get('/material/:materialId/download', generateMaterialDownloadUrl);

export default router;

