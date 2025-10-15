// Production-ready authentication configuration
import dotenv from "dotenv";

dotenv.config();

// Validate required environment variables (only in production)
if (process.env.NODE_ENV === "production") {
  const requiredEnvVars = [
    "JWT_SECRET",
    "REFRESH_TOKEN_SECRET",
    "JWT_EXPIRES_IN",
    "REFRESH_TOKEN_EXPIRES_IN",
  ];

  for (const envVar of requiredEnvVars) {
    if (!process.env[envVar]) {
      throw new Error(
        `❌ CRITICAL: ${envVar} environment variable is required for production`
      );
    }
  }
}

// Production authentication configuration
export const authConfig = {
  // JWT Configuration
  jwt: {
    secret:
      process.env.JWT_SECRET ||
      "your-super-secret-jwt-key-change-this-in-production-2024-secure-auth",
    expiresIn: process.env.JWT_EXPIRES_IN || "15m", // Short-lived access tokens
    algorithm: "HS256",
    issuer: process.env.JWT_ISSUER || "tega-platform",
    audience: process.env.JWT_AUDIENCE || "tega-users",
  },

  // Refresh Token Configuration
  refreshToken: {
    secret:
      process.env.REFRESH_TOKEN_SECRET ||
      "your-refresh-token-secret-change-this-in-production-2024-secure-auth",
    expiresIn: process.env.REFRESH_TOKEN_EXPIRES_IN || "7d",
    algorithm: "HS256",
  },

  // Security Configuration
  security: {
    // Rate limiting for auth endpoints
    rateLimit: {
      login: {
        windowMs: 15 * 60 * 1000, // 15 minutes
        max: 5, // 5 attempts per window
        message: "Too many login attempts, please try again later",
      },
      refresh: {
        windowMs: 15 * 60 * 1000, // 15 minutes
        max: 10, // 10 refresh attempts per window
        message: "Too many token refresh attempts",
      },
    },

    // Session configuration
    session: {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      sameSite: "strict",
      maxAge: 15 * 60 * 1000, // 15 minutes (matches JWT expiry)
    },

    // Password requirements
    password: {
      minLength: 8,
      requireUppercase: true,
      requireLowercase: true,
      requireNumbers: true,
      requireSpecialChars: true,
    },
  },

  // Token blacklist (for logout functionality)
  tokenBlacklist: new Set(),

  // Active sessions tracking
  activeSessions: new Map(), // userId -> Set of sessionIds
};

// Helper function to validate JWT configuration
export const validateAuthConfig = () => {
  const errors = [];

  if (authConfig.jwt.secret.length < 32) {
    errors.push("JWT_SECRET must be at least 32 characters long");
  }

  if (authConfig.refreshToken.secret.length < 32) {
    errors.push("REFRESH_TOKEN_SECRET must be at least 32 characters long");
  }

  if (authConfig.jwt.secret === authConfig.refreshToken.secret) {
    errors.push("JWT_SECRET and REFRESH_TOKEN_SECRET must be different");
  }

  if (errors.length > 0) {
    throw new Error(
      `❌ Authentication configuration errors:\n${errors.join("\n")}`
    );
  }

  console.log("✅ Authentication configuration validated successfully");
};

// Validate configuration on import
validateAuthConfig();
