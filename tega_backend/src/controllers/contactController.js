import ContactSubmission from '../models/ContactSubmission.js';
import nodemailer from 'nodemailer';

// Create transporter for email notifications
const transporter = nodemailer.createTransport({
  service: 'gmail', // You can change this to your email service
  auth: {
    user: process.env.EMAIL_USER || 'your-email@gmail.com',
    pass: process.env.EMAIL_PASS || 'your-app-password'
  }
});

// Submit contact form
const submitContactForm = async (req, res) => {
  try {
    const { firstName, lastName, email, phone, subject, message, source = 'contact_page' } = req.body;

    // Validate required fields
    if (!firstName || !lastName || !email || !phone || !message) {
      return res.status(400).json({
        success: false,
        message: 'All required fields must be provided'
      });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid email format'
      });
    }

    // Create new contact submission
    const submission = new ContactSubmission({
      firstName,
      lastName,
      email,
      phone,
      subject: subject || 'general',
      message,
      source,
      status: 'new'
    });

    await submission.save();

    // Send email notification to admin
    try {
      await sendAdminNotification(submission);
    } catch (emailError) {
      // console.error('Failed to send admin notification:', emailError);
      // Don't fail the submission if email fails
    }

    res.status(201).json({
      success: true,
      message: 'Contact form submitted successfully',
      submissionId: submission._id
    });

  } catch (error) {
    // console.error('Contact form submission error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error. Please try again later.'
    });
  }
};

// Get all contact submissions (Admin only)
const getAllSubmissions = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const status = req.query.status;
    const source = req.query.source;
    const search = req.query.search;

    // Build query
    let query = {};
    
    if (status) {
      query.status = status;
    }
    
    if (source) {
      query.source = source;
    }
    
    if (search) {
      query.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { message: { $regex: search, $options: 'i' } }
      ];
    }

    const submissions = await ContactSubmission.find(query)
      .sort({ submittedAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .exec();

    const total = await ContactSubmission.countDocuments(query);

    res.json({
      success: true,
      data: submissions,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    // console.error('Get submissions error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch submissions'
    });
  }
};

// Get submission by ID
const getSubmissionById = async (req, res) => {
  try {
    const submission = await ContactSubmission.findById(req.params.id);
    
    if (!submission) {
      return res.status(404).json({
        success: false,
        message: 'Submission not found'
      });
    }

    res.json({
      success: true,
      data: submission
    });

  } catch (error) {
    // console.error('Get submission error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch submission'
    });
  }
};

// Update submission status
const updateSubmissionStatus = async (req, res) => {
  try {
    const { status, adminNotes } = req.body;
    
    const submission = await ContactSubmission.findByIdAndUpdate(
      req.params.id,
      { 
        status: status || 'new',
        adminNotes: adminNotes || '',
        lastUpdated: new Date()
      },
      { new: true }
    );

    if (!submission) {
      return res.status(404).json({
        success: false,
        message: 'Submission not found'
      });
    }

    res.json({
      success: true,
      message: 'Submission updated successfully',
      data: submission
    });

  } catch (error) {
    // console.error('Update submission error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update submission'
    });
  }
};

// Delete submission
const deleteSubmission = async (req, res) => {
  try {
    const submission = await ContactSubmission.findByIdAndDelete(req.params.id);
    
    if (!submission) {
      return res.status(404).json({
        success: false,
        message: 'Submission not found'
      });
    }

    res.json({
      success: true,
      message: 'Submission deleted successfully'
    });

  } catch (error) {
    // console.error('Delete submission error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete submission'
    });
  }
};

// Get submission statistics
const getSubmissionStats = async (req, res) => {
  try {
    const stats = await ContactSubmission.aggregate([
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          new: { $sum: { $cond: [{ $eq: ['$status', 'new'] }, 1, 0] } },
          inProgress: { $sum: { $cond: [{ $eq: ['$status', 'in_progress'] }, 1, 0] } },
          resolved: { $sum: { $cond: [{ $eq: ['$status', 'resolved'] }, 1, 0] } },
          closed: { $sum: { $cond: [{ $eq: ['$status', 'closed'] }, 1, 0] } },
          contactPage: { $sum: { $cond: [{ $eq: ['$source', 'contact_page'] }, 1, 0] } },
          homePage: { $sum: { $cond: [{ $eq: ['$source', 'home_page'] }, 1, 0] } }
        }
      }
    ]);

    const result = stats[0] || {
      total: 0,
      new: 0,
      inProgress: 0,
      resolved: 0,
      closed: 0,
      contactPage: 0,
      homePage: 0
    };

    res.json({
      success: true,
      data: result
    });

  } catch (error) {
    // console.error('Get stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch statistics'
    });
  }
};

// Send admin notification email
const sendAdminNotification = async (submission) => {
  const mailOptions = {
    from: process.env.EMAIL_USER || 'your-email@gmail.com',
    to: process.env.ADMIN_EMAIL || 'admin@tega.com',
    subject: `New Contact Form Submission - ${submission.source === 'contact_page' ? 'Contact Page' : 'Home Page'}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #333; border-bottom: 2px solid #4F46E5; padding-bottom: 10px;">
          New Contact Form Submission
        </h2>
        
        <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <h3 style="color: #4F46E5; margin-top: 0;">Contact Information</h3>
          <p><strong>Name:</strong> ${submission.firstName} ${submission.lastName}</p>
          <p><strong>Email:</strong> ${submission.email}</p>
          <p><strong>Phone:</strong> ${submission.phone}</p>
          <p><strong>Subject:</strong> ${submission.subject}</p>
          <p><strong>Source:</strong> ${submission.source === 'contact_page' ? 'Contact Page' : 'Home Page'}</p>
          <p><strong>Submitted:</strong> ${new Date(submission.submittedAt).toLocaleString()}</p>
        </div>
        
        <div style="background-color: #ffffff; padding: 20px; border: 1px solid #e5e7eb; border-radius: 8px;">
          <h3 style="color: #4F46E5; margin-top: 0;">Message</h3>
          <p style="white-space: pre-wrap; line-height: 1.6;">${submission.message}</p>
        </div>
        
        <div style="margin-top: 20px; text-align: center;">
          <a href="${process.env.ADMIN_URL || 'http://localhost:3000'}/admin/contact-submissions" 
             style="background-color: #4F46E5; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; display: inline-block;">
            View in Admin Panel
          </a>
        </div>
      </div>
    `
  };

  await transporter.sendMail(mailOptions);
};

export {
  submitContactForm,
  getAllSubmissions,
  getSubmissionById,
  updateSubmissionStatus,
  deleteSubmission,
  getSubmissionStats
};
