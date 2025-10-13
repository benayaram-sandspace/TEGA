import express from 'express';
import {
  createQuestion,
  getAllQuestions,
  getQuestionById,
  updateQuestion,
  deleteQuestion,
  bulkUploadQuestions,
  createModule,
  getAllModules,
  updateModule,
  deleteModule,
  getStudentModules,
  getModuleQuestions,
  submitAnswer,
  getStudentProgress,
  updateModuleProgress,
  createMockInterview,
  getStudentInterviews,
  getPlacementStats
} from '../controllers/placementController.js';
import { adminAuth } from '../middleware/adminAuth.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// ============ ADMIN ROUTES ============

// Questions
router.post('/admin/questions', adminAuth, createQuestion);
router.get('/admin/questions', adminAuth, getAllQuestions);
router.get('/admin/questions/:id', adminAuth, getQuestionById);
router.put('/admin/questions/:id', adminAuth, updateQuestion);
router.delete('/admin/questions/:id', adminAuth, deleteQuestion);
router.post('/admin/questions/bulk', adminAuth, bulkUploadQuestions);

// Modules
router.post('/admin/modules', adminAuth, createModule);
router.get('/admin/modules', adminAuth, getAllModules);
router.put('/admin/modules/:id', adminAuth, updateModule);
router.delete('/admin/modules/:id', adminAuth, deleteModule);

// Statistics
router.get('/admin/stats', adminAuth, getPlacementStats);

// ============ STUDENT ROUTES ============

// Modules
router.get('/modules', studentAuth, getStudentModules);
router.get('/modules/:moduleId/questions', studentAuth, getModuleQuestions);

// Progress
router.get('/progress', studentAuth, getStudentProgress);
router.post('/progress/module', studentAuth, updateModuleProgress);

// Answers
router.post('/submit-answer', studentAuth, submitAnswer);

// Mock Interviews
router.post('/mock-interview', studentAuth, createMockInterview);
router.get('/mock-interviews', studentAuth, getStudentInterviews);

export default router;

