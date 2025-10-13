import express from 'express';
import {
  generateCertificate,
  getStudentCertificates,
  getCertificateById,
  downloadCertificate,
  verifyCertificate,
  getCertificateSample,
  checkCourseCompletion
} from '../controllers/certificateController.js';
import { verifyStudent } from '../middlewares/authMiddleware.js';

const router = express.Router();

// Student routes
router.post('/generate', verifyStudent, generateCertificate);
router.get('/my-certificates', verifyStudent, getStudentCertificates);
router.get('/:certificateId', getCertificateById);
router.get('/:certificateId/download', downloadCertificate);
router.get('/course/:courseId/completion', verifyStudent, checkCourseCompletion);

// Public routes
router.get('/verify/:verificationCode', verifyCertificate);
router.get('/sample/preview', getCertificateSample);

export default router;

