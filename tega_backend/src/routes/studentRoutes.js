import express from 'express';
import { studentAuth } from '../middleware/studentAuth.js';
import { adminAuth } from '../middleware/adminAuth.js';
import Notification from '../models/Notification.js';
import Student from '../models/Student.js';
import { 
  getStudentProfile, 
  updateStudentProfile, 
  uploadProfilePhoto, 
  removeProfilePhoto,
  getStudentDashboard,
  getSidebarCounts 
} from '../controllers/studentController.js';
import multer from 'multer';

// Configure multer for file uploads
const upload = multer({ dest: 'uploads/' });

const router = express.Router();

// Dashboard route
router.get('/dashboard', studentAuth, getStudentDashboard);

// Sidebar counts route
router.get('/sidebar-counts', studentAuth, getSidebarCounts);

// Get student notifications
router.get('/notifications', studentAuth, async (req, res) => {
  try {
    const notifications = await Notification.find({
      recipient: req.studentId,
      recipientModel: 'Student'
    }).sort({ createdAt: -1 });

    res.json({ success: true, notifications });
  } catch (error) {

    res.status(500).json({ success: false, message: 'Failed to load notifications' });
  }
});

// Mark notifications as read
router.post('/notifications/mark-read', studentAuth, async (req, res) => {
  try {
    await Notification.updateMany(
      { recipient: req.studentId, recipientModel: 'Student', isRead: false },
      { $set: { isRead: true } }
    );
    res.json({ success: true, message: 'Notifications marked as read' });
  } catch (error) {

    res.status(500).json({ success: false, message: 'Failed to update notifications' });
  }
});

// Profile routes
router.route('/profile')
  .get(studentAuth, getStudentProfile)
  .put(studentAuth, updateStudentProfile);

// Profile photo routes
router.post('/profile/photo', 
  studentAuth, 
  upload.single('profilePhoto'),
  (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ 
          success: false, 
          message: 'File too large. Maximum size is 5MB.' 
        });
      }
    } else if (err) {
      return res.status(400).json({ 
        success: false, 
        message: err.message 
      });
    }
    next();
  },
  uploadProfilePhoto
);

router.delete('/profile/photo', 
  studentAuth, 
  removeProfilePhoto
);


export default router;
