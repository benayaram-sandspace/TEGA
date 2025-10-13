import Lecture from '../models/Lecture.js';
import Section from '../models/Section.js';
import Course from '../models/Course.js';
import StudentProgress from '../models/StudentProgress.js';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configure multer for lecture file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = path.join(__dirname, '../../uploads/lectures');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  fileFilter: (req, file, cb) => {
    const allowedTypes = ['.mp4', '.avi', '.mov', '.wmv', '.pdf', '.doc', '.docx', '.ppt', '.pptx'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowedTypes.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('File type not allowed'), false);
    }
  },
  limits: {
    fileSize: 100 * 1024 * 1024 // 100MB limit
  }
});

// Create a new lecture
export const createLecture = async (req, res) => {
  try {
    const { sectionId, title, description, type, videoUrl, duration, order, isPreview, quiz } = req.body;
    const adminId = req.adminId;

    // Validate required fields
    if (!sectionId || !title || !type) {
      return res.status(400).json({
        success: false,
        message: 'Section ID, title, and type are required'
      });
    }

    // Check if section exists and belongs to admin
    const section = await Section.findById(sectionId);
    if (!section) {
      return res.status(404).json({
        success: false,
        message: 'Section not found'
      });
    }

    if (section.createdBy.toString() !== adminId) {
      return res.status(403).json({
        success: false,
        message: 'You can only add lectures to your own sections'
      });
    }

    // Handle file upload if present
    let fileUrl = null;
    if (req.file) {
      fileUrl = `/uploads/lectures/${req.file.filename}`;
    }

    // Create lecture
    const lecture = new Lecture({
      sectionId,
      title,
      description,
      type,
      fileUrl: fileUrl || req.body.fileUrl,
      videoUrl: videoUrl,
      duration: duration || '0:00',
      order: order || 0,
      isPreview: isPreview || false,
      quiz: type === 'quiz' ? quiz : undefined,
      createdBy: adminId
    });

    await lecture.save();

    res.status(201).json({
      success: true,
      message: 'Lecture created successfully',
      lecture
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create lecture',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get lectures by section
export const getLecturesBySection = async (req, res) => {
  try {
    const { sectionId } = req.params;

    const lectures = await Lecture.find({ sectionId, isActive: true })
      .sort({ order: 1 });

    res.json({
      success: true,
      lectures
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch lectures',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Get single lecture with progress (for students)
export const getLectureWithProgress = async (req, res) => {
  try {
    const { lectureId } = req.params;
    const studentId = req.studentId;

    const lecture = await Lecture.findById(lectureId)
      .populate('sectionId', 'title courseId')
      .populate({
        path: 'sectionId',
        populate: {
          path: 'courseId',
          select: 'title'
        }
      });

    if (!lecture) {
      return res.status(404).json({
        success: false,
        message: 'Lecture not found'
      });
    }

    // Get student progress for this lecture
    let progress = null;
    if (studentId) {
      progress = await StudentProgress.findOne({
        studentId,
        lectureId,
        courseId: lecture.sectionId.courseId._id
      });
    }

    res.json({
      success: true,
      lecture,
      progress
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch lecture',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Update lecture
export const updateLecture = async (req, res) => {
  try {
    const { lectureId } = req.params;
    const updateData = req.body;
    const adminId = req.adminId;

    // Check if lecture exists and belongs to admin
    const lecture = await Lecture.findById(lectureId);
    if (!lecture) {
      return res.status(404).json({
        success: false,
        message: 'Lecture not found'
      });
    }

    if (lecture.createdBy.toString() !== adminId) {
      return res.status(403).json({
        success: false,
        message: 'You can only update your own lectures'
      });
    }

    // Handle file upload if present
    if (req.file) {
      updateData.fileUrl = `/uploads/lectures/${req.file.filename}`;
      
      // Delete old file if exists
      if (lecture.fileUrl) {
        const oldFilePath = path.join(__dirname, '../../', lecture.fileUrl);
        if (fs.existsSync(oldFilePath)) {
          fs.unlinkSync(oldFilePath);
        }
      }
    }

    const updatedLecture = await Lecture.findByIdAndUpdate(
      lectureId,
      updateData,
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      message: 'Lecture updated successfully',
      lecture: updatedLecture
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update lecture',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Delete lecture
export const deleteLecture = async (req, res) => {
  try {
    const { lectureId } = req.params;
    const adminId = req.adminId;

    // Check if lecture exists and belongs to admin
    const lecture = await Lecture.findById(lectureId);
    if (!lecture) {
      return res.status(404).json({
        success: false,
        message: 'Lecture not found'
      });
    }

    if (lecture.createdBy.toString() !== adminId) {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own lectures'
      });
    }

    // Delete associated file
    if (lecture.fileUrl) {
      const filePath = path.join(__dirname, '../../', lecture.fileUrl);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    }

    // Soft delete lecture
    await Lecture.findByIdAndUpdate(lectureId, { isActive: false });

    res.json({
      success: true,
      message: 'Lecture deleted successfully'
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete lecture',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Update student progress
export const updateProgress = async (req, res) => {
  try {
    const { lectureId } = req.params;
    const { progressPercentage, timeSpent, lastPosition } = req.body;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Student authentication required'
      });
    }

    // Get lecture and its course
    const lecture = await Lecture.findById(lectureId)
      .populate('sectionId', 'courseId');
    
    if (!lecture) {
      return res.status(404).json({
        success: false,
        message: 'Lecture not found'
      });
    }

    const courseId = lecture.sectionId.courseId;

    // Find or create progress record
    let progress = await StudentProgress.findOne({
      studentId,
      courseId,
      sectionId: lecture.sectionId._id,
      lectureId
    });

    if (!progress) {
      progress = new StudentProgress({
        studentId,
        courseId,
        sectionId: lecture.sectionId._id,
        lectureId
      });
    }

    // Update progress
    await progress.updateProgress(progressPercentage, timeSpent, lastPosition);

    res.json({
      success: true,
      message: 'Progress updated successfully',
      progress
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update progress',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Submit quiz attempt
export const submitQuizAttempt = async (req, res) => {
  try {
    const { lectureId } = req.params;
    const { answers } = req.body;
    const studentId = req.studentId;

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Student authentication required'
      });
    }

    // Get lecture
    const lecture = await Lecture.findById(lectureId)
      .populate('sectionId', 'courseId');
    
    if (!lecture || lecture.type !== 'quiz') {
      return res.status(404).json({
        success: false,
        message: 'Quiz lecture not found'
      });
    }

    if (!lecture.quiz || !lecture.quiz.questions) {
      return res.status(400).json({
        success: false,
        message: 'Quiz questions not found'
      });
    }

    // Calculate score
    let correctAnswers = 0;
    const totalQuestions = lecture.quiz.questions.length;
    const quizAnswers = answers.map((answer, index) => {
      const question = lecture.quiz.questions[index];
      const isCorrect = answer === question.correctAnswer;
      if (isCorrect) correctAnswers++;
      
      return {
        questionIndex: index,
        selectedAnswer: answer,
        isCorrect
      };
    });

    const score = Math.round((correctAnswers / totalQuestions) * 100);

    // Find or create progress record
    let progress = await StudentProgress.findOne({
      studentId,
      courseId: lecture.sectionId.courseId,
      sectionId: lecture.sectionId._id,
      lectureId
    });

    if (!progress) {
      progress = new StudentProgress({
        studentId,
        courseId: lecture.sectionId.courseId,
        sectionId: lecture.sectionId._id,
        lectureId
      });
    }

    // Add quiz attempt
    const attemptNumber = (progress.quizAttempts?.length || 0) + 1;
    progress.quizAttempts.push({
      attemptNumber,
      score,
      totalQuestions,
      correctAnswers,
      attemptedAt: new Date(),
      answers: quizAnswers
    });

    // Mark as completed if score meets passing requirement
    if (score >= (lecture.quiz.passingScore || 70)) {
      await progress.markCompleted();
    }

    await progress.save();

    res.json({
      success: true,
      message: 'Quiz submitted successfully',
      result: {
        score,
        correctAnswers,
        totalQuestions,
        passed: score >= (lecture.quiz.passingScore || 70),
        attemptNumber
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to submit quiz',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Export multer upload middleware
export { upload };
