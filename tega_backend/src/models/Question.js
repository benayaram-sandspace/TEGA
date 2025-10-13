import mongoose from 'mongoose';

const questionSchema = new mongoose.Schema({
  // Excel import fields (in exact order as specified)
  sno: {
    type: Number,
    required: true
  },
  question: {
    type: String,
    required: true,
    trim: true
  },
  optionA: {
    type: String,
    required: true,
    trim: true
  },
  optionB: {
    type: String,
    required: true,
    trim: true
  },
  optionC: {
    type: String,
    required: true,
    trim: true
  },
  optionD: {
    type: String,
    required: true,
    trim: true
  },
  correct: {
    type: String,
    required: true,
    enum: ['A', 'B', 'C', 'D'],
    trim: true
  },
  
  // Derived fields for compatibility
  options: [{
    type: String,
    required: true,
    trim: true
  }],
  correctAnswer: {
    type: String,
    required: true,
    trim: true
  },
  
  // Additional fields
  explanation: {
    type: String,
    trim: true
  },
  marks: {
    type: Number,
    default: 1,
    min: 1
  },
  negativeMarks: {
    type: Number,
    default: 0,
    min: 0
  },
  difficulty: {
    type: String,
    enum: ['easy', 'medium', 'hard'],
    default: 'medium'
  },
  subject: {
    type: String,
    required: true,
    trim: true
  },
  topic: {
    type: String,
    trim: true
  },
  examId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Exam'
  },
  questionPaperId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'QuestionPaper'
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true
  }
}, {
  timestamps: true
});

// Pre-save middleware to populate options and correctAnswer from individual fields
questionSchema.pre('save', function(next) {
  if (this.optionA && this.optionB && this.optionC && this.optionD) {
    this.options = [this.optionA, this.optionB, this.optionC, this.optionD];
  }
  
  if (this.correct) {
    const correctIndex = ['A', 'B', 'C', 'D'].indexOf(this.correct);
    if (correctIndex !== -1 && this.options && this.options[correctIndex]) {
      this.correctAnswer = this.options[correctIndex];
    }
  }
  
  next();
});

// Index for efficient querying
questionSchema.index({ examId: 1 });
questionSchema.index({ subject: 1, difficulty: 1 });

export default mongoose.model('Question', questionSchema);
