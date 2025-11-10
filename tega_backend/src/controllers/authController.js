import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import nodemailer from 'nodemailer';
import Student from '../models/Student.js';
import Admin from '../models/Admin.js';
import Principal from '../models/Principal.js';
import Notification from '../models/Notification.js';
import { getLoginNotificationTemplate, getRegistrationOTPTemplate, getWelcomeTemplate } from '../utils/emailTemplates.js';
import config from '../config/environment.js';

// Create email transporter
const createEmailTransporter = () => {
  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    }
  });
};

// In-memory storage for fallback (when MongoDB is not connected)
export const inMemoryUsers = new Map();
export const inMemoryAdmins = new Map();
export const inMemoryPrincipals = new Map();

// Additional in-memory storage for payments and notifications
export const userPayments = new Map();
export const userNotifications = new Map();
export const userCourseAccess = new Map();

// OTP storage for registration
export const registrationOTPs = new Map();

// Check MongoDB connection
const isMongoConnected = () => {
  try {
    return Student.db.readyState === 1;
  } catch (error) {
    return false;
  }
};

// Generate JWT token
const generateToken = (payload) => {
  return jwt.sign(payload, config.JWT_SECRET, {
    expiresIn: '30d'
  });
};

// Generate refresh token
const generateRefreshToken = (payload) => {
  return jwt.sign(payload, config.JWT_SECRET, {
    expiresIn: '60d'
  });
};
// Generate OTP
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Send OTP email
const sendOTPEmail = async (email, otp, firstName) => {
  try {
    const transporter = createEmailTransporter();
    await transporter.sendMail({
      from: `"TEGA Platform" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Complete Your Registration - TEGA',
      html: getRegistrationOTPTemplate(firstName, otp)
    });
    return true;
  } catch (error) {

    return false;
  }
};

// Login function with secure cookie implementation
export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required"
      });
    }

    // Find user in database first
    let user = null;
    if (isMongoConnected()) {
      // Try to find in all collections
      user = await Student.findOne({ email: email.toLowerCase() }) ||
             await Admin.findOne({ email: email.toLowerCase() }) ||
             await Principal.findOne({ email: email.toLowerCase() });
    }

    // Fallback to in-memory storage if MongoDB is not connected
    if (!user) {
      if (inMemoryUsers.has(email.toLowerCase())) {
        user = inMemoryUsers.get(email.toLowerCase());
      } else if (inMemoryAdmins.has(email.toLowerCase())) {
        user = inMemoryAdmins.get(email.toLowerCase());
      } else if (inMemoryPrincipals.has(email.toLowerCase())) {
        user = inMemoryPrincipals.get(email.toLowerCase());
      }
    }

    if (!user) {
      return res.status(404).json({ 
        message: "No account found with this email address. Please check your email or register for a new account." 
      });
    }

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ 
        message: "Incorrect password. Please try again or use 'Forgot Password' to reset it." 
      });
    }

    // Create base payload for tokens
    const payload = {
      id: user._id,
      email: user.email,
      role: user.role || 'student'
    };

    // Generate tokens
    const token = generateToken(payload);
    const refreshToken = generateRefreshToken(payload);

    // Update user with refresh token in database
    if (isMongoConnected()) {
      const userModel = user.role === 'admin' ? Admin : 
                      user.role === 'principal' ? Principal : Student;
      
      await userModel.findByIdAndUpdate(user._id, { refreshToken });
    }

    // Set secure httpOnly cookies with proper domain configuration
    const cookieOptions = {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production', // HTTPS only in production
      sameSite: process.env.NODE_ENV === 'production' ? 'none' : 'strict', // Allow cross-site in production
      maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days
      path: '/',
      // Set domain for production to allow subdomain access
      ...(process.env.NODE_ENV === 'production' && process.env.COOKIE_DOMAIN ? { domain: process.env.COOKIE_DOMAIN } : {})
    };

    const refreshCookieOptions = {
      ...cookieOptions,
      maxAge: 60 * 24 * 60 * 60 * 1000, // 60 days for refresh token
      path: '/api/auth'
    };

    // Set secure cookies
    res.cookie('authToken', token, cookieOptions);
    res.cookie('refreshToken', refreshToken, refreshCookieOptions);

    // Prepare user response (without sensitive data)
    const userResponse = { ...user.toObject() };
    delete userResponse.password;
    delete userResponse.resetPasswordToken;
    delete userResponse.resetPasswordExpire;

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

    // Response with conditional token inclusion (development only)
    const response = {
      success: true,
      message: "Login successful",
      user: userResponse,
      role: user.role,
      expiresIn: 30 * 24 * 60 * 60 * 1000 // 30 days in milliseconds
    };

    // Only include tokens in response for development
    if (process.env.NODE_ENV !== 'production') {
      response.token = token;
      response.refreshToken = refreshToken;
    }

    res.json(response);
  } catch (error) {

    res.status(500).json({ 
      success: false, 
      message: 'Server error during login' 
    });
  }
};

// Secure logout function
export const logout = async (req, res) => {
  try {
    // Clear httpOnly cookies
    res.clearCookie('authToken', { path: '/' });
    res.clearCookie('refreshToken', { path: '/api/auth' });
    
    // Optionally invalidate refresh token in database
    const token = req.cookies.refreshToken;
    if (token) {
      try {
        const decoded = jwt.verify(token, config.JWT_SECRET);
        const userModel = decoded.role === 'admin' ? Admin : 
                         decoded.role === 'principal' ? Principal : Student;
        await userModel.findByIdAndUpdate(decoded.id, { refreshToken: null });
      } catch (error) {
        // Token invalid, ignore
      }
    }
    
    res.json({ 
      success: true, 
      message: 'Logout successful' 
    });
  } catch (error) {

    res.status(500).json({ 
      success: false, 
      message: 'Server error during logout' 
    });
  }
};

// Verify authentication status
export const verifyAuth = async (req, res) => {
  try {
    // Check for token in Authorization header first, then in cookies
    let token = req.header('Authorization')?.replace('Bearer ', '');
    
    // If no token in header, check cookies
    if (!token) {
      token = req.cookies.authToken;
    }
    
    if (!token) {
      return res.status(401).json({ 
        success: false, 
        message: 'No authentication token' 
      });
    }

    const decoded = jwt.verify(token, config.JWT_SECRET);
    
    const userModel = decoded.role === 'admin' ? Admin : 
                     decoded.role === 'principal' ? Principal : Student;
    const user = await userModel.findById(decoded.id).select('-password -refreshToken');
    
    if (!user) {
      return res.status(401).json({ 
        success: false, 
        message: 'User not found' 
      });
    }

    res.json({
      success: true,
      user: user,
      role: decoded.role
    });
  } catch (error) {

    res.status(401).json({ 
      success: false, 
      message: 'Invalid or expired token' 
    });
  }
};

// Secure token refresh
export const refreshToken = async (req, res) => {
  try {
    // Try to get refresh token from cookies first (production/preferred method)
    let refreshToken = req.cookies.refreshToken;
    
    // Fallback to request body for development (less secure, but needed for localStorage fallback)
    if (!refreshToken && process.env.NODE_ENV !== 'production' && req.body?.refreshToken) {
      refreshToken = req.body.refreshToken;
    }
    
    if (!refreshToken) {
      return res.status(401).json({ 
        success: false, 
        message: 'No refresh token provided' 
      });
    }

    const decoded = jwt.verify(refreshToken, config.JWT_SECRET);
    
    const userModel = decoded.role === 'admin' ? Admin : 
                     decoded.role === 'principal' ? Principal : Student;
    const user = await userModel.findById(decoded.id);
    
    if (!user || user.refreshToken !== refreshToken) {
      return res.status(401).json({ 
        success: false, 
        message: 'Invalid refresh token' 
      });
    }

    // Generate new tokens
    const payload = {
      id: user._id,
      email: user.email,
      role: user.role
    };

    const newToken = generateToken(payload);
    const newRefreshToken = generateRefreshToken(payload);

    // Update refresh token in database
    await userModel.findByIdAndUpdate(user._id, { refreshToken: newRefreshToken });

    // Set new cookies with proper domain configuration
    const cookieOptions = {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: process.env.NODE_ENV === 'production' ? 'none' : 'strict',
      maxAge: 30 * 24 * 60 * 60 * 1000,
      path: '/',
      // Set domain for production to allow subdomain access
      ...(process.env.NODE_ENV === 'production' && process.env.COOKIE_DOMAIN ? { domain: process.env.COOKIE_DOMAIN } : {})
    };

    const refreshCookieOptions = {
      ...cookieOptions,
      maxAge: 60 * 24 * 60 * 60 * 1000,
      path: '/api/auth'
    };

    res.cookie('authToken', newToken, cookieOptions);
    res.cookie('refreshToken', newRefreshToken, refreshCookieOptions);

    res.json({
      success: true,
      token: newToken, // Include for development
      refreshToken: process.env.NODE_ENV !== 'production' ? newRefreshToken : undefined // Include for development only
    });
  } catch (error) {

    res.status(401).json({ 
      success: false, 
      message: 'Token refresh failed' 
    });
  }
};

// CSRF token endpoint
export const getCSRFToken = async (req, res) => {
  try {
    const csrfToken = crypto.randomUUID();
    res.cookie('csrfToken', csrfToken, {
      httpOnly: false, // Client needs to read this
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 60 * 60 * 1000, // 1 hour
      path: '/'
    });
    
    res.json({ 
      success: true, 
      csrfToken 
    });
  } catch (error) {

    res.status(500).json({ 
      success: false, 
      message: 'Failed to generate CSRF token' 
    });
  }
};

// Register function (simplified for production)
export const register = async (req, res) => {
  try {
    const { email, password, firstName, lastName, institute } = req.body;

    // Basic validation
    if (!email || !password || !firstName || !lastName) {
      return res.status(400).json({
        success: false,
        message: "All required fields must be provided"
      });
    }

    // Check if user already exists
    const existingUser = await Student.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: "User already exists with this email"
      });
    }

    // Hash password
    const saltRounds = 12; // Increased for production security
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Create user
    const user = new Student({
      email: email.toLowerCase(),
      password: hashedPassword,
      firstName,
      lastName,
      institute: institute || 'Not specified',
      role: 'student'
    });

    await user.save();

    // Send verification email
    try {
      const transporter = createEmailTransporter();
      await transporter.sendMail({
        from: `"TEGA Platform" <${process.env.EMAIL_USER}>`,
        to: user.email,
        subject: 'Welcome to TEGA Platform',
        html: `
          <h2>Welcome to TEGA Platform!</h2>
          <p>Hello ${firstName},</p>
          <p>Your account has been successfully created.</p>
          <p>You can now login and start your learning journey.</p>
          <p>Best regards,<br>TEGA Team</p>
        `
      });
    } catch (emailError) {
      // Non-blocking error
    }

    res.status(201).json({
      success: true,
      message: "User registered successfully",
      user: {
        id: user._id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role
      }
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: "Server error during registration"
    });
  }
};

// Send OTP for registration
export const sendRegistrationOTP = async (req, res) => {
  try {
    const { email, firstName, lastName, institute, password } = req.body;

    // Basic validation
    if (!email || !firstName || !lastName || !password) {
      return res.status(400).json({
        success: false,
        message: "All required fields must be provided"
      });
    }

    // Check if user already exists
    const existingUser = await Student.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: "This email is already registered. Please try logging in."
      });
    }

    // Generate OTP
    const otp = generateOTP();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Store OTP and user data temporarily
    registrationOTPs.set(email.toLowerCase(), {
      otp,
      expiry: otpExpiry,
      userData: {
        email: email.toLowerCase(),
        firstName,
        lastName,
        institute: institute || 'Not specified',
        password
      }
    });

    // Send OTP email
    const emailSent = await sendOTPEmail(email, otp, firstName);
    
    if (!emailSent) {
      return res.status(500).json({
        success: false,
        message: "Failed to send verification email. Please try again."
      });
    }

    res.json({
      success: true,
      message: "OTP sent to your email address"
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: "Server error while sending OTP"
    });
  }
};

// Verify OTP and complete registration
export const verifyRegistrationOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message: "Email and OTP are required"
      });
    }

    // Get stored OTP data
    const otpData = registrationOTPs.get(email.toLowerCase());

    if (!otpData) {

      return res.status(400).json({
        success: false,
        message: "OTP not found or expired. Please request a new OTP."
      });
    }

    // Check if OTP has expired
    if (new Date() > otpData.expiry) {
      registrationOTPs.delete(email.toLowerCase());
      return res.status(400).json({
        success: false,
        message: "OTP has expired. Please request a new OTP."
      });
    }

    // Verify OTP
    if (otpData.otp !== otp) {
      return res.status(400).json({
        success: false,
        message: "Invalid OTP. Please check and try again."
      });
    }

    // OTP is valid, create the user
    const { userData } = otpData;

    // Hash password
    const saltRounds = 12;
    const hashedPassword = await bcrypt.hash(userData.password, saltRounds);

    // Create user
    const user = new Student({
      username: userData.email.split('@')[0], // Use email prefix as username
      email: userData.email,
      password: hashedPassword,
      firstName: userData.firstName,
      lastName: userData.lastName,
      institute: userData.institute,
      role: 'student',
      acceptTerms: true // Required field
    });

    try {
      await user.save();

    } catch (saveError) {

      throw saveError;
    }

    // Clean up OTP data
    registrationOTPs.delete(email.toLowerCase());

    // Send welcome email
    try {
      const transporter = createEmailTransporter();
      await transporter.sendMail({
        from: `"TEGA Platform" <${process.env.EMAIL_USER}>`,
        to: user.email,
        subject: 'Welcome to TEGA!',
        html: getWelcomeTemplate(userData.firstName)
      });
    } catch (emailError) {
      // Non-blocking error
    }

    res.status(201).json({
      success: true,
      message: "Registration completed successfully",
      user: {
        id: user._id,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role
      }
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: "Server error during verification"
    });
  }
};

// Check email availability
export const checkEmailAvailability = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: "Email is required"
      });
    }

    // Check if email exists in database
    const existingUser = await Student.findOne({ email: email.toLowerCase() });
    
    if (existingUser) {
      return res.json({
        success: true,
        available: false,
        message: "This email is already registered"
      });
    }

    res.json({
      success: true,
      available: true,
      message: "Email is available"
    });

  } catch (error) {

    res.status(500).json({
      success: false,
      message: "Server error while checking email"
    });
  }
};