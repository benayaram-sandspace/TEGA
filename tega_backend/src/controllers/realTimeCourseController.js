import RealTimeCourse from '../models/RealTimeCourse.js';
import RealTimeProgress from '../models/RealTimeProgress.js';
import Student from '../models/Student.js';
import Enrollment from '../models/Enrollment.js';
import { uploadToR2, generateR2Key, generatePresignedUploadUrl, generatePresignedDownloadUrl } from '../config/r2.js';
import mongoose from 'mongoose';

// Get all published courses with real-time features
export const getRealTimeCourses = async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 12, 
      category, 
      level, 
      search, 
      sortBy = 'publishedAt',
      sortOrder = 'desc',
      isFree,
      priceMin,
      priceMax
    } = req.query;

    const filters = { status: 'published' };
    
    if (category) filters.category = new RegExp(category, 'i');
    if (level) filters.level = level;
    if (isFree !== undefined) filters.isFree = isFree === 'true';
    if (priceMin || priceMax) {
      filters.price = {};
      if (priceMin) filters.price.$gte = Number(priceMin);
      if (priceMax) filters.price.$lte = Number(priceMax);
    }

    let query = RealTimeCourse.find(filters);

    // Search functionality
    if (search) {
      query = query.find({
        $or: [
          { title: new RegExp(search, 'i') },
          { description: new RegExp(search, 'i') },
          { tags: new RegExp(search, 'i') },
          { 'instructor.name': new RegExp(search, 'i') }
        ]
      });
    }

    // Sorting
    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === 'desc' ? -1 : 1;
    query = query.sort(sortOptions);

    // Pagination
    const skip = (page - 1) * limit;
    query = query.skip(skip).limit(Number(limit));

    const courses = await query;

    // Calculate actual enrollment counts for each course
    const coursesWithEnrollmentCount = await Promise.all(
      courses.map(async (course) => {
        try {
          // Count actual enrollments for this course
          const actualEnrollmentCount = await Enrollment.countDocuments({
            courseId: course._id,
            status: 'active'
          });
          
          // Return course with actual enrollment count
          return {
            ...course.toObject(),
            enrollmentCount: actualEnrollmentCount
          };
        } catch (error) {
          // Return course with existing enrollment count if calculation fails
          return {
            ...course.toObject(),
            enrollmentCount: course.enrollmentCount || 0
          };
        }
      })
    );

    // Get total count for pagination
    const totalCourses = await RealTimeCourse.countDocuments(filters);

    res.json({
      success: true,
      courses: coursesWithEnrollmentCount,
      pagination: {
        currentPage: Number(page),
        totalPages: Math.ceil(totalCourses / limit),
        totalCourses,
        hasNext: page * limit < totalCourses,
        hasPrev: page > 1
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch courses',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get single course with real-time data
export const getRealTimeCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    const studentId = req.studentId;
    

    const course = await RealTimeCourse.findById(courseId);

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // Get student progress if authenticated
    let studentProgress = null;
    if (studentId) {
      studentProgress = await RealTimeProgress.findOne({ studentId, courseId });
    }

    // Get currently watching students
    const currentlyWatching = await RealTimeProgress.getCurrentlyWatching(courseId);

    // Get course leaderboard (top 10)
    const leaderboard = await RealTimeProgress.getCourseLeaderboard(courseId, 10);

    // Increment view count (real-time)
    await course.updateRealTimeStats({
      currentViewers: currentlyWatching.length
    });

    // Emit real-time course view event (if io is available)
    const io = req.app.get('io');
    if (io) {
      io.emit('courseViewed', {
        courseId,
        viewers: currentlyWatching.length,
        timestamp: new Date()
      });
    }

    res.json({
      success: true,
      course: {
        ...course.toObject(),
        studentProgress,
        realTimeData: {
          currentlyWatching: currentlyWatching.length,
          viewers: currentlyWatching.map(w => ({
            name: w.studentId.name,
            avatar: w.studentId.avatar
          })),
          leaderboard: leaderboard.slice(0, 5)
        }
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get course content with real-time progress
export const getCourseContent = async (req, res) => {
  try {
    const { courseId } = req.params;
    const studentId = req.studentId;

    const course = await RealTimeCourse.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // If student is authenticated, check enrollment
    let isEnrolled = false;
    if (studentId) {
      
      // Check enrollment with multiple possible statuses
      const enrollment = await Enrollment.findOne({ 
        studentId, 
        courseId,
        $or: [
          { status: 'active' },
          { status: 'enrolled' },
          { status: { $exists: false } } // Handle old records without status field
        ]
      });
      
      isEnrolled = !!enrollment;
      if (enrollment) {
        
        // CRITICAL: Only mark as enrolled if payment is verified
        // For paid courses, isPaid must be true
        if (!course.isFree && course.price > 0 && !enrollment.isPaid) {
          isEnrolled = false;
        }
      }
      
      // Additional check: if no enrollment found, check if student has any enrollment for this course
      if (!enrollment) {
        const anyEnrollment = await Enrollment.findOne({ 
          studentId, 
          courseId
        });
        // Only set as enrolled if the enrollment has a valid status AND payment is verified
        if (anyEnrollment && (anyEnrollment.status === 'active' || anyEnrollment.status === 'enrolled')) {
          // CRITICAL: Check payment status for paid courses
          if (!course.isFree && course.price > 0 && !anyEnrollment.isPaid) {
            isEnrolled = false;
          } else {
            isEnrolled = true;
          }
        } else {
          isEnrolled = false;
        }
      }
      
      // Final enrollment decision logged above
    } else {
    }

    // Get or create student progress (only if enrolled and authenticated)
    let progress = null;
    if (studentId && isEnrolled) {
      progress = await RealTimeProgress.findOne({ studentId, courseId });
      if (!progress) {
        const totalModules = course.modules?.length || 0;
        const totalLectures = course.modules?.reduce((total, module) => total + (module.lectures?.length || 0), 0) || 0;
        
        progress = new RealTimeProgress({
          studentId,
          courseId,
          totalModules,
          totalLectures,
          overallProgress: {
            totalModules,
            totalLectures,
            completedModules: 0,
            completedLectures: 0,
            progressPercentage: 0
          }
        });
        await progress.save();
      }
    }

    // Update real-time activity (only if progress exists)
    if (progress) {
      await progress.updateRealTimeActivity({
        isCurrentlyWatching: true,
        currentLectureId: req.query.lectureId || null,
        currentModuleId: req.query.moduleId || null,
        watchingSince: new Date(),
        deviceInfo: {
          userAgent: req.headers['user-agent'],
          platform: req.headers['sec-ch-ua-platform'] || 'unknown',
          browser: req.headers['sec-ch-ua'] || 'unknown'
        }
      });
    }

    // Filter course content based on enrollment status
    // For non-enrolled students: hide video URLs except for preview lectures
    // RULE: First lecture of first module is ALWAYS free (introduction video)
    const filteredCourse = course.toObject();
    
    console.log(`📹 Filtering course content. isEnrolled: ${isEnrolled}, studentId: ${studentId}`);
    
    if (!isEnrolled) {
      // Remove video URLs from non-preview lectures
      filteredCourse.modules = filteredCourse.modules.map((module, moduleIndex) => ({
        ...module,
        lectures: module.lectures.map((lecture, lectureIndex) => {
          // First lecture of first module is ALWAYS free for everyone (introduction)
          const isIntroductionVideo = moduleIndex === 0 && lectureIndex === 0;
          
          // If lecture is marked as preview OR it's the introduction video, keep video URL
          if (lecture.isPreview || isIntroductionVideo) {
            // CRITICAL FIX: Flatten video URLs for frontend compatibility
            const videoUrl = lecture.videoContent?.r2Url || lecture.videoUrl || lecture.videoLink;
            return {
              ...lecture,
              isPreview: true, // Ensure it's marked as preview
              // Provide video URLs in multiple formats for frontend compatibility
              videoContent: lecture.videoContent ? {
                ...lecture.videoContent,
                r2Url: lecture.videoContent.r2Url
              } : null,
              // Flattened URLs for video players
              r2VideoUrl: lecture.videoContent?.r2Url || null,
              videoUrl: videoUrl,
              videoLink: videoUrl
            };
          }
          
          // For non-preview lectures, remove video content
          return {
            ...lecture,
            videoContent: lecture.videoContent ? {
              ...lecture.videoContent,
              r2Url: null, // Hide direct URL
              r2Key: lecture.videoContent.r2Key, // Keep key for signed URL generation
              // Keep metadata but hide actual video URL
              restricted: true,
              message: 'Enroll to access this video'
            } : null,
            // Also remove any direct video URLs
            videoUrl: null,
            r2VideoUrl: null,
            videoLink: null,
            // Mark as restricted for frontend
            isRestricted: true
          };
        })
      }));
    } else {
      // CRITICAL FIX: For enrolled students, ensure all video URLs are flattened and accessible
      console.log(`✅ Student is enrolled. Providing full video access.`);
      filteredCourse.modules = filteredCourse.modules.map((module, moduleIndex) => ({
        ...module,
        lectures: module.lectures.map((lecture, lectureIndex) => {
          // Flatten video URLs for frontend compatibility
          const videoUrl = lecture.videoContent?.r2Url || lecture.videoUrl || lecture.videoLink;
          
          console.log(`📹 Lecture "${lecture.title}" video URLs:`, {
            'videoContent.r2Url': lecture.videoContent?.r2Url,
            'videoUrl': lecture.videoUrl,
            'videoLink': lecture.videoLink,
            'final': videoUrl
          });
          
          return {
            ...lecture,
            // Keep original nested structure
            videoContent: lecture.videoContent ? {
              ...lecture.videoContent,
              r2Url: lecture.videoContent.r2Url
            } : null,
            // CRITICAL: Provide flattened URLs for video players
            r2VideoUrl: lecture.videoContent?.r2Url || null,
            videoUrl: videoUrl,
            videoLink: videoUrl,
            isRestricted: false
          };
        })
      }));
    }

    const response = {
      success: true,
      isEnrolled,
      course: {
        ...filteredCourse,
        progress: progress ? progress.toObject() : null
      }
    };
    
    res.json(response);

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch course content',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Update lecture progress in real-time
export const updateLectureProgress = async (req, res) => {
  try {
    const { courseId, lectureId } = req.params;
    const { 
      progress, 
      timeSpent, 
      lastPosition, 
      isCompleted,
      videoProgress,
      moduleId,
      title,
      type
    } = req.body;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    // CRITICAL: Verify enrollment and payment before allowing progress update
    const course = await RealTimeCourse.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    const enrollment = await Enrollment.findOne({
      studentId,
      courseId,
      status: { $in: ['active', 'enrolled'] }
    });

    if (!enrollment) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You are not enrolled in this course'
      });
    }

    // For paid courses, verify payment
    if (!course.isFree && course.price > 0 && !enrollment.isPaid) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: Payment required to access this course'
      });
    }

    // Check if the lecture is a preview/free lecture
    let lecture = null;
    let isFirstLecture = false;
    for (const [moduleIndex, module] of course.modules.entries()) {
      const lectureIndex = module.lectures.findIndex(l => l.id === lectureId);
      if (lectureIndex !== -1) {
        lecture = module.lectures[lectureIndex];
        isFirstLecture = moduleIndex === 0 && lectureIndex === 0;
        break;
      }
    }

    // If not enrolled or not paid, only allow progress on preview/first lecture
    if (!enrollment.isPaid && !lecture?.isPreview && !isFirstLecture) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: This lecture requires course enrollment'
      });
    }

    const progressDoc = await RealTimeProgress.findOne({ studentId, courseId });
    if (!progressDoc) {
      return res.status(404).json({
        success: false,
        message: 'Progress not found'
      });
    }

    // Update lecture progress
    await progressDoc.updateLectureProgress(lectureId, {
      moduleId,
      title,
      type,
      progress: progress || 0,
      timeSpent: timeSpent || 0,
      lastPosition: lastPosition || 0,
      isCompleted: isCompleted || false,
      videoProgress
    });

    // Recalculate overall progress
    await progressDoc.calculateOverallProgress();

    // Emit real-time progress update
    io.to(`course-${courseId}`).emit('progressUpdated', {
      studentId,
      lectureId,
      progress,
      isCompleted,
      timestamp: new Date()
    });

    res.json({
      success: true,
      message: 'Progress updated successfully',
      progress: progressDoc.overallProgress
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update progress',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Submit quiz in real-time
export const submitQuiz = async (req, res) => {
  try {
    const { courseId, lectureId } = req.params;
    const { answers, timeSpent, startedAt } = req.body;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    // Get course and lecture data
    const course = await RealTimeCourse.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // CRITICAL: Verify enrollment and payment before allowing quiz submission
    const enrollment = await Enrollment.findOne({
      studentId,
      courseId,
      status: { $in: ['active', 'enrolled'] }
    });

    if (!enrollment) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: You are not enrolled in this course'
      });
    }

    // For paid courses, verify payment
    if (!course.isFree && course.price > 0 && !enrollment.isPaid) {
      return res.status(403).json({
        success: false,
        message: 'Access denied: Payment required to access this course'
      });
    }

    // Find the lecture
    let lecture = null;
    for (const module of course.modules) {
      lecture = module.lectures.find(l => l.id === lectureId);
      if (lecture) break;
    }

    if (!lecture || lecture.type !== 'quiz') {
      return res.status(404).json({
        success: false,
        message: 'Quiz not found'
      });
    }

    // Calculate score
    let correctAnswers = 0;
    let totalQuestions = lecture.quizContent.questions.length;
    const quizAnswers = answers.map((answer, index) => {
      const question = lecture.quizContent.questions[index];
      const isCorrect = answer === question.correctAnswer;
      if (isCorrect) correctAnswers++;
      
      return {
        questionId: question.id,
        selectedAnswer: answer,
        isCorrect,
        pointsEarned: isCorrect ? question.points : 0
      };
    });

    const score = Math.round((correctAnswers / totalQuestions) * 100);
    const passed = score >= lecture.quizContent.passingScore;

    // Update progress
    const progressDoc = await RealTimeProgress.findOne({ studentId, courseId });
    if (progressDoc) {
      await progressDoc.updateQuizAttempt(lectureId, {
        score,
        totalQuestions,
        correctAnswers,
        timeSpent,
        answers: quizAnswers,
        startedAt: startedAt || new Date(),
        completedAt: new Date(),
        passed
      });

      await progressDoc.calculateOverallProgress();
    }

    // Emit real-time quiz completion
    io.to(`course-${courseId}`).emit('quizCompleted', {
      studentId,
      lectureId,
      score,
      passed,
      timestamp: new Date()
    });

    res.json({
      success: true,
      message: 'Quiz submitted successfully',
      result: {
        score,
        correctAnswers,
        totalQuestions,
        passed,
        answers: quizAnswers
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to submit quiz',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get real-time course analytics
export const getCourseAnalytics = async (req, res) => {
  try {
    const { courseId } = req.params;
    const adminId = req.adminId;

    if (!adminId) {
      return res.status(401).json({
        success: false,
        message: 'Admin authentication required'
      });
    }

    const course = await RealTimeCourse.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // Get real-time analytics
    const currentlyWatching = await RealTimeProgress.getCurrentlyWatching(courseId);
    const leaderboard = await RealTimeProgress.getCourseLeaderboard(courseId, 20);
    
    // Get progress distribution
    const progressStats = await RealTimeProgress.aggregate([
      { $match: { courseId: mongoose.Types.ObjectId(courseId) } },
      {
        $group: {
          _id: {
            $switch: {
              branches: [
                { case: { $lt: ['$overallProgress.percentage', 25] }, then: '0-25%' },
                { case: { $lt: ['$overallProgress.percentage', 50] }, then: '25-50%' },
                { case: { $lt: ['$overallProgress.percentage', 75] }, then: '50-75%' },
                { case: { $lt: ['$overallProgress.percentage', 100] }, then: '75-99%' }
              ],
              default: '100%'
            }
          },
          count: { $sum: 1 }
        }
      }
    ]);

    // Get completion rate
    const completionStats = await RealTimeProgress.aggregate([
      { $match: { courseId: mongoose.Types.ObjectId(courseId) } },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          completed: { $sum: { $cond: ['$isCompleted', 1, 0] } }
        }
      }
    ]);

    res.json({
      success: true,
      analytics: {
        realTime: {
          currentlyWatching: currentlyWatching.length,
          viewers: currentlyWatching.map(w => ({
            name: w.studentId.name,
            avatar: w.studentId.avatar,
            currentLecture: w.realTimeActivity.currentLectureId
          }))
        },
        progress: {
          distribution: progressStats,
          completion: completionStats[0] || { total: 0, completed: 0 }
        },
        leaderboard: leaderboard.slice(0, 10),
        courseStats: {
          enrollmentCount: course.enrollmentCount,
          averageRating: course.averageRating,
          totalRatings: course.totalRatings
        }
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch analytics',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Heartbeat for real-time activity
export const updateHeartbeat = async (req, res) => {
  try {
    const { courseId } = req.params;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const progressDoc = await RealTimeProgress.findOne({ studentId, courseId });
    if (progressDoc) {
      await progressDoc.updateRealTimeActivity({
        isCurrentlyWatching: true,
        lastHeartbeat: new Date()
      });
    }

    res.json({
      success: true,
      message: 'Heartbeat updated'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update heartbeat',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get student's course progress
export const getStudentProgress = async (req, res) => {
  try {
    const { courseId } = req.params;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const progress = await RealTimeProgress.findOne({ studentId, courseId });
    if (!progress) {
      return res.status(404).json({
        success: false,
        message: 'Progress not found'
      });
    }

    res.json({
      success: true,
      progress
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch progress',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// ADMIN: Create a new course
export const createRealTimeCourse = async (req, res) => {
  try {
    
    // Debug and fix modules and materials specifically
    if (req.body.modules && Array.isArray(req.body.modules)) {
      req.body.modules.forEach((module, moduleIndex) => {
        if (module.lectures && Array.isArray(module.lectures)) {
          module.lectures.forEach((lecture, lectureIndex) => {
            if (lecture.materials) {
              
              // Fix stringified materials
              if (typeof lecture.materials === 'string') {
                try {
                  lecture.materials = JSON.parse(lecture.materials);
                } catch (parseError) {
                  lecture.materials = [];
                }
              }
              
              // Ensure materials is an array
              if (!Array.isArray(lecture.materials)) {
                lecture.materials = [];
              }
            }
          });
        }
      });
    }
    
    // Check for large base64 data in thumbnail, banner, or previewVideo
    if (req.body.thumbnail && req.body.thumbnail.length > 1000) {
    }
    if (req.body.banner && req.body.banner.length > 1000) {
    }
    if (req.body.previewVideo && req.body.previewVideo.length > 1000) {
    }
    
    const {
      title,
      description,
      shortDescription,
      price,
      originalPrice,
      level,
      category,
      tags,
      isFree,
      status,
      thumbnail,
      banner,
      previewVideo,
      instructor,
      modules
    } = req.body;

    // Limit thumbnail, banner, and previewVideo to reasonable sizes to prevent issues
    const sanitizedThumbnail = thumbnail && thumbnail.length > 500 ? '' : (thumbnail || '');
    const sanitizedBanner = banner && banner.length > 500 ? '' : (banner || '');
    const sanitizedPreviewVideo = previewVideo && previewVideo.length > 500 ? '' : (previewVideo || '');

    // Validation
    if (!req.adminId) {
      return res.status(401).json({
        success: false,
        message: 'Admin authentication required'
      });
    }
    
    if (!title || !description) {
      return res.status(400).json({
        success: false,
        message: 'Title and description are required'
      });
    }

    // Calculate total duration from all lectures
    let totalDuration = 0;
    if (modules && modules.length > 0) {
      modules.forEach(module => {
        if (module.lectures && module.lectures.length > 0) {
          module.lectures.forEach(lecture => {
            totalDuration += lecture.duration || 0;
          });
        }
      });
    }

    // Format duration - ensure minimum values for required fields
    const hours = Math.max(0, Math.floor(totalDuration / 3600));
    const minutes = Math.max(0, Math.floor((totalDuration % 3600) / 60));
    const formattedDuration = hours > 0 
      ? `${hours} hour${hours > 1 ? 's' : ''} ${minutes > 0 ? `${minutes} min` : ''}`
      : `${minutes} min`;

    // Create slug for the course - ensure it's never empty
    let slug = title
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-')
      .replace(/-+/g, '-')
      .trim('-');
    
    // If slug is empty (e.g., title was all special characters), create a fallback
    if (!slug) {
      slug = `course-${Date.now()}`;
    }

    const newCourse = new RealTimeCourse({
      title,
      description,
      shortDescription: shortDescription || description.substring(0, 150),
      price: isFree ? 0 : (price || 0),
      originalPrice: originalPrice || (price || 0),
      currency: 'INR',
      isFree: isFree || false,
      level: level || 'Beginner',
      category: category || 'Web Development',
      tags: Array.isArray(tags) ? tags : [],
      status: status || 'draft',
      slug: slug,
      thumbnail: sanitizedThumbnail,
      banner: sanitizedBanner,
      previewVideo: sanitizedPreviewVideo,
      instructor: {
        name: instructor?.name || 'Admin',
        bio: instructor?.bio || '',
        avatar: instructor?.avatar || ''
      },
      modules: Array.isArray(modules) ? modules : [],
      estimatedDuration: {
        hours: hours,
        minutes: minutes
      },
      enrollmentCount: 0,
      averageRating: 0,
      totalRatings: 0,
      publishedAt: status === 'published' ? new Date() : null,
      realTimeStats: {
        currentViewers: 0,
        totalWatchTime: 0,
        engagementScore: 0,
        lastUpdated: new Date()
      },
      createdBy: req.adminId
    });

    // Ensure materials arrays are properly structured before saving
    if (newCourse.modules && Array.isArray(newCourse.modules)) {
      newCourse.modules.forEach((module, moduleIndex) => {
        if (module.lectures && Array.isArray(module.lectures)) {
          module.lectures.forEach((lecture, lectureIndex) => {
            if (lecture.materials) {
              
              // Ensure materials is properly structured
              if (typeof lecture.materials === 'string') {
                try {
                  lecture.materials = JSON.parse(lecture.materials);
                } catch (parseError) {
                  lecture.materials = [];
                }
              }
              
              // Ensure each material has required fields
              if (Array.isArray(lecture.materials)) {
                lecture.materials = lecture.materials.map(material => ({
                  id: material.id || `material-${Date.now()}`,
                  name: material.name || '',
                  type: material.type || 'pdf',
                  r2Key: material.r2Key || '',
                  r2Url: material.r2Url || '',
                  fileSize: material.fileSize || 0,
                  downloadCount: material.downloadCount || 0
                }));
              }
            }
          });
        }
      });
    }

    const savedCourse = await newCourse.save();

    res.status(201).json({
      success: true,
      message: 'Course created successfully',
      course: {
        _id: savedCourse._id,
        title: savedCourse.title,
        status: savedCourse.status,
        modules: savedCourse.modules?.length || 0,
        instructor: savedCourse.instructor?.name
      }
    });

  } catch (error) {
    
    // Handle validation errors
    if (error.name === 'ValidationError') {
      const validationErrors = Object.values(error.errors).map(err => ({
        field: err.path,
        message: err.message,
        value: err.value
      }));
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: validationErrors.map(err => `${err.field}: ${err.message}`),
        details: validationErrors
      });
    }
    
    // Handle duplicate key errors
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Course with this title already exists'
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Failed to create course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// ADMIN: Update a course
export const updateRealTimeCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    const updateData = req.body;
    
    // Debug and fix modules and materials specifically
    if (updateData.modules && Array.isArray(updateData.modules)) {
      updateData.modules.forEach((module, moduleIndex) => {
        if (module.lectures && Array.isArray(module.lectures)) {
          module.lectures.forEach((lecture, lectureIndex) => {
            if (lecture.materials) {
              
              // Fix stringified materials
              if (typeof lecture.materials === 'string') {
                try {
                  lecture.materials = JSON.parse(lecture.materials);
                } catch (parseError) {
                  lecture.materials = [];
                }
              }
              
              // Ensure materials is an array
              if (!Array.isArray(lecture.materials)) {
                lecture.materials = [];
              }
            }
          });
        }
      });
    }

    // Sanitize image URLs to prevent large base64 data
    if (updateData.thumbnail && updateData.thumbnail.length > 500) {
      updateData.thumbnail = '';
    }
    if (updateData.banner && updateData.banner.length > 500) {
      updateData.banner = '';
    }
    if (updateData.previewVideo && updateData.previewVideo.length > 500) {
      updateData.previewVideo = '';
    }

    // Calculate total duration if modules are updated
    if (updateData.modules && updateData.modules.length > 0) {
      let totalDuration = 0;
      updateData.modules.forEach(module => {
        if (module.lectures && module.lectures.length > 0) {
          module.lectures.forEach(lecture => {
            totalDuration += lecture.duration || 0;
          });
        }
      });

      const hours = Math.max(0, Math.floor(totalDuration / 3600));
      const minutes = Math.max(0, Math.floor((totalDuration % 3600) / 60));
      updateData.formattedDuration = hours > 0 
        ? `${hours} hour${hours > 1 ? 's' : ''} ${minutes > 0 ? `${minutes} min` : ''}`
        : `${minutes} min`;
      updateData.estimatedDuration = {
        hours: hours,
        minutes: minutes
      };
    }

    // Update slug if title changes
    if (updateData.title) {
      let slug = updateData.title
        .toLowerCase()
        .replace(/[^a-z0-9\s-]/g, '')
        .replace(/\s+/g, '-')
        .replace(/-+/g, '-')
        .trim('-');
      
      // If slug is empty, create a fallback
      if (!slug) {
        slug = `course-${Date.now()}`;
      }
      updateData.slug = slug;
    }

    // Ensure materials arrays are properly structured before updating
    if (updateData.modules && Array.isArray(updateData.modules)) {
      updateData.modules.forEach((module, moduleIndex) => {
        if (module.lectures && Array.isArray(module.lectures)) {
          module.lectures.forEach((lecture, lectureIndex) => {
            if (lecture.materials) {
              
              // Ensure materials is properly structured
              if (typeof lecture.materials === 'string') {
                try {
                  lecture.materials = JSON.parse(lecture.materials);
                } catch (parseError) {
                  lecture.materials = [];
                }
              }
              
              // Ensure each material has required fields
              if (Array.isArray(lecture.materials)) {
                lecture.materials = lecture.materials.map(material => ({
                  id: material.id || `material-${Date.now()}`,
                  name: material.name || '',
                  type: material.type || 'pdf',
                  r2Key: material.r2Key || '',
                  r2Url: material.r2Url || '',
                  fileSize: material.fileSize || 0,
                  downloadCount: material.downloadCount || 0
                }));
              }
            }
          });
        }
      });
    }

    // Update published date if status changes to published
    if (updateData.status === 'published' && !updateData.publishedAt) {
      updateData.publishedAt = new Date();
    }

    const course = await RealTimeCourse.findByIdAndUpdate(
      courseId,
      { $set: updateData },
      { new: true, runValidators: true }
    );

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    res.json({
      success: true,
      message: 'Course updated successfully',
      course
    });

  } catch (error) {
    
    // Handle validation errors
    if (error.name === 'ValidationError') {
      const validationErrors = Object.values(error.errors).map(err => ({
        field: err.path,
        message: err.message,
        value: err.value
      }));
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        errors: validationErrors.map(err => `${err.field}: ${err.message}`),
        details: validationErrors
      });
    }
    
    // Handle duplicate key errors
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Course with this title already exists'
      });
    }
    
    res.status(500).json({
      success: false,
      message: 'Failed to update course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// ADMIN: Delete a course
export const deleteRealTimeCourse = async (req, res) => {
  try {
    const { courseId } = req.params;

    const course = await RealTimeCourse.findByIdAndDelete(courseId);

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // Also delete related progress records
    await RealTimeProgress.deleteMany({ course: courseId });

    res.json({
      success: true,
      message: 'Course deleted successfully'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// ADMIN: Publish a course
export const publishRealTimeCourse = async (req, res) => {
  try {
    const { courseId } = req.params;

    const course = await RealTimeCourse.findByIdAndUpdate(
      courseId,
      { 
        $set: { 
          status: 'published',
          publishedAt: new Date()
        } 
      },
      { new: true }
    );

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    res.json({
      success: true,
      message: 'Course published successfully',
      course
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to publish course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// ADMIN: Get all courses (including drafts)
export const getAllCoursesForAdmin = async (req, res) => {
  try {
    const courses = await RealTimeCourse.find()
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      courses
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch courses',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get enrollment status for a course
export const getEnrollmentStatus = async (req, res) => {
  try {
    const { courseId } = req.params;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const enrollment = await Enrollment.findOne({ 
      studentId, 
      courseId,
      status: 'active'
    });

    res.json({
      success: true,
      enrolled: !!enrollment,
      enrollment: enrollment || null
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to check enrollment status',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Enroll in a course
export const enrollInCourse = async (req, res) => {
  try {
    const { courseId } = req.params;
    const studentId = req.studentId;


    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    // Get student details for logging
    const student = await Student.findById(studentId);
    if (student) {
    }

    const course = await RealTimeCourse.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }


    // Check if already enrolled
    const existingEnrollment = await Enrollment.findOne({ 
      studentId, 
      courseId 
    });

    if (existingEnrollment) {
      // If already enrolled, just return success
      return res.status(200).json({
        success: true,
        message: 'Already enrolled in this course',
        enrollment: existingEnrollment,
        alreadyEnrolled: true
      });
    }

    // Create enrollment
    const enrollment = new Enrollment({
      studentId,
      courseId,
      enrolledAt: new Date(),
      status: 'active',
      progress: 0,
      isPaid: course.isFree || course.price === 0 ? true : false, // CRITICAL: Only free courses are auto-paid
    });

    await enrollment.save();

    // Increment course enrollment count
    await course.incrementEnrollment();

    // Create initial progress tracking
    const totalModules = course.modules?.length || 0;
    const totalLectures = course.modules?.reduce((total, module) => total + (module.lectures?.length || 0), 0) || 0;
    
    const progressDoc = new RealTimeProgress({
      studentId,
      courseId,
      totalModules,
      totalLectures,
      overallProgress: {
        totalModules,
        totalLectures,
        completedModules: 0,
        completedLectures: 0,
        progressPercentage: 0
      }
    });
    await progressDoc.save();

    res.status(201).json({
      success: true,
      message: 'Successfully enrolled in course',
      enrollment
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to enroll in course',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};