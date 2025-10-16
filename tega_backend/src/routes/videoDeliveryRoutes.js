import express from 'express';
import { studentAuth } from '../middleware/studentAuth.js';
import { 
  getScalableSignedVideoUrl, 
  getBatchSignedVideoUrls, 
  clearVideoCache 
} from '../controllers/videoDeliveryController.js';

const router = express.Router();

// All routes require student authentication
router.use(studentAuth);

/**
 * SCALABLE: GET /api/video-delivery/:courseId/:lectureId/signed-url
 * Get signed URL for video with caching (optimized for 10,000+ users)
 */
router.get('/:courseId/:lectureId/signed-url', getScalableSignedVideoUrl);

/**
 * SCALABLE: POST /api/video-delivery/:courseId/batch-signed-urls
 * Get multiple signed URLs in one request (reduces API calls)
 */
router.post('/:courseId/batch-signed-urls', getBatchSignedVideoUrls);

/**
 * POST /api/video-delivery/clear-cache
 * Clear video cache for a user/course (when enrollment changes)
 */
router.post('/clear-cache', clearVideoCache);

export default router;
