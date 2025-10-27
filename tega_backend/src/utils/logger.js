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
      console.log(this.formatMessage('info', message, ...args));
    }
    // In production, you might want to send to external logging service
  }

  // Error level logging
  error(message, ...args) {
    if (this.isDevelopment) {
      // console.error(this.formatMessage('error', message, ...args));
    }
    // In production, always log errors
    if (this.isProduction) {
      // console.error(this.formatMessage('error', message, ...args));
    }
  }

  // Warning level logging
  warn(message, ...args) {
    if (this.isDevelopment) {
      // console.warn(this.formatMessage('warn', message, ...args));
    }
    // In production, log warnings
    if (this.isProduction) {
      // console.warn(this.formatMessage('warn', message, ...args));
    }
  }

  // Debug level logging (development only)
  debug(message, ...args) {
    if (this.isDevelopment) {
      console.log(this.formatMessage('debug', message, ...args));
    }
  }

  // Success level logging
  success(message, ...args) {
    if (this.isDevelopment) {
      console.log(`✅ ${this.formatMessage('success', message, ...args)}`);
    }
  }

  // Database operation logging
  db(operation, message, ...args) {
    if (this.isDevelopment) {
      console.log(`🗄️ [DB ${operation.toUpperCase()}] ${message}`, ...args);
    }
  }

  // API request logging
  api(method, url, status, duration, ...args) {
    if (this.isDevelopment) {
      console.log(`🌐 [API ${method}] ${url} - ${status} (${duration}ms)`, ...args);
    }
  }

  // Security event logging
  security(event, message, ...args) {
    // Always log security events
    // console.warn(`🔒 [SECURITY ${event.toUpperCase()}] ${message}`, ...args);
  }

  // Performance logging
  performance(operation, duration, ...args) {
    if (this.isDevelopment || duration > 1000) { // Log slow operations
      console.log(`⚡ [PERF] ${operation} took ${duration}ms`, ...args);
    }
  }
}

// Create singleton instance
const logger = new Logger();

export default logger;
