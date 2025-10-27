// Environment configuration with production validation
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const config = {
  NODE_ENV: process.env.NODE_ENV || 'development',
  PORT: process.env.PORT || 5001,
  
  // Database
  MONGODB_URI: process.env.MONGODB_URI || (process.env.NODE_ENV === 'development' ? 'mongodb://localhost:27017/tega-auth-starter' : undefined),
  
  // Security
  JWT_SECRET: process.env.JWT_SECRET || (process.env.NODE_ENV === 'development' ? 'dev-jwt-secret-change-in-production' : undefined),
  JWT_REFRESH_SECRET: process.env.JWT_REFRESH_SECRET || (process.env.NODE_ENV === 'development' ? 'dev-refresh-secret-change-in-production' : undefined),
  
  // Redis
  REDIS_URL: process.env.REDIS_URL,
  REDIS_HOST: process.env.REDIS_HOST || 'localhost',
  REDIS_PORT: process.env.REDIS_PORT || 6379,
  REDIS_PASSWORD: process.env.REDIS_PASSWORD,
  REDIS_DB: process.env.REDIS_DB || 0,
  
  // URLs
  CLIENT_URL: process.env.CLIENT_URL || (process.env.NODE_ENV === 'development' ? 'http://localhost:3000' : undefined),
  FRONTEND_URL: process.env.FRONTEND_URL || (process.env.NODE_ENV === 'development' ? 'http://localhost:3000' : undefined),
  ADMIN_URL: process.env.ADMIN_URL || (process.env.NODE_ENV === 'development' ? 'http://localhost:3000' : undefined),
  
  // Email
  EMAIL_USER: process.env.EMAIL_USER,
  EMAIL_PASS: process.env.EMAIL_PASS,
  
  // Payment
  RAZORPAY_KEY_ID: process.env.RAZORPAY_KEY_ID,
  RAZORPAY_KEY_SECRET: process.env.RAZORPAY_KEY_SECRET,
  
  // AI
  GEMINI_API_KEY: process.env.GEMINI_API_KEY,
  OLLAMA_API_URL: process.env.OLLAMA_API_URL || 'http://localhost:11434',
  OLLAMA_MODEL: process.env.OLLAMA_MODEL || 'mistral',
  
  // R2/Cloudflare
  R2_ACCOUNT_ID: process.env.R2_ACCOUNT_ID,
  R2_ACCESS_KEY_ID: process.env.R2_ACCESS_KEY_ID,
  R2_SECRET_ACCESS_KEY: process.env.R2_SECRET_ACCESS_KEY,
  R2_BUCKET_NAME: process.env.R2_BUCKET_NAME,
  R2_PUBLIC_URL: process.env.R2_PUBLIC_URL,
  
  // Development flags
  isDevelopment: process.env.NODE_ENV === 'development',
  isProduction: process.env.NODE_ENV === 'production',
  isTest: process.env.NODE_ENV === 'test'
};

// Production validation
const validateProductionConfig = () => {
  if (config.isProduction) {
    const required = [
      'MONGODB_URI',
      'JWT_SECRET',
      'JWT_REFRESH_SECRET',
      'REDIS_URL',
      'CLIENT_URL',
      'EMAIL_USER',
      'EMAIL_PASS'
    ];
    
    const missing = required.filter(key => !process.env[key]);
    
    if (missing.length > 0) {
      throw new Error(`❌ FATAL ERROR: Missing required environment variables for production: ${missing.join(', ')}`);
    }
    
    // Validate JWT secrets are not default values
    if (config.JWT_SECRET === 'your-super-secret-jwt-key-change-this-in-production') {
      throw new Error('❌ FATAL ERROR: Default JWT secret detected. Change JWT_SECRET in production!');
    }
    
    if (config.JWT_REFRESH_SECRET === 'your-super-secret-refresh-key-change-this-in-production') {
      throw new Error('❌ FATAL ERROR: Default JWT refresh secret detected. Change JWT_REFRESH_SECRET in production!');
    }
  }
};

// Validate configuration on import
validateProductionConfig();

export default config;
