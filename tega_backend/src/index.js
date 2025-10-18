import express from 'express';
import mongoose from 'mongoose';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import dotenv from 'dotenv';
import { createServer } from 'http';
import { Server } from 'socket.io';
import jobRoutes from './routes/jobRoutes.js';
import { initializeRedis } from './config/redis.js';

// Import AI Assistant routes
import aiAssistantRoutes from './routes/aiAssistant.js';

// Load environment variables
dotenv.config();

const app = express();
const server = createServer(app);

// CORS configuration
const corsOptions = {
  origin: [
    'http://localhost:3000', 
    'http://127.0.0.1:3000',
    'https://tegaedu.com',
    'https://www.tegaedu.com',
    'http://tegaedu.com',
    'http://www.tegaedu.com',
    process.env.CLIENT_URL,
    process.env.FRONTEND_URL
  ].filter(Boolean), // Remove undefined values
  credentials: true, // Allow credentials (cookies, authorization headers)
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Range'],
  exposedHeaders: ['Content-Range', 'Accept-Ranges', 'Content-Length'],
  optionsSuccessStatus: 200 // Some legacy browsers choke on 204
};

// Initialize Socket.IO
const io = new Server(server, {
  cors: corsOptions,
  transports: ['websocket', 'polling']
});

// Socket.IO connection handling
io.on('connection', (socket) => {

  // Join user to their personal room for real-time updates
  socket.on('join-user-room', (userId) => {
    socket.join(`user-${userId}`);
  });

  // Handle payment history requests
  socket.on('request-payment-history', (userId) => {
    // This will be handled by the payment routes
  });

  // Handle disconnection
  socket.on('disconnect', () => {
  });
});

// Make io available to routes
app.set('io', io);

// Middleware
app.use(cors(corsOptions));
app.use(cookieParser()); // Enable cookie parsing
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Connect to MongoDB with better error handling
const connectDB = async () => {
  try {
    // Ensure MongoDB URI is provided in production
    if (!process.env.MONGODB_URI && process.env.NODE_ENV === 'production') {
      console.error('FATAL ERROR: MONGODB_URI is not defined in production environment');
      process.exit(1);
    }
    
    const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/tega-auth-starter';
    
    // MongoDB connection options - optimized for 10,000+ users
    const options = {
      serverSelectionTimeoutMS: 30000, // 30 seconds
      socketTimeoutMS: 45000, // 45 seconds
      bufferCommands: false,
      // Increased pool size for high concurrent users
      maxPoolSize: 50, // Maintain up to 50 socket connections
      minPoolSize: 10,  // Maintain at least 10 socket connections
      maxIdleTimeMS: 30000,
      retryWrites: true, // Retry failed writes
      retryReads: true, // Retry failed reads
      autoIndex: process.env.NODE_ENV !== 'production', // Disable in production for performance
      // Additional optimization settings
      connectTimeoutMS: 10000, // 10 second connection timeout
      maxStalenessSeconds: 90, // Allow reads from secondary with up to 90s lag
    };
    
    await mongoose.connect(mongoURI, options);
    
    // Handle connection events with proper logging
    mongoose.connection.on('error', (err) => {
      console.error('❌ MongoDB Connection Error:', err);
    });
    
    // Initialize Redis (optional - will fallback to memory cache if not available)
    await initializeRedis();
    
    mongoose.connection.on('disconnected', () => {
      console.warn('⚠️  MongoDB Disconnected. Attempting to reconnect...');
    });
    
    mongoose.connection.on('reconnected', () => {
      console.log('✅ MongoDB Reconnected Successfully');
    });
    
  } catch (err) {
    console.error('❌ MongoDB Connection Failed:', err.message);
    console.error('Stack:', err.stack);
    
    // In production, exit if DB connection fails
    if (process.env.NODE_ENV === 'production') {
      console.error('Exiting application due to database connection failure');
      process.exit(1);
    }
    
    // In development, retry after delay
    console.log('Retrying connection in 5 seconds...');
    setTimeout(connectDB, 5000);
  }
};

