import mongoose from 'mongoose';

const questionSchema = new mongoose.Schema({
  sNo: Number,
  question: String,
  optionA: String,
  optionB: String,
  optionC: String,
  optionD: String,
  correctOption: String // A, B, C, or D
});

const quizSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: true
  },
  moduleId: {
    type: String,
    required: true // Module ID within course
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true
  },
  questions: [questionSchema],
  totalQuestions: Number,
  totalPassMarks: Number,
  passMarksPerQuestion: Number, // Pass marks per question set by admin during upload
  r2Key: String, // R2 storage key for the Excel file
  r2FileName: String,
  isActive: {
    type: Boolean,
    default: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Index for quick lookups
quizSchema.index({ courseId: 1, moduleId: 1 });

export default mongoose.model('Quiz', quizSchema);
