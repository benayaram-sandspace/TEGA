import express from 'express';
import Announcement from '../models/Announcement.js';
import Student from '../models/Student.js';
import Notification from '../models/Notification.js';
import principalAuth from '../middleware/principalAuth.js';

const router = express.Router();

// Create announcement
router.post('/', principalAuth, async (req, res) => {
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
      }
    } catch (socketError) {
    }

    res.status(201).json({
      success: true,
      message: 'Announcement created successfully',
      announcement
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create announcement'
    });
  }
});

// Get all announcements for a principal's university
router.get('/', principalAuth, async (req, res) => {
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
    res.status(500).json({
      success: false,
      message: 'Failed to fetch announcements'
    });
  }
});

// Get single announcement
router.get('/:id', principalAuth, async (req, res) => {
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
    res.status(500).json({
      success: false,
      message: 'Failed to fetch announcement'
    });
  }
});

// Update announcement
router.put('/:id', principalAuth, async (req, res) => {
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
      }
    } catch (socketError) {
    }

    res.json({
      success: true,
      message: 'Announcement updated successfully',
      announcement
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update announcement'
    });
  }
});

// Delete announcement
router.delete('/:id', principalAuth, async (req, res) => {
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
      }
    } catch (socketError) {
    }

    res.json({
      success: true,
      message: 'Announcement deleted successfully'
    });
  } catch (error) {
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
  }
}

export default router;
