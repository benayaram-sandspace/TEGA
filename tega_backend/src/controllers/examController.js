import Exam from '../models/Exam.js';
import Question from '../models/Question.js';
import QuestionPaper from '../models/QuestionPaper.js';
import ExamAttempt from '../models/ExamAttempt.js';
import ExamRegistration from '../models/ExamRegistration.js';
import Course from '../models/Course.js';
import Payment from '../models/Payment.js';
import { parseQuestionExcel, validateQuestionExcel, generateQuestionTemplate } from '../utils/excelParser.js';
import { checkTegaExamPaymentUtil } from './paymentController.js';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import mongoose from 'mongoose';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Helper function to mark completed exams as inactive
const markCompletedExamsAsInactive = async () => {
  try {
    const currentTime = new Date();
    
    // Find all active exams that might be completed
    const activeExams = await Exam.find({
      isActive: true,
      examDate: { $exists: true },
      duration: { $exists: true }
    });
    const completedExamIds = [];
    for (const exam of activeExams) {
      // Calculate exam end time based on the latest slot end time + duration
      let latestEndTime = null;
      
      if (exam.slots && exam.slots.length > 0) {
        // Find the latest slot end time
        for (const slot of exam.slots) {
          if (slot.isActive && slot.endTime) {
            // Parse slot end time and add duration
            const examDateStr = exam.examDate.toISOString().split('T')[0]; // Get YYYY-MM-DD
            const slotEndTime = new Date(`${examDateStr}T${slot.endTime}:00`);
            const slotEndTimeWithDuration = new Date(slotEndTime.getTime() + (exam.duration * 60 * 1000));
            
            if (!latestEndTime || slotEndTimeWithDuration > latestEndTime) {
              latestEndTime = slotEndTimeWithDuration;
            }
          }
        }
      }
      
      // Fallback to simple calculation if no slots
      if (!latestEndTime) {
        latestEndTime = new Date(exam.examDate.getTime() + (exam.duration * 60 * 1000));
      }
      if (currentTime > latestEndTime) {
        completedExamIds.push(exam._id);
      }
    }

    // Bulk update completed exams
    if (completedExamIds.length > 0) {
      await Exam.updateMany(
        { _id: { $in: completedExamIds } },
        { isActive: false }
      );
    } else {
    }
  } catch (error) {
  }
};

// Helper function to check if user has paid for a course
const checkCoursePayment = async (studentId, courseId) => {
  try {
    // Convert to ObjectId if needed
    const studentIdObj = typeof studentId === 'string' ? new mongoose.Types.ObjectId(studentId) : studentId;
    const courseIdObj = typeof courseId === 'string' ? new mongoose.Types.ObjectId(courseId) : courseId;
    // Check Payment model
    const payment = await Payment.findOne({
      studentId: studentIdObj,
      courseId: courseIdObj,
      status: 'completed'
    });
    if (payment) {
      return { hasPaid: true, source: 'payment' };
    }

    // Check RazorpayPayment model
    const RazorpayPayment = (await import('../models/RazorpayPayment.js')).default;
    const razorpayPayment = await RazorpayPayment.findOne({
      studentId: studentIdObj,
      courseId: courseIdObj,
      status: 'completed'
    });
    if (razorpayPayment) {
      return { hasPaid: true, source: 'razorpay' };
    }

    // Check UserCourse model (enrollment)
    const UserCourse = (await import('../models/UserCourse.js')).default;
    const userCourse = await UserCourse.findOne({
      studentId: studentIdObj,
      courseId: courseIdObj,
      isActive: true
    });
    if (userCourse) {
      return { hasPaid: true, source: 'usercourse' };
    }

    // Check Enrollment model (alternative enrollment tracking)
    const Enrollment = (await import('../models/Enrollment.js')).default;
    const enrollment = await Enrollment.findOne({
      studentId: studentIdObj,
      courseId: courseIdObj,
      status: 'enrolled'
    });
    if (enrollment) {
      return { hasPaid: true, source: 'enrollment' };
    }
    return { hasPaid: false, source: null };
  } catch (error) {
    return { hasPaid: false, source: null };
  }
};

// Helper function to check exam payment attempts
const checkExamPaymentAttempts = async (studentId, examId) => {
  try {
    const ExamPaymentAttempt = (await import('../models/ExamPaymentAttempt.js')).default;
    
    // Get all paid attempts for this exam
    const paidAttempts = await ExamPaymentAttempt.hasPaidAttempts(studentId, examId);
    
    // Get available (unused) attempts
    const availableAttempts = await ExamPaymentAttempt.getAvailableAttempts(studentId, examId);
    
    return {
      hasPaidAttempts: paidAttempts.length > 0,
      totalPaidAttempts: paidAttempts.length,
      availableAttempts: availableAttempts.length,
      paidAttempts: paidAttempts,
      availableAttempts: availableAttempts
    };
  } catch (error) {
    return {
      hasPaidAttempts: false,
      totalPaidAttempts: 0,
      availableAttempts: 0,
      paidAttempts: [],
      availableAttempts: []
    };
  }
};

// Helper function to check if user has paid for a Tega Exam
const checkTegaExamPayment = async (studentId, examId) => {
  try {
    // Convert to ObjectId if needed
    const studentIdObj = typeof studentId === 'string' ? new mongoose.Types.ObjectId(studentId) : studentId;
    const examIdObj = typeof examId === 'string' ? new mongoose.Types.ObjectId(examId) : examId;

    // Check Payment model for Tega Exam payment
    const payment = await Payment.findOne({
      studentId: studentIdObj,
      examId: examIdObj,
      status: 'completed'
    });

    if (payment) {
      return { hasPaid: true, source: 'tega_exam_payment' };
    }

    return { hasPaid: false, source: null };
  } catch (error) {
    return { hasPaid: false, source: null };
  }
};

// Get all exams for admin
export const getAllExams = async (req, res) => {
  try {
    // Admin should see all exams, not just active ones
    const exams = await Exam.find({})
      .populate('courseId', 'courseName')
      .populate('questionPaperId', 'name totalQuestions')
      .populate('createdBy', 'username')
      .sort({ createdAt: -1 });
    res.json({
      success: true,
      exams
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch exams'
    });
  }
};

