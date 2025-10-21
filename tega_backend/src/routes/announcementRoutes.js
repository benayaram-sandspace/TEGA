import express from 'express';
import jwt from 'jsonwebtoken';
import Announcement from '../models/Announcement.js';
import Principal from '../models/Principal.js';
import Student from '../models/Student.js';
import Notification from '../models/Notification.js';

const router = express.Router();

// Middleware to verify principal authentication
const verifyPrincipal = async (req, res, next) => {
  try {
    const authHeader = req.header('Authorization');
    const token = authHeader?.startsWith('Bearer ') ? authHeader.replace('Bearer ', '') : authHeader;
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-this-in-production');
    const principal = await Principal.findById(decoded.id);
    
    if (!principal || !principal.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Principal not found or inactive.'
      });
    }

    req.principal = principal;
    next();
  } catch (error) {
    res.status(401).json({
      success: false,
      message: 'Invalid token.'
    });
  }
};

// Create announcement
router.post('/', verifyPrincipal, async (req, res) => {
  try {
    const { title, message, priority, audience, targetAudience, expiresAt, attachments } = req.body;

    // Validate required fields
    if (!title || !message) {
      return res.status(400).json({
        success: false,
        message: 'Title and message are required'
      });
    }

    // Validate principal has university
    if (!req.principal.university) {
      return res.status(400).json({
        success: false,
        message: 'Principal university is required'
      });
    }

    // Create announcement
    const announcement = new Announcement({
      title,
      message,
      priority: priority || 'normal',
      audience: audience || 'all',
      targetAudience,
      university: req.principal.university,
      createdBy: req.principal._id,
      expiresAt: expiresAt ? new Date(expiresAt) : null,
      attachments: attachments || []
    });

    await announcement.save();

    // Create notifications for all students in the university
    await createStudentNotifications(announcement);

    // Emit real-time announcement event to all students in the university
    try {
      const io = req.app.get('io');
      if (io) {
        // Get all students in the university
        const students = await Student.find({ 
          institute: announcement.university, 
          isActive: true 
        }).select('_id');

        // Emit to each student's personal room
        students.forEach(student => {
          io.to(`user-${student._id}`).emit('new-announcement', {
            type: 'new-announcement',
            data: {
              announcementId: announcement._id,
              title: announcement.title,
              message: announcement.message,
              priority: announcement.priority,
              createdBy: announcement.createdBy,
              university: announcement.university,
              createdAt: announcement.createdAt
            },
            timestamp: new Date().toISOString()
          });
        });

        console.log(`Emitted new announcement to ${students.length} students`);
      }
    } catch (socketError) {
      console.error('Error emitting announcement event:', socketError);
    }

    res.status(201).json({
      success: true,
      message: 'Announcement created successfully',
      announcement
    });
  } catch (error) {
    console.error('Error creating announcement:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create announcement'
    });
  }
});

// Get all announcements for a principal's university
router.get('/', verifyPrincipal, async (req, res) => {
  try {
    const { page = 1, limit = 10, search, priority, audience } = req.query;
    const skip = (page - 1) * limit;

    // Build query
    let query = { 
      university: req.principal.university,
      isActive: true
    };

    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { message: { $regex: search, $options: 'i' } }
      ];
    }

    if (priority) {
      query.priority = priority;
    }

    if (audience) {
      query.audience = audience;
    }

    const announcements = await Announcement.find(query)
      .populate('createdBy', 'principalName email')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Announcement.countDocuments(query);

    res.json({
      success: true,
      announcements,
      pagination: {
        current: parseInt(page),
        pages: Math.ceil(total / limit),
        total
      }
    });
  } catch (error) {
    console.error('Error fetching announcements:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch announcements'
    });
  }
});

// Get single announcement
router.get('/:id', verifyPrincipal, async (req, res) => {
  try {
    const announcement = await Announcement.findOne({
      _id: req.params.id,
      university: req.principal.university,
      isActive: true
    }).populate('createdBy', 'principalName email');

    if (!announcement) {
      return res.status(404).json({
        success: false,
        message: 'Announcement not found'
      });
    }

    res.json({
      success: true,
      announcement
    });
  } catch (error) {
    console.error('Error fetching announcement:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch announcement'
    });
  }
});

