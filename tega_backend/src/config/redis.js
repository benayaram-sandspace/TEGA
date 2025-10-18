// Redis configuration for production scalability
// Optional Redis import - falls back to memory cache if not available

// Memory cache fallback
const memoryCache = new Map();

// Redis configuration
const redisConfig = {
  host: process.env.REDIS_HOST || 'localhost',
  port: process.env.REDIS_PORT || 6379,
  password: process.env.REDIS_PASSWORD || undefined,
  db: process.env.REDIS_DB || 0,
  retryDelayOnFailover: 100,
  maxRetriesPerRequest: 3,
  lazyConnect: true,
  keepAlive: 30000,
  // Connection pool settings for high load
  family: 4, // IPv4
  connectTimeout: 10000,
  commandTimeout: 5000,
  // Memory optimization
  maxmemoryPolicy: 'allkeys-lru',
};

// Create Redis client instance
let redis = null;
let redisAvailable = false;

// Initialize Redis connection
export const initializeRedis = async () => {
  try {
    const Redis = (await import('ioredis')).default;
    redis = new Redis(redisConfig);
    redisAvailable = true;
    
    redis.on('connect', () => {
      console.log('✅ Redis connected successfully');
    });
    
    redis.on('error', (err) => {
      console.error('❌ Redis connection error:', err);
      console.log('⚠️ Falling back to memory cache');
      redisAvailable = false;
      redis = null;
    });
    
    redis.on('close', () => {
      console.log('🔴 Redis connection closed');
      redisAvailable = false;
      redis = null;
    });
    
    console.log('✅ Redis initialized successfully');
    return true;
  } catch (error) {
    console.log('⚠️ Redis package not installed, using memory cache fallback');
    redisAvailable = false;
    redis = null;
    return false;
  }
};

export const getRedisClient = () => {
  return redis;
};

export const isRedisAvailable = () => {
  return redisAvailable && redis;
};

