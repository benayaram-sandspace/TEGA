import express from 'express';
import { studentAuth } from '../middleware/studentAuth.js';
import {
  startInterview,
  submitAnswer,
  completeInterview
} from '../controllers/interviewController.js';
import {
  getLeaderboard
} from '../controllers/mockInterviewController.js';

const router = express.Router();

// All routes require student authentication
router.use(studentAuth);

// Conversational interview routes (using real interviewController)
router.post('/conversational/start', startInterview);
router.post('/conversational/submit-answer', submitAnswer);
router.post('/conversational/complete', completeInterview);

// Get leaderboard
router.get('/leaderboard', getLeaderboard);

export default router;
