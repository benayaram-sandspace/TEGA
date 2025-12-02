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
  getOfferStats,
  createPackageOffer,
  getAllPackageOffers,
  getPackageOffersForInstitute,
  updatePackageOffer,
  deletePackageOffer,
  togglePackageOfferStatus
} from '../controllers/offerController.js';
import { adminAuth } from '../middleware/adminAuth.js';
import { studentAuth } from '../middleware/studentAuth.js';
import {
  purchasePackage,
  completePackagePurchase,
  getUserPackageTransactions
} from '../controllers/packageController.js';

const router = express.Router();

// Admin routes (require admin authentication)
// Specific routes must come before parameterized routes
router.get('/admin/stats', adminAuth, getOfferStats);
router.get('/admin/courses', adminAuth, getAvailableCourses);
router.get('/admin/tega-exams', adminAuth, getAvailableTegaExams);
router.get('/admin/institutes', adminAuth, getInstitutes);
// Package offers routes - MUST come before /admin/:id
router.get('/admin/packages', adminAuth, getAllPackageOffers);
router.post('/admin/packages', adminAuth, createPackageOffer);
router.put('/admin/packages/:id', adminAuth, updatePackageOffer);
router.delete('/admin/packages/:id', adminAuth, deletePackageOffer);
router.patch('/admin/packages/:id/toggle', adminAuth, togglePackageOfferStatus);
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
router.get('/institute/:instituteName/packages', getPackageOffersForInstitute);

// Package purchase routes (requires student auth)
router.post('/packages/purchase', studentAuth, purchasePackage);
router.post('/packages/complete', studentAuth, completePackagePurchase);
router.get('/packages/transactions', studentAuth, getUserPackageTransactions);

export default router;