import express from "express";
import { studentAuth } from "../middleware/studentAuth.js";
import { adminAuth } from "../middleware/adminAuth.js";
import Notification from "../models/Notification.js";
import Student from "../models/Student.js";
import Announcement from "../models/Announcement.js";
import {
  getStudentProfile,
  updateStudentProfile,
  uploadProfilePhoto,
  removeProfilePhoto,
  getStudentDashboard,
  getSidebarCounts,
} from "../controllers/studentController.js";
import multer from "multer";

// Configure multer for file uploads
const upload = multer({ dest: "uploads/" });

const router = express.Router();

// Dashboard route
router.get("/dashboard", studentAuth, getStudentDashboard);

// Sidebar counts route
router.get("/sidebar-counts", studentAuth, getSidebarCounts);

// Get student notifications
router.get("/notifications", studentAuth, async (req, res) => {
  try {
    const notifications = await Notification.find({
      recipient: req.studentId,
      recipientModel: "Student",
    }).sort({ createdAt: -1 });

    res.json({ success: true, notifications });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Failed to load notifications" });
  }
});

// Mark notifications as read
router.post("/notifications/mark-read", studentAuth, async (req, res) => {
  try {
    await Notification.updateMany(
      { recipient: req.studentId, recipientModel: "Student", isRead: false },
      { $set: { isRead: true } }
    );
    res.json({ success: true, message: "Notifications marked as read" });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Failed to update notifications" });
  }
});

// Get announcements for student's college
router.get("/announcements", studentAuth, async (req, res) => {
  try {
    const student = await Student.findById(req.studentId).select(
      "institute course yearOfStudy"
    );

    if (!student) {
      console.log("❌ Student not found for ID:", req.studentId);
      return res.status(404).json({
        success: false,
        message: "Student not found",
      });
    }

    console.log("📚 Student data:", {
      id: student._id,
      institute: student.institute,
      course: student.course,
      yearOfStudy: student.yearOfStudy,
    });

    // Check if student has institute set
    if (!student.institute) {
      console.log(
        "⚠️ Student has no institute set, returning empty announcements"
      );
      return res.json({
        success: true,
        announcements: [],
        pagination: {
          current: 1,
          pages: 0,
          total: 0,
        },
        message: "No institute assigned to student",
      });
    }

    const { page = 1, limit = 10 } = req.query;
    const skip = (page - 1) * limit;

    // Build query for announcements
    let query = {
      university: student.institute,
      isActive: true,
      $or: [{ expiresAt: null }, { expiresAt: { $gt: new Date() } }],
    };

    console.log("🔍 Announcements query:", query);

    // Filter by audience if needed
    let announcements = await Announcement.find(query)
      .populate("createdBy", "principalName")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    let total = await Announcement.countDocuments(query);

    // If no institute-specific announcements found, try to get general announcements
    if (announcements.length === 0) {
      console.log(
        "📢 No institute-specific announcements found, checking for general announcements..."
      );

      const generalQuery = {
        isActive: true,
        $or: [{ expiresAt: null }, { expiresAt: { $gt: new Date() } }],
      };

      announcements = await Announcement.find(generalQuery)
        .populate("createdBy", "principalName")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit));

      total = await Announcement.countDocuments(generalQuery);
      console.log(
        `📢 Found ${announcements.length} general announcements (total: ${total})`
      );
    }

    console.log(
      `📢 Final result: ${announcements.length} announcements for student (total: ${total})`
    );

    res.json({
      success: true,
      announcements,
      pagination: {
        current: parseInt(page),
        pages: Math.ceil(total / limit),
        total,
      },
    });
  } catch (error) {
    console.error("❌ Error fetching announcements:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch announcements",
    });
  }
});

// Get single announcement
router.get("/announcements/:id", studentAuth, async (req, res) => {
  try {
    const student = await Student.findById(req.studentId).select("institute");

    if (!student) {
      return res.status(404).json({
        success: false,
        message: "Student not found",
      });
    }

    const announcement = await Announcement.findOne({
      _id: req.params.id,
      university: student.institute,
      isActive: true,
      $or: [{ expiresAt: null }, { expiresAt: { $gt: new Date() } }],
    }).populate("createdBy", "principalName");

    if (!announcement) {
      return res.status(404).json({
        success: false,
        message: "Announcement not found",
      });
    }

    res.json({
      success: true,
      announcement,
    });
  } catch (error) {
    console.error("Error fetching announcement:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch announcement",
    });
  }
});

// Profile routes
router
  .route("/profile")
  .get(studentAuth, getStudentProfile)
  .put(studentAuth, updateStudentProfile);

// Profile photo routes
router.post(
  "/profile/photo",
  studentAuth,
  upload.single("profilePhoto"),
  (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
      if (err.code === "LIMIT_FILE_SIZE") {
        return res.status(400).json({
          success: false,
          message: "File too large. Maximum size is 5MB.",
        });
      }
    } else if (err) {
      return res.status(400).json({
        success: false,
        message: err.message,
      });
    }
    next();
  },
  uploadProfilePhoto
);

router.delete("/profile/photo", studentAuth, removeProfilePhoto);

export default router;
