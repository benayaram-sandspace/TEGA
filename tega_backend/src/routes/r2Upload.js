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
import { adminAuth } from '../middleware/adminAuth.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// Admin routes - Video uploads
router.post('/generate-video-upload-url', adminAuth, generateVideoUploadUrl);
router.post('/confirm-video-upload', adminAuth, confirmVideoUpload);

// Admin routes - Document uploads
router.post('/generate-document-upload-url', adminAuth, generateDocumentUploadUrl);
router.post('/confirm-document-upload', adminAuth, confirmDocumentUpload);
router.post('/upload-material', adminAuth, upload.single('file'), uploadCourseMaterial);

// Admin routes - Material management
router.delete('/material/:materialId', adminAuth, deleteMaterial);

// Student/Admin routes - Material access
router.get('/materials/course/:courseId', getMaterialsByCourse);
router.get('/materials/lecture/:lectureId', getMaterialsByLecture);
router.get('/material/:materialId/download', generateMaterialDownloadUrl);

export default router;

