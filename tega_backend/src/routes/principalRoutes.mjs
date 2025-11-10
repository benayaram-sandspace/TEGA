import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import nodemailer from 'nodemailer';
import crypto from 'crypto';
import dotenv from 'dotenv';
import mongoose from 'mongoose';
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
        message: 'OTP generated',
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

    // Calculate active students (students with recent activity - last 7 days)
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    
    // Get students with recent enrollment activity
    const Enrollment = (await import('../models/Enrollment.js')).default;
    const RealTimeProgress = (await import('../models/RealTimeProgress.js')).default;
    
    const studentIds = collegeStudents.map(s => s._id || s.id);
    
    // Find students with recent course access (from enrollments)
    const recentEnrollments = await Enrollment.find({
      studentId: { $in: studentIds },
      lastAccessedAt: { $gte: sevenDaysAgo }
    }).distinct('studentId');
    
    // Find students with recent progress activity
    const recentProgress = await RealTimeProgress.find({
      studentId: { $in: studentIds },
      $or: [
        { lastAccessedAt: { $gte: sevenDaysAgo } },
        { 'overallProgress.lastAccessedAt': { $gte: sevenDaysAgo } }
      ]
    }).distinct('studentId');
    
    // Combine both sets of active student IDs
    const activeStudentIds = new Set([
      ...recentEnrollments.map(id => String(id)),
      ...recentProgress.map(id => String(id))
    ]);
    
    // Count unique active students
    const activeStudentsCount = activeStudentIds.size;
    
    // Mark students as active in the response
    const studentsWithActivity = collegeStudents.map(student => ({
      ...student.toObject(),
      isActive: activeStudentIds.has(String(student._id || student.id))
    }));

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
        recentCollegeRegistrations,
        activeStudents: activeStudentsCount
      },
      students: studentsWithActivity
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