// Get available exams for students
export const getAvailableExams = async (req, res) => {
  try {
    const { studentId } = req.params;
    // First, mark completed exams as inactive
    await markCompletedExamsAsInactive();
    
    // Get all exams and filter them properly
    const allExams = await Exam.find({})
      .populate('courseId', 'courseName price')
      .populate('questionPaperId', 'totalQuestions')
      .sort({ examDate: 1 });
    // Filter out completed exams directly in the query
    const currentTime = new Date();
    const activeExams = allExams.filter(exam => {
      // Check if exam is active
      if (!exam.isActive) {
        return false;
      }
      
      // Check if exam is completed using improved logic
      let latestEndTime = null;
      
      if (exam.slots && exam.slots.length > 0) {
        // Find the latest slot end time
        for (const slot of exam.slots) {
          if (slot.isActive && slot.endTime) {
            // Parse slot end time and add duration
            const examDateStr = exam.examDate.toISOString().split('T')[0]; // Get YYYY-MM-DD
            const slotEndTime = new Date(`${examDateStr}T${slot.endTime}:00`);
            const slotEndTimeWithDuration = new Date(slotEndTime.getTime() + (exam.duration * 60 * 1000));
            
            if (!latestEndTime || slotEndTimeWithDuration > latestEndTime) {
              latestEndTime = slotEndTimeWithDuration;
            }
          }
        }
      }
      
      // Fallback to simple calculation if no slots
      if (!latestEndTime) {
        latestEndTime = new Date(exam.examDate.getTime() + (exam.duration * 60 * 1000));
      }
      
      if (currentTime > latestEndTime) {
        return false;
      }
      
      return true;
    });
    // Check registration status and payment status for each exam
    const examsWithRegistration = await Promise.all(
      activeExams.map(async (exam) => {

        const registration = await ExamRegistration.findOne({
          studentId,
          examId: exam._id,
          isActive: true
        });

        // Check payment status based on exam type
        let coursePaymentStatus = { hasPaid: false, source: null };
        let isFreeForUser = !exam.requiresPayment;
        let effectivePrice = exam.price;
        let examPaymentAttempts = null;

        if (!exam.requiresPayment) {
          // Free exam
          isFreeForUser = true;
          effectivePrice = 0;
        } else if (exam.courseId && exam.courseId.toString() !== 'null') {
          // Regular course exam - check if user paid for the course
          coursePaymentStatus = await checkCoursePayment(studentId, exam.courseId);
          isFreeForUser = coursePaymentStatus.hasPaid;
          effectivePrice = isFreeForUser ? 0 : exam.price;
          
          // Also check exam payment attempts for this specific exam
          examPaymentAttempts = await checkExamPaymentAttempts(studentId, exam._id);
        } else {
          // Tega Exam - check if user paid for this specific exam
          const tegaExamPaymentStatus = await checkTegaExamPayment(studentId, exam._id);
          isFreeForUser = tegaExamPaymentStatus.hasPaid;
          effectivePrice = isFreeForUser ? 0 : exam.price;
          coursePaymentStatus = tegaExamPaymentStatus; // Use same structure for consistency
          
          // Also check exam payment attempts for this specific exam
          examPaymentAttempts = await checkExamPaymentAttempts(studentId, exam._id);
        }

        // Filter slots - check if they're active, not full, and within registration time (1 minute before start for Exams page)
        const now = new Date();
        const availableSlots = exam.slots.filter(slot => {
          if (!slot.isActive || slot.registeredStudents.length >= slot.maxParticipants) {
            return false;
          }
          
          // Check if slot is within registration time (30 seconds before start for Exams page)
          if (slot.startTime) {
            const [hours, minutes] = slot.startTime.split(':').map(Number);
            const slotDateTime = new Date(exam.examDate);
            slotDateTime.setHours(hours, minutes, 0, 0);
            
            // Calculate registration cutoff (30 seconds before slot start for Exams page)
            const registrationCutoff = new Date(slotDateTime.getTime() - 30 * 1000);
            
            if (now >= registrationCutoff) {
              return false;
            }
          }
          
          return true;
        });

        return {
          ...exam.toObject(),
          isRegistered: !!registration,
          registration: registration || null,
          availableSlots,
          coursePaymentStatus,
          isFreeForUser,
          effectivePrice,
          examPaymentAttempts
        };
      })
    );

    // Filter out exams with no available slots
    const examsWithSlots = examsWithRegistration.filter(exam => {
      const hasSlots = exam.availableSlots && exam.availableSlots.length > 0;
      return hasSlots;
    });
    res.json({
      success: true,
      exams: examsWithSlots
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch available exams'
    });
  }
};

