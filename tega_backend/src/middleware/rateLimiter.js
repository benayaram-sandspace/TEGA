import rateLimit, { ipKeyGenerator } from 'express-rate-limit';
import { cacheHelpers, cacheKeys, isRedisAvailable } from '../config/redis.js';

const memoryStore = new Map();

class HybridRateLimitStore {
  constructor() {
    this.windowMs = 60 * 1000;
  }

  init(options) {
    if (options && typeof options.windowMs === 'number') {
      this.windowMs = options.windowMs;
    }
  }

  async increment(key) {
    const now = Date.now();
    const window = Math.floor(now / this.windowMs);
    const keyWithWindow = `ratelimit:${key}:${window}`;

    if (isRedisAvailable()) {
      const ttlSeconds = Math.ceil(this.windowMs / 1000);
      const count = await cacheHelpers.incr(keyWithWindow, ttlSeconds);
      return {
        totalHits: count,
        resetTime: new Date((window + 1) * this.windowMs)
      };
    }

    const current = memoryStore.get(keyWithWindow) || { count: 0, resetTime: (window + 1) * this.windowMs };
    current.count += 1;
    memoryStore.set(keyWithWindow, current);

    for (const [k, v] of memoryStore.entries()) {
      if (v.resetTime < now) {
        memoryStore.delete(k);
      }
    }

    return {
      totalHits: current.count,
      resetTime: new Date(current.resetTime)
    };
  }

  async decrement(key) {
    const now = Date.now();
    const window = Math.floor(now / this.windowMs);
    const keyWithWindow = `ratelimit:${key}:${window}`;
    const entry = memoryStore.get(keyWithWindow);
    if (entry && entry.count > 0) {
      entry.count -= 1;
      memoryStore.set(keyWithWindow, entry);
    }
  }

  async resetKey(key) {
    for (const k of memoryStore.keys()) {
      if (k.startsWith(`ratelimit:${key}:`)) {
        memoryStore.delete(k);
      }
    }
  }

  async resetAll() {
    memoryStore.clear();
  }
}

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
  store: new HybridRateLimitStore(),
  keyGenerator: (req) => {
    // IPv6-safe IP key + User-Agent combination
    const ipKey = ipKeyGenerator(req);
    return `${ipKey}:${req.get('User-Agent') || ''}`;
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
  store: new HybridRateLimitStore(),
  keyGenerator: (req) => {
    const ipKey = ipKeyGenerator(req);
    return `${ipKey}:refresh`;
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
  store: new HybridRateLimitStore(),
  keyGenerator: (req) => {
    // Rate limit by IP
    return ipKeyGenerator(req);
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
  store: new HybridRateLimitStore(),
  keyGenerator: (req) => {
    const ipKey = ipKeyGenerator(req);
    return `${ipKey}:admin`;
  },
  skip: (req) => {
    return process.env.NODE_ENV === 'development';
  }
});
