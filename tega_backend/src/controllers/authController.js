import Student from "../models/Student.js";
import Admin from "../models/Admin.js";
import Principal from "../models/Principal.js";
import Notification from "../models/Notification.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import crypto from "crypto";
import nodemailer from "nodemailer";
import mongoose from "mongoose";
import { 
  getLoginNotificationTemplate, 
  getPasswordResetTemplate, 
  getRegistrationOTPTemplate, 
  getWelcomeTemplate 
} from "../utils/emailTemplates.js";

// Generate JWT token
const generateToken = (payload, expiresIn = '24h') => { // 24 hours - actual logout controlled by inactivity timeout
  return jwt.sign(
    payload, 
    process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-this-in-production', 
    { expiresIn }
  );
};

// Generate refresh token
const generateRefreshToken = (payload) => {
  return jwt.sign(
    { ...payload, isRefreshToken: true },
    process.env.REFRESH_TOKEN_SECRET || 'your-refresh-token-secret-change-this',
    { expiresIn: '7d' } // 7 days - allows automatic token refresh
  );
};

// In-memory OTP storage (in production, use Redis or database)
const otpStorage = new Map();

// In-memory user storage for testing (when MongoDB is not available)
export const inMemoryUsers = new Map();
export const inMemoryAdmins = new Map();
export const inMemoryPrincipals = new Map();

// Controller functions are exported individually below

// User-specific data storage (payments, notifications, etc.)
export const userPayments = new Map(); // userId -> payments[]
export const userNotifications = new Map(); // userId -> notifications[]
export const userCourseAccess = new Map(); // userId -> courseIds[]

// Configure nodemailer (you'll need to set up email credentials)
const createEmailTransporter = () => {
  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    },
    debug: true, // Enable debug logs
    logger: true, // Enable logger
    secure: true, // Use SSL
    port: 465, // Gmail SMTP port
    tls: {
      rejectUnauthorized: false // For development only
    }
  });
};

// Check if MongoDB is connected
const isMongoConnected = () => {
  try {
    const readyState = Student.db.readyState;
    // Also check mongoose connection state
    const mongooseState = mongoose.connection.readyState;
    // Return true if either connection is ready
    return readyState === 1 || mongooseState === 1;
  } catch (error) {
    // Fallback: try to check mongoose connection directly
    try {
      const mongooseState = mongoose.connection.readyState;
      return mongooseState === 1;
    } catch (fallbackError) {
      return false;
    }
  }
};