// Create new exam
export const createExam = async (req, res) => {
  try {
    const {
      title,
      subject,
      courseId,
      description,
      duration,
      totalMarks,
      passingMarks,
      examDate,
      slots,
      instructions,
      requiresPayment,
      price,
      maxAttempts,
      questionPaperId,
      isTegaExam // New field to identify TEGA exams
    } = req.body;

    const { adminId } = req;

    // Handle TEGA exams vs course-based exams
    let finalCourseId = null;
    let examType = 'course-based';
    
    if (isTegaExam || courseId === 'tega-exam') {
      // This is a TEGA exam - standalone, not linked to any course
      examType = 'tega-exam';
    } else {
      // This is a regular course-based exam
      const course = await Course.findById(courseId);
      if (!course) {
        return res.status(400).json({
          success: false,
          message: 'Course not found'
        });
      }
      finalCourseId = courseId;
    }

    // Validate question paper exists
    if (questionPaperId) {
      const questionPaper = await QuestionPaper.findById(questionPaperId);
      if (!questionPaper) {
        return res.status(400).json({
          success: false,
          message: 'Question paper not found'
        });
      }
    }

    // Generate default subject if not provided
    let examSubject = subject;
    if (!examSubject) {
      if (examType === 'tega-exam') {
        examSubject = 'TEGA Exam';
      } else {
        const course = await Course.findById(courseId);
        examSubject = course ? course.courseName : 'General';
      }
    }
    // Process slots to ensure they have required fields
    const examDateObj = new Date(examDate);
    const processedSlots = (slots || []).map((slot, index) => {
      try {
        // Validate slot data
        if (!slot.startTime) {
          throw new Error(`Slot ${index + 1} missing startTime`);
        }
        if (!slot.endTime) {
          throw new Error(`Slot ${index + 1} missing endTime`);
        }
        
        // Create slotDateTime by combining examDate with slot startTime
        const [hours, minutes] = slot.startTime.split(':').map(Number);
        if (isNaN(hours) || isNaN(minutes)) {
          throw new Error(`Invalid time format for slot ${index + 1}: ${slot.startTime}`);
        }
        
        const slotDateTime = new Date(examDateObj);
        slotDateTime.setHours(hours, minutes, 0, 0);
        
        return {
          slotId: slot.slotId || `slot-${index + 1}`,
          startTime: slot.startTime,
          endTime: slot.endTime,
          slotDateTime: slotDateTime, // Add slotDateTime for real-time workflow
          maxParticipants: slot.maxStudents || slot.maxParticipants || 30,
          registeredStudents: [],
          isActive: true
        };
      } catch (slotError) {
        throw new Error(`Invalid slot data: ${slotError.message}`);
      }
    });
    // Calculate payment deadline (1 hour before exam start time)
    let paymentDeadline = null;
    if (requiresPayment && price > 0) {
      const examDateObj = new Date(examDate);
      // Set payment deadline to 1 hour before the earliest slot start time
      if (processedSlots && processedSlots.length > 0) {
        const earliestSlot = processedSlots.reduce((earliest, slot) => {
          const slotTime = new Date(`${examDateObj.toISOString().split('T')[0]}T${slot.startTime}:00`);
          return !earliest || slotTime < earliest ? slotTime : earliest;
        }, null);
        paymentDeadline = new Date(earliestSlot.getTime() - (60 * 60 * 1000)); // 1 hour before
      } else {
        // If no slots, set deadline to 1 hour before exam date
        paymentDeadline = new Date(examDateObj.getTime() - (60 * 60 * 1000));
      }
    }

    const exam = new Exam({
      title,
      subject: examSubject,
      courseId: finalCourseId,
      isTegaExam: examType === 'tega-exam',
      description,
      duration,
      totalMarks,
      passingMarks,
      examDate,
      slots: processedSlots,
      instructions,
      requiresPayment,
      price,
      maxAttempts,
      paymentDeadline,
      questionPaperId,
      createdBy: adminId
    });
    await exam.save();
    // Update question paper to mark it as used
    if (questionPaperId) {
      await QuestionPaper.findByIdAndUpdate(questionPaperId, {
        $addToSet: { usedInExams: exam._id }
      });
    }

    res.status(201).json({
      success: true,
      message: 'Exam created successfully',
      exam
    });
  } catch (error) {
    // Send detailed error message
    res.status(500).json({
      success: false,
      message: 'Failed to create exam',
      error: error.message || 'Unknown error',
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

// Download question template
export const downloadQuestionTemplate = async (req, res) => {
  try {
    const templateBuffer = generateQuestionTemplate();
    
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', 'attachment; filename="question_template.xlsx"');
    res.send(templateBuffer);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to generate template'
    });
  }
};

// Register for exam
export const registerForExam = async (req, res) => {
  try {
    const { examId } = req.params;
    const { studentId } = req;
    const { slotId } = req.body;

    // Check if exam exists
    const exam = await Exam.findById(examId);
    if (!exam || !exam.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found or not active'
      });
    }

    // Check if student already registered
    const existingRegistration = await ExamRegistration.findOne({
      studentId,
      examId,
      isActive: true
    });

    if (existingRegistration) {
      return res.status(400).json({
        success: false,
        message: 'You are already registered for this exam'
      });
    }

    // Check if student has reached maximum attempts for THIS SPECIFIC SLOT
    // Find the slot to get slot timing info
    const selectedSlot = exam.slots.find(slot => slot.slotId === slotId);
    if (!selectedSlot) {
      return res.status(400).json({
        success: false,
        message: 'Invalid slot selected'
      });
    }
    
    // Check attempts for this specific slot only
    const existingAttempts = await ExamAttempt.find({
      studentId,
      examId,
      slotId: slotId  // Only count attempts for this specific slot
    }).sort({ attemptNumber: -1 });
    
    const maxAttemptNumber = existingAttempts.length > 0 ? Math.max(...existingAttempts.map(a => a.attemptNumber)) : 0;
    if (maxAttemptNumber >= exam.maxAttempts) {
      // Check if admin has approved retake for the latest attempt in this slot
      const latestAttempt = existingAttempts.find(attempt => attempt.attemptNumber === maxAttemptNumber);
      if (!latestAttempt || !latestAttempt.canRetake) {
        return res.status(403).json({
          success: false,
          message: `You have reached the maximum number of attempts for this exam slot (${selectedSlot.startTime} - ${selectedSlot.endTime})`,
          errorType: 'MAX_ATTEMPTS_REACHED',
          maxAttempts: exam.maxAttempts,
          currentAttempts: maxAttemptNumber,
          examTitle: exam.title,
          examId: exam._id,
          slotId: slotId,
          slotTiming: `${selectedSlot.startTime} - ${selectedSlot.endTime}`,
          canRetake: false,
          attempts: existingAttempts.map(a => ({
            attemptNumber: a.attemptNumber,
            score: a.score,
            percentage: a.percentage,
            status: a.status,
            slotId: a.slotId,
            date: a.createdAt
          }))
        });
      }
    }

    // Find the selected slot
    const slot = exam.slots.find(s => s.slotId === slotId);
    if (!slot || !slot.isActive) {
      return res.status(400).json({
        success: false,
        message: 'Invalid or inactive slot selected'
      });
    }

    // Check time-based access control for registration
    const currentTime = new Date();
    const examDateStr = exam.examDate.toISOString().split('T')[0]; // Get YYYY-MM-DD
    const slotStartTime = new Date(`${examDateStr}T${slot.startTime}:00`);
    const gracePeriodEnd = new Date(slotStartTime.getTime() + (5 * 60 * 1000)); // 5 minutes grace
    
    if (currentTime > gracePeriodEnd) {
      return res.status(403).json({
        success: false,
        message: 'Registration period has expired. The grace period of 5 minutes has ended.',
        endTime: gracePeriodEnd.toISOString(),
        currentTime: currentTime.toISOString()
      });
    }

    // Check slot availability
    const slotRegistrationCount = await ExamRegistration.countDocuments({
      examId,
      slotId,
      paymentStatus: 'paid',
      isActive: true
    });

    if (slotRegistrationCount >= slot.maxParticipants) {
      return res.status(400).json({
        success: false,
        message: 'Selected slot is full'
      });
    }

    // Check payment status based on exam type
    let coursePaymentStatus = { hasPaid: false, source: null };
    let paymentStatus = 'pending';
    if (!exam.requiresPayment) {
      // Free exam - no payment required
      paymentStatus = 'paid';
    } else {
      // Paid exam - check payment requirements
      // First, check if this is a course-based exam
      if (exam.courseId && exam.courseId.toString() !== 'null') {
        // Course-based exam - user must have paid for the course
        coursePaymentStatus = await checkCoursePayment(studentId, exam.courseId);
        if (coursePaymentStatus.hasPaid) {
          // User has paid for the course - they can access the exam
          paymentStatus = 'paid';
        } else {
          // User hasn't paid for the course - they need to pay for the course first
          paymentStatus = 'pending';
        }
      } else {
        // Tega Exam or standalone exam - check payment status
        // First, check if user has paid for this specific TEGA exam
        try {
          // Check Payment model for this specific exam (including slot-specific payments)
          const examPayment = await Payment.findOne({
            studentId: studentId,
            examId: examId,
            status: 'completed'
          });
          
          if (examPayment) {
            paymentStatus = 'paid';
          } else {
            // Check RazorpayPayment model for this specific exam
            const RazorpayPayment = (await import('../models/RazorpayPayment.js')).default;
            const razorpayExamPayment = await RazorpayPayment.findOne({
              studentId: studentId,
              examId: examId,
              status: 'completed'
            });
            
            if (razorpayExamPayment) {
              paymentStatus = 'paid';
            } else {
              // Check for any TEGA exam payment (legacy check)
              const tegaExamPaymentStatus = await checkTegaExamPaymentUtil(studentId);
              if (tegaExamPaymentStatus && tegaExamPaymentStatus.hasPaidForTegaExam) {
                paymentStatus = 'paid';
              } else {
                // Check exam payment attempts as fallback
                const ExamPaymentAttempt = (await import('../models/ExamPaymentAttempt.js')).default;
                const availablePaymentAttempts = await ExamPaymentAttempt.getAvailableAttempts(studentId, examId);
                
                if (availablePaymentAttempts.length > 0) {
                  paymentStatus = 'paid';
                } else {
                  paymentStatus = 'pending';
                }
              }
            }
          }
        } catch (error) {
          paymentStatus = 'pending';
        }
      }
    }
    // If exam requires payment and user hasn't paid, prevent registration
    if (exam.requiresPayment && paymentStatus === 'pending') {
      // Determine what type of payment is required
      let paymentMessage = 'Payment required to register for this exam.';
      let paymentType = 'exam';
      let paymentAmount = exam.price;
      
      if (exam.courseId && exam.courseId.toString() !== 'null') {
        // Course-based exam - user needs to pay for the course
        const course = await Course.findById(exam.courseId);
        paymentMessage = `You must purchase the course "${course?.courseName || 'this course'}" to access this exam.`;
        paymentType = 'course';
        paymentAmount = course?.price || 0;
      } else {
        // Tega/Standalone exam - user needs to pay for the exam
        paymentMessage = `Payment required to access this exam. Please pay ₹${exam.price} to continue.`;
        paymentType = 'exam';
        paymentAmount = exam.price;
      }
      
      return res.status(403).json({
        success: false,
        message: paymentMessage,
        requiresPayment: true,
        paymentType: paymentType,
        examId: exam._id,
        examTitle: exam.title,
        courseId: exam.courseId,
        price: paymentAmount,
        coursePaymentStatus: coursePaymentStatus
      });
    }

    // Create registration
    const registration = new ExamRegistration({
      studentId,
      examId,
      courseId: exam.courseId,
      slotId,
      slotStartTime: slot.startTime,
      slotEndTime: slot.endTime,
      paymentStatus
    });
    await registration.save();
    // Add to exam's registered students
    exam.registeredStudents.push({
      studentId,
      slotId,
      registeredAt: new Date(),
      paymentStatus: registration.paymentStatus
    });
    await exam.save();
    res.status(201).json({
      success: true,
      message: 'Successfully registered for exam',
      registration,
      requiresPayment: exam.requiresPayment && !coursePaymentStatus.hasPaid,
      price: coursePaymentStatus.hasPaid ? 0 : exam.price,
      coursePaymentStatus,
      isFreeForUser: coursePaymentStatus.hasPaid
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to register for exam',
      error: error.message
    });
  }
};

