// Production-ready secure authentication middleware
import jwt from 'jsonwebtoken';
import { authConfig } from '../config/auth.js';

// Secure JWT verification with proper error handling
export const verifyJWT = (token, secret, options = {}) => {
  try {
    return jwt.verify(token, secret, {
      algorithms: [authConfig.jwt.algorithm],
      issuer: authConfig.jwt.issuer,
      audience: authConfig.jwt.audience,
      ...options
    });
  } catch (error) {
    // Provide specific error messages for different JWT errors
    if (error.name === 'TokenExpiredError') {
      throw new Error('Token has expired');
    } else if (error.name === 'JsonWebTokenError') {
      throw new Error('Invalid token');
    } else if (error.name === 'NotBeforeError') {
      throw new Error('Token not active');
    } else {
      throw new Error('Token verification failed');
    }
  }
};

// Check if token is blacklisted
export const isTokenBlacklisted = (token) => {
  return authConfig.tokenBlacklist.has(token);
};

// Add token to blacklist
export const blacklistToken = (token, expiresIn = '15m') => {
  authConfig.tokenBlacklist.add(token);
  
  // Remove from blacklist after token expires
  setTimeout(() => {
    authConfig.tokenBlacklist.delete(token);
  }, jwt.decode(token).exp * 1000 - Date.now());
};

// Secure admin authentication
export const secureAdminAuth = async (req, res, next) => {
  try {
    const authHeader = req.header('Authorization');
    
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No valid token provided.',
        code: 'NO_TOKEN'
      });
    }

    const token = authHeader.replace('Bearer ', '');
    
    // Check if token is blacklisted
    if (isTokenBlacklisted(token)) {
      return res.status(401).json({
        success: false,
        message: 'Token has been revoked.',
        code: 'TOKEN_REVOKED'
      });
    }

    const decoded = verifyJWT(token, authConfig.jwt.secret);

    // Role-based access control
    if (decoded.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Admin privileges required.',
        code: 'INSUFFICIENT_PRIVILEGES'
      });
    }

    // Add session tracking
    const sessionId = `${decoded.id}:${decoded.iat}`;
    if (!authConfig.activeSessions.has(decoded.id)) {
      authConfig.activeSessions.set(decoded.id, new Set());
    }
    authConfig.activeSessions.get(decoded.id).add(sessionId);

    req.adminId = decoded.id;
    req.sessionId = sessionId;
    req.token = token;
    
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: error.message || 'Authentication failed.',
      code: 'AUTH_FAILED'
    });
  }
};

// Secure user authentication
export const secureUserAuth = async (req, res, next) => {
  try {
    const authHeader = req.header('Authorization');
    
    if (!authHeader?.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No valid token provided.',
        code: 'NO_TOKEN'
      });
    }

    const token = authHeader.replace('Bearer ', '');
    
    // Check if token is blacklisted
    if (isTokenBlacklisted(token)) {
      return res.status(401).json({
        success: false,
        message: 'Token has been revoked.',
        code: 'TOKEN_REVOKED'
      });
    }

    const decoded = verifyJWT(token, authConfig.jwt.secret);

    // Add session tracking
    const sessionId = `${decoded.id}:${decoded.iat}`;
    if (!authConfig.activeSessions.has(decoded.id)) {
      authConfig.activeSessions.set(decoded.id, new Set());
    }
    authConfig.activeSessions.get(decoded.id).add(sessionId);

    req.userId = decoded.id;
    req.userRole = decoded.role;
    req.sessionId = sessionId;
    req.token = token;
    
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: error.message || 'Authentication failed.',
      code: 'AUTH_FAILED'
    });
  }
};

// Logout middleware (blacklist token)
export const logoutUser = (req, res, next) => {
  try {
    const token = req.token;
    
    if (token) {
      blacklistToken(token);
      
      // Remove from active sessions
      const decoded = jwt.decode(token);
      if (authConfig.activeSessions.has(decoded.id)) {
        authConfig.activeSessions.get(decoded.id).delete(req.sessionId);
        
        // Clean up empty user sessions
        if (authConfig.activeSessions.get(decoded.id).size === 0) {
          authConfig.activeSessions.delete(decoded.id);
        }
      }
    }
    
    next();
  } catch (error) {
    next(error);
  }
};

// Session monitoring middleware
export const monitorSessions = (req, res, next) => {
  // Log session activity for monitoring
  if (req.userId || req.adminId) {
    const userId = req.userId || req.adminId;
    const timestamp = new Date().toISOString();
    const endpoint = req.originalUrl;
    const method = req.method;
    
    // In production, you might want to log this to a monitoring service
    console.log(`Session activity: User ${userId} - ${method} ${endpoint} at ${timestamp}`);
  }
  
  next();
};
