import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import nodemailer from 'nodemailer';
import crypto from 'crypto';
import dotenv from 'dotenv';
import Principal from '../models/Principal.js';
import Student from '../models/Student.js';
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
      { id: principal._id, email: principal.email, university: principal.university, role: 'principal' },
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
    const principal = await Principal.findById(storedOTP.principalId);
    if (!principal) {
      return res.status(404).json({
        success: false,
        message: 'Principal not found'
      });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Update principal password
    await Principal.findByIdAndUpdate(principal._id, { password: hashedPassword });

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

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const principal = await Principal.findById(decoded.id);
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
      .select('username firstName lastName email institute course year createdAt')
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


// Get students for the principal's college
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

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const university = decoded.university;

    if (!university) {
        return res.status(401).json({
            success: false,
            message: 'Invalid token: university not found.'
        });
    }

    // Get pagination parameters
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // Get search parameters
    const search = req.query.search || '';
    const statusFilter = req.query.status || '';
    const yearFilter = req.query.year || '';
    const courseFilter = req.query.course || '';

    // Build query
    let query = { institute: university };
    
    // Add search filter
    if (search) {
      query.$or = [
        { firstName: { $regex: search, $options: 'i' } },
        { lastName: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { studentId: { $regex: search, $options: 'i' } }
      ];
    }

    // Add status filter
    if (statusFilter) {
      query.accountStatus = statusFilter;
    }

    // Add year filter
    if (yearFilter) {
      query.yearOfStudy = yearFilter;
    }

    // Add course filter
    if (courseFilter) {
      query.course = { $regex: courseFilter, $options: 'i' };
    }

    // Get students with pagination
    const students = await Student.find(query)
      .select('firstName lastName email studentId yearOfStudy course accountStatus isActive createdAt')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    // Get total count for pagination
    const totalStudents = await Student.countDocuments(query);

    // Calculate stats
    const total = await Student.countDocuments({ institute: university });
    const pending = await Student.countDocuments({ institute: university, accountStatus: 'pending' });
    const approved = await Student.countDocuments({ institute: university, accountStatus: 'approved' });
    const rejected = await Student.countDocuments({ institute: university, accountStatus: 'rejected' });
    const active = await Student.countDocuments({ institute: university, isActive: true });
    const inactive = await Student.countDocuments({ institute: university, isActive: false });

    res.json({
      success: true,
      students,
      stats: {
        total,
        pending,
        approved,
        rejected,
        active,
        inactive
      },
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalStudents / limit),
        totalStudents,
        hasNext: page < Math.ceil(totalStudents / limit),
        hasPrev: page > 1
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to load student data'
    });
  }
});

export default router;