// Get exam registrations (admin)
export const getExamRegistrations = async (req, res) => {
  try {
    const { examId } = req.params;

    const registrations = await ExamRegistration.find({ examId, isActive: true })
      .populate('studentId', 'studentName email phone')
      .sort({ registrationDate: -1 });

    res.json({
      success: true,
      registrations
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch registrations'
    });
  }
};

// Get exam registrations for student (student can see all registrations for an exam)
export const getExamRegistrationsForStudent = async (req, res) => {
  try {
    const { examId } = req.params;

    const registrations = await ExamRegistration.find({ examId, isActive: true })
      .populate('studentId', 'studentName email phone')
      .sort({ registrationDate: -1 });

    res.json({
      success: true,
      registrations
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch registrations'
    });
  }
};

// Start exam
export const startExam = async (req, res) => {
  try {
    const { examId } = req.params;
    const { studentId } = req;
    // Validate required parameters
    if (!examId || !studentId) {
      return res.status(400).json({
        success: false,
        message: 'Missing required parameters'
      });
    }

    // Check if student is registered
    const registration = await ExamRegistration.findOne({
      studentId,
      examId,
      isActive: true
    });
    if (registration) {
    }

    if (!registration) {
      return res.status(403).json({
        success: false,
        message: 'You are not registered for this exam'
      });
    }

    // Validate registration has required fields
    if (!registration.slotId) {
      return res.status(400).json({
        success: false,
        message: 'Invalid registration: missing slot information'
      });
    }

    // Check if exam exists and is active
    const exam = await Exam.findById(examId).populate('questions');
    if (exam) {
    }
    
    if (!exam || !exam.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found or not active'
      });
    }

    // Check payment access - more flexible validation
    // Check payment and attempt access
    let hasAccess = false;
    let paymentAttempts = null;
    let availableAttempt = null;
    if (!exam.requiresPayment) {
      hasAccess = true;
    } else {
      // Check exam payment attempts first
      paymentAttempts = await checkExamPaymentAttempts(studentId, exam._id);
      
      if (paymentAttempts.hasPaidAttempts && paymentAttempts.availableAttempts > 0) {
        // User has paid attempts available
        hasAccess = true;
        availableAttempt = paymentAttempts.availableAttempts[0]; // Get the first available attempt
      } else if (exam.courseId && exam.courseId.toString() !== 'null') {
        // Course-based exam - check course payment
        const coursePaymentStatus = await checkCoursePayment(studentId, exam.courseId);
        hasAccess = coursePaymentStatus.hasPaid;
      } else {
        // For standalone Tega Exam (no courseId), check if user paid for this specific exam
        // First check if registration shows payment status as 'paid'
        if (registration.paymentStatus === 'paid') {
          hasAccess = true;
        } else {
          // Fallback to TEGA exam payment check
          const tegaExamPaymentStatus = await checkTegaExamPayment(studentId, exam._id);
          hasAccess = tegaExamPaymentStatus.hasPaid;
          // If still no access, check for any TEGA exam payment (general check)
          if (!hasAccess) {
            const generalTegaPaymentStatus = await checkTegaExamPaymentUtil(studentId);
            if (generalTegaPaymentStatus && generalTegaPaymentStatus.hasPaidForTegaExam) {
              hasAccess = true;
            }
          }
        }
      }
    }

    // Final safety check: If registration shows payment as 'paid', grant access
    if (!hasAccess && registration.paymentStatus === 'paid') {
      hasAccess = true;
    }

    if (!hasAccess) {
      return res.status(403).json({
        success: false,
        message: 'Payment required to access this exam',
        requiresPayment: true,
        courseId: exam.courseId,
        examId: exam._id,
        paymentAttempts: paymentAttempts
      });
    }

    // Check time-based access control
    const currentTime = new Date();
    const slot = exam.slots.find(s => s.slotId === registration.slotId);
    if (slot) {
    }
    
    if (slot) {
      // Parse slot start time more accurately
      const examDateStr = exam.examDate.toISOString().split('T')[0]; // Get YYYY-MM-DD
      const slotStartTime = new Date(`${examDateStr}T${slot.startTime}:00`);
      const gracePeriodEnd = new Date(slotStartTime.getTime() + (5 * 60 * 1000)); // 5 minutes grace
      if (currentTime < slotStartTime) {
        return res.status(403).json({
          success: false,
          message: 'Exam has not started yet. Please wait until the start time.',
          startTime: slotStartTime.toISOString(),
          currentTime: currentTime.toISOString(),
          exam: {
            _id: exam._id,
            title: exam.title,
            subject: exam.subject,
            duration: exam.duration,
            description: exam.description,
            totalMarks: exam.totalMarks,
            passingMarks: exam.passingMarks,
            instructions: exam.instructions
          }
        });
      }
      
      // For Tega Exam, be more flexible with time access control
      const isTegaExam = exam.courseId && exam.courseId.toString() !== 'null' && 
                        exam.title && exam.title.toLowerCase().includes('tega');
      
      if (currentTime > gracePeriodEnd) {
        if (isTegaExam) {
          // For Tega Exam, allow access even after grace period (within exam duration)
          const slotEndTime = new Date(`${examDateStr}T${slot.endTime}:00`);
          const examEndTime = new Date(slotEndTime.getTime() + (exam.duration * 60 * 1000));
          if (currentTime > examEndTime) {
            return res.status(403).json({
              success: false,
              message: 'Exam has ended. The exam duration has expired.',
              endTime: examEndTime.toISOString(),
              currentTime: currentTime.toISOString()
            });
          }
        } else {
          return res.status(403).json({
            success: false,
            message: 'Exam access period has expired. The grace period of 5 minutes has ended.',
            endTime: gracePeriodEnd.toISOString(),
            currentTime: currentTime.toISOString()
          });
        }
      }
    }

    // Check if student has already attempted for THIS SPECIFIC SLOT
    // Get slot info for better error messages
    const currentSlot = exam.slots.find(slot => slot.slotId === registration.slotId);
    const slotTiming = currentSlot ? `${currentSlot.startTime} - ${currentSlot.endTime}` : 'Unknown';
    
    const existingAttempts = await ExamAttempt.find({
      studentId,
      examId,
      slotId: registration.slotId  // Only check attempts for this specific slot
    }).sort({ attemptNumber: -1 }); // Get the highest attempt number
    if (existingAttempts.length > 0) {
    }

    // Check if there's an in-progress attempt for this slot
    const inProgressAttempt = existingAttempts.find(attempt => attempt.status === 'in_progress');
    
    // Check max attempts for this slot - BUT allow if user has paid for more attempts
    const maxAttemptNumber = existingAttempts.length > 0 ? Math.max(...existingAttempts.map(a => a.attemptNumber)) : 0;
    
    // Get payment attempts to check if user has paid for more attempts
    const ExamPaymentAttempt = (await import('../models/ExamPaymentAttempt.js')).default;
    const paidAttempts = await ExamPaymentAttempt.hasPaidAttempts(studentId, examId);
    const availableAttempts = await ExamPaymentAttempt.getAvailableAttempts(studentId, examId);
    // Allow access if:
    // 1. User hasn't reached max attempts yet, OR
    // 2. User has paid for more attempts (has available unused attempts), OR  
    // 3. Admin has approved retake
    const hasAvailablePaidAttempts = availableAttempts.length > 0;
    const hasAdminRetake = existingAttempts.find(attempt => attempt.attemptNumber === maxAttemptNumber)?.canRetake;
    
    if (maxAttemptNumber >= exam.maxAttempts && !hasAvailablePaidAttempts && !hasAdminRetake) {
      return res.status(403).json({
        success: false,
        message: `You have reached the maximum number of attempts for this exam slot (${slotTiming}). Please make a payment to get additional attempts.`,
        errorType: 'MAX_ATTEMPTS_REACHED',
        slotId: registration.slotId,
        slotTiming: slotTiming,
        maxAttempts: exam.maxAttempts,
        currentAttempts: maxAttemptNumber,
        requiresPayment: exam.requiresPayment,
        price: exam.price
      });
    }
    
    if (hasAvailablePaidAttempts) {
    }
    if (hasAdminRetake) {
    }

    // Create or update exam attempt
    let examAttempt;
    if (inProgressAttempt) {
      examAttempt = inProgressAttempt;
    } else {
      // Determine attempt number based on payment attempts or existing attempts
      let nextAttemptNumber;
      if (availableAttempt) {
        // Use the attempt number from the paid attempt
        nextAttemptNumber = availableAttempt.attemptNumber;
      } else {
        // Fallback to existing logic
        nextAttemptNumber = maxAttemptNumber + 1;
      }
      
      // Use findOneAndUpdate with upsert to avoid duplicate key errors
      examAttempt = await ExamAttempt.findOneAndUpdate(
        { 
          studentId, 
          examId, 
          attemptNumber: nextAttemptNumber 
        },
        {
          studentId,
          examId,
          courseId: exam.courseId,
          duration: exam.duration,
          totalMarks: exam.totalMarks,
          attemptNumber: nextAttemptNumber,
          slotId: registration.slotId,
          slotStartTime: registration.slotStartTime,
          slotEndTime: registration.slotEndTime,
          timeRemaining: exam.duration * 60, // Convert to seconds
          status: 'in_progress',
          startTime: currentTime
        },
        { 
          upsert: true, 
          new: true,
          setDefaultsOnInsert: true
        }
      );
      // Mark the payment attempt as used if we have one
      if (availableAttempt) {
        const ExamPaymentAttempt = (await import('../models/ExamPaymentAttempt.js')).default;
        await ExamPaymentAttempt.findByIdAndUpdate(availableAttempt._id, {
          isUsed: true,
          usedAt: new Date(),
          examAttemptId: examAttempt._id,
          status: 'exam_started'
        });
      }
    }

    // Get questions for the exam
    let questions = [];
    try {
      if (exam.questionPaperId) {
        // Fetch questions from the question paper
        const QuestionPaper = (await import('../models/QuestionPaper.js')).default;
        const questionPaper = await QuestionPaper.findById(exam.questionPaperId).populate('questions');
        if (questionPaper && questionPaper.questions && questionPaper.questions.length > 0) {
          questions = questionPaper.questions.map(q => ({
            _id: q._id,
            question: q.question,
            options: q.options || [
              { label: 'A', text: q.optionA || '' },
              { label: 'B', text: q.optionB || '' },
              { label: 'C', text: q.optionC || '' },
              { label: 'D', text: q.optionD || '' }
            ],
            marks: q.marks || 1
          }));
        } else {
        }
      } else if (exam.questions && exam.questions.length > 0) {
        // Fallback to exam.questions if questionPaperId is not available
        const Question = (await import('../models/Question.js')).default;
        const examQuestions = await Question.find({ _id: { $in: exam.questions } })
          .select('-correctAnswer -correct');
        
        questions = examQuestions.map(q => ({
          _id: q._id,
          question: q.question,
          options: [
            { label: 'A', text: q.optionA || '' },
            { label: 'B', text: q.optionB || '' },
            { label: 'C', text: q.optionC || '' },
            { label: 'D', text: q.optionD || '' }
          ],
          marks: q.marks || 1
        }));
      } else {
      }
    } catch (questionError) {
      throw new Error(`Failed to fetch questions: ${questionError.message}`);
    }
    if (questions.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No questions found for this exam'
      });
    }

    res.json({
      success: true,
      exam,
      questions,
      examAttempt,
      savedAnswers: examAttempt.answers || {},
      markedQuestions: examAttempt.markedQuestions || []
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: `Failed to start exam: ${error.message}`,
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// Save answer
export const saveAnswer = async (req, res) => {
  try {
    const { examId } = req.params;
    const { studentId } = req;
    const { questionId, answer } = req.body;
    const examAttempt = await ExamAttempt.findOne({
      studentId,
      examId,
      status: 'in_progress'
    });
    if (examAttempt) {
    }

    if (!examAttempt) {
      return res.status(404).json({
        success: false,
        message: 'No active exam attempt found'
      });
    }

    // Update answer
    examAttempt.answers.set(questionId, answer);
    examAttempt.lastSavedAt = new Date();
    await examAttempt.save();
    res.json({
      success: true,
      message: 'Answer saved successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to save answer'
    });
  }
};

// Submit exam
export const submitExam = async (req, res) => {
  try {
    const { examId } = req.params;
    const { studentId } = req;
    const { answers, markedQuestions } = req.body;
    const examAttempt = await ExamAttempt.findOne({
      studentId,
      examId,
      status: 'in_progress'
    });
    if (examAttempt) {
    }

    if (!examAttempt) {
      return res.status(404).json({
        success: false,
        message: 'No active exam attempt found'
      });
    }

    const exam = await Exam.findById(examId);
    
    if (!exam) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found'
      });
    }

    // Get questions for scoring - use same logic as startExam
    let questions = [];
    try {
      if (exam.questionPaperId) {
        // Fetch questions from the question paper
        const QuestionPaper = (await import('../models/QuestionPaper.js')).default;
        const questionPaper = await QuestionPaper.findById(exam.questionPaperId).populate('questions');
        
        if (questionPaper && questionPaper.questions && questionPaper.questions.length > 0) {
          questions = questionPaper.questions;
        }
      } else if (exam.questions && exam.questions.length > 0) {
        // Fallback to exam.questions
        const Question = (await import('../models/Question.js')).default;
        questions = await Question.find({ _id: { $in: exam.questions } });
      }
    } catch (questionError) {
      return res.status(400).json({
        success: false,
        message: 'Failed to load exam questions for submission'
      });
    }

    if (questions.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No questions found in this exam'
      });
    }
    
    // Merge answers from saved attempt and submission
    // Priority: Request body answers > Saved answers (in case of auto-save)
    const mergedAnswers = { 
      ...Object.fromEntries(examAttempt.answers || new Map()),
      ...answers 
    };
    // Calculate score
    let correctAnswers = 0;
    let wrongAnswers = 0;
    const questionResults = [];

    for (const questionId of Object.keys(mergedAnswers)) {
      const question = questions.find(q => q._id.toString() === questionId);
      if (question) {
        const studentAnswer = mergedAnswers[questionId];
        const isCorrect = studentAnswer === question.correctAnswer;
        
        if (isCorrect) {
          correctAnswers++;
        } else {
          wrongAnswers++;
        }

        questionResults.push({
          questionId,
          studentAnswer,
          correctAnswer: question.correctAnswer,
          isCorrect,
          marks: isCorrect ? question.marks : 0
        });
      }
    }

    const unattempted = questions.length - Object.keys(mergedAnswers).length;
    const totalScore = correctAnswers;
    const percentage = (totalScore / exam.totalMarks) * 100;
    const isQualified = percentage >= 50; // 50% pass mark

    // Update exam attempt with merged answers
    examAttempt.status = 'completed';
    examAttempt.endTime = new Date();
    examAttempt.answers = mergedAnswers; // Use merged answers
    examAttempt.markedQuestions = markedQuestions;
    examAttempt.correctAnswers = correctAnswers;
    examAttempt.wrongAnswers = wrongAnswers;
    examAttempt.unattempted = unattempted;
    examAttempt.score = totalScore;
    examAttempt.percentage = percentage;
    examAttempt.isPassed = percentage >= exam.passingMarks;
    examAttempt.isQualified = isQualified;
    await examAttempt.save();

    res.json({
      success: true,
      message: 'Exam submitted successfully',
      result: {
        totalQuestions: questions.length,
        correctAnswers,
        wrongAnswers,
        unattempted,
        score: totalScore,
        totalMarks: exam.totalMarks,
        percentage: Math.round(percentage * 100) / 100,
        isPassed: examAttempt.isPassed,
        isQualified
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to submit exam'
    });
  }
};

