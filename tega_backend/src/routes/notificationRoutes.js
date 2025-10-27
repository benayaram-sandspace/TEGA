import express from 'express';
import Notification from '../models/Notification.js';
import { adminAuth } from '../middleware/adminAuth.js';
import { studentAuth } from '../middleware/studentAuth.js';
import { userNotifications } from '../controllers/authController.js';

// Check if MongoDB is connected
const isMongoConnected = () => {
  try {
    return Notification.db.readyState === 1;
  } catch (error) {
    return false;
  }
};

const router = express.Router();

// Admin routes
// Get all notifications for the logged-in admin
router.get('/admin', adminAuth, async (req, res) => {
  try {
    const notifications = await Notification.find({ 
      recipient: req.adminId,
      recipientModel: 'Admin'
    }).sort({ createdAt: -1 });
    
    res.json({ success: true, notifications });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to get notifications' });
  }
});

// Get admin payment notifications
router.get('/admin/payments', adminAuth, async (req, res) => {
  try {
    const notifications = await Notification.find({ 
      type: 'payment_received',
      recipientModel: 'Admin'
    }).sort({ createdAt: -1 });
    res.json({ success: true, notifications });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to get payment notifications' });
  }
});

// Mark a notification as read (admin)
router.patch('/admin/:notificationId/read', adminAuth, async (req, res) => {
  try {
    const { notificationId } = req.params;
    const notification = await Notification.findByIdAndUpdate(notificationId, { isRead: true }, { new: true });

    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    res.json({ success: true, notification });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to update notification' });
  }
});

// User (Student) routes
// Get all notifications for the logged-in student
router.get('/user', studentAuth, async (req, res) => {
  try {
    const userId = req.studentId;
    
    // console.log('🔔 Fetching notifications for student ID:', userId);
    // console.log('🔗 MongoDB connected:', isMongoConnected());
    
    // Try MongoDB first, fallback to in-memory storage
    let notifications = [];
    if (isMongoConnected()) {
      try {
        notifications = await Notification.find({ 
          recipient: userId,
          recipientModel: 'Student'
        }).sort({ createdAt: -1 });
        // console.log(`📋 Found ${notifications.length} notifications in MongoDB`);
      } catch (error) {
        // console.error('❌ Error fetching notifications from MongoDB:', error);
      }
    }
    
    // Get from in-memory storage if MongoDB failed or not connected
    if (notifications.length === 0 && userNotifications.has(userId)) {
      notifications = userNotifications.get(userId);
      // console.log(`💾 Found ${notifications.length} notifications in memory storage`);
    }
    
    // console.log(`✅ Returning ${notifications.length} notifications to student`);
    res.json({ success: true, notifications });
  } catch (error) {
    // console.error('❌ Error in notification route:', error);
    res.status(500).json({ success: false, message: 'Failed to get notifications' });
  }
});

// Mark a notification as read (user)
router.patch('/user/:notificationId/read', studentAuth, async (req, res) => {
  try {
    const { notificationId } = req.params;
    const userId = req.studentId;
    
    let notification = null;
    
    // Try MongoDB first, fallback to in-memory storage
    if (isMongoConnected()) {
      try {
        notification = await Notification.findByIdAndUpdate(
          notificationId, 
          { isRead: true }, 
          { new: true }
        );
      } catch (error) {
      }
    }
    
    // Update in-memory storage if MongoDB failed or not connected
    if (!notification && userNotifications.has(userId)) {
      const userNotifs = userNotifications.get(userId);
      const notifIndex = userNotifs.findIndex(n => n._id === notificationId);
      if (notifIndex !== -1) {
        userNotifs[notifIndex].isRead = true;
        notification = userNotifs[notifIndex];
      }
    }

    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    res.json({ success: true, notification });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to update notification' });
  }
});

// Delete a notification (user)
router.delete('/user/:notificationId', studentAuth, async (req, res) => {
  try {
    const { notificationId } = req.params;
    const userId = req.studentId;
    
    let notification = null;
    
    // Try MongoDB first, fallback to in-memory storage
    if (isMongoConnected()) {
      try {
        notification = await Notification.findByIdAndDelete(notificationId);
      } catch (error) {
      }
    }
    
    // Delete from in-memory storage if MongoDB failed or not connected
    if (!notification && userNotifications.has(userId)) {
      const userNotifs = userNotifications.get(userId);
      const notifIndex = userNotifs.findIndex(n => n._id === notificationId);
      if (notifIndex !== -1) {
        notification = userNotifs.splice(notifIndex, 1)[0];
      }
    }

    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    res.json({ success: true, message: 'Notification deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to delete notification' });
  }
});

// Create a notification (for payment success, etc.)
router.post('/user', studentAuth, async (req, res) => {
  try {
    const { message, type = 'info' } = req.body;

    // If MongoDB is connected, store in DB
    if (isMongoConnected()) {
      const notification = new Notification({
        recipient: req.studentId,
        recipientModel: 'Student',
        message,
        type
      });

      await notification.save();
      return res.json({ success: true, notification });
    }

    // Fallback: store in in-memory map when DB is unavailable
    const id = `${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
    const fallbackNotification = {
      _id: id,
      recipient: req.studentId,
      recipientModel: 'Student',
      message,
      type,
      isRead: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    const existing = userNotifications.get(req.studentId) || [];
    userNotifications.set(req.studentId, [fallbackNotification, ...existing]);
    return res.json({ success: true, notification: fallbackNotification, storage: 'memory' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to create notification' });
  }
});

export default router;
