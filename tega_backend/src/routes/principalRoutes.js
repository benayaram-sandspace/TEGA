import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import nodemailer from 'nodemailer';
import crypto from 'crypto';
import dotenv from 'dotenv';
import Student from '../models/Student.js';
import Principal from '../models/Principal.js';
import { getPasswordResetTemplate } from '../utils/emailTemplates.js';

// Ensure environment variables are loaded
dotenv.config();

const router = express.Router();

// Store OTPs temporarily (in production, use Redis)
const otpStore = new Map();

// Email transporter setup with optimized settings
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  },
  pool: true,
  maxConnections: 5,
  maxMessages: 100,
  rateLimit: 10
});



// Principal Login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    // Find principal
    const principal = await Principal.findOne({ email });
    if (principal) {
    }
    
    if (!principal) {
      return res.status(400).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Check password
    const isMatch = await bcrypt.compare(password, principal.password);
    if (!isMatch) {
      return res.status(400).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { 
        id: principal._id, 
        principalId: principal._id, 
        email: principal.email, 
        institute: principal.university, 
        university: principal.university 
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' } // 24 hours - actual logout controlled by 30-min inactivity timeout
    );

    res.json({
      success: true,
      message: 'Login successful',
      token,
      principal: {
        id: principal._id,
        principalName: principal.principalName,
        email: principal.email,
        gender: principal.gender,
        university: principal.university
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error during login'
    });
  }
});

// Forgot Password - Send OTP
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    // Check if principal exists
    const principal = await Principal.findOne({ email });
    if (!principal) {
      return res.status(404).json({
        success: false,
        message: 'Principal not found with this email'
      });
    }

    // Generate 6-digit OTP
    const otp = crypto.randomInt(100000, 999999).toString();
    
    // Store OTP with expiration (5 minutes)
    otpStore.set(email, {
      otp,
      expires: Date.now() + 10 * 60 * 1000,
      principalId: principal._id
    });

    // Send OTP email with optimized settings
    const principalName = principal.principalName || `${principal.firstName || ''} ${principal.lastName || ''}`.trim() || 'Principal';
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Password Reset OTP - TEGA Principal',
      html: getPasswordResetTemplate(principalName, otp),
      priority: 'high'
    };

    // Use Promise with timeout for faster failure detection
    const emailPromise = transporter.sendMail(mailOptions);
    const timeoutPromise = new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Email timeout after 15 seconds')), 15000)
    );
    
    try {
      await Promise.race([emailPromise, timeoutPromise]);
    } catch (emailError) {
      // Return OTP in development for testing
      return res.json({
        success: true,
        message: 'OTP generated (email failed - check console)',
        otp: process.env.NODE_ENV === 'development' ? otp : undefined,
        emailError: emailError.message
      });
    }

    res.json({
      success: true,
      message: 'OTP sent to your email'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Verify OTP and Reset Password
router.post('/reset-password', async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Email, OTP, and new password are required'
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters long'
      });
    }

    // Check if OTP exists and is valid
    const storedOTP = otpStore.get(email);
    if (!storedOTP) {
      return res.status(400).json({
        success: false,
        message: 'OTP not found or expired'
      });
    }

    if (Date.now() > storedOTP.expires) {
      otpStore.delete(email);
      return res.status(400).json({
        success: false,
        message: 'OTP has expired'
      });
    }

    if (storedOTP.otp !== otp) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    // Get principal details
    const principal = await Student.findById(storedOTP.principalId);
    if (!principal) {
      return res.status(404).json({
        success: false,
        message: 'Principal not found'
      });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Update principal password
    await Student.findByIdAndUpdate(principal._id, { password: hashedPassword });

    // Clear OTP
    otpStore.delete(email);

    res.json({
      success: true,
      message: 'Password reset successfully'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

// Principal Dashboard Data (College-specific)
router.get('/dashboard', async (req, res) => {
  try {
    const authHeader = req.header('Authorization');
    const token = authHeader?.startsWith('Bearer ') ? authHeader.replace('Bearer ', '') : authHeader;
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          message: 'Token expired. Please login again.',
          errorCode: 'TOKEN_EXPIRED'
        });
      } else if (error.name === 'JsonWebTokenError') {
        return res.status(401).json({
          success: false,
          message: 'Invalid token. Please login again.',
          errorCode: 'INVALID_TOKEN'
        });
      } else {
        return res.status(401).json({
          success: false,
          message: 'Authentication failed. Please login again.',
          errorCode: 'AUTH_FAILED'
        });
      }
    }
    const principal = await Principal.findById(decoded.principalId || decoded.id);
    if (principal) {
    } else {
      // Let's also try to find by email as a fallback
      const principalByEmail = await Principal.findOne({ email: decoded.email });
      if (principalByEmail) {
      }
    }
    
    if (!principal) {
      return res.status(401).json({
        success: false,
        message: 'Principal not found.'
      });
    }

    if (!principal.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Principal account deactivated.'
      });
    }

    // Get college-specific user data (users from the same university)
    const collegeStudents = await Student.find({ institute: principal.university })
      .select('username firstName lastName email institute course yearOfStudy createdAt accountStatus isActive')
      .sort({ createdAt: -1 })
      .limit(100);

    // Get statistics for this college only
    const totalCollegeStudents = await Student.countDocuments({ institute: principal.university });
    const recentCollegeRegistrations = await Student.countDocuments({
      institute: principal.university,
      createdAt: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
    });

    res.json({
      success: true,
      principal: {
        id: principal._id,
        principalName: principal.principalName,
        email: principal.email,
        university: principal.university
      },
      stats: {
        totalCollegeUsers: totalCollegeStudents,
        recentCollegeRegistrations
      },
      students: collegeStudents
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});