// Get all exam results for a student (only published results)
export const getAllUserExamResults = async (req, res) => {
  try {
    const { studentId } = req;
    // Get all completed AND PUBLISHED exam attempts for the student
    const examAttempts = await ExamAttempt.find({
      studentId,
      status: 'completed',
      published: true // ✅ Only return published results
    })
    .populate('examId', 'title subject examDate duration totalMarks passingMarks')
    .populate('courseId', 'courseName')
    .sort({ createdAt: -1 });
    // Group results by exam
    const groupedResults = {};
    
    examAttempts.forEach(attempt => {
      const examId = attempt.examId._id.toString();
      if (!groupedResults[examId]) {
        groupedResults[examId] = {
          exam: attempt.examId,
          course: attempt.courseId,
          attempts: [],
          hasUnpublishedResults: false,
          unpublishedCount: 0
        };
      }
      
      // Only add published attempts
      if (attempt.published) {
        groupedResults[examId].attempts.push(attempt);
      }
    });

    // Convert to array format
    const results = Object.values(groupedResults);
    res.json({
      success: true,
      results,
      totalExams: results.length,
      totalAttempts: examAttempts.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch exam results'
    });
  }
};

// Get exam questions for result viewing
export const getExamQuestions = async (req, res) => {
  try {
    const { examId } = req.params;
    const { studentId } = req;

    // Check if student has completed this exam
    const examAttempt = await ExamAttempt.findOne({
      studentId,
      examId,
      status: 'completed'
    });

    if (!examAttempt) {
      return res.status(403).json({
        success: false,
        message: 'You have not completed this exam'
      });
    }

    // Get the exam
    const exam = await Exam.findById(examId);
    if (!exam) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found'
      });
    }

    let questions = [];
    
    try {
      if (exam.questionPaperId) {
        // Fetch questions from the question paper
        const questionPaper = await QuestionPaper.findById(exam.questionPaperId).populate('questions');
        if (questionPaper && questionPaper.questions) {
          questions = questionPaper.questions.map(q => ({
            _id: q._id,
            question: q.question,
            options: q.options,
            correctAnswer: q.correctAnswer,
            marks: q.marks || 1
          }));
        }
      } else if (exam.questions && exam.questions.length > 0) {
        // Fallback to exam.questions if questionPaperId is not available
        questions = await Question.find({ _id: { $in: exam.questions } })
          .select('question options correctAnswer marks');
      }
    } catch (questionError) {
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch questions'
      });
    }

    res.json({
      success: true,
      questions
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch exam questions'
    });
  }
};

