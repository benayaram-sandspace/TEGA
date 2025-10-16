import mongoose from 'mongoose';

const companyQuizAttemptSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true,
    index: true
  },
  companyName: {
    type: String,
    required: true,
    index: true
  },
  questions: [{
    questionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'CompanyQuestion'
    },
    selectedAnswer: mongoose.Schema.Types.Mixed, // Can be string, array, or object
    isCorrect: Boolean,
    timeTaken: Number, // in seconds
    pointsEarned: Number
  }],
  
  // Quiz metadata
  totalQuestions: Number,
  correctAnswers: Number,
  incorrectAnswers: Number,
  skippedQuestions: Number,
  
  // Scoring
  totalPoints: Number,
  earnedPoints: Number,
  percentage: Number,
  
  // Timing
  startedAt: Date,
  completedAt: Date,
  totalTimeTaken: Number, // in seconds
  
  // Filters used
  filters: {
    category: String,
    difficulty: String,
    topic: String
  },
  
  status: {
    type: String,
    enum: ['in-progress', 'completed', 'abandoned'],
    default: 'in-progress'
  }
}, {
  timestamps: true
});

// Indexes for analytics
companyQuizAttemptSchema.index({ studentId: 1, companyName: 1, completedAt: -1 });
companyQuizAttemptSchema.index({ companyName: 1, status: 1 });

// Calculate percentage before save
companyQuizAttemptSchema.pre('save', function(next) {
  if (this.totalQuestions > 0) {
    this.percentage = ((this.correctAnswers / this.totalQuestions) * 100).toFixed(2);
  }
  next();
});

const CompanyQuizAttempt = mongoose.model('CompanyQuizAttempt', companyQuizAttemptSchema);

export default CompanyQuizAttempt;