// Get students for the principal's college with advanced filtering and search
router.get('/students', async (req, res) => {
  try {
    const authHeader = req.header('Authorization');
    const token = authHeader?.startsWith('Bearer ') ? authHeader.replace('Bearer ', '') : authHeader;

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          message: 'Token expired. Please login again.',
          errorCode: 'TOKEN_EXPIRED'
        });
      } else if (error.name === 'JsonWebTokenError') {
        return res.status(401).json({
          success: false,
          message: 'Invalid token. Please login again.',
          errorCode: 'INVALID_TOKEN'
        });
      } else {
        return res.status(401).json({
          success: false,
          message: 'Authentication failed. Please login again.',
          errorCode: 'AUTH_FAILED'
        });
      }
    }
    
    const university = decoded.institute || decoded.university;

    if (!university) {
        return res.status(401).json({
            success: false,
            message: 'Invalid token: university not found.'
        });
    }

    // Extract query parameters for filtering and search
    const { 
      search, 
      status, 
      year, 
      course, 
      page = 1, 
      limit = 50,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    // Build filter object
    let filter = { institute: university };

    // Add search functionality
    if (search) {
      filter.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { username: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { studentId: { $regex: search, $options: 'i' } }
      ];
    }

    // Add status filter
    if (status) {
      if (status === 'pending') {
        filter.accountStatus = 'pending';
      } else if (status === 'approved') {
        filter.accountStatus = 'approved';
      } else if (status === 'rejected') {
        filter.accountStatus = 'rejected';
      } else if (status === 'active') {
        filter.isActive = true;
        filter.accountStatus = 'approved';
      } else if (status === 'inactive') {
        filter.isActive = false;
      }
    }

    // Add year filter
    if (year) {
      filter.yearOfStudy = parseInt(year);
    }

    // Add course filter
    if (course) {
      filter.course = { $regex: course, $options: 'i' };
    }

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Build sort object
    const sort = {};
    sort[sortBy] = sortOrder === 'desc' ? -1 : 1;

    // Execute query with pagination
    const students = await Student.find(filter)
      .select('firstName lastName username email studentId yearOfStudy course institute accountStatus isActive createdAt updatedAt phone gender dob address')
      .sort(sort)
      .skip(skip)
      .limit(parseInt(limit));

    // Get total count for pagination
    const totalStudents = await Student.countDocuments(filter);

    // Get statistics
    const stats = await Student.aggregate([
      { $match: { institute: university } },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          pending: { $sum: { $cond: [{ $eq: ['$accountStatus', 'pending'] }, 1, 0] } },
          approved: { $sum: { $cond: [{ $eq: ['$accountStatus', 'approved'] }, 1, 0] } },
          rejected: { $sum: { $cond: [{ $eq: ['$accountStatus', 'rejected'] }, 1, 0] } },
          active: { $sum: { $cond: [{ $eq: ['$isActive', true] }, 1, 0] } },
          inactive: { $sum: { $cond: [{ $eq: ['$isActive', false] }, 1, 0] } }
        }
      }
    ]);

    res.json({
      success: true,
      students,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(totalStudents / parseInt(limit)),
        totalStudents,
        hasNext: skip + students.length < totalStudents,
        hasPrev: parseInt(page) > 1
      },
      stats: stats[0] || {
        total: 0,
        pending: 0,
        approved: 0,
        rejected: 0,
        active: 0,
        inactive: 0
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to load student data'
    });
  }
});

