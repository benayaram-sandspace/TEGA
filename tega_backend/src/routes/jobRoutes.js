import express from 'express';
import {
  getActiveJobs,
  getJobById,
  createJob,
  updateJob,
  deleteJob,
  getAllJobsForAdmin,
  updateJobStatus,
  applyForJob
} from '../controllers/jobController.js';
import { adminAuth } from '../middleware/adminAuth.js';
import { authRequired } from '../middleware/auth.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// Admin routes (authentication required) - place BEFORE parameterized routes
router.get('/admin/all', adminAuth, getAllJobsForAdmin);
router.post('/', adminAuth, createJob);
router.put('/:id', adminAuth, updateJob);
router.delete('/:id', adminAuth, deleteJob);
router.patch('/:id/status', adminAuth, updateJobStatus);

// Public routes (no authentication required)
router.get('/', getActiveJobs);
router.get('/:id', getJobById);

// Job application route (requires student authentication and job access)
router.post('/:id/apply', studentAuth, applyForJob);

export default router;
