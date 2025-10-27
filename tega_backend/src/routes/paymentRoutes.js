import express from 'express';
import { 
  getCourses,
  getCoursePricing,
  createPaymentOrder,
  processDummyPayment,
  verifyPayment,
  getPaymentHistory,
  checkCourseAccess,
  getUserPaidCourses,
  processRefund,
  getPaymentStats,
  getAllPayments,
  verifyUPIPayment,
  getUPIPaymentStatus,
  getOfferPrice,
  checkTegaExamPayment,
  getCourseSpecificOffer,
  getTegaExamSpecificOffer,
  getAvailableTegaExams,
  getPaidSlotsForExam,
  checkSlotPayment,
  getTegaExamPayments
} from '../controllers/paymentController.js';
import { authRequired } from '../middleware/auth.js';
import { studentAuth } from '../middleware/studentAuth.js';
import { adminAuth } from '../middleware/adminAuth.js';

const router = express.Router();

// Public routes (no authentication required)
router.get('/courses', getCourses);
router.get('/pricing', getCoursePricing);
router.get('/tega-exams', getAvailableTegaExams);

// Payment processing routes
router.post('/create-order', studentAuth, createPaymentOrder);
router.post('/process-dummy', studentAuth, processDummyPayment);
router.post('/verify', studentAuth, verifyPayment);

// UPI Payment routes
router.post('/upi/verify', studentAuth, verifyUPIPayment);
router.get('/upi/status/:transactionId', studentAuth, getUPIPaymentStatus);

// User payment history and access
router.get('/history', studentAuth, getPaymentHistory);
router.get('/access/:courseId', studentAuth, checkCourseAccess);
router.get('/paid-courses', studentAuth, getUserPaidCourses);
router.get('/check-tega-exam-payment', studentAuth, checkTegaExamPayment);
router.get('/offer-price/:studentId/:feature?', studentAuth, getOfferPrice);
router.get('/course-offer/:studentId/:courseId', studentAuth, getCourseSpecificOffer);
router.get('/tega-exam-offer/:studentId/:examId', studentAuth, getTegaExamSpecificOffer);

// Slot-specific payment routes
router.get('/exam/:examId/paid-slots', studentAuth, getPaidSlotsForExam);
router.get('/exam/:examId/slot/:slotId/check', studentAuth, checkSlotPayment);
router.get('/tega-exam-payments', studentAuth, getTegaExamPayments);

// Refund processing
router.post('/refund', studentAuth, processRefund);

// Admin routes (for payment statistics)
router.get('/stats', getPaymentStats);
router.get('/admin/all', adminAuth, getAllPayments);
router.get('/admin/stats', adminAuth, getPaymentStats);
router.get('/admin/courses', adminAuth, getCourses);
router.get('/admin/pricing', adminAuth, getCoursePricing);

export default router;
