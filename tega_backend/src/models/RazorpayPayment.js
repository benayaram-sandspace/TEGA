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
    required: function() {
      return !this.isTegaExam && !this.isPackage; // Only required if it's not a TEGA exam and not a package
    },
    default: null
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
  slotId: {
    type: String,
    default: null // For specific exam slot payments
  },
  slotDateTime: {
    type: Date,
    default: null // DateTime of the specific slot paid for
  },
  attemptNumber: {
    type: Number,
    default: null
  },
  isRetake: {
    type: Boolean,
    default: false
  },
  isPackage: {
    type: Boolean,
    default: false
  },
  packageId: {
    type: String,
    default: null
  },
  packageData: {
    type: mongoose.Schema.Types.Mixed,
    default: null
  },
  isTegaExam: {
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
razorpayPaymentSchema.statics.checkExistingPayment = async function(studentId, courseId, examId = null, slotId = null) {
  const query = {
    studentId,
    status: 'completed'
  };
  
  if (examId) {
    // For exam payments, check by examId
    query.examId = examId;
    // If slotId is provided, check for that specific slot
    if (slotId) {
      query.slotId = slotId;
    }
  } else if (courseId) {
    // For course payments, check by courseId
    query.courseId = courseId;
  }
  
  return await this.findOne(query);
};

// Static method to find payment by Razorpay order ID
razorpayPaymentSchema.statics.findByOrderId = async function(orderId) {
  return await this.findOne({ razorpayOrderId: orderId });
};

// Static method to find payment by Razorpay payment ID
razorpayPaymentSchema.statics.findByPaymentId = async function(paymentId) {
  return await this.findOne({ razorpayPaymentId: paymentId });
};

// Static method to get all paid slots for a specific exam and student
razorpayPaymentSchema.statics.getPaidSlotsForExam = async function(studentId, examId) {
  const payments = await this.find({
    studentId,
    examId,
    status: 'completed'
  }).select('slotId slotDateTime amount');
  
  return payments.map(p => ({
    slotId: p.slotId,
    slotDateTime: p.slotDateTime,
    amount: p.amount,
    paymentDate: p.paymentDate
  }));
};

// Static method to check if user has paid for a specific slot
razorpayPaymentSchema.statics.hasUserPaidForSlot = async function(studentId, examId, slotId) {
  const payment = await this.findOne({
    studentId,
    examId,
    slotId,
    status: 'completed'
  });
  return !!payment;
};

export default mongoose.model('RazorpayPayment', razorpayPaymentSchema);