// Get exam results
// Check if user can access exam (payment deadline and retake status)
export const checkExamAccess = async (req, res) => {
  try {
    const { examId } = req.params;
    const studentId = req.studentId;
    const exam = await Exam.findById(examId);
    if (!exam) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found'
      });
    }

    const currentTime = new Date();
    let canAccess = true;
    let reason = '';
    let requiresPayment = false;
    let isRetake = false;

    // Check payment deadline
    if (exam.paymentDeadline && currentTime > exam.paymentDeadline) {
      canAccess = false;
      reason = 'Payment deadline has passed. Payment must be completed before the exam start time.';
      return res.json({
        success: true,
        data: {
          canAccess: false,
          reason,
          paymentDeadline: exam.paymentDeadline,
          currentTime,
          requiresPayment: false,
          isRetake: false
        }
      });
    }

    // Check if exam requires payment
    if (exam.requiresPayment && exam.price > 0) {
      requiresPayment = true;

      // Check if user has already taken this exam
      const ExamAttempt = (await import('../models/ExamAttempt.js')).default;
      const existingAttempts = await ExamAttempt.find({
        studentId,
        examId,
        status: 'completed'
      });

      if (existingAttempts.length > 0) {
        isRetake = true;
        reason = 'You have already taken this exam. You need to pay again to retake it.';
      } else {
        reason = 'Payment required to access this exam.';
      }

      // Check if user has paid for this exam
      const RazorpayPayment = (await import('../models/RazorpayPayment.js')).default;
      const payment = await RazorpayPayment.findOne({
        studentId,
        $or: [
          { examId: examId },
          { isTegaExam: true, status: 'completed' }
        ],
        status: 'completed'
      });

      if (!payment) {
        canAccess = false;
      }
    }

    return res.json({
      success: true,
      data: {
        canAccess,
        reason,
        requiresPayment,
        isRetake,
        paymentDeadline: exam.paymentDeadline,
        currentTime,
        examPrice: exam.price
      }
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error checking exam access'
    });
  }
};

