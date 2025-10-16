import mongoose from 'mongoose';

const examRegistrationSchema = new mongoose.Schema({
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
    required: true
  },
  slotId: {
    type: String,
    required: true
  },
  slotStartTime: {
    type: String,
    required: true
  },
  slotEndTime: {
    type: String,
    required: true
  },
  registrationDate: {
    type: Date,
    default: Date.now
  },
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'failed', 'refunded'],
    default: 'pending'
  },
  paymentId: {
    type: String,
    trim: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  // Exam attempt tracking
  attemptCount: {
    type: Number,
    default: 0
  },
  lastAttemptDate: {
    type: Date
  },
  // Qualification status
  isQualified: {
    type: Boolean,
    default: false
  },
  qualificationDate: {
    type: Date
  }
}, {
  timestamps: true
});

// Compound index to ensure one registration per student per exam
examRegistrationSchema.index({ studentId: 1, examId: 1 }, { unique: true });

// Index for efficient querying
examRegistrationSchema.index({ examId: 1, paymentStatus: 1 });
examRegistrationSchema.index({ studentId: 1, isActive: 1 });
examRegistrationSchema.index({ slotId: 1, registrationDate: 1 });

// Static method to check if student can register for exam
examRegistrationSchema.statics.canRegister = function(studentId, examId) {
  return this.findOne({
    studentId,
    examId,
    isActive: true
  });
};

// Static method to get slot availability
examRegistrationSchema.statics.getSlotAvailability = function(examId, slotId) {
  return this.countDocuments({
    examId,
    slotId,
    paymentStatus: 'paid',
    isActive: true
  });
};

export default mongoose.model('ExamRegistration', examRegistrationSchema);
