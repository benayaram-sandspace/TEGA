// Production-ready secure authentication controller
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { authConfig } from '../config/auth.js';
import { verifyJWT, blacklistToken } from '../middleware/secureAuth.js';
import Admin from '../models/Admin.js';
import Student from '../models/Student.js';
import Principal from '../models/Principal.js';

// Generate secure JWT token
const generateAccessToken = (payload) => {
  return jwt.sign(payload, authConfig.jwt.secret, {
    expiresIn: authConfig.jwt.expiresIn,
    issuer: authConfig.jwt.issuer,
    audience: authConfig.jwt.audience,
    algorithm: authConfig.jwt.algorithm
  });
};

// Generate secure refresh token
const generateRefreshToken = (payload) => {
  return jwt.sign(
    { ...payload, isRefreshToken: true },
    authConfig.refreshToken.secret,
    {
      expiresIn: authConfig.refreshToken.expiresIn,
      algorithm: authConfig.refreshToken.algorithm
    }
  );
};

// Secure login with enhanced security
export const secureLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Input validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required',
        code: 'MISSING_CREDENTIALS'
      });
    }

    // Find user in database
    const user = await findUserByEmail(email);
    
    if (!user) {
      // Don't reveal if email exists or not
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
        code: 'INVALID_CREDENTIALS'
      });
    }

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
        code: 'INVALID_CREDENTIALS'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(403).json({
        success: false,
        message: 'Account is deactivated',
        code: 'ACCOUNT_DEACTIVATED'
      });
    }

    // Generate tokens
    const tokenPayload = {
      id: user._id,
      email: user.email,
      role: user.role,
      sessionId: crypto.randomUUID()
    };

    const accessToken = generateAccessToken(tokenPayload);
    const refreshToken = generateRefreshToken(tokenPayload);

    // Store refresh token in database
    await updateUserRefreshToken(user._id, refreshToken, user.role);

    // Set secure HTTP-only cookie
    res.cookie('refreshToken', refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60 * 1000 // 7 days
    });

    // Prepare user response (exclude sensitive data)
    const userResponse = {
      id: user._id,
      email: user.email,
      role: user.role,
      username: user.username,
      firstName: user.firstName,
      lastName: user.lastName,
      isActive: user.isActive,
      lastLogin: new Date()
    };

    // Update last login
    await updateLastLogin(user._id, user.role);

    res.json({
      success: true,
      message: 'Login successful',
      accessToken,
      user: userResponse,
      expiresIn: 15 * 60 * 1000 // 15 minutes
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      code: 'INTERNAL_ERROR'
    });
  }
};

// Secure token refresh
export const secureRefreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Refresh token is required',
        code: 'NO_REFRESH_TOKEN'
      });
    }

    // Verify refresh token
    const decoded = verifyJWT(refreshToken, authConfig.refreshToken.secret);

    if (!decoded.isRefreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token type',
        code: 'INVALID_TOKEN_TYPE'
      });
    }

    // Find user and verify refresh token
    const user = await findUserById(decoded.id, decoded.role);
    
    if (!user || user.refreshToken !== refreshToken) {
      return res.status(401).json({
        success: false,
        message: 'Invalid refresh token',
        code: 'INVALID_REFRESH_TOKEN'
      });
    }

    // Check if user is still active
    if (!user.isActive) {
      return res.status(403).json({
        success: false,
        message: 'Account is deactivated',
        code: 'ACCOUNT_DEACTIVATED'
      });
    }

    // Generate new tokens
    const tokenPayload = {
      id: user._id,
      email: user.email,
      role: user.role,
      sessionId: crypto.randomUUID()
    };

    const newAccessToken = generateAccessToken(tokenPayload);
    const newRefreshToken = generateRefreshToken(tokenPayload);

    // Update refresh token in database
    await updateUserRefreshToken(user._id, newRefreshToken, user.role);

    // Set new refresh token cookie
    res.cookie('refreshToken', newRefreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60 * 1000
    });

    res.json({
      success: true,
      accessToken: newAccessToken,
      expiresIn: 15 * 60 * 1000
    });

  } catch (error) {
    console.error('Token refresh error:', error);
    
    if (error.message === 'Token has expired') {
      return res.status(401).json({
        success: false,
        message: 'Refresh token has expired',
        code: 'REFRESH_TOKEN_EXPIRED'
      });
    }

    res.status(401).json({
      success: false,
      message: 'Invalid refresh token',
      code: 'INVALID_REFRESH_TOKEN'
    });
  }
};

// Secure logout
export const secureLogout = async (req, res) => {
  try {
    const token = req.token;
    const userId = req.userId || req.adminId;

    if (token) {
      // Blacklist the current token
      blacklistToken(token);

      // Clear refresh token from database
      if (userId) {
        await clearUserRefreshToken(userId, req.userRole);
      }
    }

    // Clear refresh token cookie
    res.clearCookie('refreshToken');

    res.json({
      success: true,
      message: 'Logout successful'
    });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      code: 'INTERNAL_ERROR'
    });
  }
};

// Helper functions
const findUserByEmail = async (email) => {
  // Try to find user in all collections
  const admin = await Admin.findOne({ email });
  if (admin) return admin;

  const student = await Student.findOne({ email });
  if (student) return student;

  const principal = await Principal.findOne({ email });
  if (principal) return principal;

  return null;
};

const findUserById = async (id, role) => {
  switch (role) {
    case 'admin':
      return await Admin.findById(id);
    case 'student':
      return await Student.findById(id);
    case 'principal':
      return await Principal.findById(id);
    default:
      return null;
  }
};

const updateUserRefreshToken = async (userId, refreshToken, role) => {
  switch (role) {
    case 'admin':
      return await Admin.findByIdAndUpdate(userId, { refreshToken });
    case 'student':
      return await Student.findByIdAndUpdate(userId, { refreshToken });
    case 'principal':
      return await Principal.findByIdAndUpdate(userId, { refreshToken });
  }
};

const clearUserRefreshToken = async (userId, role) => {
  switch (role) {
    case 'admin':
      return await Admin.findByIdAndUpdate(userId, { refreshToken: null });
    case 'student':
      return await Student.findByIdAndUpdate(userId, { refreshToken: null });
    case 'principal':
      return await Principal.findByIdAndUpdate(userId, { refreshToken: null });
  }
};

const updateLastLogin = async (userId, role) => {
  const lastLogin = new Date();
  switch (role) {
    case 'admin':
      return await Admin.findByIdAndUpdate(userId, { lastLogin });
    case 'student':
      return await Student.findByIdAndUpdate(userId, { lastLogin });
    case 'principal':
      return await Principal.findByIdAndUpdate(userId, { lastLogin });
  }
};
