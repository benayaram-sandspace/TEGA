import mongoose from 'mongoose';

const realTimeCourseSchema = new mongoose.Schema({
  // Basic Course Info
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true,
    trim: true
  },
  shortDescription: {
    type: String,
    maxlength: 200
  },
  
  // Visual Elements
  thumbnail: {
    type: String, // R2 URL for thumbnail
    default: ''
  },
  banner: {
    type: String // R2 URL for course banner
  },
  previewVideo: {
    type: String // R2 URL for preview video
  },
  
  // Course Details
  instructor: {
    name: {
      type: String,
      required: true
    },
    avatar: {
      type: String // R2 URL for instructor avatar
    },
    bio: {
      type: String
    },
    socialLinks: {
      linkedin: String,
      twitter: String,
      website: String
    }
  },
  
  // Pricing & Access
  price: {
    type: Number,
    required: true,
    min: 0
  },
  originalPrice: {
    type: Number
  },
  currency: {
    type: String,
    default: 'INR'
  },
  isFree: {
    type: Boolean,
    default: false
  },
  
  // Course Structure
  level: {
    type: String,
    enum: ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
    required: true
  },
  category: {
    type: String,
    required: true
  },
  tags: [String],
  
  // Duration & Content
  estimatedDuration: {
    hours: {
      type: Number,
      required: true
    },
    minutes: {
      type: Number,
      default: 0
    }
  },
  totalLectures: {
    type: Number,
    default: 0
  },
  totalQuizzes: {
    type: Number,
    default: 0
  },
  totalMaterials: {
    type: Number,
    default: 0
  },
  
  // Real-time Features
  isLive: {
    type: Boolean,
    default: false
  },
  liveStreamUrl: {
    type: String // For live streaming
  },
  nextLiveSession: {
    type: Date
  },
  liveViewers: {
    type: Number,
    default: 0
  },
  
  // Engagement Metrics
  enrollmentCount: {
    type: Number,
    default: 0
  },
  completionRate: {
    type: Number,
    default: 0
  },
  averageRating: {
    type: Number,
    default: 0
  },
  totalRatings: {
    type: Number,
    default: 0
  },
  
  // Real-time Analytics
  realTimeStats: {
    currentViewers: {
      type: Number,
      default: 0
    },
    totalWatchTime: {
      type: Number,
      default: 0 // in seconds
    },
    engagementScore: {
      type: Number,
      default: 0
    },
    lastUpdated: {
      type: Date,
      default: Date.now
    }
  },
  
  // Course Content
  modules: [{
    _id: false,
    id: {
      type: String,
      required: true
    },
    title: {
      type: String,
      required: true
    },
    description: {
      type: String
    },
    order: {
      type: Number,
      required: true
    },
    isUnlocked: {
      type: Boolean,
      default: false
    },
    unlockCondition: {
      type: String,
      enum: ['immediate', 'previous_complete', 'quiz_pass', 'time_based'],
      default: 'immediate'
    },
    // ✅ NEW: Quiz reference for this module
    quiz: {
      id: mongoose.Schema.Types.ObjectId,
      totalQuestions: Number,
      passMarks: Number,
      passMarksPerQuestion: Number
    },
    lectures: [{
      _id: false,
      id: {
        type: String,
        required: true
      },
      title: {
        type: String,
        required: true
      },
      description: {
        type: String
      },
      type: {
        type: String,
        enum: ['video', 'quiz', 'assignment', 'live_session'],
        required: true
      },
      order: {
        type: Number,
        required: true
      },
      duration: {
        type: Number, // in seconds
        default: 0
      },
      
      // Video Content (R2)
      videoContent: {
        r2Key: String,
        r2Url: String,
        fileSize: Number,
        resolution: String,
        format: String,
        thumbnail: String,
        subtitles: [{
          language: String,
          r2Key: String,
          r2Url: String
        }]
      },
      
      // Quiz Content
      quizContent: {
        questions: [{
          id: String,
          question: String,
          type: {
            type: String,
            enum: ['multiple_choice', 'true_false', 'fill_blank', 'essay']
          },
          options: [String],
          correctAnswer: mongoose.Schema.Types.Mixed,
          explanation: String,
          points: {
            type: Number,
            default: 1
          }
        }],
        timeLimit: Number, // in minutes
        passingScore: {
          type: Number,
          default: 70
        },
        attemptsAllowed: {
          type: Number,
          default: 3
        },
        shuffleQuestions: {
          type: Boolean,
          default: false
        },
        showCorrectAnswers: {
          type: Boolean,
          default: true
        }
      },
      
      // Assignment Content
      assignmentContent: {
        instructions: String,
        attachments: [{
          name: String,
          r2Key: String,
          r2Url: String,
          type: String
        }],
        dueDate: Date,
        maxFileSize: Number,
        allowedFileTypes: [String]
      },
      
      // Live Session Content
      liveSessionContent: {
        scheduledAt: Date,
        duration: Number,
        streamUrl: String,
        recordingUrl: String,
        chatEnabled: {
          type: Boolean,
          default: true
        },
        qaEnabled: {
          type: Boolean,
          default: true
        }
      },
      
      // Materials (R2)
      materials: [{
        id: {
          type: String,
          required: true
        },
        name: {
          type: String,
          required: true
        },
        type: {
          type: String,
          required: true
        },
        r2Key: {
          type: String,
          required: true
        },
        r2Url: {
          type: String,
          required: true
        },
        fileSize: {
          type: Number,
          required: true
        },
        downloadCount: {
          type: Number,
          default: 0
        }
      }],
      
      // Prerequisites
      prerequisites: [String],
      
      // Status
      isPreview: {
        type: Boolean,
        default: false
      },
      isActive: {
        type: Boolean,
        default: true
      },
      isPremium: {
        type: Boolean,
        default: false
      },
      requiresEnrollment: {
        type: Boolean,
        default: true
      }
    }]
  }],
  
  // Real-time Features
  realTimeFeatures: {
    liveChat: {
      enabled: {
        type: Boolean,
        default: true
      },
      moderation: {
        type: Boolean,
        default: true
      }
    },
    progressTracking: {
      enabled: {
        type: Boolean,
        default: true
      },
      granularity: {
        type: String,
        enum: ['lecture', 'module', 'course'],
        default: 'lecture'
      }
    },
    notifications: {
      enabled: {
        type: Boolean,
        default: true
      },
      types: [String] // ['email', 'push', 'in_app']
    },
    socialFeatures: {
      discussionForum: {
        type: Boolean,
        default: true
      },
      peerInteraction: {
        type: Boolean,
        default: true
      },
      leaderboard: {
        type: Boolean,
        default: true
      }
    }
  },
  
  // Course Status
  status: {
    type: String,
    enum: ['draft', 'published', 'archived', 'scheduled'],
    default: 'draft'
  },
  publishedAt: {
    type: Date
  },
  
  // SEO & Marketing
  slug: {
    type: String,
    unique: true,
    required: true
  },
  metaDescription: {
    type: String
  },
  keywords: [String],
  
  // Creator Info
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true
  },
  
  // Timestamps
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes for performance
realTimeCourseSchema.index({ status: 1, publishedAt: -1 });
realTimeCourseSchema.index({ category: 1, level: 1 });
realTimeCourseSchema.index({ slug: 1 });
realTimeCourseSchema.index({ 'instructor.name': 1 });
realTimeCourseSchema.index({ tags: 1 });
realTimeCourseSchema.index({ price: 1, currency: 1 });
realTimeCourseSchema.index({ 'realTimeStats.lastUpdated': 1 });

