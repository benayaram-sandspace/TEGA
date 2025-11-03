import mongoose from 'mongoose';

const placementProgressSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  // Overall progress
  assessmentCompleted: {
    type: Boolean,
    default: false
  },
  codingProblemsSolved: {
    type: Number,
    default: 0
  },
  mockInterviewsCompleted: {
    type: Number,
    default: 0
  },
  projectsCompleted: {
    type: Number,
    default: 0
  },
  learningStreak: {
    type: Number,
    default: 0
  },
  totalPoints: {
    type: Number,
    default: 0
  },
  lastActivityDate: Date,
  
  // Question attempts
  questionAttempts: [{
    questionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'PlacementQuestion'
    },
    attemptedAt: Date,
    isCorrect: Boolean,
    timeTaken: Number, // in seconds
    answer: mongoose.Schema.Types.Mixed,
    code: String, // for coding questions
    language: String, // programming language used
    pointsEarned: Number
  }],
  
  // Module progress
  moduleProgress: [{
    moduleId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'PlacementModule'
    },
    status: {
      type: String,
      enum: ['not-started', 'in-progress', 'completed'],
      default: 'not-started'
    },
    progress: {
      type: Number,
      default: 0
    },
    startedAt: Date,
    completedAt: Date
  }],
  
  // Skills assessment
  skillLevels: [{
    skill: String,
    level: {
      type: String,
      enum: ['beginner', 'intermediate', 'advanced', 'expert']
    },
    assessedAt: Date
  }],
  
  // Achievements
  achievements: [{
    type: String,
    achievedAt: Date
  }],
  
  // Learning path recommendations
  recommendedPath: {
    jobRole: String,
    skills: [String],
    generatedAt: Date
  }
}, {
  timestamps: true
});

// Compound index for efficient student-specific queries
placementProgressSchema.index({ studentId: 1 });
placementProgressSchema.index({ 'questionAttempts.questionId': 1 });

// Update learning streak on save
placementProgressSchema.pre('save', function(next) {
  if (this.lastActivityDate) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const lastActivity = new Date(this.lastActivityDate);
    lastActivity.setHours(0, 0, 0, 0);
    
    const daysDiff = Math.floor((today - lastActivity) / (1000 * 60 * 60 * 24));
    
    if (daysDiff === 0) {
      // Same day, don't update streak
    } else if (daysDiff === 1) {
      // Consecutive day, increment streak
      this.learningStreak += 1;
    } else {
      // Streak broken
      this.learningStreak = 1;
    }
  } else {
    this.learningStreak = 1;
  }
  
  this.lastActivityDate = new Date();
  next();
});

const PlacementProgress = mongoose.model('PlacementProgress', placementProgressSchema);

export default PlacementProgress;
