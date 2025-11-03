import Student from '../models/Student.js';
import { inMemoryUsers } from './authController.js';
import mongoose from 'mongoose';

// Get student profile
export const getStudentProfile = async (req, res) => {
  try {
    const studentId = req.studentId;

    let student = null;
    
    // Check if studentId is a valid MongoDB ObjectId
    if (/^[0-9a-fA-F]{24}$/.test(studentId)) {

      student = await Student.findById(studentId).select('-password');

    }
    
    // If not found in MongoDB or not a valid ObjectId, check in-memory storage
    if (!student) {

      student = inMemoryUsers.find(user => user._id === studentId);

    }
    
    if (!student) {
      return res.status(404).json({ 
        success: false,
        message: 'Student not found' 
      });
    }
    
    res.json({
      success: true,
      data: student
    });
  } catch (err) {

    res.status(500).json({ 
      success: false,
      message: 'Server error while fetching profile' 
    });
  }
};

// Update student profile
export const updateStudentProfile = async (req, res) => {
  try {
    const studentId = req.studentId;

    let student = null;
    
    // Check if studentId is a valid MongoDB ObjectId
    if (/^[0-9a-fA-F]{24}$/.test(studentId)) {

      student = await Student.findById(studentId);

    }
    
    // If not found in MongoDB or not a valid ObjectId, check in-memory storage
    if (!student) {

      student = inMemoryUsers.find(user => user._id === studentId);

    }

    if (!student) {
      return res.status(404).json({ 
        success: false,
        message: 'Student not found' 
      });
    }

    // Build a sanitized payload to avoid validation issues
    const src = req.body || {};
    const cleaned = { ...src };
    
    // Debug logging
    // Normalize gender - ensure it matches schema enum values
    if (cleaned.gender !== undefined && cleaned.gender !== null && cleaned.gender !== '') {
      const g = String(cleaned.gender).toLowerCase().trim();
      const genderMap = {
        'male': 'Male',
        'female': 'Female',
        'other': 'Other',
        'prefer-not-to-say': 'Other'
      };
      cleaned.gender = genderMap[g] || (['Male', 'Female', 'Other'].includes(cleaned.gender) ? cleaned.gender : undefined);
    }
    
    // Normalize marital status - keep as string but trim whitespace
    if (cleaned.maritalStatus !== undefined && cleaned.maritalStatus !== null && cleaned.maritalStatus !== '') {
      cleaned.maritalStatus = String(cleaned.maritalStatus).trim();
    }

    // Normalize numeric/date fields with better error handling
    if (cleaned.yearOfStudy !== undefined && cleaned.yearOfStudy !== null && cleaned.yearOfStudy !== '') {
      const n = parseInt(cleaned.yearOfStudy, 10);
      cleaned.yearOfStudy = Number.isNaN(n) ? null : n;
    }
    
    if (cleaned.dob && cleaned.dob !== '') {
      let d;
      if (typeof cleaned.dob === 'string' && cleaned.dob.includes('T')) {
        // It's an ISO string, parse directly
        d = new Date(cleaned.dob);
      } else if (typeof cleaned.dob === 'string' && cleaned.dob.includes('-')) {
        // It's in YYYY-MM-DD format, create date in UTC
        const [year, month, day] = cleaned.dob.split('-');
        d = new Date(Date.UTC(parseInt(year), parseInt(month) - 1, parseInt(day)));
      } else {
        // Try parsing as regular date
        d = new Date(cleaned.dob);
      }
      cleaned.dob = isNaN(d.getTime()) ? null : d;
    }
    
    if (cleaned.enrollmentYear && cleaned.enrollmentYear !== '') {
      const d = new Date(cleaned.enrollmentYear);
      cleaned.enrollmentYear = isNaN(d.getTime()) ? null : d;
    }
    
    if (cleaned.expectedGraduation && cleaned.expectedGraduation !== '') {
      const d = new Date(cleaned.expectedGraduation);
      cleaned.expectedGraduation = isNaN(d.getTime()) ? null : d;
    }

    // Normalize CGPA and percentage with better handling
    if (cleaned.cgpa !== undefined && cleaned.cgpa !== null && cleaned.cgpa !== '') {
      const cgpaNum = parseFloat(cleaned.cgpa);
      cleaned.cgpa = Number.isNaN(cgpaNum) ? null : cgpaNum;
    }
    
    if (cleaned.percentage !== undefined && cleaned.percentage !== null && cleaned.percentage !== '') {
      const percentNum = parseFloat(cleaned.percentage);
      cleaned.percentage = Number.isNaN(percentNum) ? null : percentNum;
    }

    // Normalize ids/strings - keep empty strings as empty strings, not undefined
    if (cleaned.studentId !== undefined && cleaned.studentId !== null) {
      cleaned.studentId = String(cleaned.studentId).trim();
    }

    // Normalize phone numbers to last 10 digits
    const sanitizePhone = (v) => (v ? String(v).replace(/\D/g, '').slice(-10) : '');
    if (cleaned.phone !== undefined) cleaned.phone = sanitizePhone(cleaned.phone);
    if (cleaned.contactNumber !== undefined) cleaned.contactNumber = sanitizePhone(cleaned.contactNumber);
    if (cleaned.alternateNumber !== undefined) cleaned.alternateNumber = sanitizePhone(cleaned.alternateNumber);
    if (cleaned.emergencyContact !== undefined) cleaned.emergencyContact = String(cleaned.emergencyContact || '');
    if (cleaned.emergencyPhone !== undefined) cleaned.emergencyPhone = sanitizePhone(cleaned.emergencyPhone);
    if (cleaned.fatherPhone !== undefined) cleaned.fatherPhone = sanitizePhone(cleaned.fatherPhone);
    if (cleaned.motherPhone !== undefined) cleaned.motherPhone = sanitizePhone(cleaned.motherPhone);
    if (cleaned.guardianPhone !== undefined) cleaned.guardianPhone = sanitizePhone(cleaned.guardianPhone);

    // Normalize arrays: accept comma-separated strings or arrays of strings
    const toArray = (v) => Array.isArray(v) ? v : (typeof v === 'string' && v.trim() ? v.split(',').map(s => s.trim()).filter(Boolean) : []);

    // Handle skills array
    if (cleaned.skills !== undefined) {
      if (Array.isArray(cleaned.skills)) {
        // Already an array, ensure proper structure
        cleaned.skills = cleaned.skills.map(skill => {
          if (typeof skill === 'string') {
            return { name: skill, level: 'Intermediate' };
          }
          return skill;
        });
      } else if (typeof cleaned.skills === 'string' && cleaned.skills.trim() !== '') {
      const arr = toArray(cleaned.skills);
      cleaned.skills = arr.map(name => ({ name, level: 'Intermediate' }));
      } else {
        cleaned.skills = [];
      }
    }

    // Handle certifications array
    if (cleaned.certifications !== undefined) {
      if (Array.isArray(cleaned.certifications)) {
        // Already an array, ensure proper structure
        cleaned.certifications = cleaned.certifications.map(cert => {
          if (typeof cert === 'string') {
            return { name: cert, issuer: 'Not specified', date: new Date(), url: '' };
          }
          return cert;
        });
      } else if (typeof cleaned.certifications === 'string' && cleaned.certifications.trim() !== '') {
      const arr = toArray(cleaned.certifications);
      cleaned.certifications = arr.map(name => ({ name, issuer: 'Not specified', date: new Date(), url: '' }));
      } else {
        cleaned.certifications = [];
      }
    }

    // Handle languages array
    if (cleaned.languages !== undefined) {
      if (Array.isArray(cleaned.languages)) {
        cleaned.languages = cleaned.languages.map(lang => {
          if (typeof lang === 'string') {
            return { name: lang, proficiency: 'Conversational' };
          }
          return lang;
        });
      } else if (typeof cleaned.languages === 'string' && cleaned.languages.trim() !== '') {
      const arr = toArray(cleaned.languages);
      cleaned.languages = arr.map(name => ({ name, proficiency: 'Conversational' }));
      } else {
        cleaned.languages = [];
      }
    }

    // Handle hobbies array
    if (cleaned.hobbies !== undefined) {
      if (Array.isArray(cleaned.hobbies)) {
        cleaned.hobbies = cleaned.hobbies.map(hobby => {
          if (typeof hobby === 'string') {
            return { name: hobby, description: '' };
          }
          return hobby;
        });
      } else if (typeof cleaned.hobbies === 'string' && cleaned.hobbies.trim() !== '') {
      const arr = toArray(cleaned.hobbies);
        cleaned.hobbies = arr.map(name => ({ name, description: '' }));
      } else {
        cleaned.hobbies = [];
      }
    }

    // Ensure other optional array fields are arrays
    const arrayFields = ['projects','achievements','education','experience','volunteerExperience','extracurricularActivities'];
    arrayFields.forEach(f => {
      if (cleaned[f] === '' || cleaned[f] === null || cleaned[f] === undefined) {
        cleaned[f] = [];
      }
    });

    // Clean up string fields - convert null to empty string for better compatibility
    const stringFields = [
      'username', 'studentName', 'firstName', 'lastName', 'email', 'phone', 'contactNumber',
      'alternateNumber', 'personalEmail', 'emergencyContact', 'emergencyPhone',
      'institute', 'course', 'major', 'studentId', 'address', 'landmark', 'zipcode',
      'city', 'district', 'state', 'country', 'permanentAddress', 'fatherName',
      'fatherOccupation', 'fatherPhone', 'motherName', 'motherOccupation', 'motherPhone',
      'guardianName', 'guardianRelation', 'guardianPhone', 'profilePhoto', 'title',
      'summary', 'linkedin', 'website', 'github', 'portfolio', 'behance', 'dribbble',
      'jobType', 'preferredLocation', 'workMode', 'salaryExpectation', 'noticePeriod',
      'availability', 'interests', 'achievements', 'publications', 'patents', 'awards',
      'nationality', 'maritalStatus', 'certificateName'
    ];
    
    stringFields.forEach(field => {
      if (cleaned[field] === null) {
        cleaned[field] = '';
      }
    });

    // Remove fields that are undefined or invalid
    Object.keys(cleaned).forEach((key) => {
      // Only delete undefined values
      if (cleaned[key] === undefined) {
        delete cleaned[key];
      }
      // For enum fields (gender), delete if invalid
      if (key === 'gender' && cleaned[key] && !['Male', 'Female', 'Other'].includes(cleaned[key])) {
        delete cleaned[key];
      }
    });

    // Apply sanitized values - use Object.assign to preserve existing fields
    Object.assign(student, cleaned);

    // Ensure enum-safe value for gender on the document itself
    const validGender = ['Male', 'Female', 'Other'];
    if (student.gender && !validGender.includes(student.gender)) {
      student.gender = undefined;
    }
    
    // Debug logging after processing
    // Check if this is a MongoDB user or in-memory user
    const isValidObjectId = /^[0-9a-fA-F]{24}$/.test(studentId);

    if (isValidObjectId) {
      // MongoDB user - save to database
      try {
      await student.save();
      } catch (saveError) {
        throw saveError;
      }
    } else {
      // In-memory user - update in memory
      const userIndex = inMemoryUsers.findIndex(user => user._id === studentId);
      if (userIndex !== -1) {
        inMemoryUsers[userIndex] = { ...inMemoryUsers[userIndex], ...student };
      }
    }

    res.json({
      success: true,
      data: student,
      message: 'Profile updated successfully'
    });
  } catch (err) {

    // Send more helpful messages for common issues
    if (err && err.name === 'ValidationError') {
      const details = Object.values(err.errors || {}).map(e => e.message).join('; ');

      return res.status(400).json({ success: false, message: `Validation failed: ${details}` });
    }
    if (err && err.code === 11000) {
      const fields = Object.keys(err.keyPattern || {});

      return res.status(409).json({ success: false, message: `Duplicate value for field(s): ${fields.join(', ')}` });
    }

    return res.status(500).json({ success: false, message: 'Server error while updating profile', error: err.message });
  }
};

