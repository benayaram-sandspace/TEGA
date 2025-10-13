import express from 'express';
import { 
  uploadSingleCourse, 
  uploadBulkCourses, 
  getAllCourses, 
  getAllCoursesForAdmin,
  getAdminCourses, 
  updateCourse, 
  deleteCourse,
  getCourseWithContent,
  createCourse,
  bulkImportCourses,
  addVideoToCourse,
  diagnoseExcelFile,
  testCreateCourse,
  upload 
} from '../controllers/courseController.js';
import { adminAuth } from '../middleware/adminAuth.js';
import { studentAuth } from '../middleware/studentAuth.js';

const router = express.Router();

// Public routes (for users) - Universal access for all institutes
router.get('/', studentAuth, getAllCourses); // Handle /api/courses (all courses)
router.get('/all', studentAuth, getAllCourses);

// Test endpoint (must come before /:courseId)
router.get('/test', (req, res) => {
  res.json({ message: 'Course API is working', timestamp: new Date().toISOString() });
});

// Test endpoint with student auth but no college access
router.get('/test-auth', studentAuth, (req, res) => {
  res.json({ 
    message: 'Course API with auth is working', 
    timestamp: new Date().toISOString(),
    student: req.student ? 'Student found' : 'No student'
  });
});

// Course access for all users (universal access)
router.get('/:courseId', studentAuth, (req, res, next) => {
  next();
}, getCourseWithContent);

// Admin routes (protected)
router.post('/', adminAuth, createCourse);
router.post('/upload', adminAuth, uploadSingleCourse);
router.post('/bulk-upload', adminAuth, upload.single('file'), uploadBulkCourses);
router.post('/bulk-import', adminAuth, upload.single('file'), bulkImportCourses);
router.post('/diagnose-excel', adminAuth, upload.single('file'), diagnoseExcelFile);
router.post('/test-create', adminAuth, testCreateCourse);
router.get('/admin/all', adminAuth, getAdminCourses);
router.get('/admin/all-courses', adminAuth, getAllCoursesForAdmin);
router.put('/:courseId', adminAuth, updateCourse);
router.put('/:courseId/add-video', adminAuth, addVideoToCourse);
router.delete('/:courseId', adminAuth, deleteCourse);

export default router;
