import mongoose from 'mongoose';

const realTimeProgressSchema = new mongoose.Schema({
  // Student & Course Info
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
  
  // Overall Progress
  overallProgress: {
    percentage: {
      type: Number,
      default: 0,
      min: 0,
      max: 100
    },
    completedModules: {
      type: Number,
      default: 0
    },
    totalModules: {
      type: Number,
      required: true
    },
    completedLectures: {
      type: Number,
      default: 0
    },
    totalLectures: {
      type: Number,
      required: true
    },
    timeSpent: {
      type: Number,
      default: 0 // in seconds
    },
    lastAccessedAt: {
      type: Date,
      default: Date.now
    }
  },
  
  // Module Progress
  moduleProgress: [{
    moduleId: {
      type: String,
      required: true
    },
    title: {
      type: String,
      required: true
    },
    progress: {
      type: Number,
      default: 0,
      min: 0,
      max: 100
    },
    isCompleted: {
      type: Boolean,
      default: false
    },
    completedAt: {
      type: Date
    },
    timeSpent: {
      type: Number,
      default: 0 // in seconds
    },
    lastAccessedAt: {
      type: Date,
      default: Date.now
    }
  }],
  
  // Lecture Progress
  lectureProgress: [{
    lectureId: {
      type: String,
      required: true
    },
    moduleId: {
      type: String,
      required: true
    },
    title: {
      type: String,
      required: true
    },
    type: {
      type: String,
      enum: ['video', 'quiz', 'assignment', 'live_session'],
      required: true
    },
    progress: {
      type: Number,
      default: 0,
      min: 0,
      max: 100
    },
    isCompleted: {
      type: Boolean,
      default: false
    },
    completedAt: {
      type: Date
    },
    timeSpent: {
      type: Number,
      default: 0 // in seconds
    },
    lastPosition: {
      type: Number,
      default: 0 // in seconds for videos
    },
    lastAccessedAt: {
      type: Date,
      default: Date.now
    },
    
    // Video-specific progress
    videoProgress: {
      watchedDuration: {
        type: Number,
        default: 0 // in seconds
      },
      totalDuration: {
        type: Number,
        default: 0 // in seconds
      },
      playbackRate: {
        type: Number,
        default: 1
      },
      quality: {
        type: String,
        default: 'auto'
      }
    },
    
    // Quiz-specific progress
    quizProgress: {
      attempts: [{
        attemptNumber: {
          type: Number,
          required: true
        },
        score: {
          type: Number,
          required: true,
          min: 0,
          max: 100
        },
        totalQuestions: {
          type: Number,
          required: true
        },
        correctAnswers: {
          type: Number,
          required: true
        },
        timeSpent: {
          type: Number,
          required: true // in seconds
        },
        answers: [{
          questionId: String,
          selectedAnswer: mongoose.Schema.Types.Mixed,
          isCorrect: Boolean,
          pointsEarned: Number
        }],
        startedAt: {
          type: Date,
          required: true
        },
        completedAt: {
          type: Date,
          required: true
        },
        passed: {
          type: Boolean,
          required: true
        }
      }],
      bestScore: {
        type: Number,
        default: 0
      },
      totalAttempts: {
        type: Number,
        default: 0
      },
      isPassed: {
        type: Boolean,
        default: false
      },
      passedAt: {
        type: Date
      }
    },
    
    // Assignment-specific progress
    assignmentProgress: {
      submitted: {
        type: Boolean,
        default: false
      },
      submittedAt: {
        type: Date
      },
      grade: {
        type: Number
      },
      feedback: {
        type: String
      },
      attachments: [{
        name: String,
        r2Key: String,
        r2Url: String,
        size: Number
      }]
    },
    
    // Live session progress
    liveSessionProgress: {
      attended: {
        type: Boolean,
        default: false
      },
      attendedAt: {
        type: Date
      },
      attendanceDuration: {
        type: Number,
        default: 0 // in seconds
      },
      questionsAsked: {
        type: Number,
        default: 0
      },
      chatMessages: {
        type: Number,
        default: 0
      }
    }
  }],
  
  // Real-time Activity
  realTimeActivity: {
    isCurrentlyWatching: {
      type: Boolean,
      default: false
    },
    currentLectureId: {
      type: String
    },
    currentModuleId: {
      type: String
    },
    watchingSince: {
      type: Date
    },
    lastHeartbeat: {
      type: Date,
      default: Date.now
    },
    deviceInfo: {
      userAgent: String,
      platform: String,
      browser: String
    }
  },
  
  // Engagement Metrics
  engagement: {
    totalInteractions: {
      type: Number,
      default: 0
    },
    quizInteractions: {
      type: Number,
      default: 0
    },
    discussionPosts: {
      type: Number,
      default: 0
    },
    materialsDownloaded: {
      type: Number,
      default: 0
    },
    averageSessionDuration: {
      type: Number,
      default: 0 // in seconds
    },
    streakDays: {
      type: Number,
      default: 0
    },
    lastActiveDate: {
      type: Date,
      default: Date.now
    }
  },
  
  // Certificates & Achievements
  achievements: [{
    id: {
      type: String,
      required: true
    },
    name: {
      type: String,
      required: true
    },
    description: {
      type: String
    },
    icon: {
      type: String
    },
    earnedAt: {
      type: Date,
      default: Date.now
    },
    category: {
      type: String,
      enum: ['completion', 'performance', 'engagement', 'milestone']
    }
  }],
  
  certificate: {
    isEligible: {
      type: Boolean,
      default: false
    },
    isGenerated: {
      type: Boolean,
      default: false
    },
    generatedAt: {
      type: Date
    },
    certificateId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Certificate'
    },
    finalGrade: {
      type: String,
      enum: ['A+', 'A', 'B+', 'B', 'C+', 'C', 'Pass', 'N/A']
    },
    finalScore: {
      type: Number,
      min: 0,
      max: 100
    }
  },
  
  // Course Completion
  isCompleted: {
    type: Boolean,
    default: false
  },
  completedAt: {
    type: Date
  },
  completionPercentage: {
    type: Number,
    default: 0,
    min: 0,
    max: 100
  },
  
  // Timestamps
  enrolledAt: {
    type: Date,
    default: Date.now
  },
  lastUpdatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Compound indexes
realTimeProgressSchema.index({ studentId: 1, courseId: 1 }, { unique: true });
realTimeProgressSchema.index({ studentId: 1, lastUpdatedAt: -1 });
realTimeProgressSchema.index({ courseId: 1, 'overallProgress.percentage': -1 });
realTimeProgressSchema.index({ 'realTimeActivity.isCurrentlyWatching': 1, 'realTimeActivity.lastHeartbeat': -1 });

// Methods
realTimeProgressSchema.methods.updateLectureProgress = function(lectureId, progressData) {
  const lectureIndex = this.lectureProgress.findIndex(l => l.lectureId === lectureId);
  
  if (lectureIndex === -1) {
    // Add new lecture progress
    this.lectureProgress.push({
      lectureId,
      moduleId: progressData.moduleId,
      title: progressData.title,
      type: progressData.type,
      progress: progressData.progress || 0,
      isCompleted: progressData.isCompleted || false,
      completedAt: progressData.isCompleted ? new Date() : undefined,
      timeSpent: progressData.timeSpent || 0,
      lastPosition: progressData.lastPosition || 0,
      lastAccessedAt: new Date(),
      ...progressData
    });
  } else {
    // Update existing lecture progress
    const lecture = this.lectureProgress[lectureIndex];
    Object.assign(lecture, progressData);
    lecture.lastAccessedAt = new Date();
    
    if (progressData.isCompleted && !lecture.isCompleted) {
      lecture.completedAt = new Date();
    }
  }
  
  return this.save();
};

realTimeProgressSchema.methods.updateQuizAttempt = function(lectureId, attemptData) {
  const lectureIndex = this.lectureProgress.findIndex(l => l.lectureId === lectureId);
  
  if (lectureIndex !== -1) {
    const lecture = this.lectureProgress[lectureIndex];
    
    if (!lecture.quizProgress) {
      lecture.quizProgress = {
        attempts: [],
        bestScore: 0,
        totalAttempts: 0,
        isPassed: false
      };
    }
    
    const attemptNumber = lecture.quizProgress.attempts.length + 1;
    
    lecture.quizProgress.attempts.push({
      attemptNumber,
      ...attemptData,
      startedAt: attemptData.startedAt || new Date(),
      completedAt: attemptData.completedAt || new Date()
    });
    
    lecture.quizProgress.totalAttempts = attemptNumber;
    
    // Update best score
    if (attemptData.score > lecture.quizProgress.bestScore) {
      lecture.quizProgress.bestScore = attemptData.score;
    }
    
    // Check if quiz is passed (assuming 70% passing score)
    if (attemptData.score >= 70 && !lecture.quizProgress.isPassed) {
      lecture.quizProgress.isPassed = true;
      lecture.quizProgress.passedAt = new Date();
      lecture.isCompleted = true;
      lecture.completedAt = new Date();
    }
  }
  
  return this.save();
};

realTimeProgressSchema.methods.updateRealTimeActivity = function(activityData) {
  this.realTimeActivity = {
    ...this.realTimeActivity,
    ...activityData,
    lastHeartbeat: new Date()
  };
  
  this.lastUpdatedAt = new Date();
  return this.save();
};

realTimeProgressSchema.methods.calculateOverallProgress = function() {
  // Production-ready: Calculate module and lecture progress dynamically
  const totalLectures = this.overallProgress.totalLectures || 0;
  const totalModules = this.overallProgress.totalModules || 0;
  
  if (totalLectures === 0) {
    this.overallProgress.percentage = 0;
    this.overallProgress.completedLectures = 0;
    this.overallProgress.completedModules = 0;
    return this.save();
  }
  
  // Calculate completed lectures
  const completedLectures = this.lectureProgress.filter(l => l.isCompleted === true).length;
  this.overallProgress.completedLectures = completedLectures;
  
  // Calculate overall progress percentage
  this.overallProgress.percentage = Math.round((completedLectures / totalLectures) * 100);
  
  // Calculate total time spent from all lectures
  this.overallProgress.timeSpent = this.lectureProgress.reduce((total, lecture) => {
    return total + (Number(lecture.timeSpent) || 0);
  }, 0);
  
  // Group lectures by module to calculate module progress
  const lecturesByModule = {};
  this.lectureProgress.forEach(lecture => {
    const moduleId = lecture.moduleId;
    if (!moduleId) return;
    
    if (!lecturesByModule[moduleId]) {
      lecturesByModule[moduleId] = {
        total: 0,
        completed: 0
      };
    }
    lecturesByModule[moduleId].total++;
    if (lecture.isCompleted) {
      lecturesByModule[moduleId].completed++;
    }
  });
  
  // Update module progress and calculate completed modules
  let completedModulesCount = 0;
  Object.keys(lecturesByModule).forEach(moduleId => {
    const moduleStats = lecturesByModule[moduleId];
    const moduleProgressIndex = this.moduleProgress.findIndex(m => m.moduleId === moduleId);
    
    // Calculate module progress percentage
    const moduleProgressPercentage = moduleStats.total > 0 
      ? Math.round((moduleStats.completed / moduleStats.total) * 100)
      : 0;
    
    const isModuleCompleted = moduleStats.total > 0 && moduleStats.completed === moduleStats.total;
    
    if (moduleProgressIndex >= 0) {
      // Update existing module progress
      const moduleProgress = this.moduleProgress[moduleProgressIndex];
      moduleProgress.progress = moduleProgressPercentage;
      moduleProgress.isCompleted = isModuleCompleted;
      
      // Update time spent for module (sum of all lectures in module)
      moduleProgress.timeSpent = this.lectureProgress
        .filter(l => l.moduleId === moduleId)
        .reduce((sum, l) => sum + (Number(l.timeSpent) || 0), 0);
      
      if (isModuleCompleted && !moduleProgress.isCompleted) {
        moduleProgress.completedAt = new Date();
      }
      
      moduleProgress.lastAccessedAt = new Date();
    } else {
      // Create new module progress entry (should not happen in production, but handle gracefully)
      const lecture = this.lectureProgress.find(l => l.moduleId === moduleId);
      if (lecture) {
        this.moduleProgress.push({
          moduleId,
          title: lecture.title || `Module ${moduleId}`,
          progress: moduleProgressPercentage,
          isCompleted: isModuleCompleted,
          completedAt: isModuleCompleted ? new Date() : undefined,
          timeSpent: this.lectureProgress
            .filter(l => l.moduleId === moduleId)
            .reduce((sum, l) => sum + (Number(l.timeSpent) || 0), 0),
          lastAccessedAt: new Date()
        });
      }
    }
    
    if (isModuleCompleted) {
      completedModulesCount++;
    }
  });
  
  // Update completed modules count
  this.overallProgress.completedModules = completedModulesCount;
  
  // Check if course is completed (all modules completed or all lectures completed)
  const isFullyCompleted = (completedModulesCount === totalModules && totalModules > 0) || 
                          (completedLectures === totalLectures && totalLectures > 0);
  
  if (isFullyCompleted && !this.isCompleted) {
    this.isCompleted = true;
    this.completedAt = new Date();
    this.completionPercentage = 100;
    this.overallProgress.percentage = 100;
    
    // Mark certificate as eligible when course is completed
    if (!this.certificate.isEligible) {
      this.certificate.isEligible = true;
    }
  }
  
  // Update last accessed timestamp
  this.overallProgress.lastAccessedAt = new Date();
  this.lastUpdatedAt = new Date();
  
  return this.save();
};

realTimeProgressSchema.methods.addAchievement = function(achievement) {
  // Check if achievement already exists
  const exists = this.achievements.some(a => a.id === achievement.id);
  if (!exists) {
    this.achievements.push({
      ...achievement,
      earnedAt: new Date()
    });
    return this.save();
  }
  return Promise.resolve(this);
};

// Static methods
realTimeProgressSchema.statics.getStudentProgress = function(studentId, courseId) {
  return this.findOne({ studentId, courseId });
};

realTimeProgressSchema.statics.getCourseLeaderboard = function(courseId, limit = 10) {
  return this.find({ courseId })
    .sort({ 'overallProgress.percentage': -1, 'overallProgress.timeSpent': -1 })
    .limit(limit)
    .populate('studentId', 'name email avatar');
};

realTimeProgressSchema.statics.getCurrentlyWatching = function(courseId) {
  const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
  
  return this.find({
    courseId,
    'realTimeActivity.isCurrentlyWatching': true,
    'realTimeActivity.lastHeartbeat': { $gte: fiveMinutesAgo }
  }).populate('studentId', 'name avatar');
};

realTimeProgressSchema.statics.getStudentStats = function(studentId) {
  return this.aggregate([
    { $match: { studentId: mongoose.Types.ObjectId(studentId) } },
    {
      $group: {
        _id: null,
        totalCourses: { $sum: 1 },
        completedCourses: { $sum: { $cond: ['$isCompleted', 1, 0] } },
        averageProgress: { $avg: '$overallProgress.percentage' },
        totalTimeSpent: { $sum: '$overallProgress.timeSpent' },
        totalAchievements: { $sum: { $size: '$achievements' } }
      }
    }
  ]);
};

// Pre-save middleware
realTimeProgressSchema.pre('save', function(next) {
  this.lastUpdatedAt = new Date();
  next();
});

export default mongoose.model('RealTimeProgress', realTimeProgressSchema);
