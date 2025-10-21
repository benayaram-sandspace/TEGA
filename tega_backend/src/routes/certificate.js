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
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// Student routes
router.post('/generate', studentAuth, generateCertificate);
router.get('/my-certificates', studentAuth, getStudentCertificates);
router.get('/:certificateId', getCertificateById);
router.get('/:certificateId/download', downloadCertificate);
router.get('/course/:courseId/completion', studentAuth, checkCourseCompletion);

// Public routes
router.get('/verify/:verificationCode', verifyCertificate);
router.get('/sample/preview', getCertificateSample);

export default router;

