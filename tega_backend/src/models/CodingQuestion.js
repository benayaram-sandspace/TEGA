import mongoose from 'mongoose';

const codingQuestionSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  category: {
    type: String,
    enum: ['technical', 'interview', 'aptitude', 'logical', 'verbal'],
    required: true,
    default: 'technical'
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
  // Coding-specific fields
  problemStatement: {
    type: String,
    required: true
  },
  constraints: String,
  inputFormat: String,
  outputFormat: String,
  sampleInput: String,
  sampleOutput: String,
  testCases: [{
    input: String,
    output: String,
    isHidden: { type: Boolean, default: false }
  }],
  starterCode: {
    javascript: String,
    python: String,
    java: String,
    cpp: String,
    c: String
  },
  hints: [String],
  explanation: String,
  points: {
    type: Number,
    default: 10
  },
  timeLimit: {
    type: Number, // in minutes
    default: 30
  },
  companies: [String], // Companies that asked this question
  tags: [String],
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
codingQuestionSchema.index({ category: 1, difficulty: 1 });
codingQuestionSchema.index({ topic: 1 });
codingQuestionSchema.index({ isActive: 1 });

const CodingQuestion = mongoose.model('CodingQuestion', codingQuestionSchema);

export default CodingQuestion;