// Graceful shutdown handler
const gracefulShutdown = async (signal) => {
  console.log(`\n${signal} received. Starting graceful shutdown...`);
  
  try {
    // Close MongoDB connection
    await mongoose.connection.close();
    console.log('✅ MongoDB connection closed');
    
    // Close server
    server.close(() => {
      console.log('✅ HTTP server closed');
      process.exit(0);
    });
    
    // Force close after timeout
    setTimeout(() => {
      console.error('⚠️  Forced shutdown after timeout');
      process.exit(1);
    }, 10000); // 10 seconds timeout
    
  } catch (err) {
    console.error('❌ Error during shutdown:', err);
    process.exit(1);
  }
};

// Register shutdown handlers
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
  gracefulShutdown('uncaughtException');
});
process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  gracefulShutdown('unhandledRejection');
});

// Routes
import authRoutes from './routes/authRoutes.js';
import adminRoutes from './routes/adminRoutes.js';
import studentRoutes from './routes/studentRoutes.js';
import principalRoutes from './routes/principalRoutes.mjs';
import notificationRoutes from './routes/notificationRoutes.js';
import paymentRoutes from './routes/paymentRoutes.js';
import razorpayRoutes from './routes/razorpayRoutes.js';
import resumeRoutes from './routes/resumeRoutes.js';
import examRoutes from './routes/examRoutes.js';
import questionPaperRoutes from './routes/questionPaperRoutes.js';
import tegaExamPaymentRoutes from './routes/tegaExamPaymentRoutes.js';
import enrollmentRoutes from './routes/enrollmentRoutes.js';
import offerRoutes from './routes/offerRoutes.js';
import adminExamResultRoutes from './routes/adminExamResultRoutes.js';
import chatbotRoutes from './routes/chatbot.js';
import placementRoutes from './routes/placementRoutes.js';
import companyQuestionRoutes from './routes/companyQuestionRoutes.js';
import imageRoutes from './routes/imageRoutes.js';
import r2UploadRoutes from './routes/r2Upload.js';
import certificateRoutes from './routes/certificate.js';
import realTimeCourseRoutes from './routes/realTimeCourse.js';
import videoDeliveryRoutes from './routes/videoDeliveryRoutes.js';
import contactRoutes from './routes/contactRoutes.js';

// Serve static files (uploaded images)
app.use('/uploads', express.static('uploads'));

// Use routes
app.use("/api/jobs", jobRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/student', studentRoutes);
app.use('/api/principal', principalRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/razorpay', razorpayRoutes);
app.use('/api/resume', resumeRoutes);
app.use('/api/exams', examRoutes);
app.use('/api/question-papers', questionPaperRoutes);
app.use('/api/tega-exam-payments', tegaExamPaymentRoutes);

// Real-Time Course System (R2-Based) - CONSOLIDATED SINGLE SYSTEM
app.use('/api/real-time-courses', realTimeCourseRoutes);
app.use('/api/courses', realTimeCourseRoutes); // Alias for backward compatibility
app.use('/api/r2', r2UploadRoutes);
app.use('/api/certificates', certificateRoutes);
app.use('/api/video-delivery', videoDeliveryRoutes);
app.use('/api/enrollments', enrollmentRoutes);
app.use('/api/offers', offerRoutes);
app.use('/api/admin/exam-results', adminExamResultRoutes);
app.use('/api/chatbot', chatbotRoutes);
app.use('/api/placement', placementRoutes);
app.use('/api/company-questions', companyQuestionRoutes);
app.use('/api/images', imageRoutes);
app.use('/api/ai-assistant', aiAssistantRoutes);
app.use('/api/contact', contactRoutes);

// Static file serving is already configured above

// Note: All course access now handled by realTimeCourse.js (R2-based system only)

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'Tega Auth Starter API is running',
    timestamp: new Date().toISOString(),
    database: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected'
  });
});

// Test endpoint for CORS
app.get('/api/test', (req, res) => {
  res.json({ 
    message: 'CORS is working! Server is responding correctly.',
    timestamp: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  res.status(500).json({ 
    success: false, 
    message: 'Something went wrong!' 
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    success: false, 
    message: 'Route not found' 
  });
});

const PORT = process.env.PORT || 5001;

// Start server only after database connection is established
const startServer = async () => {
  try {
    await connectDB();
    server.listen(PORT, () => {
    });
  } catch (error) {
    process.exit(1);
  }
};

startServer();
