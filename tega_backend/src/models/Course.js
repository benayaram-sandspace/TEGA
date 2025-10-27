import mongoose from 'mongoose';

const courseSchema = new mongoose.Schema({
  courseName: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true,
    trim: true
  },
  price: {
    type: Number,
    required: true,
    min: 0
  },
  duration: {
    type: String,
    required: true,
    trim: true
  },
  category: {
    type: String,
    required: true,
    trim: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  instructor: {
    type: String,
    trim: true
  },
  level: {
    type: String,
    enum: ['Beginner', 'Intermediate', 'Advanced'],
    default: 'Beginner'
  },
  maxStudents: {
    type: Number,
    default: 100
  },
  enrolledStudents: {
    type: Number,
    default: 0
  },
  startDate: {
    type: Date
  },
  endDate: {
    type: Date
  },
  syllabus: [{
    week: Number,
    title: String,
    description: String,
    materials: [String]
  }],
  requirements: [String],
  outcomes: [String],
  thumbnail: {
    type: String
  },
  image: {
    type: String,
    default: null
  },
  videoUrl: {
    type: String
  },
  modules: [{
    title: {
      type: String,
      required: true
    },
    description: {
      type: String,
      default: ''
    },
    order: {
      type: Number,
      default: 0
    },
    videos: [{
      title: {
        type: String,
        required: true
      },
      videoLink: {
        type: String,
        required: true
      },
      duration: {
        type: String,
        default: '0:00'
      },
      isPreview: {
        type: Boolean,
        default: false
      },
      order: {
        type: Number,
        default: 0
      }
    }]
  }]
}, {
  timestamps: true
});

// Index for better query performance
courseSchema.index({ courseName: 1, category: 1, isActive: 1 });
courseSchema.index({ price: 1 });
courseSchema.index({ isActive: 1 });

// Virtual for enrollment status
courseSchema.virtual('enrollmentStatus').get(function() {
  if (this.enrolledStudents >= this.maxStudents) {
    return 'Full';
  } else if (this.enrolledStudents >= this.maxStudents * 0.8) {
    return 'Almost Full';
  } else {
    return 'Available';
  }
});

// Method to check if course is available for enrollment
courseSchema.methods.canEnroll = function() {
  return this.isActive && this.enrolledStudents < this.maxStudents;
};

// Method to increment enrolled students
courseSchema.methods.incrementEnrollment = function() {
  if (this.enrolledStudents < this.maxStudents) {
    this.enrolledStudents += 1;
    return this.save();
  }
  throw new Error('Course is full');
};

// Method to decrement enrolled students
courseSchema.methods.decrementEnrollment = function() {
  if (this.enrolledStudents > 0) {
    this.enrolledStudents -= 1;
    return this.save();
  }
  throw new Error('No students enrolled');
};

// Static method to get courses by category
courseSchema.statics.getByCategory = function(category) {
  return this.find({ 
    category, 
    isActive: true,
    courseName: { $ne: 'Tega Exam' } // Exclude Tega Exam from user courses
  }).sort({ price: 1 });
};

// Static method to get courses by price range
courseSchema.statics.getByPriceRange = function(minPrice, maxPrice) {
  return this.find({ 
    price: { $gte: minPrice, $lte: maxPrice }, 
    isActive: true,
    courseName: { $ne: 'Tega Exam' } // Exclude Tega Exam from user courses
  }).sort({ price: 1 });
};

// Static method to get popular courses
courseSchema.statics.getPopular = function(limit = 10) {
  return this.find({ 
    isActive: true,
    courseName: { $ne: 'Tega Exam' } // Exclude Tega Exam from user courses
  })
    .sort({ enrolledStudents: -1 })
    .limit(limit);
};

// Static method to get all active courses
courseSchema.statics.getActiveCourses = function() {
  return this.find({ 
    isActive: true,
    courseName: { $ne: 'Tega Exam' } // Exclude Tega Exam from user courses
  })
    .sort({ createdAt: -1 })
    .select('courseName description price duration category instructor level maxStudents enrolledStudents image');
};

// Static method to get course pricing
courseSchema.statics.getCoursePricing = function() {
  return this.find({ 
    isActive: true,
    courseName: { $ne: 'Tega Exam' } // Exclude Tega Exam from user courses
  })
    .select('courseName price duration category')
    .sort({ price: 1 });
};

export default mongoose.model('Course', courseSchema);
