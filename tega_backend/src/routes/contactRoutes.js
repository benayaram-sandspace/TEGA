import express from 'express';
import * as contactController from '../controllers/contactController.js';
import { adminAuth } from '../middleware/adminAuth.js';

const router = express.Router();

// Public routes (no authentication required)
router.post('/submit', contactController.submitContactForm);

// Admin routes (authentication required)
router.get('/admin/submissions', adminAuth, contactController.getAllSubmissions);
router.get('/admin/submissions/stats', adminAuth, contactController.getSubmissionStats);
router.get('/admin/submissions/:id', adminAuth, contactController.getSubmissionById);
router.put('/admin/submissions/:id', adminAuth, contactController.updateSubmissionStatus);
router.delete('/admin/submissions/:id', adminAuth, contactController.deleteSubmission);

export default router;