// Cache helper functions for production use
export const cacheHelpers = {
  // Set cache with TTL
  async set(key, value, ttlSeconds = 300) {
    try {
      if (isRedisAvailable()) {
        await redis.setex(key, ttlSeconds, JSON.stringify(value));
        return true;
      } else {
        // Use memory cache fallback
        memoryCache.set(key, {
          value: JSON.stringify(value),
          expires: Date.now() + (ttlSeconds * 1000)
        });
        return true;
      }
    } catch (error) {
      console.error('Cache set error:', error);
      // Fallback to memory cache
      memoryCache.set(key, {
        value: JSON.stringify(value),
        expires: Date.now() + (ttlSeconds * 1000)
      });
      return true;
    }
  },
  
  // Get cache
  async get(key) {
    try {
      if (isRedisAvailable()) {
        const value = await redis.get(key);
        return value ? JSON.parse(value) : null;
      } else {
        // Use memory cache fallback
        const cached = memoryCache.get(key);
        if (cached && cached.expires > Date.now()) {
          return JSON.parse(cached.value);
        } else if (cached) {
          memoryCache.delete(key); // Remove expired entry
        }
        return null;
      }
    } catch (error) {
      console.error('Cache get error:', error);
      // Fallback to memory cache
      const cached = memoryCache.get(key);
      if (cached && cached.expires > Date.now()) {
        return JSON.parse(cached.value);
      } else if (cached) {
        memoryCache.delete(key); // Remove expired entry
      }
      return null;
    }
  },
  
  // Delete cache
  async del(key) {
    try {
      if (isRedisAvailable()) {
        await redis.del(key);
      } else {
        memoryCache.delete(key);
      }
      return true;
    } catch (error) {
      console.error('Cache delete error:', error);
      memoryCache.delete(key); // Fallback
      return true;
    }
  },
  
  // Check if key exists
  async exists(key) {
    try {
      if (isRedisAvailable()) {
        const result = await redis.exists(key);
        return result === 1;
      } else {
        const cached = memoryCache.get(key);
        return cached && cached.expires > Date.now();
      }
    } catch (error) {
      console.error('Cache exists error:', error);
      const cached = memoryCache.get(key);
      return cached && cached.expires > Date.now();
    }
  },
  
  // Set multiple keys with TTL
  async mset(keyValuePairs, ttlSeconds = 300) {
    try {
      if (isRedisAvailable()) {
        const pipeline = redis.pipeline();
        Object.entries(keyValuePairs).forEach(([key, value]) => {
          pipeline.setex(key, ttlSeconds, JSON.stringify(value));
        });
        await pipeline.exec();
      } else {
        // Use memory cache fallback
        Object.entries(keyValuePairs).forEach(([key, value]) => {
          memoryCache.set(key, {
            value: JSON.stringify(value),
            expires: Date.now() + (ttlSeconds * 1000)
          });
        });
      }
      return true;
    } catch (error) {
      console.error('Cache mset error:', error);
      // Fallback to memory cache
      Object.entries(keyValuePairs).forEach(([key, value]) => {
        memoryCache.set(key, {
          value: JSON.stringify(value),
          expires: Date.now() + (ttlSeconds * 1000)
        });
      });
      return true;
    }
  },
  
  // Get multiple keys
  async mget(keys) {
    try {
      if (isRedisAvailable()) {
        const values = await redis.mget(keys);
        return values.map(value => value ? JSON.parse(value) : null);
      } else {
        // Use memory cache fallback
        return keys.map(key => {
          const cached = memoryCache.get(key);
          if (cached && cached.expires > Date.now()) {
            return JSON.parse(cached.value);
          } else if (cached) {
            memoryCache.delete(key); // Remove expired entry
          }
          return null;
        });
      }
    } catch (error) {
      console.error('Cache mget error:', error);
      // Fallback to memory cache
      return keys.map(key => {
        const cached = memoryCache.get(key);
        if (cached && cached.expires > Date.now()) {
          return JSON.parse(cached.value);
        } else if (cached) {
          memoryCache.delete(key); // Remove expired entry
        }
        return null;
      });
    }
  },
  
  // Increment counter with TTL
  async incr(key, ttlSeconds = 60) {
    try {
      if (isRedisAvailable()) {
        const pipeline = redis.pipeline();
        pipeline.incr(key);
        pipeline.expire(key, ttlSeconds);
        const results = await pipeline.exec();
        return results[0][1]; // Return the incremented value
      } else {
        // Use memory cache fallback
        const cached = memoryCache.get(key);
        const count = cached && cached.expires > Date.now() ? parseInt(cached.value) : 0;
        const newCount = count + 1;
        memoryCache.set(key, {
          value: newCount.toString(),
          expires: Date.now() + (ttlSeconds * 1000)
        });
        return newCount;
      }
    } catch (error) {
      console.error('Cache incr error:', error);
      // Fallback to memory cache
      const cached = memoryCache.get(key);
      const count = cached && cached.expires > Date.now() ? parseInt(cached.value) : 0;
      const newCount = count + 1;
      memoryCache.set(key, {
        value: newCount.toString(),
        expires: Date.now() + (ttlSeconds * 1000)
      });
      return newCount;
    }
  },
  
  // Get TTL of a key
  async ttl(key) {
    try {
      if (isRedisAvailable()) {
        return await redis.ttl(key);
      } else {
        const cached = memoryCache.get(key);
        if (cached) {
          const remaining = Math.ceil((cached.expires - Date.now()) / 1000);
          return remaining > 0 ? remaining : -1;
        }
        return -1;
      }
    } catch (error) {
      console.error('Cache ttl error:', error);
      const cached = memoryCache.get(key);
      if (cached) {
        const remaining = Math.ceil((cached.expires - Date.now()) / 1000);
        return remaining > 0 ? remaining : -1;
      }
      return -1;
    }
  }
};

// Cache key generators for different data types
export const cacheKeys = {
  // Video delivery cache keys
  signedVideoUrl: (studentId, courseId, lectureId) => 
    `video:url:${studentId}:${courseId}:${lectureId}`,
  
  // Enrollment status cache keys
  enrollmentStatus: (studentId, courseId) => 
    `enrollment:${studentId}:${courseId}`,
  
  // Rate limiting cache keys
  rateLimit: (identifier, window) => 
    `ratelimit:${identifier}:${window}`,
  
  // Course data cache keys
  courseContent: (courseId, userId) => 
    `course:content:${courseId}:${userId}`,
  
  // User session cache keys
  userSession: (userId) => 
    `session:${userId}`,
  
  // Video access attempts
  videoAccessAttempts: (studentId, ip) => 
    `video:attempts:${studentId}:${ip}`,
};

// Clean up expired memory cache entries periodically
setInterval(() => {
  const now = Date.now();
  for (const [key, value] of memoryCache.entries()) {
    if (value.expires <= now) {
      memoryCache.delete(key);
    }
  }
}, 60000); // Clean up every minute

export default { initializeRedis, getRedisClient, isRedisAvailable, cacheHelpers, cacheKeys };