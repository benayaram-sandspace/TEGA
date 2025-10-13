import express from 'express';
import {
  createSection,
  getSectionsByCourse,
  updateSection,
  deleteSection,
  reorderSections
} from '../controllers/sectionController.js';
import { adminAuth } from '../middleware/adminAuth.js';

const router = express.Router();

// Public routes
router.get('/course/:courseId', getSectionsByCourse);

// Admin routes (protected)
router.post('/', adminAuth, createSection);
router.put('/:sectionId', adminAuth, updateSection);
router.delete('/:sectionId', adminAuth, deleteSection);
router.put('/reorder/:courseId', adminAuth, reorderSections);

export default router;
