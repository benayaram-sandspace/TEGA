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
    required: false,
    default: null
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

// Pre-save hook for conditional validation
examRegistrationSchema.pre('save', async function(next) {
  try {
    // For course-based exams, courseId should be present
    if (this.courseId === null || this.courseId === undefined) {
      // Check if this is a course-based exam
      const Exam = mongoose.model('Exam');
      const exam = await Exam.findById(this.examId);
      
      if (exam && exam.courseId && exam.courseId.toString() !== 'null') {
        // This is a course-based exam but courseId is missing
        const error = new Error('courseId is required for course-based exams');
        return next(error);
      }
      // For TEGA/standalone exams, courseId can be null
    }
    next();
  } catch (error) {
    next(error);
  }
});

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
