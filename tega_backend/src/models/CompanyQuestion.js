import mongoose from 'mongoose';

const companyQuestionSchema = new mongoose.Schema({
  companyName: {
    type: String,
    required: true,
    trim: true,
    index: true
  },
  questionText: {
    type: String,
    required: true
  },
  // Rich content support
  questionHTML: String, // HTML formatted question
  questionImages: [{
    url: String,
    caption: String,
    position: String // 'before', 'after', 'inline'
  }],
  mathFormula: String, // LaTeX format
  codeSnippet: {
    code: String,
    language: String, // 'javascript', 'python', 'java', etc.
    theme: String
  },
  diagram: {
    type: String, // 'image', 'mermaid', 'chart'
    data: String, // image URL or diagram code
    description: String
  },
  
  questionType: {
    type: String,
    enum: ['mcq', 'multiple-select', 'true-false', 'coding', 'subjective'],
    default: 'mcq'
  },
  options: [{
    text: String,
    image: String, // Image URL for option
    isCorrect: Boolean
  }],
  correctAnswer: String, // For non-MCQ questions
  explanation: String,
  difficulty: {
    type: String,
    enum: ['easy', 'medium', 'hard'],
    default: 'medium'
  },
  category: {
    type: String,
    enum: ['technical', 'aptitude', 'reasoning', 'verbal', 'coding', 'hr'],
    default: 'technical'
  },
  topic: String,
  points: {
    type: Number,
    default: 10
  },
  timeLimit: {
    type: Number, // in seconds
    default: 60
  },
  
  // Metadata
  uploadedFrom: {
    type: String,
    enum: ['pdf', 'manual', 'bulk-import'],
    default: 'manual'
  },
  pdfFileName: String,
  pageNumber: Number,
  
  // Statistics
  totalAttempts: {
    type: Number,
    default: 0
  },
  correctAttempts: {
    type: Number,
    default: 0
  },
  
  // Tags and search
  tags: [String],
  searchText: String, // For full-text search
  
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

// Text index for search
companyQuestionSchema.index({ 
  questionText: 'text', 
  explanation: 'text', 
  topic: 'text',
  tags: 'text'
});

// Compound indexes for efficient queries
companyQuestionSchema.index({ companyName: 1, category: 1 });
companyQuestionSchema.index({ companyName: 1, difficulty: 1 });
companyQuestionSchema.index({ isActive: 1, companyName: 1 });

// Virtual for success rate
companyQuestionSchema.virtual('successRate').get(function() {
  if (this.totalAttempts === 0) return 0;
  return ((this.correctAttempts / this.totalAttempts) * 100).toFixed(2);
});

// Pre-save middleware to update search text
companyQuestionSchema.pre('save', function(next) {
  this.searchText = `${this.questionText} ${this.explanation || ''} ${this.topic || ''} ${this.tags.join(' ')}`;
  next();
});

const CompanyQuestion = mongoose.model('CompanyQuestion', companyQuestionSchema);

export default CompanyQuestion;

