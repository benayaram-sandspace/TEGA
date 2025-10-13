import express from 'express';
import RazorpayPayment from '../models/RazorpayPayment.js';

const router = express.Router();

// Test endpoint to check if models are working
router.get('/test-models', async (req, res) => {
  try {
    
    // Test if we can access the model
    const count = await RazorpayPayment.countDocuments();
    
    res.json({
      success: true,
      message: 'Models are working',
      razorpayPaymentCount: count
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Model test failed',
      error: error.message,
      stack: error.stack
    });
  }
});

export default router;
