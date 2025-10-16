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
  getOfferPrice
} from '../controllers/paymentController.js';
import { authRequired } from '../middleware/auth.js';
import { studentAuth } from '../middleware/studentAuth.js';
import { adminAuth } from '../middleware/adminAuth.js';
import { generateServerPDFReceipt } from '../utils/pdfReceiptGenerator.js';

const router = express.Router();

// Public routes (no authentication required)
router.get('/courses', getCourses);
router.get('/pricing', getCoursePricing);

// Protected routes (require authentication)
router.use(authRequired);

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
router.get('/offer-price/:studentId/:feature?', studentAuth, getOfferPrice);

// PDF Receipt download
router.get('/receipt/:transactionId', studentAuth, async (req, res) => {
  try {
    const { transactionId } = req.params;
    const userId = req.studentId;
    
    // Import in-memory storage to find transaction
    const { userPayments } = await import('../controllers/authController.js');
    
    // Find transaction in user's payment history
    let transaction = null;
    if (userPayments.has(userId)) {
      const userPaymentHistory = userPayments.get(userId);
      transaction = userPaymentHistory.find(payment => 
        payment.transactionId === transactionId || payment._id === transactionId
      );
    }
    
    if (!transaction) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }
    
    // Generate PDF receipt
    const doc = generateServerPDFReceipt(transaction, req.user);
    
    // Set response headers for PDF download
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="receipt-${transactionId}.pdf"`);
    
    // Pipe PDF to response
    doc.pipe(res);
    doc.end();
    
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to generate PDF receipt'
    });
  }
});

// Refund processing
router.post('/refund', studentAuth, processRefund);

// Admin routes (for payment statistics)
router.get('/stats', getPaymentStats);
router.get('/admin/all', adminAuth, getAllPayments);
router.get('/admin/stats', adminAuth, getPaymentStats);
router.get('/admin/courses', adminAuth, getCourses);
router.get('/admin/pricing', adminAuth, getCoursePricing);

export default router;
