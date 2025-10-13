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
    required: true
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

// Index for efficient querying
questionPaperSchema.index({ courseId: 1, isActive: 1 });
questionPaperSchema.index({ subject: 1 });
questionPaperSchema.index({ createdBy: 1 });

// Static method to get question papers by course
questionPaperSchema.statics.getByCourse = function(courseId) {
  return this.find({ courseId, isActive: true })
    .populate('courseId', 'courseName')
    .sort({ createdAt: -1 });
};

// Static method to check if question paper is used in any exam
questionPaperSchema.statics.isUsedInExam = function(questionPaperId) {
  return this.findById(questionPaperId)
    .then(paper => paper && paper.usedInExams.length > 0);
};

export default mongoose.model('QuestionPaper', questionPaperSchema);
