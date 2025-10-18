// Production-ready rate limiting middleware with Redis support
import rateLimit from 'express-rate-limit';
import { cacheHelpers, cacheKeys, isRedisAvailable } from '../config/redis.js';

// Memory store for rate limiting (fallback when Redis unavailable)
const store = new Map();

// Redis-backed store implementation with memory fallback
const customStore = {
  increment: async (key, windowMs) => {
    const now = Date.now();
    const window = Math.floor(now / windowMs);
    const keyWithWindow = `ratelimit:${key}:${window}`;
    
    try {
      // Try Redis first if available
      if (isRedisAvailable()) {
        const count = await cacheHelpers.incr(keyWithWindow, Math.ceil(windowMs / 1000));
        return {
          totalHits: count,
          resetTime: new Date((window + 1) * windowMs)
        };
      } else {
        // Use memory store fallback
        const current = store.get(keyWithWindow) || { count: 0, resetTime: (window + 1) * windowMs };
        current.count++;
        store.set(keyWithWindow, current);
        
        // Clean up old entries
        for (const [k, v] of store.entries()) {
          if (v.resetTime < now) {
            store.delete(k);
          }
        }
        
        return {
          totalHits: current.count,
          resetTime: new Date(current.resetTime)
        };
      }
    } catch (error) {
      console.log('Rate limiter falling back to memory store');
      // Fallback to memory store
      const current = store.get(keyWithWindow) || { count: 0, resetTime: (window + 1) * windowMs };
      current.count++;
      store.set(keyWithWindow, current);
      
      // Clean up old entries
      for (const [k, v] of store.entries()) {
        if (v.resetTime < now) {
          store.delete(k);
        }
      }
      
      return {
        totalHits: current.count,
        resetTime: new Date(current.resetTime)
      };
    }
  }
};

// Login rate limiter
export const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per window
  message: {
    error: 'Too many login attempts',
    message: 'Please try again in 15 minutes',
    retryAfter: '15 minutes'
  },
  standardHeaders: true,
  legacyHeaders: false,
  store: customStore,
  keyGenerator: (req) => {
    // Rate limit by IP + User-Agent combination
    return `${req.ip}:${req.get('User-Agent')}`;
  },
  skip: (req) => {
    // Skip rate limiting for development
    return process.env.NODE_ENV === 'development';
  }
});

// Refresh token rate limiter
export const refreshLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10, // 10 refresh attempts per window
  message: {
    error: 'Too many token refresh attempts',
    message: 'Please try again in 15 minutes',
    retryAfter: '15 minutes'
  },
  standardHeaders: true,
  legacyHeaders: false,
  store: customStore,
  keyGenerator: (req) => {
    return `${req.ip}:refresh`;
  },
  skip: (req) => {
    return process.env.NODE_ENV === 'development';
  }
});

// General API rate limiter
export const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  message: {
    error: 'Too many requests',
    message: 'Please slow down your requests',
    retryAfter: '15 minutes'
  },
  standardHeaders: true,
  legacyHeaders: false,
  store: customStore,
  keyGenerator: (req) => {
    // Rate limit by IP
    return req.ip;
  },
  skip: (req) => {
    return process.env.NODE_ENV === 'development';
  }
});

// Admin-specific rate limiter
export const adminLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 200, // 200 requests per window (higher limit for admin)
  message: {
    error: 'Too many admin requests',
    message: 'Please slow down your admin requests',
    retryAfter: '15 minutes'
  },
  standardHeaders: true,
  legacyHeaders: false,
  store: customStore,
  keyGenerator: (req) => {
    return `${req.ip}:admin`;
  },
  skip: (req) => {
    return process.env.NODE_ENV === 'development';
  }
});