// Get specific student details with enrollments and progress
router.get('/students/:studentId', principalAuth, async (req, res) => {
  try {
    const principal = req.principal;
    const { studentId } = req.params;
    const university = principal.university;

    // Validate studentId format
    if (!mongoose.Types.ObjectId.isValid(studentId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid student ID format'
      });
    }

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

    // Get student's enrollments and progress
    const Enrollment = (await import('../models/Enrollment.js')).default;
    const RealTimeProgress = (await import('../models/RealTimeProgress.js')).default;
    const RealTimeCourse = (await import('../models/RealTimeCourse.js')).default;
    
    // Fetch all enrollments for this student
    const enrollments = await Enrollment.find({ 
      studentId: studentId,
      status: 'active'
    }).lean();
    
    // Fetch all progress records for this student with full details
    let progressRecords = [];
    try {
      progressRecords = await RealTimeProgress.find({ 
        studentId: studentId 
      })
      .populate('courseId', 'title category thumbnail modules')
      .select('courseId overallProgress moduleProgress lectureProgress isCompleted completedAt enrolledAt lastUpdatedAt')
      .lean();
    } catch (progressError) {
      // Continue with empty progress records if there's an error
      progressRecords = [];
    }
    
    // Combine enrollment and progress data
    const coursesWithProgress = [];
    const courseIds = new Set();
    
    // Process enrollments
    for (const enrollment of enrollments) {
      // Handle both ObjectId and string courseId
      const rawCourseId = enrollment.courseId?._id || enrollment.courseId;
      if (!rawCourseId) continue;
      
      const courseId = String(rawCourseId);
      if (courseId === 'undefined' || courseId === 'null' || courseId === '') continue;
      
      if (!courseIds.has(courseId)) {
        courseIds.add(courseId);
        
        // Find corresponding progress - handle both populated and non-populated courseId
        const progress = progressRecords.find(p => {
          const pCourseId = String(p.courseId?._id || p.courseId || '');
          return pCourseId === courseId && pCourseId !== 'undefined' && pCourseId !== 'null';
        });
        
        // Fetch course details with modules/lectures count
        let courseDetails = null;
        let totalModules = 0;
        let totalLecturesCount = 0;
        
        try {
          // Validate courseId before querying
          if (mongoose.Types.ObjectId.isValid(courseId)) {
            courseDetails = await RealTimeCourse.findById(courseId).select('title category thumbnail modules').lean();
            
            // Calculate total modules and lectures
            if (courseDetails?.modules && Array.isArray(courseDetails.modules)) {
              totalModules = courseDetails.modules.length;
              totalLecturesCount = courseDetails.modules.reduce((sum, module) => {
                return sum + (module.lectures?.length || 0);
              }, 0);
            }
          }
        } catch (err) {
        }
        
        // Extract complete progress data safely
        const overallProgress = progress?.overallProgress || {};
        let progressPercentage = 0;
        
        if (typeof overallProgress === 'number') {
          progressPercentage = overallProgress;
        } else if (overallProgress && typeof overallProgress === 'object') {
          progressPercentage = overallProgress?.percentage || 0;
        }
        
        // Calculate actual completed lectures from lectureProgress array if available
        let actualCompletedLectures = 0;
        if (overallProgress?.completedLectures !== undefined) {
          actualCompletedLectures = overallProgress.completedLectures;
        }
        if (progress?.lectureProgress && Array.isArray(progress.lectureProgress)) {
          const completedFromArray = progress.lectureProgress.filter(l => l.isCompleted === true).length;
          // Use the higher value
          actualCompletedLectures = Math.max(actualCompletedLectures, completedFromArray);
        }
        
        // Get total from progress or course details
        const finalTotalLectures = overallProgress?.totalLectures || totalLecturesCount || 0;
        const finalTotalModules = overallProgress?.totalModules || totalModules || 0;
        
        // Calculate time spent - sum from lectureProgress or use overallProgress
        let calculatedTimeSpent = overallProgress?.timeSpent || 0;
        if (progress?.lectureProgress && Array.isArray(progress.lectureProgress)) {
          const calculatedFromArray = progress.lectureProgress.reduce((sum, lecture) => {
            return sum + (Number(lecture.timeSpent) || 0);
          }, 0);
          // Use the higher value between calculated and stored
          calculatedTimeSpent = Math.max(calculatedTimeSpent, calculatedFromArray);
        }
        
        // Calculate completed modules
        let completedModulesCount = overallProgress?.completedModules || 0;
        if (progress?.moduleProgress && Array.isArray(progress.moduleProgress)) {
          const completedFromArray = progress.moduleProgress.filter(m => m.isCompleted === true).length;
          completedModulesCount = Math.max(completedModulesCount, completedFromArray);
        }
        
        coursesWithProgress.push({
          courseId: courseId,
          courseName: courseDetails?.title || enrollment.courseName || 'Unknown Course',
          category: courseDetails?.category || 'General',
          thumbnail: courseDetails?.thumbnail || null,
          enrolledAt: enrollment.enrolledAt || enrollment.createdAt || progress?.enrolledAt,
          lastAccessedAt: enrollment.lastAccessedAt || progress?.lastUpdatedAt || overallProgress?.lastAccessedAt || new Date(),
          progressPercentage: Math.round(progressPercentage),
          totalLectures: finalTotalLectures,
          completedLectures: actualCompletedLectures,
          totalModules: finalTotalModules,
          completedModules: completedModulesCount,
          isCompleted: progress?.isCompleted || progressPercentage === 100,
          completedAt: progress?.completedAt || null,
          timeSpent: Math.round(calculatedTimeSpent),
          moduleProgress: progress?.moduleProgress || [],
          lectureProgress: progress?.lectureProgress || []
        });
      }
    }
    
    // Process progress records that might not have enrollments
    for (const progress of progressRecords) {
      // Handle populated courseId
      const rawCourseId = progress.courseId?._id || progress.courseId;
      if (!rawCourseId) continue;
      
      const courseId = String(rawCourseId);
      if (courseId === 'undefined' || courseId === 'null' || courseId === '') continue;
      
      if (!courseIds.has(courseId)) {
        courseIds.add(courseId);
        
        // Get course details - either from populated data or fetch it
        let courseDetails = null;
        if (progress.courseId && typeof progress.courseId === 'object' && progress.courseId.title) {
          // Already populated
          courseDetails = progress.courseId;
        } else if (mongoose.Types.ObjectId.isValid(courseId)) {
          // Need to fetch
          try {
            courseDetails = await RealTimeCourse.findById(courseId).select('title category thumbnail modules').lean();
          } catch (err) {
          }
        }
        
        // Calculate total modules and lectures
        let totalModules = 0;
        let totalLecturesCount = 0;
        
        if (courseDetails?.modules && Array.isArray(courseDetails.modules)) {
          totalModules = courseDetails.modules.length;
          totalLecturesCount = courseDetails.modules.reduce((sum, module) => {
            return sum + (module.lectures?.length || 0);
          }, 0);
        }
        
        // Extract complete progress data safely (for progress records without enrollments)
        const overallProgress = progress?.overallProgress || {};
        let progressPercentage = 0;
        
        if (typeof overallProgress === 'number') {
          progressPercentage = overallProgress;
        } else if (overallProgress && typeof overallProgress === 'object') {
          progressPercentage = overallProgress?.percentage || 0;
        }
        
        // Calculate actual completed lectures from lectureProgress array if available
        let actualCompletedLectures = 0;
        if (overallProgress?.completedLectures !== undefined) {
          actualCompletedLectures = overallProgress.completedLectures;
        }
        if (progress?.lectureProgress && Array.isArray(progress.lectureProgress)) {
          const completedFromArray = progress.lectureProgress.filter(l => l.isCompleted === true).length;
          // Use the higher value
          actualCompletedLectures = Math.max(actualCompletedLectures, completedFromArray);
        }
        
        // Get total from progress or course details
        const finalTotalLectures = overallProgress?.totalLectures || totalLecturesCount || 0;
        const finalTotalModules = overallProgress?.totalModules || totalModules || 0;
        
        // Calculate time spent - sum from lectureProgress or use overallProgress
        let calculatedTimeSpent = overallProgress?.timeSpent || 0;
        if (progress?.lectureProgress && Array.isArray(progress.lectureProgress)) {
          const calculatedFromArray = progress.lectureProgress.reduce((sum, lecture) => {
            return sum + (Number(lecture.timeSpent) || 0);
          }, 0);
          // Use the higher value between calculated and stored
          calculatedTimeSpent = Math.max(calculatedTimeSpent, calculatedFromArray);
        }
        
        // Calculate completed modules
        let completedModulesCount = overallProgress?.completedModules || 0;
        if (progress?.moduleProgress && Array.isArray(progress.moduleProgress)) {
          const completedFromArray = progress.moduleProgress.filter(m => m.isCompleted === true).length;
          completedModulesCount = Math.max(completedModulesCount, completedFromArray);
        }
        
        coursesWithProgress.push({
          courseId: courseId,
          courseName: courseDetails?.title || 'Unknown Course',
          category: courseDetails?.category || 'General',
          thumbnail: courseDetails?.thumbnail || null,
          enrolledAt: progress.enrolledAt || progress.createdAt || new Date(),
          lastAccessedAt: progress.lastUpdatedAt || overallProgress?.lastAccessedAt || new Date(),
          progressPercentage: Math.round(progressPercentage),
          totalLectures: finalTotalLectures,
          completedLectures: actualCompletedLectures,
          totalModules: finalTotalModules,
          completedModules: completedModulesCount,
          isCompleted: progress?.isCompleted || progressPercentage === 100,
          completedAt: progress?.completedAt || null,
          timeSpent: Math.round(calculatedTimeSpent),
          moduleProgress: progress?.moduleProgress || [],
          lectureProgress: progress?.lectureProgress || []
        });
      }
    }
    
    // Sort by last accessed date (most recent first)
    coursesWithProgress.sort((a, b) => 
      new Date(b.lastAccessedAt || 0) - new Date(a.lastAccessedAt || 0)
    );

    res.json({
      success: true,
      student: {
        ...student.toObject(),
        enrolledCoursesCount: coursesWithProgress.length
      },
      courses: coursesWithProgress
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to load student details',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Get Course Enrollment Statistics for Principal
router.get('/course-enrollments', principalAuth, async (req, res) => {
  try {
    const principal = req.principal;
    const university = principal.university;

    const Enrollment = (await import('../models/Enrollment.js')).default;
    const UserCourse = (await import('../models/UserCourse.js')).default;
    const RealTimeProgress = (await import('../models/RealTimeProgress.js')).default;
    const RealTimeCourse = (await import('../models/RealTimeCourse.js')).default;
    const Course = (await import('../models/Course.js')).default;
    const Student = (await import('../models/Student.js')).default;

    // Get all students from this institute
    const instituteStudents = await Student.find({ institute: university }).select('_id').lean();
    const instituteStudentIds = instituteStudents.map(s => s._id);

    if (instituteStudentIds.length === 0) {
      return res.json({
        success: true,
        courseEnrollments: []
      });
    }

    // Get all enrollments for students from this institute (from Enrollment model)
    // Include both active and inactive (to get complete picture)
    const enrollments = await Enrollment.find({
      studentId: { $in: instituteStudentIds },
      $or: [
        { status: 'active' },
        { isActive: true },
        { status: { $exists: false } }, // Include if status field doesn't exist
        { isActive: { $exists: false } } // Include if isActive field doesn't exist
      ]
    }).select('courseId studentId').lean();

    // Get all user courses for students from this institute (from UserCourse model - for regular courses)
    let userCourses = [];
    try {
      userCourses = await UserCourse.find({
        studentId: { $in: instituteStudentIds },
        $or: [
          { isActive: true },
          { isActive: { $exists: false } } // Include if isActive field doesn't exist
        ]
      }).select('courseId studentId').lean();
    } catch (userCourseError) {
    }

    // Get all progress records (RealTimeProgress) - also indicates enrollment
    let progressRecords = [];
    try {
      progressRecords = await RealTimeProgress.find({
        studentId: { $in: instituteStudentIds }
      }).select('courseId studentId').lean();
    } catch (progressError) {
    }

    // Get all courses (both real-time and regular)
    const [realTimeCourses, regularCourses] = await Promise.all([
      RealTimeCourse.find({}).select('_id title category').lean().catch(() => []),
      Course.find({}).select('_id courseName category').lean().catch(() => [])
    ]);

    // Count enrollments per course from all sources (avoiding double-counting)
    const enrollmentCounts = {};
    const countedEnrollments = new Set(); // Track unique student-course combinations
    
    // Helper function to safely extract and stringify ObjectId
    const safeStringifyId = (id) => {
      if (!id) return null;
      if (typeof id === 'object' && id._id) return String(id._id);
      if (typeof id === 'object' && id.toString) return String(id);
      return String(id);
    };
    
    // Count from Enrollment model
    enrollments.forEach(enrollment => {
      const rawCourseId = enrollment.courseId;
      const rawStudentId = enrollment.studentId;
      
      if (rawCourseId && rawStudentId) {
        const courseId = safeStringifyId(rawCourseId);
        const studentId = safeStringifyId(rawStudentId);
        
        if (courseId && studentId && 
            courseId !== 'undefined' && courseId !== 'null' && courseId !== '' &&
            studentId !== 'undefined' && studentId !== 'null' && studentId !== '') {
          const key = `${courseId}_${studentId}`;
          
          if (!countedEnrollments.has(key)) {
            enrollmentCounts[courseId] = (enrollmentCounts[courseId] || 0) + 1;
            countedEnrollments.add(key);
          }
        }
      }
    });

    // Count from UserCourse model (for regular courses) - only if not already counted
    userCourses.forEach(userCourse => {
      const rawCourseId = userCourse.courseId;
      const rawStudentId = userCourse.studentId;
      
      if (rawCourseId && rawStudentId) {
        const courseId = safeStringifyId(rawCourseId);
        const studentId = safeStringifyId(rawStudentId);
        
        if (courseId && studentId && 
            courseId !== 'undefined' && courseId !== 'null' && courseId !== '' &&
            studentId !== 'undefined' && studentId !== 'null' && studentId !== '') {
          const key = `${courseId}_${studentId}`;
          
          if (!countedEnrollments.has(key)) {
            enrollmentCounts[courseId] = (enrollmentCounts[courseId] || 0) + 1;
            countedEnrollments.add(key);
          }
        }
      }
    });
    
    // Count from RealTimeProgress (students with progress are enrolled) - only if not already counted
    progressRecords.forEach(progress => {
      const rawCourseId = progress.courseId;
      const rawStudentId = progress.studentId;
      
      if (rawCourseId && rawStudentId) {
        const courseId = safeStringifyId(rawCourseId);
        const studentId = safeStringifyId(rawStudentId);
        
        if (courseId && studentId && 
            courseId !== 'undefined' && courseId !== 'null' && courseId !== '' &&
            studentId !== 'undefined' && studentId !== 'null' && studentId !== '') {
          const key = `${courseId}_${studentId}`;
          
          // Only count if not already counted from Enrollment or UserCourse
          if (!countedEnrollments.has(key)) {
            enrollmentCounts[courseId] = (enrollmentCounts[courseId] || 0) + 1;
            countedEnrollments.add(key);
          }
        }
      }
    });

    // Combine course data with enrollment counts
    const courseEnrollments = [];

    // Process real-time courses
    realTimeCourses.forEach(course => {
      const courseId = String(course._id);
      if (courseId && courseId !== 'undefined' && courseId !== 'null') {
        courseEnrollments.push({
          courseId,
          courseName: course.title || 'Unknown Course',
          category: course.category || 'General',
          enrollments: enrollmentCounts[courseId] || 0
        });
      }
    });

    // Process regular courses
    regularCourses.forEach(course => {
      const courseId = String(course._id);
      if (courseId && courseId !== 'undefined' && courseId !== 'null') {
        // Avoid duplicates if course exists in both
        if (!courseEnrollments.find(c => c.courseId === courseId)) {
          courseEnrollments.push({
            courseId,
            courseName: course.courseName || 'Unknown Course',
            category: course.category || 'General',
            enrollments: enrollmentCounts[courseId] || 0
          });
        }
      }
    });

    // Filter out courses with invalid names and sort by enrollment count (descending)
    const validCourses = courseEnrollments
      .filter(c => c.courseName && c.courseName !== 'Unknown Course')
      .sort((a, b) => b.enrollments - a.enrollments);

    // Calculate total students in institute
    const totalInstituteStudents = instituteStudentIds.length;

    res.json({
      success: true,
      courseEnrollments: validCourses,
      totalInstituteStudents: totalInstituteStudents
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to load course enrollment data',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Get Top Performing Students based on TEGA Exam Results
router.get('/top-students-tega-exam', principalAuth, async (req, res) => {
  try {
    const principal = req.principal;
    const university = principal.university;

    const ExamAttempt = (await import('../models/ExamAttempt.js')).default;
    const Exam = (await import('../models/Exam.js')).default;
    const Student = (await import('../models/Student.js')).default;

    // Get all students from this institute (case-insensitive matching)
    const instituteStudents = await Student.find({ 
      institute: { $regex: new RegExp(`^${university}$`, 'i') }
    })
      .select('_id firstName lastName email course institute')
      .lean();
    
    const instituteStudentIds = instituteStudents.map(s => s._id);

    if (instituteStudentIds.length === 0) {
      return res.json({
        success: true,
        topStudents: [],
        debug: {
          university,
          studentsFound: 0
        }
      });
    }

    // Get all TEGA exams (where isTegaExam: true) - include inactive too for testing
    const tegaExams = await Exam.find({ isTegaExam: true })
      .select('_id title subject isActive')
      .lean();
    
    const tegaExamIds = tegaExams.map(e => e._id);

    if (tegaExamIds.length === 0) {
      return res.json({
        success: true,
        topStudents: [],
        debug: {
          university,
          studentsFound: instituteStudentIds.length,
          tegaExamsFound: 0
        }
      });
    }

    // First, let's check ALL exam attempts (regardless of status) for debugging
    const allAttemptsCount = await ExamAttempt.countDocuments({
      studentId: { $in: instituteStudentIds },
      examId: { $in: tegaExamIds }
    });

    const completedAttemptsCount = await ExamAttempt.countDocuments({
      studentId: { $in: instituteStudentIds },
      examId: { $in: tegaExamIds },
      status: 'completed'
    });

    // Get all completed TEGA exam attempts for students from this institute
    let examAttempts = await ExamAttempt.find({
      studentId: { $in: instituteStudentIds },
      examId: { $in: tegaExamIds },
      status: 'completed'
    })
      .populate('studentId', 'firstName lastName email course institute')
      .populate('examId', 'title subject isTegaExam')
      .select('studentId examId score percentage totalMarks correctAnswers wrongAnswers createdAt published')
      .sort({ percentage: -1, score: -1 })
      .lean();
    
    // Filter to only TEGA exams (double-check in case populate didn't filter correctly)
    examAttempts = examAttempts.filter(attempt => {
      const isTegaExam = attempt.examId?.isTegaExam === true || 
                         tegaExamIds.some(id => String(id) === String(attempt.examId?._id));
      return isTegaExam;
    });
 
    if (examAttempts.length === 0) {
      return res.json({
        success: true,
        topStudents: [],
        debug: {
          university,
          studentsFound: instituteStudentIds.length,
          tegaExamsFound: tegaExamIds.length,
          examAttemptsFound: 0,
          message: 'No completed TEGA exam attempts found for students from this institute'
        }
      });
    }

    // Group by student and calculate average scores
    const studentPerformance = {};
    
    examAttempts.forEach(attempt => {
      const studentId = String(attempt.studentId._id);
      
      if (!studentPerformance[studentId]) {
        studentPerformance[studentId] = {
          studentId: studentId,
          firstName: attempt.studentId.firstName || '',
          lastName: attempt.studentId.lastName || '',
          email: attempt.studentId.email || '',
          course: attempt.studentId.course || 'N/A',
          examScores: [],
          totalScore: 0,
          totalPercentage: 0,
          examCount: 0,
          avgPercentage: 0,
          highestScore: 0,
          subjects: new Set()
        };
      }
      
      const perf = studentPerformance[studentId];
      perf.examScores.push({
        score: attempt.score || 0,
        percentage: attempt.percentage || 0,
        examTitle: attempt.examId?.title || 'Unknown Exam',
        subject: attempt.examId?.subject || 'General',
        totalMarks: attempt.totalMarks || 0
      });
      
      perf.totalScore += attempt.score || 0;
      perf.totalPercentage += attempt.percentage || 0;
      perf.examCount += 1;
      perf.highestScore = Math.max(perf.highestScore, attempt.percentage || 0);
      
      if (attempt.examId?.subject) {
        perf.subjects.add(attempt.examId.subject);
      }
    });

    // Calculate averages and convert to array
    const topStudents = Object.values(studentPerformance).map(perf => {
      perf.avgPercentage = perf.examCount > 0 
        ? Math.round(perf.totalPercentage / perf.examCount) 
        : 0;
      perf.subjects = Array.from(perf.subjects);
      return perf;
    });

    // Sort by average percentage (descending), then by highest score
    topStudents.sort((a, b) => {
      if (b.avgPercentage !== a.avgPercentage) {
        return b.avgPercentage - a.avgPercentage;
      }
      return b.highestScore - a.highestScore;
    });

    // Limit to top 10 and format response
    const formattedStudents = topStudents.slice(0, 10).map((student, index) => ({
      rank: index + 1,
      name: `${student.firstName} ${student.lastName}`.trim() || student.email,
      score: student.avgPercentage, // Average percentage across all TEGA exams
      highestScore: student.highestScore,
      skills: student.subjects.slice(0, 3), // Top 3 subjects as skills
      examCount: student.examCount,
      course: student.course,
      email: student.email
    }));

    res.json({
      success: true,
      topStudents: formattedStudents,
      totalStudents: topStudents.length,
      debug: process.env.NODE_ENV === 'development' ? {
        university,
        studentsFound: instituteStudentIds.length,
        tegaExamsFound: tegaExamIds.length,
        examAttemptsFound: examAttempts.length,
        studentsWithResults: topStudents.length
      } : undefined
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to load top performing students',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// Get Trend Analysis Data for Principal
router.get('/trend-analysis', principalAuth, async (req, res) => {
  try {
    const principal = req.principal;
    const university = principal.university;
    const period = parseInt(req.query.period) || 30; // days

    const Student = (await import('../models/Student.js')).default;
    const Enrollment = (await import('../models/Enrollment.js')).default;
    const RealTimeProgress = (await import('../models/RealTimeProgress.js')).default;

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - period);

    // Determine time intervals based on period
    let intervalDays = 1; // Default to daily
    if (period <= 30) {
      intervalDays = 1; // Daily for 30 days
    } else if (period <= 90) {
      intervalDays = 7; // Weekly for 90 days
    } else {
      intervalDays = 30; // Monthly for 180+ days
    }

    const trendData = [];
    const intervals = Math.ceil(period / intervalDays);

    // Get all students from this institute
    const instituteStudents = await Student.find({ 
      institute: { $regex: new RegExp(`^${university}$`, 'i') }
    }).select('_id createdAt').lean();

    const instituteStudentIds = instituteStudents.map(s => s._id);

    // Calculate data for each interval
    for (let i = 0; i < intervals; i++) {
      const intervalStart = new Date(startDate);
      intervalStart.setDate(intervalStart.getDate() + (i * intervalDays));
      
      const intervalEnd = new Date(intervalStart);
      intervalEnd.setDate(intervalEnd.getDate() + intervalDays);

      // Total students registered up to this point
      const totalStudents = await Student.countDocuments({
        institute: { $regex: new RegExp(`^${university}$`, 'i') },
        createdAt: { $lte: intervalEnd }
      });

      // Active students (with activity in last 7 days from this interval)
      const activeStartDate = new Date(intervalEnd);
      activeStartDate.setDate(activeStartDate.getDate() - 7);

      const recentEnrollments = await Enrollment.find({
        studentId: { $in: instituteStudentIds },
        lastAccessedAt: { $gte: activeStartDate, $lte: intervalEnd }
      }).distinct('studentId');

      const recentProgress = await RealTimeProgress.find({
        studentId: { $in: instituteStudentIds },
        $or: [
          { lastUpdatedAt: { $gte: activeStartDate, $lte: intervalEnd } },
          { 'overallProgress.lastAccessedAt': { $gte: activeStartDate, $lte: intervalEnd } }
        ]
      }).distinct('studentId');

      const activeStudentIds = new Set([
        ...recentEnrollments.map(id => String(id)),
        ...recentProgress.map(id => String(id))
      ]);
      const activeStudents = activeStudentIds.size;

      // Completed courses (courses with 100% progress or isCompleted: true)
      const completedCourses = await RealTimeProgress.countDocuments({
        studentId: { $in: instituteStudentIds },
        $or: [
          { isCompleted: true, completedAt: { $lte: intervalEnd } },
          { 'overallProgress.percentage': 100 }
        ]
      });

      // Format date label
      let dateLabel;
      if (intervalDays === 1) {
        dateLabel = intervalStart.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
      } else if (intervalDays === 7) {
        const weekEnd = new Date(intervalEnd);
        weekEnd.setDate(weekEnd.getDate() - 1);
        dateLabel = `Week ${i + 1} (${intervalStart.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} - ${weekEnd.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })})`;
      } else {
        dateLabel = intervalStart.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
      }

      trendData.push({
        date: dateLabel,
        students: totalStudents,
        active: activeStudents,
        completed: completedCourses
      });
    }

    res.json({
      success: true,
      trendData,
      period,
      intervalDays
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to load trend analysis data',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
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
    res.status(500).json({
      success: false,
      message: 'Failed to change password.'
    });
  }
});

export default router;
