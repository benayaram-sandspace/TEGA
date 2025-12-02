import mongoose from 'mongoose';

const codingAssessmentSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  instructions: {
    type: String,
    default: 'Complete all coding questions in this assessment. Each question will be evaluated based on test cases.'
  },
  // Array of coding question IDs
  questions: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'CodingQuestion',
    required: true
  }],
  // Assessment settings
  totalTimeLimit: {
    type: Number, // in minutes
    default: 60
  },
  questionTimeLimit: {
    type: Number, // in minutes per question (optional, overrides question's timeLimit)
    default: null
  },
  passingScore: {
    type: Number, // percentage (0-100)
    default: 70
  },
  maxAttempts: {
    type: Number,
    default: 3 // -1 for unlimited
  },
  // Assessment metadata
  difficulty: {
    type: String,
    enum: ['easy', 'medium', 'hard', 'mixed'],
    default: 'mixed'
  },
  category: {
    type: String,
    enum: ['technical', 'interview', 'aptitude', 'logical', 'verbal'],
    default: 'technical'
  },
  tags: [String],
  // Scoring settings
  pointsPerQuestion: {
    type: Number,
    default: 10
  },
  totalPoints: {
    type: Number,
    default: 0 // Calculated: questions.length * pointsPerQuestion
  },
  // Display settings
  showResults: {
    type: Boolean,
    default: true // Show results immediately after submission
  },
  showCorrectAnswers: {
    type: Boolean,
    default: true // Show correct answers after submission
  },
  // Status
  isActive: {
    type: Boolean,
    default: true
  },
  isPublished: {
    type: Boolean,
    default: false // Must be published for students to see
  },
  // Scheduling (optional)
  startDate: {
    type: Date,
    default: null
  },
  endDate: {
    type: Date,
    default: null
  },
  // Creator
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true
  }
}, {
  timestamps: true
});

// Calculate total points before saving
codingAssessmentSchema.pre('save', function(next) {
  if (this.isModified('questions') || this.isModified('pointsPerQuestion')) {
    this.totalPoints = this.questions.length * this.pointsPerQuestion;
  }
  next();
});

// Indexes for efficient querying
codingAssessmentSchema.index({ isActive: 1, isPublished: 1 });
codingAssessmentSchema.index({ category: 1, difficulty: 1 });
codingAssessmentSchema.index({ createdBy: 1 });
codingAssessmentSchema.index({ startDate: 1, endDate: 1 });

const CodingAssessment = mongoose.model('CodingAssessment', codingAssessmentSchema);

export default CodingAssessment;