// Student Registration Only - This endpoint only creates student accounts
export const register = async (req, res) => {
  try {
    const {
      username,
      firstName,
      lastName,
      dob,
      gender,
      studentId,
      institute,
      course,
      year,
      address,
      landmark,
      zipcode,
      city,
      district,
      phone,
      email,
      password,
      acceptTerms,
    } = req.body;

    // Comprehensive validation - studentId is now optional and will be auto-generated
    const requiredFields = [
      'username', 'firstName', 'lastName', 'dob', 'gender', 'institute', 'course',
      'year', 'address', 'landmark', 'zipcode', 'city', 'district', 'phone',
      'email', 'password', 'acceptTerms'
    ];

    for (const field of requiredFields) {
      if (!req.body[field]) {
        // The acceptTerms field is a boolean, so check for its presence differently
        if (field === 'acceptTerms' && req.body[field] === false) continue;
        if (!req.body[field]) {
          return res.status(400).json({ message: `The ${field} field is required.` });
        }
      }
    }

    // Password validation
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    if (!passwordRegex.test(password)) {
      return res.status(400).json({
        message: "Password must be at least 8 characters long and include an uppercase letter, a lowercase letter, a number, and a special character."
      });
    }

    // Phone number validation
    const phoneRegex = /^\d{10}$/;
    if (!phoneRegex.test(phone)) {
      return res.status(400).json({ message: "Phone number must be exactly 10 digits." });
    }

    // Email validation
    const emailRegex = /\S+@\S+\.\S+/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ message: "Please provide a valid email address." });
    }

    // Check if user exists (try MongoDB first, fallback to in-memory)
    let existingEmail = null;
    if (isMongoConnected()) {
      try {
        existingEmail = await Student.findOne({ email });
      } catch (error) {
      }
    }
    
    // Check in-memory storage if MongoDB failed or not connected
    if (!existingEmail && inMemoryUsers.has(email)) {
      existingEmail = inMemoryUsers.get(email);
    }
    
    if (existingEmail) {
      return res.status(400).json({ message: "Email already registered" });
    }

    // hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // create user (try MongoDB first, fallback to in-memory)
    let user = null;
    if (isMongoConnected()) {
      // Create new student
      const userData = {
        username,
        firstName,
        lastName,
        dob,
        gender: gender ? (typeof gender === 'string' ? gender.charAt(0).toUpperCase() + gender.slice(1).toLowerCase() : gender) : undefined,
        institute,
        course,
        yearOfStudy: year,
        address,
        landmark,
        zipcode,
        city,
        district,
        phone,
        email,
        password: hashedPassword,
        acceptTerms: acceptTerms === 'true' || acceptTerms === true,
        role: 'student',
        isActive: true
      };
      
      // Only include studentId if it's provided (it will be auto-generated if not provided)
      if (studentId) {
        userData.studentId = studentId;
      }
      
      try {
        user = new Student(userData);
        await user.save();
      } catch (error) {
        return res.status(500).json({ message: 'Error saving student to database' });
      }
    } else {
    }
    
    // If MongoDB failed, use in-memory storage
    if (!user) {
      // For in-memory storage, generate a TEGA ID if not provided
      const generatedStudentId = studentId || `TEGA${Math.floor(Math.random() * 10000000000).toString().padStart(10, '0')}`;
      
      user = {
        _id: crypto.randomUUID(),
        username,
        firstName,
        lastName,
        dob,
        gender,
        studentId: generatedStudentId,
        isAutoGeneratedId: !studentId,
        institute,
        course,
        year,
        address,
        landmark,
        zipcode,
        city,
        district,
        phone,
        email,
        password: hashedPassword,
        acceptTerms,
        role: 'student', // Always 'student' for homepage registration
        createdAt: new Date(),
        updatedAt: new Date()
      };
      inMemoryUsers.set(email, user);
      
      // Initialize user-specific data storage
      userPayments.set(user._id, []);
      userNotifications.set(user._id, []);
      userCourseAccess.set(user._id, []);
    }

    // Notify admin (only if MongoDB is connected)
    if (isMongoConnected()) {
      try {
        const admin = await Admin.findOne();
        if (admin) {
          const notification = new Notification({
            recipient: admin._id,
            recipientModel: 'Admin',
            message: `New student registered: ${user.username} from ${user.institute} (ID: ${user.studentId})`,
            type: 'registration'
          });
          await notification.save();
        }
      } catch (error) {
      }
    }

    // Send welcome email (only if email is configured)
    if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
      try {
        const transporter = createEmailTransporter();
        await transporter.sendMail({
          from: `"TEGA Platform" <${process.env.EMAIL_USER}>`,
          to: user.email,
          subject: 'Welcome to TEGA!',
          html: getWelcomeTemplate(`${user.firstName} ${user.lastName}`)
        });
      } catch (emailError) {
        // Don't block registration if email fails
      }
    }

    res.status(201).json({ 
      message: "Student registered successfully", 
      user: {
        id: user._id,
        username: user.username,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        institute: user.institute
      }
    });
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({ message: "Email and password are required" });
    }

    // Find user in all collections (try MongoDB first, fallback to in-memory)
    let user = null;
    let userType = null;
    
    if (isMongoConnected()) {
      try {
        // Check each collection and log what we find
        const student = await Student.findOne({ email });
        const admin = await Admin.findOne({ email });
        const principal = await Principal.findOne({ email });
        user = student || admin || principal;
        if (student) userType = 'student';
        else if (admin) userType = 'admin';
        else if (principal) userType = 'principal';
        
      } catch (error) {
      }
    }
    
    // Check in-memory storage if MongoDB failed or not connected
    if (!user) {
      user = inMemoryUsers.get(email) || inMemoryAdmins.get(email) || inMemoryPrincipals.get(email);
      if (inMemoryUsers.get(email)) userType = 'student';
      else if (inMemoryAdmins.get(email)) userType = 'admin';
      else if (inMemoryPrincipals.get(email)) userType = 'principal';
    }
    
    if (!user) {
      return res.status(400).json({ message: "Invalid credentials" });
    }
    // Check if password field exists
    if (!user.password) {
      return res.status(400).json({ message: "Account configuration error - please contact administrator" });
    }

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    // Create base payload for tokens
    const payload = {
      id: user._id,
      email: user.email,
      role: user.role || 'student' // Default to student if role is not set
    };

    // Add role-specific fields
    if (user.role === 'principal' && user.university) {
      payload.university = user.university;
    }

    // Generate tokens
    const token = generateToken(payload); // Uses default 30 days from generateToken function
    const refreshToken = generateRefreshToken(payload);
    // Update user with refresh token in database
    if (isMongoConnected()) {
      const userModel = user.role === 'admin' ? Admin : 
                      user.role === 'principal' ? Principal : Student;
      
      await userModel.findByIdAndUpdate(user._id, { refreshToken });
    }
    
    // Prepare user response (without sensitive data)
    const userResponse = { ...user.toObject() };
    delete userResponse.password;
    delete userResponse.resetPasswordToken;
    delete userResponse.resetPasswordExpire;

    // Notify admin of login (only if MongoDB is connected and not an admin logging in)
    if (isMongoConnected() && user.role !== 'admin') {
      try {
        const admin = await Admin.findOne();
        if (admin) {
          const role = user.role ? user.role.charAt(0).toUpperCase() + user.role.slice(1) : 'User';
          const notification = new Notification({
            recipient: admin._id,
            recipientModel: 'Admin',
            message: `${role} logged in: ${user.username}`,
            type: 'login'
          });
          await notification.save();
        }
      } catch (error) {
      }
    }

    // Send login notification email to the user
    try {
      const transporter = createEmailTransporter();
      const loginTime = new Date().toLocaleString('en-US', { 
        dateStyle: 'medium', 
        timeStyle: 'short',
        hour12: true 
      });
      const userAgent = req.get('user-agent') || 'Unknown Device';
      const ipAddress = req.ip || req.connection.remoteAddress || 'Unknown';
      
      await transporter.sendMail({
        from: `"TEGA Platform" <${process.env.EMAIL_USER}>`,
        to: user.email,
        subject: 'Successful Login to TEGA Platform',
        html: getLoginNotificationTemplate(
          `${user.firstName} ${user.lastName}`,
          loginTime,
          userAgent,
          ipAddress
        )
      });
    } catch (emailError) {
      // Non-blocking error
    }

    // Set JWT in an HTTP-Only cookie
    res.cookie('token', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production', // Use secure cookies in production
      sameSite: 'strict', // Prevent CSRF attacks
      maxAge: 24 * 60 * 60 * 1000 // 24 hours
    });
    res.json({
      message: "Login successful",
      token,
      refreshToken, // Include refresh token in response
      expiresIn: 24 * 60 * 60 * 1000, // 24 hours in milliseconds (actual logout controlled by 30-min inactivity)
      user: {
        _id: user._id,
        id: user._id,
        username: user.username,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        phone: user.phone,
        dob: user.dob,
        gender: user.gender,
        nationality: user.nationality,
        maritalStatus: user.maritalStatus,
        address: user.address,
        city: user.city,
        state: user.state,
        zipcode: user.zipcode,
        country: user.country,
        permanentAddress: user.permanentAddress,
        fatherName: user.fatherName,
        fatherOccupation: user.fatherOccupation,
        motherName: user.motherName,
        motherOccupation: user.motherOccupation,
        emergencyContact: user.emergencyContact,
        emergencyPhone: user.emergencyPhone,
        fatherPhone: user.fatherPhone,
        motherPhone: user.motherPhone,
        guardianName: user.guardianName,
        guardianRelation: user.guardianRelation,
        guardianPhone: user.guardianPhone,
        institute: user.institute,
        course: user.course,
        yearOfStudy: user.yearOfStudy,
        studentId: user.studentId,
        enrollmentYear: user.enrollmentYear,
        expectedGraduation: user.expectedGraduation,
        cgpa: user.cgpa,
        percentage: user.percentage,
        skills: user.skills,
        certifications: user.certifications,
        languages: user.languages,
        hobbies: user.hobbies,
        workMode: user.workMode,
        salaryExpectation: user.salaryExpectation,
        noticePeriod: user.noticePeriod,
        availability: user.availability,
        interests: user.interests,
        publications: user.publications,
        patents: user.patents,
        awards: user.awards,
        linkedin: user.linkedin,
        github: user.github,
        portfolio: user.portfolio,
        behance: user.behance,
        dribbble: user.dribbble,
        experience: user.experience,
        education: user.education,
        projects: user.projects,
        volunteerExperience: user.volunteerExperience,
        extracurricularActivities: user.extracurricularActivities,
        references: user.references,
        role: user.role,
        profilePicture: user.profilePicture,
        profileViews: user.profileViews,
        lastUpdated: user.lastUpdated,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        uploadedResume: user.uploadedResume
      }
    });
  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

