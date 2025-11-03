import express from 'express';
import { studentAuth } from '../middleware/studentAuth.js';
import {
  startInterview,
  submitAnswer,
  completeInterview
} from '../controllers/interviewController.js';

const router = express.Router();

router.use(studentAuth);

router.post('/start', startInterview);
router.post('/submit-answer', submitAnswer);
router.post('/complete', completeInterview);

export default router;

