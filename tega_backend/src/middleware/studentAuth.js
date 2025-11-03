import jwt from 'jsonwebtoken';
import Student from '../models/Student.js';
import { inMemoryUsers } from '../controllers/authController.js';
import config from '../config/environment.js';

const studentAuth = async (req, res, next) => {
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
        message: 'Access denied. No token provided.'
      });
    }

    const decoded = jwt.verify(token, config.JWT_SECRET);
    
    // Check for both 'id' and 'userId' in the decoded token
    const studentId = decoded.id || decoded.userId;
    
    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token structure.'
      });
    }
    
    let student;
    
    // Check if it's a valid MongoDB ObjectId format (24 hex characters)
    const isValidObjectId = /^[0-9a-fA-F]{24}$/.test(studentId);
    
    if (isValidObjectId) {
      // Try to find in MongoDB
      student = await Student.findById(studentId);
    }
    
    // If not found in MongoDB or not a valid ObjectId, check in-memory storage
    if (!student) {
      
      // Find user in in-memory storage by ID
      for (const [email, user] of inMemoryUsers) {
        if (user._id === studentId) {
          student = user;
          break;
        }
      }
    }
    
    if (!student) {
      return res.status(401).json({
        success: false,
        message: 'Account not found. Please verify your email address or register for a new account.'
      });
    }

    req.student = student;
    req.studentId = student._id;

    next();
  } catch (error) {
    res.status(401).json({
      success: false,
      message: 'Invalid token.'
    });
  }
};

export { studentAuth };