export const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }

    // Check if user exists
    const user = await Student.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: "Student not found" });
    }

    // Generate 6-digit OTP
    const otp = crypto.randomInt(100000, 999999).toString();
    
    // Store OTP with expiration (5 minutes)
    otpStorage.set(email, {
      otp,
      expires: Date.now() + 5 * 60 * 1000, // 5 minutes
      attempts: 0
    });

    // Send OTP via email
    try {
      const transporter = createEmailTransporter();
      
      await transporter.sendMail({
        from: `"TEGA Platform" <${process.env.EMAIL_USER}>`,
        to: email,
        subject: 'TEGA - Password Reset OTP',
        html: getPasswordResetTemplate(`${user.firstName} ${user.lastName}`, otp)
      });

      res.json({ message: "OTP sent to your email successfully" });
    } catch (emailError) {
      // Always return OTP in development for testing
      res.json({ 
        message: "OTP generated (check console for email errors)", 
        otp: otp,
        success: false,
        emailError: emailError.message
      });
    }

  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

export const verifyOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({ message: "Email and OTP are required" });
    }

    const storedData = otpStorage.get(email);
    
    if (!storedData) {
      return res.status(400).json({ message: "OTP not found or expired" });
    }

    // Check if OTP is expired
    if (Date.now() > storedData.expires) {
      otpStorage.delete(email);
      return res.status(400).json({ message: "OTP has expired" });
    }

    // Check attempts limit
    if (storedData.attempts >= 3) {
      otpStorage.delete(email);
      return res.status(400).json({ message: "Too many failed attempts" });
    }

    // Verify OTP
    if (storedData.otp !== otp) {
      storedData.attempts += 1;
      return res.status(400).json({ message: "Invalid OTP" });
    }

    // Mark as verified
    storedData.verified = true;
    
    res.json({ message: "OTP verified successfully" });

  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

