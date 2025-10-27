import mongoose from 'mongoose';

const examPaymentAttemptSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  examId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Exam',
    required: true
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: false,
    default: null
  },
  paymentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'RazorpayPayment',
    required: true
  },
  attemptNumber: {
    type: Number,
    required: true,
    default: 1
  },
  paymentAmount: {
    type: Number,
    required: true
  },
  paymentDate: {
    type: Date,
    default: Date.now
  },
  examAttemptId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'ExamAttempt'
  },
  status: {
    type: String,
    enum: ['paid', 'exam_started', 'exam_completed', 'exam_abandoned'],
    default: 'paid'
  },
  // Track if this payment attempt has been used for an exam
  isUsed: {
    type: Boolean,
    default: false
  },
  usedAt: {
    type: Date
  },
  // Track exam completion details
  examCompletedAt: {
    type: Date
  },
  examScore: {
    type: Number,
    default: 0
  },
  examPercentage: {
    type: Number,
    default: 0
  },
  isPassed: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

// Indexes for efficient querying
examPaymentAttemptSchema.index({ studentId: 1, examId: 1, attemptNumber: 1 }, { unique: true });
examPaymentAttemptSchema.index({ studentId: 1, courseId: 1 });
examPaymentAttemptSchema.index({ paymentId: 1 });

// Static method to get the next attempt number for a student-exam combination
examPaymentAttemptSchema.statics.getNextAttemptNumber = async function(studentId, examId) {
  const lastAttempt = await this.findOne({ studentId, examId })
    .sort({ attemptNumber: -1 });
  
  return lastAttempt ? lastAttempt.attemptNumber + 1 : 1;
};

// Static method to check if student has paid for exam attempts
examPaymentAttemptSchema.statics.hasPaidAttempts = async function(studentId, examId) {
  const paidAttempts = await this.find({ 
    studentId, 
    examId, 
    status: { $in: ['paid', 'exam_started', 'exam_completed'] }
  }).sort({ attemptNumber: -1 });
  
  return paidAttempts;
};

// Static method to get available (unused) paid attempts
examPaymentAttemptSchema.statics.getAvailableAttempts = async function(studentId, examId) {
  const availableAttempts = await this.find({ 
    studentId, 
    examId, 
    isUsed: false,
    status: 'paid'
  }).sort({ attemptNumber: 1 });
  
  return availableAttempts;
};

export default mongoose.model('ExamPaymentAttempt', examPaymentAttemptSchema);
