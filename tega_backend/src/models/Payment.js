import mongoose from 'mongoose';

const paymentSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'RealTimeCourse',
    required: false // Made optional for Tega Exam payments
  },
  examId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Exam',
    required: false // For Tega Exam payments
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
  originalPrice: {
    type: Number,
    min: 0
  },
  offerPrice: {
    type: Number,
    min: 0
  },
  currency: {
    type: String,
    default: 'INR'
  },
  paymentMethod: {
    type: String,
    enum: ['razorpay', 'stripe', 'paypal', 'manual', 'card', 'upi', 'netbanking', 'Google Pay UPI'],
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
  razorpayReceipt: {
    type: String
  },
  razorpayNotes: {
    type: mongoose.Schema.Types.Mixed
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
  // For exam access verification
  examAccess: {
    type: Boolean,
    default: true
  },
  validUntil: {
    type: Date
  },
  // UPI specific fields
  upiId: {
    type: String,
    trim: true
  },
  upiReferenceId: {
    type: String,
    trim: true
  },
  failureReason: {
    type: String,
    trim: true
  }
}, {
  timestamps: true
});

// Static method to check if a user has paid for a specific course
paymentSchema.statics.hasUserPaidForCourse = async function (studentId, courseId) {
  const payment = await this.findOne({
    studentId: studentId,
    courseId: courseId,
    status: 'completed'
  });
  return !!payment;
};

// Static method to get all paid courses for a user
paymentSchema.statics.getUserPaidCourses = async function (studentId) {
  const payments = await this.find({
    studentId: studentId,
    status: 'completed'
  }).distinct('courseId');
  return payments;
};

// Static method to check for existing successful payment
paymentSchema.statics.checkExistingPayment = async function(studentId, courseId) {
  return await this.findOne({
    studentId,
    courseId,
    status: 'completed'
  });
};

// Static method to find payment by Razorpay order ID
paymentSchema.statics.findByOrderId = async function(orderId) {
  return await this.findOne({ razorpayOrderId: orderId });
};

// Static method to find payment by Razorpay payment ID
paymentSchema.statics.findByPaymentId = async function(paymentId) {
  return await this.findOne({ razorpayPaymentId: paymentId });
};

// Index for efficient querying
paymentSchema.index({ studentId: 1, courseId: 1 });
paymentSchema.index({ status: 1, paymentDate: 1 });
paymentSchema.index({ transactionId: 1 });
paymentSchema.index({ studentId: 1, courseId: 1, status: 1 });
paymentSchema.index({ razorpayOrderId: 1 });
paymentSchema.index({ razorpayPaymentId: 1 });

export default mongoose.model('Payment', paymentSchema);
