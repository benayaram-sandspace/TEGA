import express from 'express';
import { adminAuth } from '../middleware/adminAuth.js';
import {
  createCourseWithContent,
  addSectionToCourse,
  addLessonToSection,
  updateCourse,
  deleteCourse,
  updateLesson,
  deleteLesson,
  getCourseAnalytics
} from '../controllers/adminCourseController.js';

const router = express.Router();

// All routes require admin authentication
router.use(adminAuth);

// Course management routes
router.post('/create', createCourseWithContent);
router.put('/:courseId', updateCourse);
router.delete('/:courseId', deleteCourse);
router.get('/:courseId/analytics', getCourseAnalytics);

// Section management routes
router.post('/:courseId/sections', addSectionToCourse);

// Lesson management routes
router.post('/sections/:sectionId/lessons', addLessonToSection);
router.put('/lessons/:lessonId', updateLesson);
router.delete('/lessons/:lessonId', deleteLesson);

export default router;
