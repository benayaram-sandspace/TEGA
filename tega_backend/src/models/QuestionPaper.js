import mongoose from 'mongoose';

const questionPaperSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: false, // Make it not required, we'll validate in pre-save hook
    default: null // Explicitly set default to null
  },
  // New field to identify TEGA exam question papers
  isTegaExamPaper: {
    type: Boolean,
    default: false
  },
  subject: {
    type: String,
    required: false,
    trim: true
  },
  fileName: {
    type: String,
    required: true
  },
  originalFileName: {
    type: String,
    required: true
  },
  filePath: {
    type: String,
    required: true
  },
  fileSize: {
    type: Number,
    required: true
  },
  totalQuestions: {
    type: Number,
    default: 0
  },
  questions: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Question'
  }],
  isActive: {
    type: Boolean,
    default: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true
  },
  usedInExams: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Exam'
  }]
}, {
  timestamps: true
});

// Pre-save validation hook
questionPaperSchema.pre('save', function(next) {
  console.log('🔍 Pre-save hook triggered:', {
    isTegaExamPaper: this.isTegaExamPaper,
    courseId: this.courseId,
    hasCourseId: !!this.courseId
  });

  // If it's not a TEGA exam paper, courseId is required
  if (!this.isTegaExamPaper && !this.courseId) {
    console.log('❌ Validation failed: courseId required for non-TEGA exam papers');
    const error = new Error('courseId is required for non-TEGA exam question papers');
    error.name = 'ValidationError';
    return next(error);
  }
  
  // If it's a TEGA exam paper, courseId should not be present
  if (this.isTegaExamPaper && this.courseId) {
    console.log('⚠️ Warning: TEGA exam question paper should not have courseId, removing it');
    this.courseId = undefined;
  }
  
  console.log('✅ Pre-save validation passed');
  next();
});

// Index for efficient querying
questionPaperSchema.index({ courseId: 1, isActive: 1 });
questionPaperSchema.index({ subject: 1 });
questionPaperSchema.index({ createdBy: 1 });
questionPaperSchema.index({ isTegaExamPaper: 1 }); // Add index for TEGA exam papers

// Static method to get question papers by course
questionPaperSchema.statics.getByCourse = function(courseId) {
  return this.find({ courseId, isActive: true })
    .populate('courseId', 'courseName')
    .sort({ createdAt: -1 });
};

// Static method to get TEGA exam question papers
questionPaperSchema.statics.getTegaExamPapers = function() {
  return this.find({ isTegaExamPaper: true, isActive: true })
    .populate('createdBy', 'username')
    .sort({ createdAt: -1 });
};

// Static method to check if question paper is used in any exam
questionPaperSchema.statics.isUsedInExam = function(questionPaperId) {
  return this.findById(questionPaperId)
    .then(paper => paper && paper.usedInExams.length > 0);
};

export default mongoose.model('QuestionPaper', questionPaperSchema);
