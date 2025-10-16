import mongoose from 'mongoose';

const enrollmentSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'RealTimeCourse',
    required: true
  },
  enrolledAt: {
    type: Date,
    default: Date.now
  },
  status: {
    type: String,
    enum: ['active', 'completed', 'cancelled'],
    default: 'active'
  },
  progress: {
    type: Number,
    default: 0,
    min: 0,
    max: 100
  },
  completedLectures: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Lecture'
  }],
  lastAccessedAt: {
    type: Date,
    default: Date.now
  },
  // For paid courses
  paymentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Payment'
  },
  isPaid: {
    type: Boolean,
    default: false
  },
  // Additional fields from UserCourse
  courseName: {
    type: String,
    required: true
  },
  accessExpiresAt: {
    type: Date
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Compound index for efficient queries
enrollmentSchema.index({ studentId: 1, courseId: 1 }, { unique: true });
enrollmentSchema.index({ studentId: 1, status: 1 });
enrollmentSchema.index({ courseId: 1, status: 1 });

// Method to check if student has access to a lecture
enrollmentSchema.methods.hasAccessToLecture = function(lecture, isFirstLecture = false) {
  // First lecture is always free
  if (isFirstLecture) {
    return true;
  }
  
  // If course is free, all lectures are accessible
  if (this.courseId.price === 0) {
    return true;
  }
  
  // For paid courses, student must be enrolled
  return this.status === 'active';
};

// Method to update progress
enrollmentSchema.methods.updateProgress = function(completedLectures, totalLectures) {
  this.progress = Math.round((completedLectures / totalLectures) * 100);
  this.lastAccessedAt = new Date();
  
  if (this.progress >= 100) {
    this.status = 'completed';
  }
  
  return this.save();
};

// Static method to get student's enrollments
enrollmentSchema.statics.getStudentEnrollments = function(studentId) {
  return this.find({ studentId, status: 'active' })
    .populate('courseId', 'title description thumbnail price category level')
    .sort({ lastAccessedAt: -1 });
};

// Static method to get course enrollment count
enrollmentSchema.statics.getCourseEnrollmentCount = function(courseId) {
  return this.countDocuments({ courseId, status: 'active' });
};

// Static method to check if user has access to course (from UserCourse)
enrollmentSchema.statics.hasAccess = async function(studentId, courseId) {
  const enrollment = await this.findOne({
    studentId,
    courseId,
    status: 'active',
    isActive: true,
    $or: [
      { accessExpiresAt: { $exists: false } },
      { accessExpiresAt: { $gt: new Date() } }
    ]
  });
  
  return !!enrollment;
};

// Static method to get user's active courses (from UserCourse)
enrollmentSchema.statics.getActiveCourses = async function(studentId) {
  return await this.find({
    studentId,
    status: 'active',
    isActive: true,
    $or: [
      { accessExpiresAt: { $exists: false } },
      { accessExpiresAt: { $gt: new Date() } }
    ]
  }).populate('courseId', 'title description price estimatedDuration category');
};

export default mongoose.model('Enrollment', enrollmentSchema);
