import express from 'express';
import { 
  getExamResultsForAdmin, 
  publishExamResults, 
  unpublishExamResults,
  getStudentResultDetails,
  publishAllResultsForDate,
  clearDummyExamData
} from '../controllers/adminExamResultController.js';
import { adminAuth } from '../middleware/adminAuth.js';

const router = express.Router();

// Test endpoint to verify route is working
router.get('/test', (req, res) => {
  res.json({ 
    success: true, 
    message: 'Admin exam results route is working!',
    timestamp: new Date().toISOString()
  });
});

// Get all exam results for admin (grouped by exam and date)
router.get('/results', adminAuth, getExamResultsForAdmin);

// Publish results for a specific exam and date
router.post('/publish', adminAuth, publishExamResults);

// Unpublish results for a specific exam and date
router.post('/unpublish', adminAuth, unpublishExamResults);

// Get individual student result details
router.get('/result/:attemptId', adminAuth, getStudentResultDetails);

// Publish all results for a specific date
router.post('/publish-all-date', adminAuth, publishAllResultsForDate);
router.post('/publish-all', adminAuth, publishAllResultsForDate);

// Clear dummy exam data
router.delete('/clear-dummy-data', adminAuth, clearDummyExamData);

export default router;
