import Razorpay from 'razorpay';
import crypto from 'crypto';

// Check if Razorpay keys are configured
const isRazorpayConfigured = process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET;

// Initialize Razorpay instance (only if keys are provided)
let razorpay = null;
if (isRazorpayConfigured) {
  razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET,
  });
} else {
}

// Verify Razorpay signature
export const verifyRazorpaySignature = (razorpay_order_id, razorpay_payment_id, razorpay_signature) => {
  if (!isRazorpayConfigured) {
    return false;
  }
  
  const body = razorpay_order_id + "|" + razorpay_payment_id;
  const expectedSignature = crypto
    .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET)
    .update(body.toString())
    .digest("hex");

  return expectedSignature === razorpay_signature;
};

// Verify webhook signature
export const verifyWebhookSignature = (body, signature) => {
  if (!isRazorpayConfigured) {
    return false;
  }
  
  // Skip webhook verification in development mode
  if (process.env.NODE_ENV === 'development') {
    return true;
  }
  
  const expectedSignature = crypto
    .createHmac("sha256", process.env.RAZORPAY_WEBHOOK_SECRET)
    .update(body)
    .digest("hex");

  return expectedSignature === signature;
};

export default razorpay;