export const resetPassword = async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({ message: "Email, OTP, and new password are required" });
    }

    const storedData = otpStorage.get(email);
    
    if (!storedData || !storedData.verified || storedData.otp !== otp) {
      return res.status(400).json({ message: "Invalid or unverified OTP" });
    }

    // Check if OTP is expired
    if (Date.now() > storedData.expires) {
      otpStorage.delete(email);
      return res.status(400).json({ message: "OTP has expired" });
    }

    // Find user and update password
    const user = await Student.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: "Student not found" });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Update user password
        await Student.findByIdAndUpdate(user._id, { password: hashedPassword });

    // Clear OTP from storage
    otpStorage.delete(email);

    res.json({ message: "Password reset successfully" });

  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

// Registration OTP functions
export const sendRegistrationOTP = async (req, res) => {
  try {
    const { firstName, lastName, institute, email, password } = req.body;

    // Validation
    if (!firstName || !lastName || !institute || !email || !password) {
      return res.status(400).json({ message: "All fields are required" });
    }

    // Email validation
    const emailRegex = /\S+@\S+\.\S+/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ message: "Please provide a valid email address." });
    }

    // Check if user already exists
    let existingEmail = null;
    if (isMongoConnected()) {
      try {
        existingEmail = await Student.findOne({ email });
      } catch (error) {
      }
    }
    
    // Check in-memory storage if MongoDB failed or not connected
    if (!existingEmail && inMemoryUsers.has(email)) {
      existingEmail = inMemoryUsers.get(email);
    }
    
    if (existingEmail) {
      return res.status(400).json({ message: "Email already registered" });
    }

    // Generate 6-digit OTP
    const otp = crypto.randomInt(100000, 999999).toString();

    // Store OTP with expiration (5 minutes) and registration data
    otpStorage.set(email, {
      otp,
      expires: Date.now() + 5 * 60 * 1000, // 5 minutes
      attempts: 0,
      verified: false,
      registrationData: {
        firstName,
        lastName,
        institute,
        email,
        password
      }
    });

    // Send OTP via email
    if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
      try {
        const transporter = createEmailTransporter();
        
        // Test the transporter connection
        await transporter.verify();
        await transporter.sendMail({
          from: `"TEGA Platform" <${process.env.EMAIL_USER}>`,
          to: email,
          subject: 'TEGA - Registration OTP',
          html: getRegistrationOTPTemplate(`${firstName} ${lastName}`, otp)
        });
      } catch (emailError) {
      }
    } else {
    }

    // Always return OTP in development for testing
    if (process.env.NODE_ENV === 'development') {
      res.json({ 
        message: "OTP sent to your email successfully (dev mode)", 
        otp: otp,
        success: true
      });
    } else {
      res.json({ 
        message: "OTP sent to your email successfully",
        success: true
      });
    }

  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

