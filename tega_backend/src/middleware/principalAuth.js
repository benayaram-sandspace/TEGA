// Principal authentication middleware
import jwt from 'jsonwebtoken';
import Principal from '../models/Principal.js';
import config from '../config/environment.js';

const principalAuth = async (req, res, next) => {
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

    // Role-based access control
    if (decoded.role !== 'principal') {
      return res.status(401).json({
        success: false,
        message: 'Access denied. User is not a principal.'
      });
    }

    const principal = await Principal.findById(decoded.id);

    req.principalId = decoded.id; // Attach principalId to the request
    req.principal = principal; // Attach principal object to the request
    
    if (!principal) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token or principal account deactivated.'
      });
    }

    if (!principal.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Principal account is deactivated.'
      });
    }
    
    next();
  } catch (error) {
    res.status(401).json({
      success: false,
      message: 'Invalid token.'
    });
  }
};

export default principalAuth;
