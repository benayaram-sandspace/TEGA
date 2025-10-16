import mongoose from 'mongoose';

const placementQuestionSchema = new mongoose.Schema({
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
    enum: ['mcq', 'coding', 'subjective', 'behavioral'],
    required: true
  },
  category: {
    type: String,
    enum: ['assessment', 'technical', 'interview', 'aptitude', 'logical', 'verbal'],
    required: true
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
  // For coding questions
  problemStatement: String,
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
    cpp: String
  },
  hints: [String],
  // For all question types
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
placementQuestionSchema.index({ type: 1, category: 1, difficulty: 1 });
placementQuestionSchema.index({ topic: 1 });
placementQuestionSchema.index({ isActive: 1 });

const PlacementQuestion = mongoose.model('PlacementQuestion', placementQuestionSchema);

export default PlacementQuestion;

