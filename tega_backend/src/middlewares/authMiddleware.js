import jwt from 'jsonwebtoken';
import Student from '../models/Student.js';
import Admin from '../models/Admin.js';
import Principal from '../models/Principal.js';

const isAuthenticated = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Authentication token is required' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-this-in-production');
    let user;

    if (decoded.role === 'admin') {
      user = await Admin.findById(decoded.id).select('-password');
    } else if (decoded.role === 'principal') {
      user = await Principal.findById(decoded.id).select('-password');
    } else {
      user = await Student.findById(decoded.id).select('-password');
    }

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    req.user = { ...user.toObject(), role: decoded.role };
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
};

// Verify Admin middleware
const verifyAdmin = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Authentication token is required' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-this-in-production');
    
    if (decoded.role !== 'admin') {
      return res.status(403).json({ message: 'Admin access required' });
    }

    const admin = await Admin.findById(decoded.id).select('-password');

    if (!admin) {
      return res.status(404).json({ message: 'Admin not found' });
    }

    req.adminId = decoded.id;
    req.admin = admin;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
};

// Verify Student middleware
const verifyStudent = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    console.log('🔍 verifyStudent: No auth header provided');
    return res.status(401).json({ message: 'Authentication token is required' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-this-in-production');
    console.log('🔍 verifyStudent: Token decoded successfully:', { id: decoded.id, role: decoded.role, email: decoded.email });
    
    if (decoded.role !== 'student') {
      console.log('🔍 verifyStudent: Not a student role:', decoded.role);
      return res.status(403).json({ message: 'Student access required' });
    }

    const student = await Student.findById(decoded.id).select('-password');

    if (!student) {
      console.log('🔍 verifyStudent: Student not found in database:', decoded.id);
      return res.status(404).json({ message: 'Student not found' });
    }

    console.log('🔍 verifyStudent: Student authenticated successfully:', { id: student._id, email: student.email });
    req.studentId = decoded.id;
    req.student = student;
    next();
  } catch (error) {
    console.log('🔍 verifyStudent: Token verification failed:', error.message);
    return res.status(401).json({ message: 'Invalid or expired token' });
  }
};

// Optional student authentication - doesn't fail if no token
const optionalStudentAuth = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    // No token provided, continue without authentication
    req.studentId = null;
    req.student = null;
    return next();
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-super-secret-jwt-key-change-this-in-production');
    
    if (decoded.role !== 'student') {
      // Not a student token, continue without authentication
      req.studentId = null;
      req.student = null;
      return next();
    }

    const student = await Student.findById(decoded.id).select('-password');

    if (!student) {
      // Student not found, continue without authentication
      req.studentId = null;
      req.student = null;
      return next();
    }

    req.studentId = decoded.id;
    req.student = student;
    next();
  } catch (error) {
    // Token invalid, continue without authentication
    req.studentId = null;
    req.student = null;
    next();
  }
};

export { isAuthenticated, verifyAdmin, verifyStudent, optionalStudentAuth };
