import RealTimeCourse from '../models/RealTimeCourse.js';
import RealTimeProgress from '../models/RealTimeProgress.js';
import Student from '../models/Student.js';
import Enrollment from '../models/Enrollment.js';
import { uploadToR2, generateR2Key, generatePresignedUploadUrl, generatePresignedDownloadUrl } from '../config/r2.js';
import mongoose from 'mongoose';

// Helper function to check course access (both Enrollment and UserCourse)
const checkCourseAccess = async (studentId, courseId, course) => {
  // Check Enrollment record first
  let enrollment = await Enrollment.findOne({
    studentId,
    courseId,
    status: { $in: ['active', 'enrolled'] }
  });

  // If no enrollment found, check UserCourse (for Razorpay payments)
  if (!enrollment) {
    const UserCourse = (await import('../models/UserCourse.js')).default;
    const userCourse = await UserCourse.findOne({
      studentId,
      courseId,
      isActive: true
    });
    
    if (userCourse) {
      // Create a virtual enrollment object for consistency
      enrollment = {
        studentId: userCourse.studentId,
        courseId: userCourse.courseId,
        isPaid: true, // UserCourse records are created only after successful payment
        status: 'active'
      };
    }
  }

  return enrollment;
};

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
      // Checking enrollment for studentId
      
      // Use the helper function to check both Enrollment and UserCourse
      const enrollment = await checkCourseAccess(studentId, courseId, course);
      isEnrolled = !!enrollment;
      
      // CRITICAL FIX: Auto-enroll students for free courses
      if (!isEnrolled && course.isFree && course.price === 0) {
        // Auto-enrolling student in free course
        try {
          const autoEnrollment = new Enrollment({
            studentId,
            courseId,
            isPaid: true, // Free courses are considered "paid"
            enrolledAt: new Date(),
            status: 'active'
          });
          await autoEnrollment.save();
          isEnrolled = true;
          // Auto-enrollment successful
        } catch (enrollmentError) {
          // Auto-enrollment failed
        }
      }
      
      // Final enrollment decision logged above
      // Final enrollment decision
    } else {
      // No studentId provided - treating as not enrolled
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
    
    // Filtering course content
    
    // CRITICAL FIX: Ensure all modules are properly structured
    if (!filteredCourse.modules || filteredCourse.modules.length === 0) {

      filteredCourse.modules = [{
        id: 'module-1',
        title: 'Course Content',
        description: 'Main course content',
        order: 1,
        lectures: []
      }];
    }
    
    // CRITICAL FIX: Always ensure first lecture is accessible for video playback
    if (filteredCourse.modules?.[0]?.lectures?.[0]) {
      const firstLecture = filteredCourse.modules[0].lectures[0];
      const originalFirstLecture = course.modules[0].lectures[0];
      // Ensuring first lecture is always accessible
      
      // Force first lecture to have video access regardless of enrollment
      if (originalFirstLecture.videoContent) {
        firstLecture.videoContent = {
          ...originalFirstLecture.videoContent,
          r2Url: originalFirstLecture.videoContent.r2Url,
          restricted: false
        };
      }
      
      // CRITICAL FIX: Ensure first lecture has proper ID
      if (!firstLecture.id || firstLecture.id === 'lecture-1' || firstLecture.id === 'undefined') {
        firstLecture.id = `module-1-lecture-0`; // Use 0-based indexing to match frontend
        // Generated fallback ID for first lecture
      }
      firstLecture.isPreview = true;
      firstLecture.isRestricted = false;
      firstLecture.videoUrl = originalFirstLecture.videoContent?.r2Url || originalFirstLecture.videoUrl;
      firstLecture.r2VideoUrl = originalFirstLecture.videoContent?.r2Url;
      firstLecture.videoLink = originalFirstLecture.videoContent?.r2Url || originalFirstLecture.videoLink;
      
      // Ensure lecture has proper ID
      if (!firstLecture.id) {
        firstLecture.id = 'lecture-1';
      }
    }
    
    if (!isEnrolled) {
      // Student not enrolled - filtering content for preview access only
      // Remove video URLs from non-preview lectures
      filteredCourse.modules = filteredCourse.modules.map((module, moduleIndex) => ({
        ...module,
        lectures: module.lectures.map((lecture, lectureIndex) => {
          // First lecture of first module is ALWAYS free for everyone (introduction)
          const isIntroductionVideo = moduleIndex === 0 && lectureIndex === 0;
          
          // Processing lecture
          
          // If lecture is marked as preview OR it's the introduction video, keep video URL
          if (lecture.isPreview || isIntroductionVideo) {
            // Keeping video URL for preview/introduction
            // CRITICAL FIX: Flatten video URLs for frontend compatibility
            const videoUrl = lecture.videoContent?.r2Url || lecture.videoUrl || lecture.videoLink;
            return {
              ...lecture,
              isPreview: true, // Ensure it's marked as preview
              isPremium: false, // Preview lectures are not premium
              // Provide video URLs in multiple formats for frontend compatibility
              videoContent: lecture.videoContent ? {
                ...lecture.videoContent,
                r2Url: lecture.videoContent.r2Url
              } : null,
              // Flattened URLs for video players
              r2VideoUrl: lecture.videoContent?.r2Url || null,
              videoUrl: videoUrl,
              videoLink: videoUrl,
              // Ensure proper ID - use consistent pattern for frontend compatibility
              id: lecture.id || `module-${moduleIndex + 1}-lecture-${lectureIndex}`
            };
          }
          
          // For non-preview lectures, remove video content and mark as premium
          // Restricting video access - enrollment required
          return {
            ...lecture,
            isPremium: true, // Mark as premium content
            videoContent: lecture.videoContent ? {
              ...lecture.videoContent,
              r2Url: null, // Hide direct URL
              r2Key: lecture.videoContent.r2Key, // Keep key for signed URL generation
              // Keep metadata but hide actual video URL
              restricted: true,
              message: course.isFree ? 'Enroll to access this video' : 'Premium access required'
            } : null,
            // Also remove any direct video URLs
            videoUrl: null,
            r2VideoUrl: null,
            videoLink: null,
            // Mark as restricted for frontend
            isRestricted: true,
            // Ensure proper ID - use consistent pattern for frontend compatibility
            id: lecture.id || `module-${moduleIndex + 1}-lecture-${lectureIndex}`
          };
        })
      }));
    } else {
      // CRITICAL FIX: For enrolled students, ensure all video URLs are flattened and accessible
      // Student is enrolled. Providing full video access.
      filteredCourse.modules = filteredCourse.modules.map((module, moduleIndex) => ({
        ...module,
        lectures: module.lectures.map((lecture, lectureIndex) => {
          // Get original lecture data to ensure we have all video URLs
          const originalModule = course.modules[moduleIndex];
          const originalLecture = originalModule?.lectures[lectureIndex];
          
          // Flatten video URLs for frontend compatibility
          const videoUrl = originalLecture?.videoContent?.r2Url || originalLecture?.videoUrl || originalLecture?.videoLink || 
                          lecture.videoContent?.r2Url || lecture.videoUrl || lecture.videoLink;

          return {
            ...lecture,
            // Keep original nested structure with original data
            videoContent: originalLecture?.videoContent ? {
              ...originalLecture.videoContent,
              r2Url: originalLecture.videoContent.r2Url
            } : (lecture.videoContent ? {
              ...lecture.videoContent,
              r2Url: lecture.videoContent.r2Url
            } : null),
            // CRITICAL: Provide flattened URLs for video players
            r2VideoUrl: originalLecture?.videoContent?.r2Url || lecture.videoContent?.r2Url || null,
            videoUrl: videoUrl,
            videoLink: videoUrl,
            isRestricted: false,
            // Mark premium status based on lecture settings
            isPremium: lectureIndex === 0 ? false : (originalLecture?.isPremium || false),
            isPreview: lectureIndex === 0 ? true : (originalLecture?.isPreview || false),
            // Ensure proper ID - use consistent pattern for frontend compatibility
            id: originalLecture?.id || lecture.id || `module-${moduleIndex + 1}-lecture-${lectureIndex}`
          };
        })
      }));
    }

    // DEBUG: Log the final course structure

    // CRITICAL FIX: Ensure course data consistency between admin and student views

    // Log the original course data for comparison

    // CRITICAL FIX: Ensure data consistency - use original course data if filtered data is missing
    const finalCourseData = {
      ...filteredCourse,
      // Ensure we have the original course data as fallback
      originalCourseId: course._id,
      originalTitle: course.title,
      progress: progress ? progress.toObject() : null
    };
    
    // Validate that we have proper course structure
    if (!finalCourseData.modules || finalCourseData.modules.length === 0) {

      finalCourseData.modules = course.modules || [];
    }
    
    // CRITICAL FIX: Ensure ALL lectures are visible and have proper video content
    if (finalCourseData.modules?.[0]?.lectures) {
      const originalModule = course.modules?.[0];

      // Restore all lectures from original course data
      if (originalModule?.lectures) {

        finalCourseData.modules[0].lectures = originalModule.lectures.map((originalLecture, index) => {
          const existingLecture = finalCourseData.modules[0].lectures[index];
          
          if (existingLecture) {
            // Merge existing filtered data with original data
            return {
              ...existingLecture,
              // Restore original video content
              videoContent: originalLecture.videoContent || existingLecture.videoContent,
              videoUrl: originalLecture.videoContent?.r2Url || existingLecture.videoUrl,
              r2VideoUrl: originalLecture.videoContent?.r2Url || existingLecture.r2VideoUrl,
              videoLink: originalLecture.videoContent?.r2Url || existingLecture.videoLink,
              // Ensure proper IDs and titles - use consistent pattern
              id: originalLecture.id || existingLecture.id || `module-1-lecture-${index}`,
              title: originalLecture.title || existingLecture.title,
              // Mark first lecture as preview
              isPreview: index === 0 ? true : (originalLecture.isPreview || false)
            };
          } else {
            // Add missing lecture from original data

            return {
              ...originalLecture,
              isPreview: index === 0 ? true : (originalLecture.isPreview || false),
              videoUrl: originalLecture.videoContent?.r2Url,
              r2VideoUrl: originalLecture.videoContent?.r2Url,
              videoLink: originalLecture.videoContent?.r2Url,
              // Ensure proper ID - use consistent pattern
              id: originalLecture.id || `module-1-lecture-${index}`
            };
          }
        });

      }
    }

    // DEBUG: Log what we're sending to frontend

    const response = {
      success: true,
      isEnrolled,
      course: finalCourseData
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

// Update lecture duration
export const updateLectureDuration = async (req, res) => {
  try {
    const { courseId, lectureId } = req.params;
    const { duration } = req.body;

    if (!duration || duration <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Valid duration is required'
      });
    }

    // Find the course
    const course = await RealTimeCourse.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // Find and update the lecture duration
    let lectureUpdated = false;

    if (course.modules && course.modules.length > 0) {
      for (const module of course.modules) {
        if (module.lectures && module.lectures.length > 0) {
          for (const lecture of module.lectures) {

            if ((lecture._id && lecture._id.toString() === lectureId) || lecture.id === lectureId) {

              lecture.duration = duration;
              lectureUpdated = true;
              break;
            }
          }
        }
        if (lectureUpdated) break;
      }
    }

    if (!lectureUpdated) {
      return res.status(404).json({
        success: false,
        message: 'Lecture not found'
      });
    }

    // Recalculate course total duration after lecture duration update
    let totalDuration = 0;
    if (course.modules && course.modules.length > 0) {
      course.modules.forEach(module => {
        if (module.lectures && module.lectures.length > 0) {
          module.lectures.forEach(lecture => {
            totalDuration += lecture.duration || 0;
          });
        }
      });
    }

    // Update formattedDuration
    const hours = Math.max(0, Math.floor(totalDuration / 3600));
    const minutes = Math.max(0, Math.floor((totalDuration % 3600) / 60));
    course.formattedDuration = hours > 0 
      ? `${hours} hour${hours > 1 ? 's' : ''} ${minutes > 0 ? `${minutes} min` : ''}`
      : `${minutes} min`;
    course.estimatedDuration = {
      hours: hours,
      minutes: minutes
    };

    // Save the course
    await course.save();

    res.json({
      success: true,
      message: 'Lecture duration updated successfully',
      duration: duration,
      courseDuration: course.formattedDuration
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Failed to update lecture duration'
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
    // Check both RealTimeCourse and regular Course
    let course = await RealTimeCourse.findById(courseId);
    let courseType = 'real-time';
    
    if (!course) {
      // Try regular Course model
      try {
        const Course = mongoose.model('Course');
        course = await Course.findById(courseId);
        courseType = 'regular';
      } catch (modelError) {
        // Course model doesn't exist
      }
    }
    
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    let enrollment = await checkCourseAccess(studentId, courseId, course);

    // CRITICAL FIX: Auto-enroll students for free courses (similar to getCourseContent)
    if (!enrollment && course.isFree && course.price === 0) {
      try {
        const autoEnrollment = new Enrollment({
          studentId,
          courseId,
          isPaid: true, // Free courses are considered "paid"
          enrolledAt: new Date(),
          status: 'active'
        });
        await autoEnrollment.save();
        enrollment = {
          studentId,
          courseId,
          isPaid: true,
          status: 'active'
        };
      } catch (enrollmentError) {
        // Auto-enrollment failed - continue to check if lecture is preview/first
      }
    }

    // Don't immediately deny if no enrollment - check if it's a preview/first lecture first
    // We'll handle access denial later after checking the lecture
    if (!enrollment) {
      // Create a temporary enrollment object to check lecture access
      enrollment = {
        studentId,
        courseId,
        isPaid: false,
        status: 'pending'
      };
    }

    // For paid courses with existing enrollment, verify payment
    if (!course.isFree && course.price > 0 && enrollment.isPaid === false) {
      // Check Payment/UserCourse models as fallback before denying
      let hasPaid = false;
      
      try {
        const Payment = mongoose.model('Payment');
        const payment = await Payment.findOne({
          studentId,
          courseId,
          status: 'completed'
        });
        if (payment) {
          hasPaid = true;
          enrollment.isPaid = true;
          enrollment.status = 'active';
        }
      } catch (modelError) {
        // Payment model doesn't exist
      }
      
      if (!hasPaid) {
        try {
          const UserCourse = (await import('../models/UserCourse.js')).default;
          const userCourse = await UserCourse.findOne({
            studentId,
            courseId,
            isActive: true
          });
          if (userCourse) {
            hasPaid = true;
            enrollment.isPaid = true;
            enrollment.status = 'active';
          }
        } catch (modelError) {
          // UserCourse model doesn't exist
        }
      }
      
      if (!hasPaid) {
        try {
          const RazorpayPayment = (await import('../models/RazorpayPayment.js')).default;
          const razorpayPayment = await RazorpayPayment.findOne({
            studentId,
            courseId,
            status: 'completed'
          });
          if (razorpayPayment) {
            hasPaid = true;
            enrollment.isPaid = true;
            enrollment.status = 'active';
          }
        } catch (modelError) {
          // RazorpayPayment model doesn't exist
        }
      }
      
      // Only deny if truly no payment found AND it's not a free/preview lecture
      // We'll check this after finding the lecture below
    }

    // Check if the lecture is a preview/free lecture
    let lecture = null;
    let isFirstLecture = false;
    
    if (courseType === 'real-time') {
      for (const [moduleIndex, module] of course.modules.entries()) {
        const lectureIndex = module.lectures?.findIndex(l => l.id === lectureId || l._id?.toString() === lectureId);
        if (lectureIndex !== -1) {
          lecture = module.lectures[lectureIndex];
          isFirstLecture = moduleIndex === 0 && lectureIndex === 0;
          break;
        }
      }
    } else {
      // Regular course - check videos in modules
      for (const [moduleIndex, module] of course.modules.entries()) {
        const videoIndex = module.videos?.findIndex(v => (v._id || v.id)?.toString() === lectureId);
        if (videoIndex !== -1) {
          lecture = module.videos[videoIndex];
          isFirstLecture = moduleIndex === 0 && videoIndex === 0;
          break;
        }
      }
    }

    // If not enrolled or not paid, only allow progress on preview/first lecture
    // Also allow progress if user has access via UserCourse or Payment models
    if (!enrollment.isPaid && !lecture?.isPreview && !isFirstLecture) {
      // Double-check access via Payment/UserCourse systems before denying
      let hasAccess = false;
      
      // Check Payment model
      try {
        const Payment = mongoose.model('Payment');
        const hasPaidOld = await Payment.findOne({
          studentId,
          courseId,
          status: 'completed'
        });
        if (hasPaidOld) {
          hasAccess = true;
        }
      } catch (modelError) {
        // Payment model doesn't exist
      }
      
      // Check UserCourse model
      if (!hasAccess) {
        try {
          const UserCourse = (await import('../models/UserCourse.js')).default;
          const userCourse = await UserCourse.findOne({
            studentId,
            courseId,
            isActive: true
          });
          if (userCourse) {
            hasAccess = true;
            // Update enrollment object
            enrollment.isPaid = true;
            enrollment.status = 'active';
          }
        } catch (modelError) {
          // UserCourse model doesn't exist
        }
      }
      
      // Check RazorpayPayment as final fallback
      if (!hasAccess) {
        try {
          const RazorpayPayment = (await import('../models/RazorpayPayment.js')).default;
          const razorpayPayment = await RazorpayPayment.findOne({
            studentId,
            courseId,
            status: 'completed'
          });
          if (razorpayPayment) {
            hasAccess = true;
            enrollment.isPaid = true;
            enrollment.status = 'active';
          }
        } catch (modelError) {
          // RazorpayPayment model doesn't exist
        }
      }
      
      // If still no access, deny for non-preview/non-first lectures
      if (!hasAccess) {
        return res.status(403).json({
          success: false,
          message: 'Access denied: This lecture requires course enrollment. Please enroll to continue.'
        });
      }
    }

    // Update progress based on course type
    if (courseType === 'real-time') {
      // Real-time course progress update
      let progressDoc = await RealTimeProgress.findOne({ studentId, courseId });
      
      if (!progressDoc) {
        // Create progress if it doesn't exist
        const totalModules = course.modules?.length || 0;
        const totalLectures = course.modules?.reduce((total, module) => total + (module.lectures?.length || 0), 0) || 0;
        
        progressDoc = new RealTimeProgress({
          studentId,
          courseId,
          overallProgress: {
            totalModules,
            totalLectures,
            completedModules: 0,
            completedLectures: 0,
            percentage: 0
          }
        });
        await progressDoc.save();
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

      // Recalculate overall progress (production-ready: includes module progress)
      await progressDoc.calculateOverallProgress();

      // Get updated progress after calculation
      const updatedProgress = await RealTimeProgress.findById(progressDoc._id);

      // Emit real-time progress update with complete data
      const io = req.app.get('io');
      if (io) {
        // Emit to course room for real-time updates
        io.to(`course-${courseId}`).emit('course-progress-update', {
          studentId,
          courseId,
          lectureId,
          progress: progress || updatedProgress.lectureProgress.find(l => l.lectureId === lectureId)?.progress || 0,
          progressPercentage: updatedProgress.overallProgress.percentage,
          completedLectures: updatedProgress.overallProgress.completedLectures,
          totalLectures: updatedProgress.overallProgress.totalLectures,
          completedModules: updatedProgress.overallProgress.completedModules,
          totalModules: updatedProgress.overallProgress.totalModules,
          timeSpent: updatedProgress.overallProgress.timeSpent,
          isCompleted: updatedProgress.isCompleted,
          isLectureCompleted: isCompleted,
          timestamp: new Date()
        });
        
        // Emit to user's personal room for cross-device sync
        io.to(`user-${studentId}`).emit('course-progress-update', {
          studentId,
          courseId,
          lectureId,
          progress: progress || updatedProgress.lectureProgress.find(l => l.lectureId === lectureId)?.progress || 0,
          progressPercentage: updatedProgress.overallProgress.percentage,
          completedLectures: updatedProgress.overallProgress.completedLectures,
          totalLectures: updatedProgress.overallProgress.totalLectures,
          completedModules: updatedProgress.overallProgress.completedModules,
          totalModules: updatedProgress.overallProgress.totalModules,
          timeSpent: updatedProgress.overallProgress.timeSpent,
          isCompleted: updatedProgress.isCompleted,
          isLectureCompleted: isCompleted,
          timestamp: new Date()
        });
      }

      res.json({
        success: true,
        message: 'Progress updated successfully',
        progress: progressDoc.overallProgress
      });
    } else {
      // Regular course progress update
      try {
        const StudentProgress = mongoose.model('StudentProgress');
        
        // Find or create StudentProgress record
        let studentProgress = await StudentProgress.findOne({ studentId, courseId, lectureId });
        
        if (!studentProgress) {
          studentProgress = new StudentProgress({
            studentId,
            courseId,
            lectureId,
            progress: progress || 0,
            timeSpent: timeSpent || 0,
            lastPosition: lastPosition || 0,
            isCompleted: isCompleted || false
          });
        } else {
          // Update existing progress
          studentProgress.progress = progress || studentProgress.progress || 0;
          studentProgress.timeSpent = timeSpent || studentProgress.timeSpent || 0;
          studentProgress.lastPosition = lastPosition || studentProgress.lastPosition || 0;
          studentProgress.isCompleted = isCompleted !== undefined ? isCompleted : studentProgress.isCompleted || false;
        }
        
        await studentProgress.save();

        try {
          const PlacementProgress = (await import('../models/PlacementProgress.js')).default;
          let placementProgress = await PlacementProgress.findOne({ studentId });
          
          if (!placementProgress) {
            placementProgress = new PlacementProgress({ studentId });
          }
          
          // Update lastActivityDate to trigger streak calculation
          placementProgress.lastActivityDate = new Date();
          await placementProgress.save();
        } catch (streakError) {
          // If PlacementProgress doesn't exist or fails, continue without updating streak
        }

        // Emit real-time progress update
        const io = req.app.get('io');
        if (io) {
          io.to(`course-${courseId}`).emit('progressUpdated', {
            studentId,
            lectureId,
            progress,
            isCompleted,
            timestamp: new Date()
          });
        }

        res.json({
          success: true,
          message: 'Progress updated successfully',
          progress: {
            percentage: progress || 0,
            isCompleted: isCompleted || false
          }
        });
      } catch (modelError) {
        // StudentProgress model doesn't exist, fallback to creating RealTimeProgress
        // This allows regular courses to use real-time progress tracking
        let progressDoc = await RealTimeProgress.findOne({ studentId, courseId });
        
        if (!progressDoc) {
          const totalModules = course.modules?.length || 0;
          const totalLectures = course.modules?.reduce((total, module) => total + (module.videos?.length || 0), 0) || 0;
          
          progressDoc = new RealTimeProgress({
            studentId,
            courseId,
            overallProgress: {
              totalModules,
              totalLectures,
              completedModules: 0,
              completedLectures: 0,
              percentage: 0
            }
          });
          await progressDoc.save();
        }

        await progressDoc.updateLectureProgress(lectureId, {
          moduleId,
          title: title || lecture?.title,
          type: type || 'video',
          progress: progress || 0,
          timeSpent: timeSpent || 0,
          lastPosition: lastPosition || 0,
          isCompleted: isCompleted || false,
          videoProgress
        });

        await progressDoc.calculateOverallProgress();
        
        try {
          const PlacementProgress = (await import('../models/PlacementProgress.js')).default;
          let placementProgress = await PlacementProgress.findOne({ studentId });
          
          if (!placementProgress) {
            placementProgress = new PlacementProgress({ studentId });
          }
          
          // Update lastActivityDate to trigger streak calculation
          placementProgress.lastActivityDate = new Date();
          await placementProgress.save();
        } catch (streakError) {
          // If PlacementProgress doesn't exist or fails, continue without updating streak
        }

        res.json({
          success: true,
          message: 'Progress updated successfully',
          progress: progressDoc.overallProgress
        });
      }
    }

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
    const enrollment = await checkCourseAccess(studentId, courseId, course);

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
      
      try {
        const PlacementProgress = (await import('../models/PlacementProgress.js')).default;
        let placementProgress = await PlacementProgress.findOne({ studentId });
        
        if (!placementProgress) {
          placementProgress = new PlacementProgress({ studentId });
        }
        
        // Update lastActivityDate to trigger streak calculation
        placementProgress.lastActivityDate = new Date();
        await placementProgress.save();
      } catch (streakError) {
        // If PlacementProgress doesn't exist or fails, continue without updating streak
      }
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

// Get student's course progress (works for both real-time and regular courses)
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

    // Check if student is enrolled
    const enrollment = await checkCourseAccess(studentId, courseId, null);
    
    // Try to find course - check both RealTimeCourse and regular Course
    let course = await RealTimeCourse.findById(courseId);
    let courseType = 'real-time';
    
    if (!course) {
      // Try regular Course model
      try {
        const Course = mongoose.model('Course');
        course = await Course.findById(courseId);
        courseType = 'regular';
      } catch (modelError) {
        // Course model doesn't exist
      }
    }
    
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // If not enrolled, return success with null progress (not 404)
    if (!enrollment) {
      return res.json({
        success: true,
        progress: null,
        enrolled: false,
        courseType
      });
    }

    // Get progress based on course type
    let progress = null;
    
    if (courseType === 'real-time') {
      // Real-time course progress
      progress = await RealTimeProgress.findOne({ studentId, courseId });
    
      // If no progress exists but student is enrolled, create it
      if (!progress) {
        const totalModules = course.modules?.length || 0;
        const totalLectures = course.modules?.reduce((total, module) => total + (module.lectures?.length || 0), 0) || 0;
        
        progress = new RealTimeProgress({
          studentId,
          courseId,
          overallProgress: {
            totalModules,
            totalLectures,
            completedModules: 0,
            completedLectures: 0,
            percentage: 0
          }
        });
        await progress.save();
      }
    } else {
      // Regular course progress - convert StudentProgress to unified format
      try {
        const StudentProgress = mongoose.model('StudentProgress');
        const studentProgressRecords = await StudentProgress.find({ studentId, courseId });
        
        // Calculate progress from StudentProgress records
        const totalLectures = course.modules?.reduce((total, module) => total + (module.videos?.length || 0), 0) || 0;
        const completedLectures = studentProgressRecords.filter(p => p.isCompleted).length || 0;
        const overallProgressPercentage = totalLectures > 0 ? (completedLectures / totalLectures) * 100 : 0;
        const timeSpent = studentProgressRecords.reduce((sum, p) => sum + (p.timeSpent || 0), 0);
        
        // Get lecture progress (convert StudentProgress to unified format)
        const lectureProgress = studentProgressRecords.map(p => ({
          lectureId: p.lectureId?.toString() || p.lectureId,
          moduleId: p.moduleId?.toString() || p.moduleId,
          title: p.title || course.modules
            ?.find(m => m.videos?.some(v => (v._id || v.id)?.toString() === (p.lectureId?.toString() || p.lectureId)))
            ?.videos?.find(v => (v._id || v.id)?.toString() === (p.lectureId?.toString() || p.lectureId))?.title || 'Lecture',
          progress: p.isCompleted ? 100 : (p.progress || 0),
          isCompleted: p.isCompleted || false,
          lastPosition: p.lastPosition || 0,
          timeSpent: p.timeSpent || 0,
          lastAccessedAt: p.updatedAt || p.createdAt
        }));
        
        // Create unified progress object
        progress = {
          studentId,
          courseId,
          courseType: 'regular',
          overallProgress: {
            percentage: Math.round(overallProgressPercentage),
            completedModules: 0, // Regular courses don't track modules separately
            totalModules: course.modules?.length || 0,
            completedLectures,
            totalLectures,
            timeSpent,
            lastAccessedAt: studentProgressRecords.length > 0
              ? studentProgressRecords.sort((a, b) => new Date(b.updatedAt || 0) - new Date(a.updatedAt || 0))[0]?.updatedAt
              : new Date()
          },
          lectureProgress,
          isCompleted: overallProgressPercentage >= 100
        };
      } catch (modelError) {
        // StudentProgress model doesn't exist, create empty progress
        const totalLectures = course.modules?.reduce((total, module) => total + (module.videos?.length || 0), 0) || 0;
        progress = {
          studentId,
          courseId,
          courseType: 'regular',
          overallProgress: {
            percentage: 0,
            completedModules: 0,
            totalModules: course.modules?.length || 0,
            completedLectures: 0,
            totalLectures,
            timeSpent: 0,
            lastAccessedAt: new Date()
          },
          lectureProgress: [],
          isCompleted: false
        };
      }
    }

    res.json({
      success: true,
      progress,
      enrolled: true,
      courseType
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch progress',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get all course progress for a student (for Courses Page)
export const getAllStudentProgress = async (req, res) => {
  try {
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    const formattedProgress = [];

    // 1. Get all RealTimeCourse progress
    try {
      const realTimeProgress = await RealTimeProgress.find({ studentId })
        .populate('courseId', 'title thumbnail image category level')
        .sort({ 'overallProgress.lastAccessedAt': -1 });

      realTimeProgress.forEach(progress => {
        formattedProgress.push({
          courseId: progress.courseId._id || progress.courseId,
          courseTitle: progress.courseId.title || 'Course',
          thumbnail: progress.courseId.thumbnail || progress.courseId.image,
          category: progress.courseId.category,
          level: progress.courseId.level,
          overallProgress: progress.overallProgress?.percentage || 0,
          completedLectures: progress.overallProgress?.completedLectures || 0,
          totalLectures: progress.overallProgress?.totalLectures || 0,
          timeSpent: progress.overallProgress?.timeSpent || 0,
          lastAccessedAt: progress.overallProgress?.lastAccessedAt || progress.updatedAt,
          isCompleted: progress.isCompleted || false,
          courseType: 'real-time',
          lastWatchedLecture: progress.lectureProgress
            ?.filter(l => l.lastPosition > 0)
            .sort((a, b) => new Date(b.lastAccessedAt || 0) - new Date(a.lastAccessedAt || 0))[0] || null
        });
      });
    } catch (realTimeError) {
      // Silent fail - continue with regular courses
    }

    // 2. Get regular Course progress (if StudentProgress model exists)
    try {
      const Course = mongoose.model('Course');
      let StudentProgress = null;
      
      try {
        StudentProgress = mongoose.model('StudentProgress');
      } catch (modelError) {
        // StudentProgress model doesn't exist, skip regular course progress
      }

      if (StudentProgress) {
        // Get enrollments for regular courses
        const Enrollment = mongoose.model('Enrollment');
        const enrollments = await Enrollment.find({
          studentId,
          status: { $in: ['active', 'enrolled'] }
        }).populate('courseId');

        // Get all RealTimeCourse IDs to exclude them
        const realTimeCourseIds = await RealTimeCourse.find({}).select('_id').lean();
        const realTimeCourseIdSet = new Set(realTimeCourseIds.map(c => c._id.toString()));

        // Get progress for each enrolled regular course
        for (const enrollment of enrollments) {
          const courseId = enrollment.courseId?._id || enrollment.courseId;
          const courseIdString = courseId?.toString() || String(courseId);
          
          // Skip if this is a RealTimeCourse (already handled above)
          if (realTimeCourseIdSet.has(courseIdString)) {
            continue;
          }
          
          // Check if this is a regular Course (not RealTimeCourse)
          try {
            const regularCourse = await Course.findById(courseId);
            if (!regularCourse) continue; // Skip if not found
            
            // Get progress for this course
            const courseProgress = await StudentProgress.find({
              studentId,
              courseId
            });

            // Calculate progress statistics
            const totalLectures = courseProgress.length || 0;
            const completedLectures = courseProgress.filter(p => p.isCompleted).length || 0;
            const overallProgress = totalLectures > 0 ? (completedLectures / totalLectures) * 100 : 0;
            const timeSpent = courseProgress.reduce((sum, p) => sum + (p.timeSpent || 0), 0);
            const lastAccessed = courseProgress.length > 0 
              ? courseProgress.sort((a, b) => new Date(b.updatedAt || 0) - new Date(a.updatedAt || 0))[0]?.updatedAt 
              : enrollment.updatedAt;

            formattedProgress.push({
              courseId: courseIdString,
              courseTitle: regularCourse.courseName || 'Course',
              thumbnail: regularCourse.thumbnail || regularCourse.image,
              category: regularCourse.category,
              level: regularCourse.level,
              overallProgress: Math.round(overallProgress),
              completedLectures,
              totalLectures,
              timeSpent,
              lastAccessedAt: lastAccessed,
              isCompleted: overallProgress >= 100,
              courseType: 'regular',
              lastWatchedLecture: null // Regular courses may not have lecture-level tracking
            });
          } catch (courseError) {
            // Skip this course if error
            continue;
          }
        }
      }
    } catch (regularError) {
      // Silent fail - continue with response
    }

    // Sort by lastAccessedAt
    formattedProgress.sort((a, b) => new Date(b.lastAccessedAt) - new Date(a.lastAccessedAt));

    res.json({
      success: true,
      progress: formattedProgress
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

    // Always recalculate total duration from current course modules (ensures accuracy when modules/lectures are added/updated)
    const existingCourse = await RealTimeCourse.findById(courseId);
    if (existingCourse) {
      // Use updated modules if provided, otherwise use existing modules from database
      const modulesToCalculate = updateData.modules && updateData.modules.length > 0 
        ? updateData.modules 
        : (existingCourse.modules || []);
      
      if (modulesToCalculate && modulesToCalculate.length > 0) {
        let totalDuration = 0;
        modulesToCalculate.forEach(module => {
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
    } else if (updateData.modules && updateData.modules.length > 0) {
      // Fallback: calculate from updateData if course not found (shouldn't happen, but safety check)
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

    const enrollment = await checkCourseAccess(studentId, courseId, null);

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