// Production-ready storage service using Redis
import { cacheHelpers, isRedisAvailable } from '../config/redis.js';
import logger from '../utils/logger.js';

class StorageService {
  constructor() {
    this.isRedisAvailable = isRedisAvailable();
    this.fallbackStorage = new Map(); // Fallback for when Redis is unavailable
  }

  // OTP Storage
  async storeOTP(email, otp, ttl = 300) {
    const key = `otp:${email}`;
    try {
      if (this.isRedisAvailable) {
        await cacheHelpers.set(key, otp, ttl);
        logger.info(`OTP stored for ${email}`);
        return true;
      } else {
        // Fallback to memory with expiration
        this.fallbackStorage.set(key, {
          value: otp,
          expires: Date.now() + (ttl * 1000)
        });
        logger.warn(`OTP stored in fallback storage for ${email}`);
        return true;
      }
    } catch (error) {
      logger.error('Failed to store OTP:', error);
      return false;
    }
  }

  async getOTP(email) {
    const key = `otp:${email}`;
    try {
      if (this.isRedisAvailable) {
        return await cacheHelpers.get(key);
      } else {
        const stored = this.fallbackStorage.get(key);
        if (stored && stored.expires > Date.now()) {
          return stored.value;
        } else if (stored) {
          this.fallbackStorage.delete(key); // Remove expired
        }
        return null;
      }
    } catch (error) {
      logger.error('Failed to get OTP:', error);
      return null;
    }
  }

  async deleteOTP(email) {
    const key = `otp:${email}`;
    try {
      if (this.isRedisAvailable) {
        await cacheHelpers.del(key);
      } else {
        this.fallbackStorage.delete(key);
      }
      logger.info(`OTP deleted for ${email}`);
      return true;
    } catch (error) {
      logger.error('Failed to delete OTP:', error);
      return false;
    }
  }

  // User Session Storage
  async storeUserSession(userId, sessionData, ttl = 3600) {
    const key = `session:${userId}`;
    try {
      if (this.isRedisAvailable) {
        await cacheHelpers.set(key, sessionData, ttl);
        logger.info(`Session stored for user ${userId}`);
        return true;
      } else {
        this.fallbackStorage.set(key, {
          value: sessionData,
          expires: Date.now() + (ttl * 1000)
        });
        logger.warn(`Session stored in fallback storage for user ${userId}`);
        return true;
      }
    } catch (error) {
      logger.error('Failed to store user session:', error);
      return false;
    }
  }

  async getUserSession(userId) {
    const key = `session:${userId}`;
    try {
      if (this.isRedisAvailable) {
        return await cacheHelpers.get(key);
      } else {
        const stored = this.fallbackStorage.get(key);
        if (stored && stored.expires > Date.now()) {
          return stored.value;
        } else if (stored) {
          this.fallbackStorage.delete(key);
        }
        return null;
      }
    } catch (error) {
      logger.error('Failed to get user session:', error);
      return null;
    }
  }

  async deleteUserSession(userId) {
    const key = `session:${userId}`;
    try {
      if (this.isRedisAvailable) {
        await cacheHelpers.del(key);
      } else {
        this.fallbackStorage.delete(key);
      }
      logger.info(`Session deleted for user ${userId}`);
      return true;
    } catch (error) {
      logger.error('Failed to delete user session:', error);
      return false;
    }
  }

  // Payment Storage
  async storePayment(paymentId, paymentData, ttl = 86400) {
    const key = `payment:${paymentId}`;
    try {
      if (this.isRedisAvailable) {
        await cacheHelpers.set(key, paymentData, ttl);
        logger.info(`Payment stored: ${paymentId}`);
        return true;
      } else {
        this.fallbackStorage.set(key, {
          value: paymentData,
          expires: Date.now() + (ttl * 1000)
        });
        logger.warn(`Payment stored in fallback storage: ${paymentId}`);
        return true;
      }
    } catch (error) {
      logger.error('Failed to store payment:', error);
      return false;
    }
  }

  async getPayment(paymentId) {
    const key = `payment:${paymentId}`;
    try {
      if (this.isRedisAvailable) {
        return await cacheHelpers.get(key);
      } else {
        const stored = this.fallbackStorage.get(key);
        if (stored && stored.expires > Date.now()) {
          return stored.value;
        } else if (stored) {
          this.fallbackStorage.delete(key);
        }
        return null;
      }
    } catch (error) {
      logger.error('Failed to get payment:', error);
      return null;
    }
  }

  // Notification Storage
  async storeNotification(userId, notification, ttl = 604800) { // 7 days
    const key = `notification:${userId}:${Date.now()}`;
    try {
      if (this.isRedisAvailable) {
        await cacheHelpers.set(key, notification, ttl);
        logger.info(`Notification stored for user ${userId}`);
        return true;
      } else {
        this.fallbackStorage.set(key, {
          value: notification,
          expires: Date.now() + (ttl * 1000)
        });
        logger.warn(`Notification stored in fallback storage for user ${userId}`);
        return true;
      }
    } catch (error) {
      logger.error('Failed to store notification:', error);
      return false;
    }
  }

  // Rate Limiting
  async incrementRateLimit(identifier, windowMs = 900000) { // 15 minutes default
    const key = `ratelimit:${identifier}`;
    try {
      if (this.isRedisAvailable) {
        const count = await cacheHelpers.incr(key, Math.ceil(windowMs / 1000));
        return count;
      } else {
        const stored = this.fallbackStorage.get(key);
        const count = stored && stored.expires > Date.now() ? stored.value : 0;
        const newCount = count + 1;
        this.fallbackStorage.set(key, {
          value: newCount,
          expires: Date.now() + windowMs
        });
        return newCount;
      }
    } catch (error) {
      logger.error('Failed to increment rate limit:', error);
      return 1;
    }
  }

  // Cleanup expired entries from fallback storage
  cleanupFallbackStorage() {
    const now = Date.now();
    for (const [key, value] of this.fallbackStorage.entries()) {
      if (value.expires <= now) {
        this.fallbackStorage.delete(key);
      }
    }
  }

  // Get storage status
  getStatus() {
    return {
      redisAvailable: this.isRedisAvailable,
      fallbackEntries: this.fallbackStorage.size,
      storageType: this.isRedisAvailable ? 'Redis' : 'Memory'
    };
  }
}

// Create singleton instance
const storageService = new StorageService();

// Cleanup fallback storage every 5 minutes
setInterval(() => {
  storageService.cleanupFallbackStorage();
}, 5 * 60 * 1000);

export default storageService;
