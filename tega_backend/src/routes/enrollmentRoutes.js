import express from 'express';
import { studentAuth } from '../middleware/studentAuth.js';
import {
  enrollInCourse,
  checkEnrollment,
  getStudentEnrollments,
  checkLectureAccess,
  unenrollFromCourse
} from '../controllers/enrollmentController.js';

const router = express.Router();

// All routes require student authentication
router.use(studentAuth);

// Enrollment routes - Universal access for all institutes
// Note: Order matters - specific routes before parameterized routes
router.get('/student/enrollments', getStudentEnrollments);
router.get('/check/:courseId', checkEnrollment); // Alternative route format
router.post('/check/:courseId', checkEnrollment); // Support POST as well
router.post('/:courseId/enroll', enrollInCourse);
router.get('/:courseId/check', checkEnrollment);
router.get('/:courseId/lectures/:lectureId/access', checkLectureAccess);
router.delete('/:courseId/unenroll', unenrollFromCourse);

// Add route for getting all enrollments (without courseId)
router.get('/', getStudentEnrollments);
router.get('/completed', getStudentEnrollments); // For completed courses

export default router;