export const verifyRegistrationOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({ message: "Email and OTP are required" });
    }

    const storedData = otpStorage.get(email);
    
    if (!storedData) {
      return res.status(400).json({ message: "OTP not found or expired" });
    }

    // Check if OTP is expired
    if (Date.now() > storedData.expires) {
      otpStorage.delete(email);
      return res.status(400).json({ message: "OTP has expired" });
    }

    // Check attempts limit
    if (storedData.attempts >= 3) {
      otpStorage.delete(email);
      return res.status(400).json({ message: "Too many failed attempts" });
    }

    // Verify OTP
    if (storedData.otp !== otp) {
      storedData.attempts += 1;
      return res.status(400).json({ message: "Invalid OTP" });
    }

    // Get registration data
    const { registrationData } = storedData;
    if (!registrationData) {
      return res.status(400).json({ message: "Registration data not found" });
    }

    // Password validation
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
    if (!passwordRegex.test(registrationData.password)) {
      return res.status(400).json({
        message: "Password must be at least 8 characters long and include an uppercase letter, a lowercase letter, a number, and a special character."
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(registrationData.password, 10);

    // Create user with complete data
    const userData = {
      username: registrationData.email.split('@')[0], // Generate username from email
      firstName: registrationData.firstName,
      lastName: registrationData.lastName,
      institute: registrationData.institute,
      email: registrationData.email,
      password: hashedPassword,
      // Add required fields with default values
      dob: '1990-01-01',
      gender: 'Other',
      studentId: `TEGA${Math.floor(Math.random() * 10000000000).toString().padStart(10, '0')}`,
      course: 'General',
      yearOfStudy: 1,
      address: 'Not specified',
      landmark: 'Not specified',
      zipcode: '000000',
      city: 'Not specified',
      district: 'Not specified',
      phone: '0000000000',
      acceptTerms: true,
      role: 'student'
    };

    // Create user (try MongoDB first, fallback to in-memory)
    let user = null;
    if (isMongoConnected()) {
      try {
        user = new Student(userData);
        await user.save();
      } catch (error) {
        user = null;
      }
    } else {
    }
    
    // If MongoDB failed, use in-memory storage
    if (!user) {
      user = {
        _id: crypto.randomUUID(),
        ...userData,
        role: 'student',
        createdAt: new Date(),
        updatedAt: new Date()
      };
      inMemoryUsers.set(registrationData.email, user);
      
      // Initialize user-specific data storage
      userPayments.set(user._id, []);
      userNotifications.set(user._id, []);
      userCourseAccess.set(user._id, []);
    }

    // Notify admin (only if MongoDB is connected)
    if (isMongoConnected()) {
      try {
        const admin = await Admin.findOne();
        if (admin) {
          const notification = new Notification({
            recipient: admin._id,
            recipientModel: 'Admin',
            message: `New student registered: ${user.username} from ${user.institute} (ID: ${user.studentId})`,
            type: 'registration'
          });
          await notification.save();
        }
      } catch (error) {
      }
    }

    // Send welcome email (only if email is configured)
    if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
      try {
        const transporter = createEmailTransporter();
        await transporter.sendMail({
          from: `"TEGA Platform" <${process.env.EMAIL_USER}>`,
          to: user.email,
          subject: 'Welcome to TEGA!',
          html: getWelcomeTemplate(`${user.firstName} ${user.lastName}`)
        });
      } catch (emailError) {
        // Don't block registration if email fails
      }
    }

    // Clear OTP from storage
    otpStorage.delete(email);

    res.status(201).json({ 
      message: "Student registered successfully", 
      user: {
        id: user._id,
        username: user.username,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        institute: user.institute
      }
    });

  } catch (err) {
    res.status(500).json({ message: "Server error" });
  }
};