// Update profile picture with R2 data
export const updateProfilePicture = async (req, res) => {
  try {
    const studentId = req.studentId;
    const { r2Key, url, fileName, fileSize, mimeType } = req.body;

    if (!r2Key || !url) {
      return res.status(400).json({
        success: false,
        message: 'R2 key and URL are required'
      });
    }

    let student = null;
    
    // Check if studentId is a valid MongoDB ObjectId
    if (/^[0-9a-fA-F]{24}$/.test(studentId)) {
      student = await Student.findById(studentId);
    }
    
    // If not found in MongoDB or not a valid ObjectId, check in-memory storage
    if (!student) {
      student = inMemoryUsers.find(user => user._id === studentId);
    }
    
    if (!student) {
      return res.status(404).json({ 
        success: false,
        message: 'Student not found' 
      });
    }

    // Generate proxy URL to avoid CORS issues
    // Extract just the filename from the R2 key (remove the profile-pictures/ prefix)
    const filename = r2Key.split('/').pop();
    const publicUrl = `${process.env.SERVER_URL || process.env.CLIENT_URL || 'http://localhost:5001'}/api/r2/profile-picture/${filename}`;
    // Update profile picture data
    student.profilePicture = {
      url: publicUrl,
      r2Key: r2Key,
      fileName: fileName || 'profile-picture',
      fileSize: fileSize || 0,
      mimeType: mimeType || 'image/jpeg',
      uploadedAt: new Date()
    };
    
    // Also update the legacy profilePhoto field for backward compatibility
    student.profilePhoto = publicUrl;

    // Check if this is a MongoDB user or in-memory user
    const isValidObjectId = /^[0-9a-fA-F]{24}$/.test(studentId);
    
    if (isValidObjectId) {
      // MongoDB user - save to database
      await student.save();
    } else {
      // In-memory user - update in memory
      const userIndex = inMemoryUsers.findIndex(user => user._id === studentId);
      if (userIndex !== -1) {
        inMemoryUsers[userIndex] = { ...inMemoryUsers[userIndex], ...student };
      }
    }

    res.json({
      success: true,
      message: 'Profile picture updated successfully',
      data: {
        profilePicture: student.profilePicture
      }
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Server error while updating profile picture',
      error: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
  }
};

// Legacy profile photo upload (keeping for backward compatibility)
export const uploadProfilePhoto = async (req, res) => {
  try {
    const studentId = req.studentId;

    let student = null;
    
    // Check if studentId is a valid MongoDB ObjectId
    if (/^[0-9a-fA-F]{24}$/.test(studentId)) {
      student = await Student.findById(studentId);
    }
    
    // If not found in MongoDB or not a valid ObjectId, check in-memory storage
    if (!student) {
      student = inMemoryUsers.find(user => user._id === studentId);
    }
    
    if (!student) {
      return res.status(404).json({ msg: 'Student not found' });
    }

    if (req.file) {
      // Convert buffer to Base64 Data URI (legacy support)
      const photoDataUri = `data:${req.file.mimetype};base64,${req.file.buffer.toString('base64')}`;
      student.profilePhoto = photoDataUri;
    }

    // Check if this is a MongoDB user or in-memory user
    const isValidObjectId = /^[0-9a-fA-F]{24}$/.test(studentId);
    
    if (isValidObjectId) {
      // MongoDB user - save to database
      await student.save();
    } else {
      // In-memory user - update in memory
      const userIndex = inMemoryUsers.findIndex(user => user._id === studentId);
      if (userIndex !== -1) {
        inMemoryUsers[userIndex] = { ...inMemoryUsers[userIndex], ...student };
      }
    }
    
    // Return only the necessary fields
    res.json({ profilePhoto: student.profilePhoto });
  } catch (err) {
    res.status(500).send('Server Error');
  }
};

// Remove profile photo
export const removeProfilePhoto = async (req, res) => {
  try {
    const studentId = req.studentId;

    let student = null;
    
    // Check if studentId is a valid MongoDB ObjectId
    if (/^[0-9a-fA-F]{24}$/.test(studentId)) {

      student = await Student.findById(studentId);

    }
    
    // If not found in MongoDB or not a valid ObjectId, check in-memory storage
    if (!student) {

      student = inMemoryUsers.find(user => user._id === studentId);

    }
    
    if (!student) {
      return res.status(404).json({ msg: 'Student not found' });
    }

    student.profilePhoto = undefined;

    // Check if this is a MongoDB user or in-memory user
    const isValidObjectId = /^[0-9a-fA-F]{24}$/.test(studentId);
    
    if (isValidObjectId) {
      // MongoDB user - save to database
      await student.save();
    } else {
      // In-memory user - update in memory
      const userIndex = inMemoryUsers.findIndex(user => user._id === studentId);
      if (userIndex !== -1) {
        inMemoryUsers[userIndex] = { ...inMemoryUsers[userIndex], ...student };

      }
    }
    res.json({ profilePhoto: undefined });
  } catch (err) {

    res.status(500).send('Server Error');
  }
};

// Get student dashboard data
export const getStudentDashboard = async (req, res) => {
  try {
    const studentId = req.studentId;

    // Check if we have the necessary models
    let StudentProgress, Payment, Course, ExamAttempt;
    
    try {
      StudentProgress = mongoose.model('StudentProgress');
      Payment = mongoose.model('Payment');
      Course = mongoose.model('Course');
      ExamAttempt = mongoose.model('ExamAttempt');
    } catch (modelError) {

    }

    // Initialize dashboard data structure
    const dashboardData = {
      userProgress: {
        completedCourses: 0,
        inProgress: 0,
        certificates: 0,
        totalHours: 0,
        currentStreak: 0,
        weeklyGoal: 10,
        weeklyProgress: 0
      },
      recentActivity: [],
      upcomingEvents: [],
      achievements: [],
      recommendedCourses: [],
      enrolledCourses: []
    };

    // Get student's enrolled courses from payments
    if (Payment) {
      try {
        const enrolledPayments = await Payment.find({
          studentId: studentId,
          status: 'completed'
        }).populate('courseId').sort({ paymentDate: -1 });

        dashboardData.enrolledCourses = enrolledPayments
          .filter(p => p.courseId)
          .map(p => ({
            id: p.courseId._id,
            title: p.courseId.title || p.courseName,
            instructor: p.courseId.instructor || 'TEGA Instructor',
            thumbnail: p.courseId.thumbnail,
            enrolledDate: p.paymentDate
          }));
      } catch (error) {

      }
    }

    // Get student's course progress
    if (StudentProgress) {
      try {
        const progressData = await StudentProgress.aggregate([
          { $match: { studentId: mongoose.Types.ObjectId(studentId) } },
          {
            $group: {
              _id: '$courseId',
              totalLectures: { $sum: 1 },
              completedLectures: {
                $sum: { $cond: ['$isCompleted', 1, 0] }
              },
              totalTimeSpent: { $sum: '$timeSpent' }
            }
          }
        ]);

        // Calculate stats
        const totalHoursInSeconds = progressData.reduce((sum, course) => sum + course.totalTimeSpent, 0);
        dashboardData.userProgress.totalHours = Math.floor(totalHoursInSeconds / 3600);

        // Count completed and in-progress courses
        progressData.forEach(course => {
          const progress = (course.completedLectures / course.totalLectures) * 100;
          if (progress === 100) {
            dashboardData.userProgress.completedCourses++;
            dashboardData.userProgress.certificates++; // Assuming certificates are given for completed courses
          } else if (progress > 0) {
            dashboardData.userProgress.inProgress++;
          }
        });

        // Get recent activity from progress
        const recentProgress = await StudentProgress.find({
          studentId: studentId,
          isCompleted: true
        })
        .populate('courseId', 'title')
        .populate('lectureId', 'title')
        .sort({ completedAt: -1 })
        .limit(5);

        dashboardData.recentActivity = recentProgress.map((progress, index) => ({
          id: index + 1,
          type: 'lecture_completed',
          title: `Completed: ${progress.lectureId?.title || 'Lecture'} in ${progress.courseId?.title || 'Course'}`,
          time: getRelativeTime(progress.completedAt),
          icon: 'CheckCircle',
          color: 'text-green-500'
        }));

      } catch (error) {

      }
    }

    // Get exam attempts for recent activity
    if (ExamAttempt) {
      try {
        const recentExams = await ExamAttempt.find({
          studentId: studentId
        })
        .populate('examId', 'title')
        .sort({ attemptDate: -1 })
        .limit(3);

        const examActivity = recentExams.map((attempt, index) => ({
          id: `exam_${index}`,
          type: 'exam_taken',
          title: `${attempt.examId?.title || 'Exam'} - ${attempt.score || 0}%`,
          time: getRelativeTime(attempt.attemptDate),
          icon: 'FileText',
          color: 'text-blue-500'
        }));

        dashboardData.recentActivity = [...examActivity, ...dashboardData.recentActivity].slice(0, 6);
      } catch (error) {

      }
    }

    // Get recommended courses
    if (Course) {
      try {
        const recommendedCourses = await Course.find({ isActive: true })
          .sort({ enrollmentCount: -1 })
          .limit(3)
          .select('title instructor rating thumbnail duration level price');

        dashboardData.recommendedCourses = recommendedCourses.map(course => ({
          id: course._id,
          title: course.title,
          instructor: course.instructor || 'TEGA Instructor',
          rating: course.rating || 4.5,
          duration: course.duration || '4 weeks',
          level: course.level || 'Beginner',
          progress: 0,
          image: course.thumbnail || 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400&h=250&fit=crop'
        }));
      } catch (error) {

      }
    }

    // Calculate current streak (simplified - can be enhanced with actual login data)
    dashboardData.userProgress.currentStreak = Math.min(
      Math.floor(dashboardData.userProgress.totalHours / 2),
      30
    );

    // Calculate weekly progress (simplified - last 7 days study time)
    dashboardData.userProgress.weeklyProgress = Math.min(
      Math.floor(dashboardData.userProgress.totalHours / 10),
      dashboardData.userProgress.weeklyGoal
    );

    // Add achievements based on progress
    if (dashboardData.userProgress.completedCourses > 0) {
      dashboardData.achievements.push({
        id: 1,
        title: 'First Course Complete',
        description: 'Completed your first course',
        icon: 'Star',
        earned: true,
        date: new Date().toISOString().split('T')[0]
      });
    }

    if (dashboardData.userProgress.currentStreak >= 7) {
      dashboardData.achievements.push({
        id: 2,
        title: 'Week Warrior',
        description: 'Studied 7 days in a row',
        icon: 'Target',
        earned: true,
        date: new Date().toISOString().split('T')[0]
      });
    }

    dashboardData.achievements.push({
      id: 3,
      title: 'Exam Master',
      description: 'Score 90%+ in 5 exams',
      icon: 'Award',
      earned: false,
      progress: Math.min(dashboardData.recentActivity.filter(a => a.type === 'exam_taken').length, 5)
    });

    res.json({
      success: true,
      data: dashboardData
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Server error while fetching dashboard data',
      error: error.message
    });
  }
};

// Helper function to calculate relative time
function getRelativeTime(date) {
  if (!date) return 'recently';
  
  const now = new Date();
  const past = new Date(date);
  const diffMs = now - past;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);
  const diffWeeks = Math.floor(diffMs / 604800000);

  if (diffMins < 60) return `${diffMins} ${diffMins === 1 ? 'minute' : 'minutes'} ago`;
  if (diffHours < 24) return `${diffHours} ${diffHours === 1 ? 'hour' : 'hours'} ago`;
  if (diffDays < 7) return `${diffDays} ${diffDays === 1 ? 'day' : 'days'} ago`;
  return `${diffWeeks} ${diffWeeks === 1 ? 'week' : 'weeks'} ago`;
}

// Get sidebar counts for badges
export const getSidebarCounts = async (req, res) => {
  try {
    const studentId = req.studentId;

    // Initialize counts
    const counts = {
      notifications: 0,
      exams: 0,
      jobs: 0,
      internships: 0
    };

    // Check if we have the necessary models
    let Notification, Exam, ExamRegistration, Job, Internship;
    
    try {
      Notification = mongoose.model('Notification');
      Exam = mongoose.model('Exam');
      ExamRegistration = mongoose.model('ExamRegistration');
      Job = mongoose.model('Job');
      Internship = mongoose.model('Internship');
    } catch (modelError) {

    }

    // Get unread notifications count
    if (Notification) {
      try {
        const unreadNotifications = await Notification.countDocuments({
          recipient: studentId,
          recipientModel: 'Student',
          isRead: false
        });
        counts.notifications = unreadNotifications;
      } catch (error) {

      }
    }

    // Get available exams count (exams student can take)
    if (Exam && ExamRegistration) {
      try {
        const currentTime = new Date();
        const availableExams = await Exam.countDocuments({
          isActive: true,
          examDate: { $gte: currentTime }
        });
        counts.exams = availableExams;
      } catch (error) {

      }
    }

    // Get active jobs count
    if (Job) {
      try {
        const activeJobs = await Job.countDocuments({
          isActive: true,
          deadline: { $gte: new Date() }
        });
        counts.jobs = activeJobs;
      } catch (error) {

      }
    }

    // Get active internships count
    if (Internship) {
      try {
        const activeInternships = await Internship.countDocuments({
          isActive: true,
          applicationDeadline: { $gte: new Date() }
        });
        counts.internships = activeInternships;
      } catch (error) {

      }
    }

    res.json({
      success: true,
      counts
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: 'Server error while fetching sidebar counts',
      error: error.message
    });
  }
};
