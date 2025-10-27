import express from 'express';
import { studentAuth } from '../middleware/studentAuth.js';
import {
  startInterview,
  submitAnswer,
  submitCode,
  completeInterview,
  getInterviewStats,
  getLeaderboard
} from '../controllers/mockInterviewController.js';

const router = express.Router();

// All routes require student authentication
router.use(studentAuth);

// Start a new interview
router.post('/start', startInterview);

// Submit an answer to a question
router.post('/submit-answer', submitAnswer);

// Submit code solution
router.post('/submit-code', submitCode);

// Complete interview and generate report
router.post('/complete', completeInterview);

// Get interview statistics for a user
router.get('/stats/:userId', getInterviewStats);

// Get leaderboard
router.get('/leaderboard', getLeaderboard);

export default router;

