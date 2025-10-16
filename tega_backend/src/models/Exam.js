import mongoose from 'mongoose';

const examSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  subject: {
    type: String,
    required: true,
    trim: true
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'RealTimeCourse',
    required: true
  },
  description: {
    type: String,
    trim: true
  },
  duration: {
    type: Number, // in minutes
    required: true,
    min: 1
  },
  totalMarks: {
    type: Number,
    required: true,
    min: 1
  },
  passingMarks: {
    type: Number,
    required: true,
    min: 0
  },
  // Date and time slots management
  examDate: {
    type: Date,
    required: true
  },
  slots: [{
    slotId: {
      type: String,
      required: true
    },
    startTime: {
      type: String, // HH:MM format
      required: true
    },
    endTime: {
      type: String, // HH:MM format
      required: true
    },
    maxParticipants: {
      type: Number,
      required: true,
      default: 30
    },
    registeredStudents: [{
      studentId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Student'
      },
      registeredAt: {
        type: Date,
        default: Date.now
      }
    }],
    isActive: {
      type: Boolean,
      default: true
    }
  }],
  isActive: {
    type: Boolean,
    default: true
  },
  requiresPayment: {
    type: Boolean,
    default: true
  },
  price: {
    type: Number,
    default: 0
  },
  maxAttempts: {
    type: Number,
    default: 1
  },
  instructions: {
    type: String,
    trim: true
  },
  // Question paper management
  questionPaperId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'QuestionPaper'
  },
  // Registration management
  registeredStudents: [{
    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Student'
    },
    slotId: {
      type: String
    },
    registeredAt: {
      type: Date,
      default: Date.now
    },
    paymentStatus: {
      type: String,
      enum: ['pending', 'paid', 'failed'],
      default: 'pending'
    }
  }],
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true
  },
  questions: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Question'
  }]
}, {
  timestamps: true
});

// Index for efficient querying
examSchema.index({ courseId: 1, isActive: 1 });
examSchema.index({ startDate: 1, endDate: 1 });

export default mongoose.model('Exam', examSchema);