// Virtual for total duration in minutes
realTimeCourseSchema.virtual('totalDurationMinutes').get(function() {
  return this.estimatedDuration.hours * 60 + this.estimatedDuration.minutes;
});

// Virtual for formatted duration
realTimeCourseSchema.virtual('formattedDuration').get(function() {
  const hours = this.estimatedDuration.hours;
  const minutes = this.estimatedDuration.minutes;
  
  if (hours > 0 && minutes > 0) {
    return `${hours}h ${minutes}m`;
  } else if (hours > 0) {
    return `${hours}h`;
  } else {
    return `${minutes}m`;
  }
});

// Virtual for discount percentage
realTimeCourseSchema.virtual('discountPercentage').get(function() {
  if (this.originalPrice && this.originalPrice > this.price) {
    return Math.round(((this.originalPrice - this.price) / this.originalPrice) * 100);
  }
  return 0;
});

// Methods
realTimeCourseSchema.methods.updateRealTimeStats = function(stats) {
  this.realTimeStats = {
    ...this.realTimeStats,
    ...stats,
    lastUpdated: new Date()
  };
  return this.save();
};

realTimeCourseSchema.methods.incrementEnrollment = function() {
  this.enrollmentCount += 1;
  return this.save();
};

realTimeCourseSchema.methods.updateRating = function(newRating) {
  const totalRatings = this.totalRatings + 1;
  const newAverage = ((this.averageRating * this.totalRatings) + newRating) / totalRatings;
  
  this.totalRatings = totalRatings;
  this.averageRating = Math.round(newAverage * 10) / 10; // Round to 1 decimal
  return this.save();
};

// Static methods
realTimeCourseSchema.statics.getPublishedCourses = function(filters = {}) {
  const query = { status: 'published', ...filters };
  return this.find(query).sort({ publishedAt: -1 });
};

realTimeCourseSchema.statics.getPopularCourses = function(limit = 10) {
  return this.find({ status: 'published' })
    .sort({ enrollmentCount: -1, averageRating: -1 })
    .limit(limit);
};

realTimeCourseSchema.statics.getCoursesByCategory = function(category, limit = 20) {
  return this.find({ 
    status: 'published',
    category: new RegExp(category, 'i')
  }).sort({ enrollmentCount: -1 }).limit(limit);
};

realTimeCourseSchema.statics.searchCourses = function(searchTerm, filters = {}) {
  const query = {
    status: 'published',
    ...filters,
    $or: [
      { title: new RegExp(searchTerm, 'i') },
      { description: new RegExp(searchTerm, 'i') },
      { tags: new RegExp(searchTerm, 'i') },
      { 'instructor.name': new RegExp(searchTerm, 'i') }
    ]
  };
  
  return this.find(query).sort({ enrollmentCount: -1 });
};

// Pre-save middleware
realTimeCourseSchema.pre('save', function(next) {
  if (this.isModified('title')) {
    this.slug = this.title
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .trim('-');
  }
  
  if (this.status === 'published' && !this.publishedAt) {
    this.publishedAt = new Date();
  }
  
  this.updatedAt = new Date();
  next();
});

export default mongoose.model('RealTimeCourse', realTimeCourseSchema);
