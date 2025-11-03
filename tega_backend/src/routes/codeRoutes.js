import express from 'express';
import { 
  runCode, 
  getSubmissionHistory, 
  getSubmission, 
  deleteSubmission,
  getUserStats, 
  getLanguages 
} from '../controllers/codeController.js';
import { studentAuth } from '../middleware/studentAuth.js';
import { authRequired } from '../middleware/auth.js';

const router = express.Router();

// Code execution routes - Allow all authenticated users
router.post('/run', authRequired, runCode);
router.get('/history', studentAuth, getSubmissionHistory);
router.get('/submission/:id', studentAuth, getSubmission);
router.delete('/history/:id', studentAuth, deleteSubmission);
router.get('/stats', studentAuth, getUserStats);
router.get('/languages', getLanguages);

// Test authentication endpoint
router.get('/auth-test', studentAuth, (req, res) => {
  res.json({
    success: true,
    message: 'Authentication working',
    user: {
      id: req.student?._id || req.studentId || req.user?.id,
      name: req.student?.name || req.user?.name
    }
  });
});

export default router;
