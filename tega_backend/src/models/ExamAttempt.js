import mongoose from 'mongoose';

const examAttemptSchema = new mongoose.Schema({
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
  startTime: {
    type: Date,
    default: Date.now
  },
  endTime: {
    type: Date
  },
  duration: {
    type: Number, // in minutes
    required: true
  },
  answers: {
    type: Map,
    of: String, // questionId -> selected answer
    default: new Map()
  },
  markedQuestions: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Question'
  }],
  score: {
    type: Number,
    default: 0
  },
  totalMarks: {
    type: Number,
    required: true
  },
  correctAnswers: {
    type: Number,
    default: 0
  },
  wrongAnswers: {
    type: Number,
    default: 0
  },
  unattempted: {
    type: Number,
    default: 0
  },
  status: {
    type: String,
    enum: ['in_progress', 'completed', 'abandoned'],
    default: 'in_progress'
  },
  isPassed: {
    type: Boolean,
    default: false
  },
  percentage: {
    type: Number,
    default: 0
  },
  attemptNumber: {
    type: Number,
    default: 1
  },
  // Auto-save data
  lastSavedAt: {
    type: Date,
    default: Date.now
  },
  timeRemaining: {
    type: Number, // in seconds
    default: 0
  },
  // Slot information
  slotId: {
    type: String
  },
  slotStartTime: {
    type: String
  },
  slotEndTime: {
    type: String
  },
  // Qualification status (50% pass)
  isQualified: {
    type: Boolean,
    default: false
  },
  // Admin retake functionality
  canRetake: {
    type: Boolean,
    default: false
  },
  retakeApprovedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin'
  },
  retakeApprovedAt: {
    type: Date
  },
  // Result publishing
  published: {
    type: Boolean,
    default: false
  },
  publishedAt: {
    type: Date
  },
  publishedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin'
  }
}, {
  timestamps: true
});

// Index for efficient querying
examAttemptSchema.index({ studentId: 1, examId: 1 });
examAttemptSchema.index({ status: 1, startTime: 1 });
examAttemptSchema.index({ courseId: 1, studentId: 1 });

// Compound index to ensure one attempt per student per exam
examAttemptSchema.index({ studentId: 1, examId: 1, attemptNumber: 1 }, { unique: true });

export default mongoose.model('ExamAttempt', examAttemptSchema);
