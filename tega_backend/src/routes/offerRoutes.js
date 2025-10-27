import express from 'express';
import {
  getAllOffers,
  getOfferById,
  createOffer,
  updateOffer,
  deleteOffer,
  toggleOfferStatus,
  getOffersForInstitute,
  getCourseOfferForInstitute,
  getTegaExamOfferForInstitute,
  getAvailableCourses,
  getAvailableTegaExams,
  getInstitutes,
  getOfferStats
} from '../controllers/offerController.js';
import { adminAuth } from '../middleware/adminAuth.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// Admin routes (require admin authentication)
// Specific routes must come before parameterized routes
router.get('/admin/stats', adminAuth, getOfferStats);
router.get('/admin/courses', adminAuth, getAvailableCourses);
router.get('/admin/tega-exams', adminAuth, getAvailableTegaExams);
router.get('/admin/institutes', adminAuth, getInstitutes);
router.get('/admin', adminAuth, getAllOffers);
// Parameterized routes come after specific routes
router.get('/admin/:id', adminAuth, getOfferById);
router.post('/admin', adminAuth, createOffer);
router.put('/admin/:id', adminAuth, updateOffer);
router.delete('/admin/:id', adminAuth, deleteOffer);
router.patch('/admin/:id/toggle', adminAuth, toggleOfferStatus);

// Public routes (no authentication required for viewing offers)
router.get('/institute/:instituteName', getOffersForInstitute);
router.get('/institute/:instituteName/course/:courseId', getCourseOfferForInstitute);
router.get('/institute/:instituteName/tega-exam', getTegaExamOfferForInstitute);

export default router;