// Refresh token endpoint
export const refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(401).json({ success: false, message: 'Refresh token is required' });
    }
    
    // Verify the refresh token
    const decoded = jwt.verify(
      refreshToken, 
      process.env.REFRESH_TOKEN_SECRET || 'your-refresh-token-secret-change-this'
    );
    
    if (!decoded.isRefreshToken) {
      return res.status(403).json({ success: false, message: 'Invalid token type' });
    }
    
    // Find the user
    let user;
    if (isMongoConnected()) {
      const userModel = decoded.role === 'admin' ? Admin : 
                       decoded.role === 'principal' ? Principal : Student;
      
      user = await userModel.findById(decoded.id);
      
      // Verify the refresh token matches the one stored in the database
      if (user.refreshToken !== refreshToken) {
        return res.status(403).json({ success: false, message: 'Invalid refresh token' });
      }
    } else {
      // Fallback to in-memory storage if MongoDB is not available
      const users = decoded.role === 'admin' ? inMemoryAdmins : 
                   decoded.role === 'principal' ? inMemoryPrincipals : inMemoryUsers;
      
      user = Array.from(users.values()).find(u => u.id === decoded.id || u._id === decoded.id);
      
      if (!user || user.refreshToken !== refreshToken) {
        return res.status(403).json({ success: false, message: 'Invalid refresh token' });
      }
    }
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    // Generate new tokens
    const payload = {
      id: user._id || user.id,
      email: user.email,
      role: user.role
    };
    
    const newToken = generateToken(payload); // Uses default 30 days from generateToken function
    const newRefreshToken = generateRefreshToken(payload);
    
    // Update the refresh token in the database
    if (isMongoConnected()) {
      const userModel = user.role === 'admin' ? Admin : 
                       user.role === 'principal' ? Principal : Student;
      
      await userModel.findByIdAndUpdate(user._id || user.id, { 
        refreshToken: newRefreshToken 
      });
    }
    
    const userResponse = {
      id: user._id || user.id,
      username: user.username,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      institute: user.institute
    };
    
    res.status(200).json({
      success: true,
      token: newToken,
      refreshToken: newRefreshToken,
      user: userResponse,
      expiresIn: 24 * 60 * 60 * 1000, // 24 hours in milliseconds (actual logout controlled by 30-min inactivity)
      role: user.role // Include user role in response
    });
    
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ 
        success: false, 
        message: 'Refresh token has expired. Please log in again.' 
      });
    }
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid refresh token' 
      });
    }
    
    res.status(500).json({ 
      success: false, 
      message: 'Error refreshing token',
      error: error.message 
    });
  }
};

// Check email availability for registration
export const checkEmailAvailability = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ 
        success: false,
        message: "Email is required" 
      });
    }

    // Email validation
    const emailRegex = /\S+@\S+\.\S+/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ 
        success: false,
        message: "Invalid email format" 
      });
    }

    // Check if email exists in database
    let existingEmail = null;
    if (isMongoConnected()) {
      try {
        existingEmail = await Student.findOne({ email: email.toLowerCase() });
      } catch (error) {
      }
    }
    
    // Check in-memory storage if MongoDB failed or not connected
    if (!existingEmail && inMemoryUsers.has(email)) {
      existingEmail = inMemoryUsers.get(email);
    }
    
    if (existingEmail) {
      return res.json({ 
        success: true,
        available: false,
        message: "This email is already registered" 
      });
    }

    return res.json({ 
      success: true,
      available: true,
      message: "Email is available" 
    });

  } catch (err) {
    res.status(500).json({ 
      success: false,
      message: "Server error" 
    });
  }
};
