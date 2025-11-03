import mongoose from 'mongoose';

const companyProgressSchema = new mongoose.Schema({
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
  
  // Overall stats
  totalQuestionsAttempted: {
    type: Number,
    default: 0
  },
  totalCorrect: {
    type: Number,
    default: 0
  },
  totalIncorrect: {
    type: Number,
    default: 0
  },
  totalPoints: {
    type: Number,
    default: 0
  },
  averageScore: {
    type: Number,
    default: 0
  },
  
  // Category-wise performance
  categoryPerformance: [{
    category: String,
    attempted: Number,
    correct: Number,
    accuracy: Number
  }],
  
  // Difficulty-wise performance
  difficultyPerformance: [{
    difficulty: String,
    attempted: Number,
    correct: Number,
    accuracy: Number
  }],
  
  // Time tracking
  totalTimeSpent: {
    type: Number,
    default: 0
  }, // in seconds
  averageTimePerQuestion: Number,
  
  // Quiz history
  quizAttempts: [{
    attemptId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'CompanyQuizAttempt'
    },
    score: Number,
    completedAt: Date
  }],
  
  // Best performance
  bestScore: {
    type: Number,
    default: 0
  },
  bestAccuracy: {
    type: Number,
    default: 0
  },
  
  // Weak areas
  weakTopics: [String],
  strongTopics: [String],
  
  lastAttemptDate: Date,
  
  // Rank (optional)
  rank: Number
}, {
  timestamps: true
});

// Compound index for leaderboard
companyProgressSchema.index({ companyName: 1, totalPoints: -1 });
companyProgressSchema.index({ studentId: 1, companyName: 1 }, { unique: true });

// Calculate accuracy
companyProgressSchema.virtual('overallAccuracy').get(function() {
  if (this.totalQuestionsAttempted === 0) return 0;
  return ((this.totalCorrect / this.totalQuestionsAttempted) * 100).toFixed(2);
});

const CompanyProgress = mongoose.model('CompanyProgress', companyProgressSchema);

export default CompanyProgress;
