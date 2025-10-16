import express from 'express';
import {
  createTegaExamPaymentOrder,
  processTegaExamDummyPayment,
  checkTegaExamPayment,
  getTegaExamPaymentHistory
} from '../controllers/tegaExamPaymentController.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// All routes require student authentication
router.use(studentAuth);

// Tega Exam payment routes
router.post('/create-order', createTegaExamPaymentOrder);
router.post('/process-dummy', processTegaExamDummyPayment);
router.get('/check/:examId', checkTegaExamPayment);
router.get('/history', getTegaExamPaymentHistory);

export default router;
