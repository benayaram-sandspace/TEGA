import mongoose from 'mongoose';

const lectureSchema = new mongoose.Schema({
  sectionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Section',
    required: true
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
    enum: ['video', 'pdf', 'quiz', 'text'],
    default: 'video'
  },
  fileUrl: {
    type: String,
    trim: true
  },
  videoUrl: {
    type: String,
    trim: true
  },
  duration: {
    type: String,
    default: '0:00'
  },
  order: {
    type: Number,
    required: true,
    default: 0
  },
  isPreview: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  // For quiz type lectures
  quiz: {
    questions: [{
      question: String,
      options: [String],
      correctAnswer: Number,
      explanation: String
    }],
    passingScore: {
      type: Number,
      default: 70
    },
    timeLimit: {
      type: Number, // in minutes
      default: 30
    }
  },
  // Video stored in R2
  r2VideoKey: {
    type: String,
    trim: true
  },
  r2VideoUrl: {
    type: String,
    trim: true
  },
  videoSize: {
    type: Number // in bytes
  },
  // Quiz to appear after video
  hasQuizAfterVideo: {
    type: Boolean,
    default: false
  },
  // For file attachments
  attachments: [{
    name: String,
    url: String,
    type: String,
    size: Number
  }],
  // Materials (PDFs, PPTs) - references to CourseMaterial
  materials: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'CourseMaterial'
  }],
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true
  }
}, {
  timestamps: true
});

// Index for efficient queries
lectureSchema.index({ sectionId: 1, order: 1 });
lectureSchema.index({ sectionId: 1, isActive: 1 });
lectureSchema.index({ type: 1 });

// Virtual to get the course through section
lectureSchema.virtual('course', {
  ref: 'Course',
  localField: 'sectionId',
  foreignField: 'sections',
  justOne: true
});

// Method to get content URL based on type
lectureSchema.methods.getContentUrl = function() {
  if (this.type === 'video') {
    return this.videoUrl;
  } else if (this.type === 'pdf') {
    return this.fileUrl;
  }
  return null;
};

// Static method to get lectures by section
lectureSchema.statics.getLecturesBySection = function(sectionId) {
  return this.find({ sectionId: sectionId, isActive: true }).sort({ order: 1 });
};

// Static method to get lectures by course (through sections)
lectureSchema.statics.getLecturesByCourse = function(courseId) {
  return this.aggregate([
    {
      $lookup: {
        from: 'sections',
        localField: 'sectionId',
        foreignField: '_id',
        as: 'section'
      }
    },
    {
      $match: {
        'section.courseId': mongoose.Types.ObjectId(courseId),
        isActive: true
      }
    },
    {
      $sort: { 'section.order': 1, order: 1 }
    }
  ]);
};

export default mongoose.model('Lecture', lectureSchema);
