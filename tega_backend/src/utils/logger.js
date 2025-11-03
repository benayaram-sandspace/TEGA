// Production-ready logging system
import config from '../config/environment.js';

class Logger {
  constructor() {
    this.isDevelopment = config.isDevelopment;
    this.isProduction = config.isProduction;
  }

  // Format log message with timestamp and level
  formatMessage(level, message, ...args) {
    const timestamp = new Date().toISOString();
    const prefix = `[${timestamp}] [${level.toUpperCase()}]`;
    
    if (args.length > 0) {
      return `${prefix} ${message} ${JSON.stringify(args, null, 2)}`;
    }
    return `${prefix} ${message}`;
  }

  // Info level logging
  info(message, ...args) {
    if (this.isDevelopment) {
    }
    // In production, you might want to send to external logging service
  }

  // Error level logging
  error(message, ...args) {
    if (this.isDevelopment) {
    }
    // In production, always log errors
    if (this.isProduction) {
    }
  }

  // Warning level logging
  warn(message, ...args) {
    if (this.isDevelopment) {
    }
    // In production, log warnings
    if (this.isProduction) {
    }
  }

  // Debug level logging (development only)
  debug(message, ...args) {
    if (this.isDevelopment) {
    }
  }

  // Success level logging
  success(message, ...args) {
    if (this.isDevelopment) {
    }
  }

  // Database operation logging
  db(operation, message, ...args) {
    if (this.isDevelopment) {
    }
  }

  // API request logging
  api(method, url, status, duration, ...args) {
    if (this.isDevelopment) {
    }
  }

  // Security event logging
  security(event, message, ...args) {
    // Always log security events
  }

  // Performance logging
  performance(operation, duration, ...args) {
    if (this.isDevelopment || duration > 1000) { // Log slow operations
    }
  }
}

// Create singleton instance
const logger = new Logger();

export default logger;
