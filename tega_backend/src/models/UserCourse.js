import mongoose from 'mongoose';

const userCourseSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: true
  },
  courseName: {
    type: String,
    required: true
  },
  paymentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'RazorpayPayment',
    required: true
  },
  enrolledAt: {
    type: Date,
    default: Date.now
  },
  accessExpiresAt: {
    type: Date,
    required: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  progress: {
    type: Number,
    default: 0,
    min: 0,
    max: 100
  },
  lastAccessedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes for better performance
userCourseSchema.index({ studentId: 1, courseId: 1 });
userCourseSchema.index({ studentId: 1, isActive: 1 });
userCourseSchema.index({ accessExpiresAt: 1 });

// Static method to check if user has access to course
userCourseSchema.statics.hasAccess = async function(studentId, courseId) {
  const userCourse = await this.findOne({
    studentId,
    courseId,
    isActive: true,
    accessExpiresAt: { $gt: new Date() }
  });
  
  return !!userCourse;
};

// Static method to get user's active courses
userCourseSchema.statics.getActiveCourses = async function(studentId) {
  return await this.find({
    studentId,
    isActive: true,
    accessExpiresAt: { $gt: new Date() }
  }).populate('courseId', 'courseName description price duration category');
};

export default mongoose.model('UserCourse', userCourseSchema);
