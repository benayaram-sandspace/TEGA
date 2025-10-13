import mongoose from 'mongoose';

const razorpayPaymentSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: true
  },
  courseName: {
    type: String,
    required: true
  },
  amount: {
    type: Number,
    required: true,
    min: 0
  },
  currency: {
    type: String,
    default: 'INR'
  },
  paymentMethod: {
    type: String,
    enum: ['razorpay', 'stripe', 'paypal', 'manual', 'card', 'upi', 'netbanking'],
    default: 'razorpay'
  },
  status: {
    type: String,
    enum: ['pending', 'completed', 'failed', 'refunded', 'cancelled'],
    default: 'pending'
  },
  // Razorpay specific fields
  razorpayOrderId: {
    type: String,
    unique: true,
    sparse: true
  },
  razorpayPaymentId: {
    type: String,
    unique: true,
    sparse: true
  },
  razorpaySignature: {
    type: String
  },
  transactionId: {
    type: String,
    unique: true,
    sparse: true
  },
  paymentDate: {
    type: Date,
    default: Date.now
  },
  description: {
    type: String,
    trim: true
  },
  receiptUrl: {
    type: String
  },
  examAccess: {
    type: Boolean,
    default: false
  },
  validUntil: {
    type: Date
  },
  // Exam payment specific fields
  examId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Exam',
    default: null
  },
  attemptNumber: {
    type: Number,
    default: null
  },
  isRetake: {
    type: Boolean,
    default: false
  },
  failureReason: {
    type: String,
    trim: true
  },
  // Additional Razorpay fields
  razorpayReceipt: {
    type: String
  },
  razorpayNotes: {
    type: mongoose.Schema.Types.Mixed
  }
}, {
  timestamps: true
});

// Indexes for better performance
razorpayPaymentSchema.index({ studentId: 1, courseId: 1, status: 1 });
razorpayPaymentSchema.index({ razorpayOrderId: 1 });
razorpayPaymentSchema.index({ razorpayPaymentId: 1 });

// Static method to check for existing successful payment
razorpayPaymentSchema.statics.checkExistingPayment = async function(studentId, courseId) {
  return await this.findOne({
    studentId,
    courseId,
    status: 'completed'
  });
};

// Static method to find payment by Razorpay order ID
razorpayPaymentSchema.statics.findByOrderId = async function(orderId) {
  return await this.findOne({ razorpayOrderId: orderId });
};

// Static method to find payment by Razorpay payment ID
razorpayPaymentSchema.statics.findByPaymentId = async function(paymentId) {
  return await this.findOne({ razorpayPaymentId: paymentId });
};

export default mongoose.model('RazorpayPayment', razorpayPaymentSchema);
