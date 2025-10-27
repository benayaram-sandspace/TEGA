import jwt from 'jsonwebtoken';
import Admin from '../models/Admin.js';
import config from '../config/environment.js';

const adminAuth = async (req, res, next) => {
  try {
    // Try to get token from cookie first (production), then from header (development)
    let token = req.cookies.authToken;
    
    if (!token) {
      token = req.header('Authorization')?.replace('Bearer ', '');
    }
    
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    const decoded = jwt.verify(token, config.JWT_SECRET);
    
    // console.log('🔐 Token decoded:', { id: decoded.id, email: decoded.email, role: decoded.role });

    // Role-based access control
    if (decoded.role !== 'admin') {
      return res.status(401).json({
        success: false,
        message: 'Access denied. User is not an admin.'
      });
    }

    const admin = await Admin.findById(decoded.id);

    req.adminId = decoded.id; // Attach adminId to the request
    
    if (!admin) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token or admin account deactivated.'
      });
    }
    
    req.admin = admin;
    next();
  } catch (error) {
    res.status(401).json({
      success: false,
      message: 'Invalid token.'
    });
  }
};

export { adminAuth };