// Update announcement
router.put('/:id', verifyPrincipal, async (req, res) => {
  try {
    const { title, message, priority, audience, targetAudience, expiresAt, attachments } = req.body;

    const announcement = await Announcement.findOne({
      _id: req.params.id,
      university: req.principal.university,
      createdBy: req.principal._id,
      isActive: true
    });

    if (!announcement) {
      return res.status(404).json({
        success: false,
        message: 'Announcement not found or you do not have permission to edit it'
      });
    }

    // Update fields
    if (title) announcement.title = title;
    if (message) announcement.message = message;
    if (priority) announcement.priority = priority;
    if (audience) announcement.audience = audience;
    if (targetAudience) announcement.targetAudience = targetAudience;
    if (expiresAt) announcement.expiresAt = new Date(expiresAt);
    if (attachments) announcement.attachments = attachments;

    await announcement.save();

    // Emit real-time announcement update event
    try {
      const io = req.app.get('io');
      if (io) {
        const students = await Student.find({ 
          institute: announcement.university, 
          isActive: true 
        }).select('_id');

        students.forEach(student => {
          io.to(`user-${student._id}`).emit('announcement-updated', {
            type: 'announcement-updated',
            data: {
              announcementId: announcement._id,
              title: announcement.title,
              message: announcement.message,
              priority: announcement.priority,
              updatedAt: announcement.updatedAt
            },
            timestamp: new Date().toISOString()
          });
        });

        console.log(`Emitted announcement update to ${students.length} students`);
      }
    } catch (socketError) {
      console.error('Error emitting announcement update event:', socketError);
    }

    res.json({
      success: true,
      message: 'Announcement updated successfully',
      announcement
    });
  } catch (error) {
    console.error('Error updating announcement:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update announcement'
    });
  }
});

// Delete announcement
router.delete('/:id', verifyPrincipal, async (req, res) => {
  try {
    const announcement = await Announcement.findOne({
      _id: req.params.id,
      university: req.principal.university,
      createdBy: req.principal._id,
      isActive: true
    });

    if (!announcement) {
      return res.status(404).json({
        success: false,
        message: 'Announcement not found or you do not have permission to delete it'
      });
    }

    // Soft delete
    announcement.isActive = false;
    await announcement.save();

    // Delete related notifications
    await Notification.deleteMany({
      type: 'announcement',
      data: { announcementId: announcement._id }
    });

    // Emit real-time announcement deletion event
    try {
      const io = req.app.get('io');
      if (io) {
        const students = await Student.find({ 
          institute: announcement.university, 
          isActive: true 
        }).select('_id');

        students.forEach(student => {
          io.to(`user-${student._id}`).emit('announcement-deleted', {
            type: 'announcement-deleted',
            data: {
              announcementId: announcement._id,
              title: announcement.title
            },
            timestamp: new Date().toISOString()
          });
        });

        console.log(`Emitted announcement deletion to ${students.length} students`);
      }
    } catch (socketError) {
      console.error('Error emitting announcement deletion event:', socketError);
    }

    res.json({
      success: true,
      message: 'Announcement deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting announcement:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete announcement'
    });
  }
});

// Helper function to create notifications for students
async function createStudentNotifications(announcement) {
  try {
    // Build student query based on announcement audience
    let studentQuery = { institute: announcement.university, isActive: true };
    
    if (announcement.audience === 'specific_course' && announcement.targetAudience?.course) {
      studentQuery.course = announcement.targetAudience.course;
    }
    
    if (announcement.audience === 'specific_year' && announcement.targetAudience?.yearOfStudy) {
      studentQuery.yearOfStudy = announcement.targetAudience.yearOfStudy;
    }

    const students = await Student.find(studentQuery).select('_id');
    
    // Create notifications for each student
    const notifications = students.map(student => ({
      recipient: student._id,
      recipientModel: 'Student',
      message: `New announcement: ${announcement.title}`,
      type: 'announcement',
      data: {
        announcementId: announcement._id,
        title: announcement.title,
        priority: announcement.priority
      },
      isRead: false
    }));

    if (notifications.length > 0) {
      await Notification.insertMany(notifications);
    }
  } catch (error) {
    console.error('Error creating student notifications:', error);
  }
}

export default router;
