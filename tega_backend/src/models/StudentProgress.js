import mongoose from 'mongoose';

const studentProgressSchema = new mongoose.Schema({
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
  sectionId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Section',
    required: true
  },
  lectureId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Lecture',
    required: true
  },
  isCompleted: {
    type: Boolean,
    default: false
  },
  completedAt: {
    type: Date
  },
  progressPercentage: {
    type: Number,
    default: 0,
    min: 0,
    max: 100
  },
  timeSpent: {
    type: Number, // in seconds
    default: 0
  },
  lastPosition: {
    type: Number, // for video lectures - last watched position in seconds
    default: 0
  },
  // For quiz lectures
  quizAttempts: [{
    attemptNumber: Number,
    score: Number,
    totalQuestions: Number,
    correctAnswers: Number,
    attemptedAt: Date,
    answers: [{
      questionIndex: Number,
      selectedAnswer: Number,
      isCorrect: Boolean
    }]
  }],
  // For PDF lectures
  downloadCount: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Compound index for efficient queries
studentProgressSchema.index({ studentId: 1, courseId: 1, lectureId: 1 }, { unique: true });
studentProgressSchema.index({ studentId: 1, courseId: 1 });
studentProgressSchema.index({ studentId: 1, isCompleted: 1 });

// Method to mark lecture as completed
studentProgressSchema.methods.markCompleted = function() {
  this.isCompleted = true;
  this.completedAt = new Date();
  this.progressPercentage = 100;
  return this.save();
};

// Method to update progress
studentProgressSchema.methods.updateProgress = function(percentage, timeSpent = 0, lastPosition = 0) {
  this.progressPercentage = Math.min(100, Math.max(0, percentage));
  this.timeSpent += timeSpent;
  this.lastPosition = lastPosition;
  
  // Auto-complete if progress is 90% or more
  if (this.progressPercentage >= 90 && !this.isCompleted) {
    this.markCompleted();
  }
  
  return this.save();
};

// Static method to get student's course progress
studentProgressSchema.statics.getCourseProgress = function(studentId, courseId) {
  return this.find({ studentId, courseId }).populate('lectureId', 'title type duration');
};

// Static method to get student's overall progress
studentProgressSchema.statics.getStudentProgress = function(studentId) {
  return this.aggregate([
    { $match: { studentId: mongoose.Types.ObjectId(studentId) } },
    {
      $group: {
        _id: '$courseId',
        totalLectures: { $sum: 1 },
        completedLectures: {
          $sum: { $cond: ['$isCompleted', 1, 0] }
        },
        totalTimeSpent: { $sum: '$timeSpent' }
      }
    },
    {
      $lookup: {
        from: 'courses',
        localField: '_id',
        foreignField: '_id',
        as: 'course'
      }
    },
    {
      $project: {
        courseId: '$_id',
        course: { $arrayElemAt: ['$course', 0] },
        totalLectures: 1,
        completedLectures: 1,
        totalTimeSpent: 1,
        progressPercentage: {
          $multiply: [
            { $divide: ['$completedLectures', '$totalLectures'] },
            100
          ]
        }
      }
    }
  ]);
};

export default mongoose.model('StudentProgress', studentProgressSchema);
