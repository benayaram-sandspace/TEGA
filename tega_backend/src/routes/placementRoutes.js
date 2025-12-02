import express from 'express';
import multer from 'multer';
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
  deleteSubmission,
  runCode,
  getCodingQuestions,
  getPlacementStats,
  getCodingLeaderboard,
  createCodingAssessment,
  getAllCodingAssessments,
  getCodingAssessmentById,
  updateCodingAssessment,
  deleteCodingAssessment,
  getStudentCodingAssessments,
  getCodingAssessmentQuestions,
  submitCodingAssessment,
  getStudentSkillAssessments,
  migrateQuestionsFromPlacementTable
} from '../controllers/placementController.js';
import { adminAuth } from '../middleware/adminAuth.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// Configure multer for Excel file uploads (in-memory processing)
const upload = multer({
  storage: multer.memoryStorage(),
  fileFilter: (req, file, cb) => {
    const allowedTypes = [
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/vnd.ms-excel'
    ];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only Excel files (.xlsx or .xls) are allowed'), false);
    }
  },
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  }
});

// ============ ADMIN ROUTES ============

// Questions
router.post('/admin/questions', adminAuth, createQuestion);
router.get('/admin/questions', adminAuth, getAllQuestions);
router.get('/admin/questions/:id', adminAuth, getQuestionById);
router.put('/admin/questions/:id', adminAuth, updateQuestion);
router.delete('/admin/questions/:id', adminAuth, deleteQuestion);
router.post('/admin/questions/bulk', adminAuth, upload.single('file'), bulkUploadQuestions);

// Modules
router.post('/admin/modules', adminAuth, createModule);
router.get('/admin/modules', adminAuth, getAllModules);
router.put('/admin/modules/:id', adminAuth, updateModule);
router.delete('/admin/modules/:id', adminAuth, deleteModule);

// Coding Assessments
router.post('/admin/coding-assessments', adminAuth, createCodingAssessment);
router.get('/admin/coding-assessments', adminAuth, getAllCodingAssessments);
router.get('/admin/coding-assessments/:id', adminAuth, getCodingAssessmentById);
router.put('/admin/coding-assessments/:id', adminAuth, updateCodingAssessment);
router.delete('/admin/coding-assessments/:id', adminAuth, deleteCodingAssessment);

// Statistics
router.get('/admin/stats', adminAuth, getPlacementStats);

// Migration
router.post('/admin/migrate-questions', adminAuth, migrateQuestionsFromPlacementTable);

// ============ STUDENT ROUTES ============

// Coding Questions
router.get('/coding-questions', studentAuth, getCodingQuestions);
router.post('/run-code', studentAuth, runCode);

// Modules
router.get('/modules', studentAuth, getStudentModules);
router.get('/modules/:moduleId/questions', studentAuth, getModuleQuestions);

// Progress
router.get('/progress', studentAuth, getStudentProgress);
router.post('/progress/module', studentAuth, updateModuleProgress);
router.delete('/progress/submission/:attemptId', studentAuth, deleteSubmission);

// Answers
router.post('/submit-answer', studentAuth, submitAnswer);

// Coding Assessments (Student)
router.get('/coding-assessments', studentAuth, getStudentCodingAssessments);
router.get('/coding-assessments/:assessmentId/questions', studentAuth, getCodingAssessmentQuestions);
router.post('/coding-assessments/:assessmentId/submit', studentAuth, submitCodingAssessment);

// Skill Assessments (Student)
router.get('/skill-assessments', studentAuth, getStudentSkillAssessments);

// Leaderboard
router.get('/leaderboard', studentAuth, getCodingLeaderboard);

export default router;
