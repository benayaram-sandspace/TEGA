import mongoose from 'mongoose';

const skillAssessmentQuestionSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: ['mcq', 'subjective', 'behavioral'],
    required: true,
    default: 'mcq'
  },
  difficulty: {
    type: String,
    enum: ['easy', 'medium', 'hard'],
    default: 'medium'
  },
  topic: {
    type: String,
    required: true
  },
  // For MCQ questions
  options: [{
    text: String,
    isCorrect: Boolean
  }],
  // For subjective/behavioral questions
  expectedAnswer: String,
  evaluationCriteria: String,
  timeLimit: {
    type: Number, // in minutes
    default: 30
  },
  tags: [String],
  skillAreas: [String], // e.g., ['communication', 'problem-solving', 'leadership']
  isActive: {
    type: Boolean,
    default: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin'
  }
}, {
  timestamps: true
});

// Indexes for efficient querying
skillAssessmentQuestionSchema.index({ type: 1, difficulty: 1 });
skillAssessmentQuestionSchema.index({ topic: 1 });
skillAssessmentQuestionSchema.index({ isActive: 1 });
skillAssessmentQuestionSchema.index({ skillAreas: 1 });

const SkillAssessmentQuestion = mongoose.model('SkillAssessmentQuestion', skillAssessmentQuestionSchema);

export default SkillAssessmentQuestion;