// Get detailed student profile for principal
router.get('/students/:studentId', async (req, res) => {
  try {
    const authHeader = req.header('Authorization');
    const token = authHeader?.startsWith('Bearer ') ? authHeader.replace('Bearer ', '') : authHeader;

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          message: 'Token expired. Please login again.',
          errorCode: 'TOKEN_EXPIRED'
        });
      } else if (error.name === 'JsonWebTokenError') {
        return res.status(401).json({
          success: false,
          message: 'Invalid token. Please login again.',
          errorCode: 'INVALID_TOKEN'
        });
      } else {
        return res.status(401).json({
          success: false,
          message: 'Authentication failed. Please login again.',
          errorCode: 'AUTH_FAILED'
        });
      }
    }
    const university = decoded.institute || decoded.university;

    if (!university) {
        return res.status(401).json({
            success: false,
            message: 'Invalid token: university not found.'
        });
    }

    const { studentId } = req.params;

    // Find student by ID or studentId, ensuring they belong to the principal's university
    const student = await Student.findOne({
      $or: [{ _id: studentId }, { studentId: studentId }],
      institute: university
    }).select('-password -refreshToken');

    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found or access denied.'
      });
    }

    res.json({
      success: true,
      student
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to load student details'
    });
  }
});

// Export students data for principal
router.get('/students/export', async (req, res) => {
  try {
    const authHeader = req.header('Authorization');
    const token = authHeader?.startsWith('Bearer ') ? authHeader.replace('Bearer ', '') : authHeader;

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          message: 'Token expired. Please login again.',
          errorCode: 'TOKEN_EXPIRED'
        });
      } else if (error.name === 'JsonWebTokenError') {
        return res.status(401).json({
          success: false,
          message: 'Invalid token. Please login again.',
          errorCode: 'INVALID_TOKEN'
        });
      } else {
        return res.status(401).json({
          success: false,
          message: 'Authentication failed. Please login again.',
          errorCode: 'AUTH_FAILED'
        });
      }
    }
    const university = decoded.institute || decoded.university;

    if (!university) {
        return res.status(401).json({
            success: false,
            message: 'Invalid token: university not found.'
        });
    }

    const { format = 'json', status, year, course } = req.query;

    // Build filter object (same as students endpoint)
    let filter = { institute: university };

    if (status) {
      if (status === 'pending') {
        filter.accountStatus = 'pending';
      } else if (status === 'approved') {
        filter.accountStatus = 'approved';
      } else if (status === 'rejected') {
        filter.accountStatus = 'rejected';
      } else if (status === 'active') {
        filter.isActive = true;
        filter.accountStatus = 'approved';
      } else if (status === 'inactive') {
        filter.isActive = false;
      }
    }

    if (year) {
      filter.yearOfStudy = parseInt(year);
    }

    if (course) {
      filter.course = { $regex: course, $options: 'i' };
    }

    const students = await Student.find(filter)
      .select('firstName lastName username email studentId yearOfStudy course institute accountStatus isActive createdAt updatedAt phone gender dob address')
      .sort({ createdAt: -1 });

    if (format === 'csv') {
      // Convert to CSV format
      const csvHeader = 'Name,Username,Email,Student ID,Year,Course,Institute,Status,Active,Phone,Gender,DOB,Address,Registered Date\n';
      const csvData = students.map(student => {
        const name = `${student.firstName || ''} ${student.lastName || ''}`.trim();
        const status = student.accountStatus || 'unknown';
        const active = student.isActive ? 'Yes' : 'No';
        const registeredDate = student.createdAt ? new Date(student.createdAt).toLocaleDateString() : '';
        
        return `"${name}","${student.username || ''}","${student.email || ''}","${student.studentId || ''}","${student.yearOfStudy || ''}","${student.course || ''}","${student.institute || ''}","${status}","${active}","${student.phone || ''}","${student.gender || ''}","${student.dob || ''}","${student.address || ''}","${registeredDate}"`;
      }).join('\n');

      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename="students_${university}_${new Date().toISOString().split('T')[0]}.csv"`);
      res.send(csvHeader + csvData);
    } else {
      // Return JSON format
      res.json({
        success: true,
        data: students,
        exportedAt: new Date().toISOString(),
        totalRecords: students.length,
        university: university
      });
    }

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to export student data'
    });
  }
});

export default router;