export const getExamResults = async (req, res) => {
  try {
    const { examId } = req.params;
    const { studentId } = req;
    // Only return PUBLISHED results to students
    const examAttempts = await ExamAttempt.find({
      studentId,
      examId,
      status: 'completed',
      published: true // ✅ Only return published results
    }).sort({ createdAt: -1 });
    const exam = await Exam.findById(examId).populate('courseId', 'courseName');

    // Check if there are unpublished results (for informational purposes)
    const unpublishedCount = await ExamAttempt.countDocuments({
      studentId,
      examId,
      status: 'completed',
      published: false
    });
    res.json({
      success: true,
      exam,
      attempts: examAttempts, // Only show published results
      hasUnpublishedResults: unpublishedCount > 0,
      unpublishedCount: unpublishedCount
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch exam results'
    });
  }
};

// Get all exam attempts (admin)
export const getAllExamAttempts = async (req, res) => {
  try {
    const { examId } = req.params;

    const attempts = await ExamAttempt.find({ examId, status: 'completed' })
      .populate('studentId', 'studentName email phone')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      attempts
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch exam attempts'
    });
  }
};

// Approve retake for student
export const approveRetake = async (req, res) => {
  try {
    const { examId, studentId } = req.params;
    const { adminId } = req;

    const examAttempt = await ExamAttempt.findOne({
      studentId,
      examId,
      status: 'completed'
    }).sort({ createdAt: -1 });

    if (!examAttempt) {
      return res.status(404).json({
        success: false,
        message: 'No exam attempt found for this student'
      });
    }

    examAttempt.canRetake = true;
    examAttempt.retakeApprovedBy = adminId;
    examAttempt.retakeApprovedAt = new Date();

    await examAttempt.save();

    res.json({
      success: true,
      message: 'Retake approved successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to approve retake'
    });
  }
};

