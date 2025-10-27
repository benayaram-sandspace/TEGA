import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import nodemailer from 'nodemailer';
import crypto from 'crypto';
import dotenv from 'dotenv';
import Principal from '../models/Principal.js';
import Student from '../models/Student.js';
import { getPasswordResetTemplate } from '../utils/emailTemplates.js';
import config from '../config/environment.js';
import principalAuth from '../middleware/principalAuth.js';

// Ensure environment variables are loaded
dotenv.config();

const router = express.Router();

// Import storage service for OTP management
import storageService from '../services/storageService.js';

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
      config.JWT_SECRET,
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
    
    // Store OTP using storage service (5 minutes)
    await storageService.storeOTP(email, otp, 300);

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
    const storedOTP = await storageService.getOTP(email);
    if (!storedOTP) {
      return res.status(400).json({
        success: false,
        message: 'OTP not found or expired'
      });
    }

    if (storedOTP !== otp) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    // Get principal by email
    const principal = await Principal.findOne({ email });
    if (!principal) {
      return res.status(404).json({
        success: false,
        message: 'Principal not found'
      });
    }

    // Check if new password is same as old password
    const isSamePassword = await bcrypt.compare(newPassword, principal.password);
    if (isSamePassword) {
      return res.status(400).json({
        success: false,
        message: 'New password cannot be the same as your current password. Please choose a different password.'
      });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Update principal password
    await Principal.findByIdAndUpdate(principal._id, { password: hashedPassword });

    // Clear OTP
    await storageService.deleteOTP(email);

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
router.get('/dashboard', principalAuth, async (req, res) => {
  try {
    const principal = req.principal;

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
router.get('/students', principalAuth, async (req, res) => {
  try {
    const principal = req.principal;

    const university = principal.university;

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

// Get specific student details
router.get('/students/:studentId', principalAuth, async (req, res) => {
  try {
    const principal = req.principal;
    const { studentId } = req.params;
    const university = principal.university;

    const student = await Student.findOne({ 
      _id: studentId, 
      institute: university 
    }).select('-password');

    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found'
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

// Get Placement Readiness Data for Principal
router.get('/placement-readiness', async (req, res) => {
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

    if (!principal) {
      return res.status(404).json({
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

    // Get all students from the principal's university
    const students = await Student.find({ institute: principal.university })
      .select('_id firstName lastName email course');

    const studentIds = students.map(student => student._id);

    // Get all active jobs on the platform (matching the frontend query)
    // Include both 'open' and 'active' statuses as per the job controller
    const jobs = await Job.find({ 
      isActive: true, 
      status: { $in: ['open', 'active'] },
      postingType: 'job'  // Only include jobs, not internships
    }).select('title company location salary jobType');

    // Get all applications from students in this university
    const applications = await Application.find({ 
      studentId: { $in: studentIds } 
    }).populate('jobId', 'title company');

    // Calculate total applications
    const totalApplications = applications.length;
    const totalJobs = jobs.length;

    // Calculate job-wise statistics
    const jobStats = jobs.map(job => {
      const applicationsForJob = applications.filter(app => 
        app.jobId && app.jobId._id.toString() === job._id.toString()
      );
      
      return {
        jobTitle: job.title,
        company: job.company,
        applications: applicationsForJob.length,
        jobId: job._id
      };
    });

    // Sort by applications count (descending)
    jobStats.sort((a, b) => b.applications - a.applications);

    res.json({
      success: true,
      data: {
        totalJobs,
        totalApplications,
        jobStats,
        students: students.length
      }
    });

  } catch (error) {
    console.error('Placement readiness error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to load placement readiness data',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Export students data
router.get('/students/export', principalAuth, async (req, res) => {
  try {
    const principal = req.principal;

    const university = principal.university;
    const format = req.query.format || 'csv';

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
      query.yearOfStudy = parseInt(yearFilter);
    }

    // Add course filter
    if (courseFilter) {
      query.course = { $regex: courseFilter, $options: 'i' };
    }

    const students = await Student.find(query)
      .select('firstName lastName email studentId institute course yearOfStudy accountStatus isActive createdAt')
      .sort({ createdAt: -1 });

    if (format === 'csv') {
      // Convert to CSV format
      const csvHeader = 'Name,Email,Student ID,Institute,Course,Year,Status,Active,Registered\n';
      const csvData = students.map(student => {
        const name = `${student.firstName} ${student.lastName}`;
        const status = student.accountStatus || 'pending';
        const active = student.isActive ? 'Yes' : 'No';
        const registered = student.createdAt ? new Date(student.createdAt).toLocaleDateString() : 'Unknown';
        return `"${name}","${student.email}","${student.studentId}","${student.institute}","${student.course || 'Not specified'}","${student.yearOfStudy || 'Not specified'}","${status}","${active}","${registered}"`;
      }).join('\n');

      const csvContent = csvHeader + csvData;
      
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename="students_export_${new Date().toISOString().split('T')[0]}.csv"`);
      res.send(csvContent);
    } else {
      // Return JSON format
      res.json({
        success: true,
        data: students
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to export student data'
    });
  }
});

// Update Principal Account Information
router.put('/account', async (req, res) => {
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
    
    if (!principal) {
      return res.status(404).json({
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

    const { principalName, email, phone, designation } = req.body;

    // Validate required fields
    if (!principalName || !email || !phone) {
      return res.status(400).json({
        success: false,
        message: 'Principal name, email, and phone are required.'
      });
    }

    // Check if email is already taken by another principal
    if (email !== principal.email) {
      const existingPrincipal = await Principal.findOne({ email, _id: { $ne: principal._id } });
      if (existingPrincipal) {
        return res.status(400).json({
          success: false,
          message: 'Email is already taken by another principal.'
        });
      }
    }

    // Update principal information
    principal.principalName = principalName;
    principal.email = email;
    principal.phone = phone;
    principal.designation = designation || principal.designation;
    principal.updatedAt = new Date();

    await principal.save();

    res.json({
      success: true,
      message: 'Account information updated successfully.',
      principal: {
        id: principal._id,
        principalName: principal.principalName,
        email: principal.email,
        phone: principal.phone,
        designation: principal.designation,
        university: principal.university,
        college: principal.college
      }
    });

  } catch (error) {
    console.error('Account update error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update account information.'
    });
  }
});

// Update Principal College Information
router.put('/college', async (req, res) => {
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
    
    if (!principal) {
      return res.status(404).json({
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

    const { 
      collegeName, 
      university, 
      address, 
      city, 
      state, 
      pincode, 
      website, 
      phone, 
      email, 
      establishedYear, 
      accreditation 
    } = req.body;

    // Validate required fields
    if (!collegeName || !university || !address || !city || !state || !pincode) {
      return res.status(400).json({
        success: false,
        message: 'College name, university, address, city, state, and pincode are required.'
      });
    }

    // Update college information
    principal.college = collegeName;
    principal.university = university;
    principal.address = address;
    principal.city = city;
    principal.state = state;
    principal.pincode = pincode;
    principal.website = website || principal.website;
    principal.phone = phone || principal.phone;
    principal.email = email || principal.email;
    principal.establishedYear = establishedYear || principal.establishedYear;
    principal.accreditation = accreditation || principal.accreditation;
    principal.updatedAt = new Date();

    await principal.save();

    res.json({
      success: true,
      message: 'College information updated successfully.',
      principal: {
        id: principal._id,
        principalName: principal.principalName,
        email: principal.email,
        phone: principal.phone,
        designation: principal.designation,
        college: principal.college,
        university: principal.university,
        address: principal.address,
        city: principal.city,
        state: principal.state,
        pincode: principal.pincode,
        website: principal.website,
        establishedYear: principal.establishedYear,
        accreditation: principal.accreditation
      }
    });

  } catch (error) {
    console.error('College update error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update college information.'
    });
  }
});

// Get Course Engagement Statistics
router.get('/course-engagement', async (req, res) => {
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

    if (!principal) {
      return res.status(404).json({
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

    // Import models
    const RealTimeCourse = (await import('../models/RealTimeCourse.js')).default;
    const RealTimeProgress = (await import('../models/RealTimeProgress.js')).default;
    const Enrollment = (await import('../models/Enrollment.js')).default;

    // Get all students from the principal's university
    const students = await Student.find({ institute: principal.university })
      .select('_id')
      .lean();

    const studentIds = students.map(student => student._id);

    // Get all courses
    const courses = await RealTimeCourse.find()
      .select('title category modules')
      .lean();

    // Get all enrollments for students from this university
    const enrollments = await Enrollment.find({
      studentId: { $in: studentIds },
      status: 'active'
    }).lean();

    // Get all progress records for students from this university
    const progressRecords = await RealTimeProgress.find({
      studentId: { $in: studentIds }
    }).lean();

    // Calculate statistics for each course
    const courseStats = courses.map(course => {
      // Get enrollments for this course
      const courseEnrollments = enrollments.filter(e => 
        e.courseId.toString() === course._id.toString()
      );

      // Get progress records for this course
      const courseProgress = progressRecords.filter(p => 
        p.courseId.toString() === course._id.toString()
      );

      // Calculate average completion
      const avgCompletion = courseProgress.length > 0
        ? Math.round(
            courseProgress.reduce((sum, p) => sum + (p.overallProgress?.percentage || 0), 0) / courseProgress.length
          )
        : 0;

      return {
        _id: course._id,
        title: course.title,
        category: course.category,
        students: courseEnrollments.length,
        completion: avgCompletion
      };
    });

    // Calculate total statistics
    const totalStudents = enrollments.length;
    const totalCourses = courses.length;
    const avgCompletion = progressRecords.length > 0
      ? Math.round(
          progressRecords.reduce((sum, p) => sum + (p.overallProgress?.percentage || 0), 0) / progressRecords.length
        )
      : 0;

    res.json({
      success: true,
      data: {
        courses: courseStats,
        totalStudents,
        totalCourses,
        avgCompletion
      }
    });

  } catch (error) {
    console.error('Course engagement error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to load course engagement data',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Change Principal Password
router.post('/change-password', async (req, res) => {
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
    
    if (!principal) {
      return res.status(404).json({
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

    const { currentPassword, newPassword } = req.body;

    // Validate required fields
    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Current password and new password are required.'
      });
    }

    // Verify current password
    const isCurrentPasswordValid = await bcrypt.compare(currentPassword, principal.password);
    if (!isCurrentPasswordValid) {
      return res.status(400).json({
        success: false,
        message: 'Current password is incorrect.'
      });
    }

    // Validate new password strength
    if (newPassword.length < 8) {
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 8 characters long.'
      });
    }

    // Check if new password is different from current
    if (currentPassword === newPassword) {
      return res.status(400).json({
        success: false,
        message: 'New password must be different from current password.'
      });
    }

    // Hash new password
    const saltRounds = 12;
    const hashedNewPassword = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    principal.password = hashedNewPassword;
    principal.updatedAt = new Date();

    await principal.save();

    res.json({
      success: true,
      message: 'Password changed successfully.'
    });

  } catch (error) {
    console.error('Password change error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to change password.'
    });
  }
});

export default router;
