import { generatePresignedDownloadUrl } from '../config/r2.js';
import Enrollment from '../models/Enrollment.js';
// Enrollment functionality now in Enrollment model
import RealTimeCourse from '../models/RealTimeCourse.js';

/**
 * Get signed video URL for enrolled students only
 * This prevents direct URL sharing and unauthorized access
 */
export const getSignedVideoUrl = async (req, res) => {
  try {
    const { courseId, lectureId } = req.params;
    const studentId = req.studentId;

    // Step 1: Verify authentication
    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    // Step 2: Get course and lecture data FIRST (to check if intro/preview)
    const course = await RealTimeCourse.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // Step 4: Find the lecture and get video key
    let videoKey = null;
    let lecture = null;
    let moduleIndex = -1;
    let lectureIndex = -1;

    console.log('Searching for lecture:', lectureId, 'in course:', courseId);
    console.log('Course modules:', course.modules?.length || 0);

    for (let mIdx = 0; mIdx < course.modules.length; mIdx++) {
      const module = course.modules[mIdx];
      console.log('Module:', module.title, 'has', module.lectures?.length || 0, 'lectures');
      
      for (let lIdx = 0; lIdx < module.lectures.length; lIdx++) {
        if (module.lectures[lIdx].id === lectureId) {
          lecture = module.lectures[lIdx];
          moduleIndex = mIdx;
          lectureIndex = lIdx;
          videoKey = lecture.videoContent?.r2Key;
          console.log('Found lecture:', lecture.title, 'at module', mIdx, 'lecture', lIdx);
          console.log('Video key:', videoKey);
          break;
        }
      }
      if (lecture) break;
    }

    if (!lecture) {
      console.error('Lecture not found:', lectureId);
      return res.status(404).json({
        success: false,
        message: 'Lecture not found'
      });
    }

    if (!videoKey) {
      console.error('Video key not found for lecture:', lecture.title);
      return res.status(404).json({
        success: false,
        message: 'Video not found - no video key available'
      });
    }

    // Step 4: Check if it's intro/preview BEFORE enrollment check
    const isPreview = lecture.isPreview;
    const isIntroductionVideo = moduleIndex === 0 && lectureIndex === 0;

    console.log('🔍 Video Access Check:', {
      lectureTitle: lecture.title,
      isPreview,
      isIntroductionVideo,
      moduleIndex,
      lectureIndex
    });

    // Step 5: Allow access to intro/preview videos WITHOUT enrollment
    if (isPreview || isIntroductionVideo) {
      console.log('✅ Intro/Preview video - generating signed URL without enrollment check');
      
      // Generate signed URL for preview/intro videos
      const signedUrl = await generatePresignedDownloadUrl(videoKey);
      const expiresAt = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

      return res.json({
        success: true,
        signedUrl,
        expiresAt,
        lecture: {
          id: lecture.id,
          title: lecture.title,
          isPreview: true,
          isFree: true
        }
      });
    }

    // Step 6: For premium videos, verify enrollment
    const enrollment = await Enrollment.findOne({ 
      studentId, 
      courseId,
      status: 'active' 
    });

    const userCourse = await Enrollment.findOne({
      studentId,
      courseId,
      isActive: true,
      accessExpiresAt: { $gt: new Date() }
    });

    const isEnrolled = !!(enrollment || userCourse);

    if (!isEnrolled) {
      console.log('❌ Premium video - enrollment required');
      return res.status(403).json({
        success: false,
        message: 'Access denied. You must be enrolled in this course to watch videos.',
        code: 'NOT_ENROLLED'
      });
    }

    // Step 7: Check payment for paid courses
    if (!course.isFree && course.price > 0) {
      const isPaidEnrollment = enrollment?.isPaid || userCourse?.paymentStatus === 'completed';
      if (!isPaidEnrollment) {
        console.log('❌ Paid course - payment required');
        return res.status(403).json({
          success: false,
          message: 'Access denied. Payment required to access this course.',
          code: 'PAYMENT_REQUIRED'
        });
      }
    }

    // Step 8: Generate signed URL (expires in 3600 seconds = 1 hour)
    // This uses AWS SDK presigned URLs - works even with R2 public access disabled
    console.log('Generating signed URL for video key:', videoKey);
    const signedUrlResult = await generatePresignedDownloadUrl(videoKey, 3600);
    console.log('Signed URL result:', signedUrlResult);

    if (!signedUrlResult.success) {
      console.error('Failed to generate signed URL:', signedUrlResult);
      return res.status(500).json({
        success: false,
        message: 'Failed to generate video access URL',
        error: signedUrlResult.error || 'Unknown error'
      });
    }

    // Step 7: Log access for audit (optional)
    console.log(`Video accessed: ${lectureId} by student ${studentId} at ${new Date().toISOString()}`);

    // Step 8: Return signed URL
    res.json({
      success: true,
      signedUrl: signedUrlResult.downloadUrl,
      expiresAt: new Date(Date.now() + 3600000), // 1 hour from now
      lecture: {
        id: lecture.id,
        title: lecture.title,
        duration: lecture.duration,
        isPreview: isPreview || isIntroductionVideo
      }
    });

  } catch (error) {
    console.error('Get signed video URL error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate video access URL',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Get video access status (for frontend to check if user can access)
 */
export const getVideoAccessStatus = async (req, res) => {
  try {
    const { courseId, lectureId } = req.params;
    const studentId = req.studentId;

    if (!studentId) {
      return res.json({
        success: true,
        hasAccess: false,
        reason: 'Authentication required',
        canAccess: false
      });
    }

    const enrollment = await Enrollment.findOne({ 
      studentId, 
      courseId,
      status: 'active' 
    });

    const userCourse = await Enrollment.findOne({
      studentId,
      courseId,
      isActive: true,
      accessExpiresAt: { $gt: new Date() }
    });

    const course = await RealTimeCourse.findById(courseId);
    if (!course) {
      return res.json({
        success: true,
        hasAccess: false,
        reason: 'Course not found',
        canAccess: false
      });
    }

    // Find lecture
    let lecture = null;
    for (const module of course.modules) {
      lecture = module.lectures.find(l => l.id === lectureId);
      if (lecture) break;
    }

    if (!lecture) {
      return res.json({
        success: true,
        hasAccess: false,
        reason: 'Lecture not found',
        canAccess: false
      });
    }

    // Check access
    const isPreview = lecture.isPreview;
    const isIntroductionVideo = course.modules[0]?.lectures[0]?.id === lectureId;
    const isEnrolled = !!(enrollment || userCourse);

    let hasAccess = false;
    let reason = '';

    if (isPreview || isIntroductionVideo) {
      hasAccess = true;
      reason = 'Preview/Introduction video';
    } else if (isEnrolled) {
      hasAccess = true;
      reason = 'Enrolled student';
    } else {
      hasAccess = false;
      reason = 'Not enrolled';
    }

    res.json({
      success: true,
      hasAccess,
      reason,
      canAccess: hasAccess,
      isPreview: isPreview || isIntroductionVideo,
      isEnrolled,
      requiresPayment: !isPreview && !isIntroductionVideo && course.price > 0 && !(enrollment?.isPaid || userCourse?.paymentStatus === 'completed')
    });

  } catch (error) {
    console.error('Get video access status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to check video access',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
