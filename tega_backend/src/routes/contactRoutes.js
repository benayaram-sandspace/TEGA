import express from 'express';
import * as contactController from '../controllers/contactController.js';
import { authRequired as auth } from '../middleware/auth.js';

const router = express.Router();

// Public routes (no authentication required)
router.post('/submit', contactController.submitContactForm);

// Admin routes (authentication required)
router.get('/admin/submissions', auth, contactController.getAllSubmissions);
router.get('/admin/submissions/stats', auth, contactController.getSubmissionStats);
router.get('/admin/submissions/:id', auth, contactController.getSubmissionById);
router.put('/admin/submissions/:id', auth, contactController.updateSubmissionStatus);
router.delete('/admin/submissions/:id', auth, contactController.deleteSubmission);

export default router;
