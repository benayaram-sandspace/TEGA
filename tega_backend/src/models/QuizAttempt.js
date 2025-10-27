import mongoose from 'mongoose';

const quizAttemptSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  quizId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Quiz',
    required: true
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: true
  },
  moduleId: {
    type: String,
    required: true
  },
  answers: {
    type: Map,
    of: String // { questionIndex: selectedOption }
  },
  score: {
    type: Number,
    default: 0
  },
  totalMarks: Number,
  correctAnswers: Number,
  totalQuestions: Number,
  attemptedQuestions: Number,
  isPassed: {
    type: Boolean,
    default: false
  },
  timeSpent: Number, // in seconds
  attemptedAt: {
    type: Date,
    default: Date.now
  }
});

// Index for quick lookups
quizAttemptSchema.index({ studentId: 1, quizId: 1 });
quizAttemptSchema.index({ studentId: 1, courseId: 1 });
quizAttemptSchema.index({ quizId: 1 });

export default mongoose.model('QuizAttempt', quizAttemptSchema);
