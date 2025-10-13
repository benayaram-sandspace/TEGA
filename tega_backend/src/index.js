import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import dotenv from "dotenv";
import { createServer } from "http";
import { Server } from "socket.io";
import jobRoutes from "./routes/jobRoutes.js";

// Import AI Assistant routes
import aiAssistantRoutes from "./routes/aiAssistant.js";

// Load environment variables
dotenv.config();

const app = express();
const server = createServer(app);

// CORS configuration
const corsOptions = {
  origin: ["http://localhost:3000", "http://127.0.0.1:3000"], // Allow your frontend URLs
  credentials: true, // Allow credentials (cookies, authorization headers)
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
  allowedHeaders: [
    "Content-Type",
    "Authorization",
    "X-Requested-With",
    "Range",
  ],
  exposedHeaders: ["Content-Range", "Accept-Ranges", "Content-Length"],
  optionsSuccessStatus: 200, // Some legacy browsers choke on 204
};

// Initialize Socket.IO
const io = new Server(server, {
  cors: corsOptions,
  transports: ["websocket", "polling"],
});

// Socket.IO connection handling
io.on("connection", (socket) => {
  // Join user to their personal room for real-time updates
  socket.on("join-user-room", (userId) => {
    socket.join(`user-${userId}`);
  });

  // Handle payment history requests
  socket.on("request-payment-history", (userId) => {
    // This will be handled by the payment routes
  });

  // Handle disconnection
  socket.on("disconnect", () => {});
});

// Make io available to routes
app.set("io", io);

// Middleware
app.use(cors(corsOptions));
app.use(express.json({ limit: "50mb" }));
app.use(express.urlencoded({ extended: true, limit: "50mb" }));

// Connect to MongoDB with better error handling
const connectDB = async () => {
  try {
    const mongoURI =
      process.env.MONGODB_URI || "mongodb://localhost:27017/tega-auth-starter";

    // MongoDB connection options with increased timeout
    const options = {
      serverSelectionTimeoutMS: 30000, // 30 seconds
      socketTimeoutMS: 45000, // 45 seconds
      bufferCommands: false,
      maxPoolSize: 10,
      minPoolSize: 5,
      maxIdleTimeMS: 30000,
    };

    await mongoose.connect(mongoURI, options);

    // Handle connection events
    mongoose.connection.on("error", (err) => {});

    mongoose.connection.on("disconnected", () => {});
  } catch (err) {}
};

// Routes
// Import routes
import authRoutes from "./routes/authRoutes.js";
import adminRoutes from "./routes/adminRoutes.js";
import studentRoutes from "./routes/studentRoutes.js";
import principalRoutes from "./routes/principalRoutes.mjs";
import notificationRoutes from "./routes/notificationRoutes.js";
import paymentRoutes from "./routes/paymentRoutes.js";
import razorpayRoutes from "./routes/razorpayRoutes.js";
import testRoutes from "./routes/testRoutes.js";
import resumeRoutes from "./routes/resumeRoutes.js";
import examRoutes from "./routes/examRoutes.js";
import questionPaperRoutes from "./routes/questionPaperRoutes.js";
import tegaExamPaymentRoutes from "./routes/tegaExamPaymentRoutes.js";
import courseRoutes from "./routes/courseRoutes.js";
import sectionRoutes from "./routes/sectionRoutes.js";
import lectureRoutes from "./routes/lectureRoutes.js";
import studentProgressRoutes from "./routes/studentProgressRoutes.js";
import adminCourseRoutes from "./routes/adminCourseRoutes.js";
import enrollmentRoutes from "./routes/enrollmentRoutes.js";
import offerRoutes from "./routes/offerRoutes.js";
import adminExamResultRoutes from "./routes/adminExamResultRoutes.js";
import chatbotRoutes from "./routes/chatbot.js";
import placementRoutes from "./routes/placementRoutes.js";
import companyQuestionRoutes from "./routes/companyQuestionRoutes.js";
import imageRoutes from "./routes/imageRoutes.js";
import r2UploadRoutes from "./routes/r2Upload.js";
import certificateRoutes from "./routes/certificate.js";
import realTimeCourseRoutes from "./routes/realTimeCourse.js";
import videoAccessRoutes from "./routes/videoAccessRoutes.js";

// Serve static files (uploaded images)
app.use("/uploads", express.static("uploads"));

// Use routes
app.use("/api/jobs", jobRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/student", studentRoutes);
app.use("/api/principal", principalRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/razorpay", razorpayRoutes);
app.use("/api/tests", testRoutes);
app.use("/api/resume", resumeRoutes);
app.use("/api/exams", examRoutes);
app.use("/api/question-papers", questionPaperRoutes);
app.use("/api/tega-exam-payments", tegaExamPaymentRoutes);
// New real-time course system (prioritized)
app.use("/api/real-time-courses", realTimeCourseRoutes);
app.use("/api/r2", r2UploadRoutes);
app.use("/api/certificates", certificateRoutes);
app.use("/api/video-access", videoAccessRoutes);

// Legacy course system (deprecated - redirect to new system)
app.use(
  "/api/courses",
  (req, res, next) => {
    // Redirect old course API calls to new real-time system
    if (req.method === "GET" && req.params.courseId) {
      return res.redirect(`/api/real-time-courses/${req.params.courseId}`);
    }
    next();
  },
  courseRoutes
);

app.use("/api/sections", sectionRoutes);
app.use("/api/lectures", lectureRoutes);
app.use("/api/student-progress", studentProgressRoutes);
app.use("/api/admin/courses", adminCourseRoutes);
app.use("/api/enrollments", enrollmentRoutes);
app.use("/api/offers", offerRoutes);
app.use("/api/admin/exam-results", adminExamResultRoutes);
app.use("/api/chatbot", chatbotRoutes);
app.use("/api/placement", placementRoutes);
app.use("/api/company-questions", companyQuestionRoutes);
app.use("/api/images", imageRoutes);
app.use("/api/ai-assistant", aiAssistantRoutes);

// Serve uploaded files
app.use("/uploads", express.static("uploads"));

// Note: Public course access is now handled by courseRoutes.js

// Health check endpoint
app.get("/api/health", (req, res) => {
  res.json({
    status: "OK",
    message: "Tega Auth Starter API is running",
    timestamp: new Date().toISOString(),
    database:
      mongoose.connection.readyState === 1 ? "Connected" : "Disconnected",
  });
});

// Test endpoint for CORS
app.get("/api/test", (req, res) => {
  res.json({
    message: "CORS is working! Server is responding correctly.",
    timestamp: new Date().toISOString(),
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  res.status(500).json({
    success: false,
    message: "Something went wrong!",
  });
});

// 404 handler
app.use("*", (req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found",
  });
});

const PORT = process.env.PORT || 5001;
const HOST = "0.0.0.0"; // Allow connections from physical devices

// Start server only after database connection is established
const startServer = async () => {
  try {
    await connectDB();
    server.listen(PORT, HOST, () => {
      console.log(`🚀 Server running on http://${HOST}:${PORT}`);
      console.log(`📱 Access from physical device: http://[YOUR_IP]:${PORT}`);
      console.log(
        `💻 Database: ${
          mongoose.connection.readyState === 1
            ? "Connected ✅"
            : "Disconnected ❌"
        }`
      );
    });
  } catch (error) {
    console.error("❌ Server startup failed:", error.message);
    process.exit(1);
  }
};

startServer();