// Update exam
export const updateExam = async (req, res) => {
  try {
    const { examId } = req.params;
    const { adminId } = req;
    const {
      title,
      courseId,
      description,
      duration,
      totalMarks,
      passingMarks,
      examDate,
      instructions,
      requiresPayment,
      price,
      maxAttempts,
      slots,
      questionPaperId
    } = req.body;
    // Find the exam
    const exam = await Exam.findById(examId);
    if (!exam) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found'
      });
    }

    // Check if admin has permission to update this exam
    if (exam.createdBy.toString() !== adminId) {
      return res.status(403).json({
        success: false,
        message: 'You do not have permission to update this exam'
      });
    }

    // Validate course if not tega-exam
    if (courseId && courseId !== 'tega-exam') {
      const course = await Course.findById(courseId);
      if (!course) {
        return res.status(400).json({
          success: false,
          message: 'Invalid course selected'
        });
      }
    }

    // Generate default subject if not provided
    let examSubject = exam.subject; // Keep existing subject
    if (!examSubject) {
      if (courseId === 'tega-exam') {
        examSubject = 'Tega Exam';
      } else {
        const course = await Course.findById(courseId);
        examSubject = course ? course.courseName : 'General';
      }
    }

    // Update exam fields
    exam.title = title || exam.title;
    exam.courseId = courseId || exam.courseId;
    exam.description = description || exam.description;
    exam.duration = duration || exam.duration;
    exam.totalMarks = totalMarks || exam.totalMarks;
    exam.passingMarks = passingMarks || exam.passingMarks;
    exam.examDate = examDate ? new Date(examDate) : exam.examDate;
    exam.instructions = instructions || exam.instructions;
    exam.requiresPayment = requiresPayment !== undefined ? requiresPayment : exam.requiresPayment;
    exam.price = price || exam.price;
    exam.maxAttempts = maxAttempts || exam.maxAttempts;
    exam.subject = examSubject;

    // Update slots (only if provided and not empty)
    if (slots && Array.isArray(slots) && slots.length > 0) {
      exam.slots = slots;
    }

    // Update question paper if provided
    if (questionPaperId) {
      exam.questionPaperId = questionPaperId;
    }

    await exam.save();
    res.json({
      success: true,
      message: 'Exam updated successfully',
      exam
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update exam'
    });
  }
};

// Delete exam
export const deleteExam = async (req, res) => {
  try {
    const { examId } = req.params;
    const { adminId } = req;
    // Find the exam
    const exam = await Exam.findById(examId);
    if (!exam) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found'
      });
    }

    // Admin can delete any exam (removed permission check)
    // Check if there are any registrations for this exam
    const registrationCount = await ExamRegistration.countDocuments({
      examId,
      isActive: true
    });
    // Delete related data (including registrations and attempts)
    // Delete all registrations for this exam
    const deletedRegistrations = await ExamRegistration.deleteMany({ examId });
    // Delete all attempts for this exam
    const deletedAttempts = await ExamAttempt.deleteMany({ examId });
    // Delete the exam
    await Exam.findByIdAndDelete(examId);
    res.json({
      success: true,
      message: `Exam deleted successfully. Removed ${deletedRegistrations.deletedCount} registrations and ${deletedAttempts.deletedCount} attempts.`
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete exam'
    });
  }
};

// Admin endpoint to manually mark completed exams as inactive
export const markCompletedExamsInactive = async (req, res) => {
  try {
    await markCompletedExamsAsInactive();
    
    res.json({
      success: true,
      message: 'Completed exams marked as inactive successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to mark completed exams as inactive'
    });
  }
};

// Admin endpoint to reactivate exams that were incorrectly marked as inactive
export const reactivateIncorrectlyInactiveExams = async (req, res) => {
  try {
    const currentTime = new Date();
    const inactiveExams = await Exam.find({ isActive: false });
    const examsToReactivate = [];
    
    for (const exam of inactiveExams) {
      // Calculate exam end time using improved logic
      let latestEndTime = null;
      
      if (exam.slots && exam.slots.length > 0) {
        for (const slot of exam.slots) {
          if (slot.isActive && slot.endTime) {
            const examDateStr = exam.examDate.toISOString().split('T')[0];
            const slotEndTime = new Date(`${examDateStr}T${slot.endTime}:00`);
            const slotEndTimeWithDuration = new Date(slotEndTime.getTime() + (exam.duration * 60 * 1000));
            
            if (!latestEndTime || slotEndTimeWithDuration > latestEndTime) {
              latestEndTime = slotEndTimeWithDuration;
            }
          }
        }
      }
      
      if (!latestEndTime) {
        latestEndTime = new Date(exam.examDate.getTime() + (exam.duration * 60 * 1000));
      }
      // If exam is not actually completed, mark it for reactivation
      if (currentTime <= latestEndTime) {
        examsToReactivate.push(exam._id);
      }
    }
    
    if (examsToReactivate.length > 0) {
      const result = await Exam.updateMany(
        { _id: { $in: examsToReactivate } },
        { isActive: true }
      );
      res.json({
        success: true,
        message: `Reactivated ${result.modifiedCount} exams that were incorrectly marked as inactive`,
        reactivatedCount: result.modifiedCount
      });
    } else {
      res.json({
        success: true,
        message: 'No exams need to be reactivated',
        reactivatedCount: 0
      });
    }
    
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to reactivate exams'
    });
  }
};

// Create exam payment attempt when user pays for an exam
export const createExamPaymentAttempt = async (req, res) => {
  try {
    const { examId, paymentId, paymentAmount } = req.body;
    const { studentId } = req;
    // Get exam details
    const exam = await Exam.findById(examId);
    if (!exam) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found'
      });
    }
    
    // Get the next attempt number
    const ExamPaymentAttempt = (await import('../models/ExamPaymentAttempt.js')).default;
    const nextAttemptNumber = await ExamPaymentAttempt.getNextAttemptNumber(studentId, examId);
    
    // Create the payment attempt record
    const examPaymentAttempt = new ExamPaymentAttempt({
      studentId,
      examId,
      courseId: exam.courseId,
      paymentId,
      attemptNumber: nextAttemptNumber,
      paymentAmount,
      status: 'paid'
    });
    
    await examPaymentAttempt.save();
    res.json({
      success: true,
      message: 'Exam payment attempt created successfully',
      data: {
        examPaymentAttemptId: examPaymentAttempt._id,
        attemptNumber: nextAttemptNumber,
        examTitle: exam.title,
        paymentAmount
      }
    });
    
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create exam payment attempt'
    });
  }
};

// Get exam payment attempts for a student
export const getExamPaymentAttempts = async (req, res) => {
  try {
    const { examId } = req.params;
    const { studentId } = req;
    const ExamPaymentAttempt = (await import('../models/ExamPaymentAttempt.js')).default;
    const paymentAttempts = await ExamPaymentAttempt.find({ studentId, examId })
      .populate('examId', 'title subject')
      .populate('courseId', 'courseName')
      .sort({ attemptNumber: 1 });
    
    res.json({
      success: true,
      data: paymentAttempts
    });
    
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get exam payment attempts'
    });
  }
};

// Get exam details by ID
export const getExamById = async (req, res) => {
  try {
    const { examId } = req.params;
    const exam = await Exam.findById(examId).select('-questions -questionPaper'); // Exclude questions and question paper for performance
    
    if (!exam) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found'
      });
    }
    res.json({
      success: true,
      exam: exam
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get exam details'
    });
  }
};
