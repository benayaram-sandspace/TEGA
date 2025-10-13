import { generatePresignedDownloadUrl } from '../config/r2.js';
import Enrollment from '../models/Enrollment.js';
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

    // Step 2: Verify enrollment
    const enrollment = await Enrollment.findOne({ 
      studentId, 
      courseId,
      status: 'active' 
    });

    if (!enrollment) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You must be enrolled in this course to watch videos.',
        code: 'NOT_ENROLLED'
      });
    }

    // Step 3: Get course and lecture data
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

    for (const module of course.modules) {
      lecture = module.lectures.find(l => l.id === lectureId);
      if (lecture) {
        videoKey = lecture.videoContent?.r2Key;
        break;
      }
    }

    if (!lecture || !videoKey) {
      return res.status(404).json({
        success: false,
        message: 'Video not found'
      });
    }

    // Step 5: Check if it's a preview lecture (always accessible)
    const isPreview = lecture.isPreview;
    const isIntroductionVideo = course.modules[0]?.lectures[0]?.id === lectureId;

    if (!isPreview && !isIntroductionVideo) {
      // For premium videos, double-check enrollment
      if (!enrollment.isPaid && course.price > 0) {
        return res.status(403).json({
          success: false,
          message: 'Payment required for premium content',
          code: 'PAYMENT_REQUIRED'
        });
      }
    }

    // Step 6: Generate signed URL (expires in 3600 seconds = 1 hour)
    // This uses AWS SDK presigned URLs - works even with R2 public access disabled
    const signedUrlResult = await generatePresignedDownloadUrl(videoKey, 3600);

    if (!signedUrlResult.success) {
      return res.status(500).json({
        success: false,
        message: 'Failed to generate video access URL'
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
    const isEnrolled = !!enrollment;

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
      requiresPayment: !isPreview && !isIntroductionVideo && course.price > 0 && (!enrollment?.isPaid)
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
