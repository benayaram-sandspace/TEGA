import express from 'express';
import {
  createOrder,
  verifyPayment,
  handleWebhook,
  getPaymentStatus,
  getPaymentHistory
} from '../controllers/razorpayController.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// Create Razorpay order
router.post('/create-order', studentAuth, createOrder);

// Verify payment
router.post('/verify-payment', studentAuth, verifyPayment);

// Get payment status
router.get('/status/:orderId', studentAuth, getPaymentStatus);

// Get payment history
router.get('/history', studentAuth, getPaymentHistory);

// Webhook (no auth required for webhooks)
router.post('/webhook', handleWebhook);

export default router;
