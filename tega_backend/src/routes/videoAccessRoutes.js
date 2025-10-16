import express from 'express';
import { studentAuth } from '../middleware/studentAuth.js';
import { getSignedVideoUrl, getVideoAccessStatus } from '../controllers/videoAccessController.js';

const router = express.Router();

// All routes require student authentication
router.use(studentAuth);

/**
 * GET /api/video-access/:courseId/:lectureId/url
 * Get signed URL for video (expires in 60 seconds)
 * Only works for enrolled students
 */
router.get('/:courseId/:lectureId/url', getSignedVideoUrl);

/**
 * GET /api/video-access/:courseId/:lectureId/status
 * Check if user can access video (without generating URL)
 */
router.get('/:courseId/:lectureId/status', getVideoAccessStatus);

export default router;
