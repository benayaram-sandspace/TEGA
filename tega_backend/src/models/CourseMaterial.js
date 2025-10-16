import mongoose from 'mongoose';

const courseMaterialSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: true
  },
  sectionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Section'
  },
  lectureId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Lecture'
  },
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  type: {
    type: String,
    required: true,
    enum: ['pdf', 'ppt', 'pptx', 'doc', 'docx', 'zip', 'other'],
    default: 'pdf'
  },
  // R2 storage information
  r2Key: {
    type: String,
    required: true,
    trim: true
  },
  r2Url: {
    type: String,
    required: true,
    trim: true
  },
  // File metadata
  fileName: {
    type: String,
    required: true
  },
  fileSize: {
    type: Number, // in bytes
    required: true
  },
  mimeType: {
    type: String,
    required: true
  },
  // Access control
  isPublic: {
    type: Boolean,
    default: false // Only enrolled students can download
  },
  downloadCount: {
    type: Number,
    default: 0
  },
  // Organization
  order: {
    type: Number,
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  // Metadata
  tags: [String],
  uploadedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true
  }
}, {
  timestamps: true
});

// Indexes for efficient queries
courseMaterialSchema.index({ courseId: 1, isActive: 1 });
courseMaterialSchema.index({ lectureId: 1, isActive: 1 });
courseMaterialSchema.index({ sectionId: 1, isActive: 1 });
courseMaterialSchema.index({ type: 1 });

// Method to increment download count
courseMaterialSchema.methods.incrementDownloadCount = function() {
  this.downloadCount += 1;
  return this.save();
};

// Static method to get materials by course
courseMaterialSchema.statics.getMaterialsByCourse = function(courseId) {
  return this.find({ courseId, isActive: true }).sort({ order: 1 });
};

// Static method to get materials by lecture
courseMaterialSchema.statics.getMaterialsByLecture = function(lectureId) {
  return this.find({ lectureId, isActive: true }).sort({ order: 1 });
};

// Format file size for display
courseMaterialSchema.methods.getFormattedFileSize = function() {
  const bytes = this.fileSize;
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
};

export default mongoose.model('CourseMaterial', courseMaterialSchema);

