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

    // console.log(`🔍 Checking ${activeExams.length} active exams for completion...`);

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
      
      // console.log(`🔍 Exam "${exam.title}": latest end time = ${latestEndTime.toISOString()}, current time = ${currentTime.toISOString()}`);
      
      if (currentTime > latestEndTime) {
        completedExamIds.push(exam._id);
        // console.log(`🔍 Exam "${exam.title}" is completed (ended at ${latestEndTime.toISOString()})`);
      }
    }

    // Bulk update completed exams
    if (completedExamIds.length > 0) {
      await Exam.updateMany(
        { _id: { $in: completedExamIds } },
        { isActive: false }
      );
      // console.log(`🔍 Marked ${completedExamIds.length} exams as inactive`);
    } else {
      // console.log('🔍 No completed exams found');
    }
  } catch (error) {
    // console.error('Error marking completed exams as inactive:', error);
  }
};

// Helper function to check if user has paid for a course
const checkCoursePayment = async (studentId, courseId) => {
  try {
    // console.log('🔍 checkCoursePayment called:', { studentId, courseId });
    
    // Convert to ObjectId if needed
    const studentIdObj = typeof studentId === 'string' ? new mongoose.Types.ObjectId(studentId) : studentId;
    const courseIdObj = typeof courseId === 'string' ? new mongoose.Types.ObjectId(courseId) : courseId;
    
    // console.log('🔍 Converted IDs:', { studentIdObj, courseIdObj });

    // Check Payment model
    // console.log('🔍 Checking Payment model for course payment...');
    const payment = await Payment.findOne({
      studentId: studentIdObj,
      courseId: courseIdObj,
      status: 'completed'
    });
    
    // console.log('🔍 Payment model result:', payment ? 'Found' : 'Not found');
    if (payment) {
      // console.log('🔍 Payment details:', { amount: payment.amount, paymentDate: payment.paymentDate });
      return { hasPaid: true, source: 'payment' };
    }

    // Check RazorpayPayment model
    // console.log('🔍 Checking RazorpayPayment model for course payment...');
    const RazorpayPayment = (await import('../models/RazorpayPayment.js')).default;
    const razorpayPayment = await RazorpayPayment.findOne({
      studentId: studentIdObj,
      courseId: courseIdObj,
      status: 'completed'
    });
    
    // console.log('🔍 RazorpayPayment model result:', razorpayPayment ? 'Found' : 'Not found');
    if (razorpayPayment) {
      // console.log('🔍 RazorpayPayment details:', { amount: razorpayPayment.amount, paymentDate: razorpayPayment.paymentDate });
      return { hasPaid: true, source: 'razorpay' };
    }

    // Check UserCourse model (enrollment)
    // console.log('🔍 Checking UserCourse model for enrollment...');
    const UserCourse = (await import('../models/UserCourse.js')).default;
    const userCourse = await UserCourse.findOne({
      studentId: studentIdObj,
      courseId: courseIdObj,
      isActive: true
    });
    
    // console.log('🔍 UserCourse model result:', userCourse ? 'Found' : 'Not found');
    if (userCourse) {
      // console.log('🔍 UserCourse details:', { enrolledAt: userCourse.enrolledAt, isActive: userCourse.isActive });
      return { hasPaid: true, source: 'usercourse' };
    }

    // Check Enrollment model (alternative enrollment tracking)
    // console.log('🔍 Checking Enrollment model for enrollment...');
    const Enrollment = (await import('../models/Enrollment.js')).default;
    const enrollment = await Enrollment.findOne({
      studentId: studentIdObj,
      courseId: courseIdObj,
      status: 'enrolled'
    });
    
    // console.log('🔍 Enrollment model result:', enrollment ? 'Found' : 'Not found');
    if (enrollment) {
      // console.log('🔍 Enrollment details:', { status: enrollment.status, enrolledAt: enrollment.enrolledAt });
      return { hasPaid: true, source: 'enrollment' };
    }

    // console.log('❌ No payment found in any model');
    return { hasPaid: false, source: null };
  } catch (error) {
    // console.error('Error checking course payment:', error);
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
    // console.error('Error checking exam payment attempts:', error);
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
    // console.error('Error checking Tega Exam payment:', error);
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

    // console.log(`🔍 Admin getAllExams: Found ${exams.length} total exams`);

    res.json({
      success: true,
      exams
    });
  } catch (error) {
    // console.error('Error fetching exams:', error);
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
    // console.log('🔍 getAvailableExams called for studentId:', studentId);
    
    // First, mark completed exams as inactive
    await markCompletedExamsAsInactive();
    
    // Get all exams and filter them properly
    const allExams = await Exam.find({})
      .populate('courseId', 'courseName price')
      .populate('questionPaperId', 'totalQuestions')
      .sort({ examDate: 1 });
    
    // console.log('🔍 All exams in database:', allExams.length);
    
    // Filter out completed exams directly in the query
    const currentTime = new Date();
    const activeExams = allExams.filter(exam => {
      // Check if exam is active
      if (!exam.isActive) {
        // console.log(`🔍 Filtering out inactive exam: ${exam.title}`);
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
        // console.log(`🔍 Filtering out completed exam: ${exam.title} (ended at ${latestEndTime.toISOString()})`);
        return false;
      }
      
      return true;
    });

    // console.log('🔍 Active exams after filtering:', activeExams.length);

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
            // console.log(`🔍 Slot ${slot.slotId} filtered out: inactive or full`);
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
              // console.log(`🔍 Slot ${slot.slotId} filtered out: registration cutoff passed (30 sec before start)`);
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
      // console.log(`🔍 Exam "${exam.title}": ${exam.availableSlots?.length || 0} available slots - ${hasSlots ? 'SHOWING' : 'HIDING'}`);
      return hasSlots;
    });

    // console.log('🔍 Final result: Returning', examsWithSlots.length, 'exams with available slots');
    res.json({
      success: true,
      exams: examsWithSlots
    });
  } catch (error) {
    // console.error('Error fetching available exams:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch available exams'
    });
  }
};

// Create new exam
export const createExam = async (req, res) => {
  try {
    // console.log('🔍 createExam called with:', {
    //   body: req.body,
    //   adminId: req.adminId
    // });

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
      // console.log('🔍 Creating TEGA exam (standalone)');
    } else {
      // This is a regular course-based exam
      const course = await Course.findById(courseId);
      // console.log('🔍 Course found:', course ? 'Yes' : 'No');
      if (!course) {
        return res.status(400).json({
          success: false,
          message: 'Course not found'
        });
      }
      finalCourseId = courseId;
      // console.log('🔍 Creating course-based exam for course:', course.courseName);
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
    // console.log('🔍 Generating subject for:', { subject, examType, courseId });
    let examSubject = subject;
    if (!examSubject) {
      if (examType === 'tega-exam') {
        examSubject = 'TEGA Exam';
      } else {
        const course = await Course.findById(courseId);
        examSubject = course ? course.courseName : 'General';
      }
    }
    // console.log('🔍 Final subject:', examSubject);

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
        // console.error(`❌ Error processing slot ${index + 1}:`, slotError.message);
        throw new Error(`Invalid slot data: ${slotError.message}`);
      }
    });

    // console.log('🔍 Creating exam with data:', {
    //   title,
    //   subject: examSubject,
    //   courseId: finalCourseId,
    //   description,
    //   duration,
    //   totalMarks,
    //   passingMarks,
    //   examDate,
    //   slots: processedSlots,
    //   instructions,
    //   requiresPayment,
    //   price,
    //   maxAttempts,
    //   questionPaperId,
    //   createdBy: adminId
    // });

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

    // console.log('🔍 Saving exam...');
    await exam.save();
    // console.log('🔍 Exam saved successfully:', exam._id);

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
    // console.error('❌ Error creating exam:', error);
    // console.error('❌ Error details:', {
    //   message: error.message,
    //   name: error.name,
    //   stack: error.stack,
    //   body: req.body
    // });
    
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
    // console.error('Error generating template:', error);
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
    // console.log('🔍 Checking max attempts for registration (slot-specific):', { studentId, examId, slotId });
    
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
    // console.log('🔍 Slot-specific max attempt number:', maxAttemptNumber, 'Exam max attempts:', exam.maxAttempts, 'for slot:', slotId);
    
    if (maxAttemptNumber >= exam.maxAttempts) {
      // Check if admin has approved retake for the latest attempt in this slot
      const latestAttempt = existingAttempts.find(attempt => attempt.attemptNumber === maxAttemptNumber);
      if (!latestAttempt || !latestAttempt.canRetake) {
        // console.log('❌ Registration blocked: Max attempts reached for this slot');
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
      // console.log('✅ Admin approved retake - allowing registration for this slot');
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

    // console.log('🔍 Exam payment validation:', {
    //   examId: exam._id,
    //   examTitle: exam.title,
    //   requiresPayment: exam.requiresPayment,
    //   courseId: exam.courseId,
    //   price: exam.price
    // });

    if (!exam.requiresPayment) {
      // Free exam - no payment required
      paymentStatus = 'paid';
      // console.log('🔍 Free exam - setting payment status to paid');
    } else {
      // Paid exam - check payment requirements
      // console.log('🔍 Paid exam - checking payment requirements');
      
      // First, check if this is a course-based exam
      if (exam.courseId && exam.courseId.toString() !== 'null') {
        // Course-based exam - user must have paid for the course
        // console.log('🔍 Course-based exam - checking course payment');
        coursePaymentStatus = await checkCoursePayment(studentId, exam.courseId);
        // console.log('🔍 Course payment status:', coursePaymentStatus);
        
        if (coursePaymentStatus.hasPaid) {
          // User has paid for the course - they can access the exam
          paymentStatus = 'paid';
          // console.log('✅ User has paid for course - access granted');
        } else {
          // User hasn't paid for the course - they need to pay for the course first
          paymentStatus = 'pending';
          // console.log('❌ User has not paid for course - access denied');
        }
      } else {
        // Tega Exam or standalone exam - check payment status
        // console.log('🔍 Tega/Standalone exam - checking payment status');
        
        // First, check if user has paid for this specific TEGA exam
        try {
          // console.log('🔍 Checking for TEGA exam payment for examId:', examId);
          
          // Check Payment model for this specific exam (including slot-specific payments)
          const examPayment = await Payment.findOne({
            studentId: studentId,
            examId: examId,
            status: 'completed'
          });
          
          if (examPayment) {
            paymentStatus = 'paid';
            // console.log('✅ User has paid for this specific TEGA exam - access granted');
            // console.log('🔍 Payment details:', {
            //   paymentId: examPayment._id,
            //   amount: examPayment.amount,
            //   slotId: examPayment.slotId,
            //   paymentDate: examPayment.paymentDate
            // });
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
              // console.log('✅ User has paid for this specific TEGA exam (Razorpay) - access granted');
              // console.log('🔍 Razorpay payment details:', {
              //   paymentId: razorpayExamPayment._id,
              //   amount: razorpayExamPayment.amount,
              //   slotId: razorpayExamPayment.slotId,
              //   paymentDate: razorpayExamPayment.paymentDate
              // });
            } else {
              // Check for any TEGA exam payment (legacy check)
              // console.log('🔍 No specific exam payment found, checking general TEGA payment...');
              const tegaExamPaymentStatus = await checkTegaExamPaymentUtil(studentId);
              // console.log('🔍 TEGA exam payment status result:', tegaExamPaymentStatus);
              
              if (tegaExamPaymentStatus && tegaExamPaymentStatus.hasPaidForTegaExam) {
                paymentStatus = 'paid';
                // console.log('✅ User has paid for TEGA exam (general) - access granted');
              } else {
                // Check exam payment attempts as fallback
                const ExamPaymentAttempt = (await import('../models/ExamPaymentAttempt.js')).default;
                const availablePaymentAttempts = await ExamPaymentAttempt.getAvailableAttempts(studentId, examId);
                
                if (availablePaymentAttempts.length > 0) {
                  paymentStatus = 'paid';
                  // console.log('✅ User has available payment attempts - access granted');
                } else {
                  paymentStatus = 'pending';
                  // console.log('❌ User has not paid for exam - access denied');
                }
              }
            }
          }
        } catch (error) {
          // console.error('❌ Error checking TEGA exam payment:', error);
          // console.error('❌ Error stack:', error.stack);
          paymentStatus = 'pending';
          // console.log('❌ Payment check failed - access denied');
        }
      }
    }
    
    // console.log('🔍 Final payment status for registration:', paymentStatus);
    // console.log('🔍 Exam requires payment:', exam.requiresPayment);
    // console.log('🔍 Payment status check:', paymentStatus === 'pending');

    // If exam requires payment and user hasn't paid, prevent registration
    if (exam.requiresPayment && paymentStatus === 'pending') {
      // console.log('❌ Registration blocked: Payment required but not paid');
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
    // console.log('🔍 Creating exam registration...');
    // console.log('🔍 Registration data:', {
    //   studentId,
    //   examId,
    //   courseId: exam.courseId,
    //   slotId,
    //   slotStartTime: slot.startTime,
    //   slotEndTime: slot.endTime,
    //   paymentStatus
    // });
    
    const registration = new ExamRegistration({
      studentId,
      examId,
      courseId: exam.courseId,
      slotId,
      slotStartTime: slot.startTime,
      slotEndTime: slot.endTime,
      paymentStatus
    });

    // console.log('🔍 Saving registration to database...');
    await registration.save();
    // console.log('✅ Registration saved successfully:', registration._id);

    // Add to exam's registered students
    // console.log('🔍 Adding student to exam registered students...');
    exam.registeredStudents.push({
      studentId,
      slotId,
      registeredAt: new Date(),
      paymentStatus: registration.paymentStatus
    });

    // console.log('🔍 Saving exam with updated registered students...');
    await exam.save();
    // console.log('✅ Exam saved successfully');

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
    // console.error('❌ Error registering for exam:', error);
    // console.error('❌ Error message:', error.message);
    // console.error('❌ Error stack:', error.stack);
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
    // console.error('Error fetching exam registrations:', error);
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
    // console.error('Error fetching exam registrations for student:', error);
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
    
    // console.log('🔍 startExam called:', { examId, studentId });

    // Validate required parameters
    if (!examId || !studentId) {
      // console.log('❌ Missing required parameters');
      return res.status(400).json({
        success: false,
        message: 'Missing required parameters'
      });
    }

    // Check if student is registered
    // console.log('🔍 Checking registration for:', { studentId, examId });
    const registration = await ExamRegistration.findOne({
      studentId,
      examId,
      isActive: true
    });
    
    // console.log('🔍 Registration found:', registration ? 'Yes' : 'No');
    if (registration) {
      // console.log('🔍 Registration details:', {
      //   slotId: registration.slotId,
      //   paymentStatus: registration.paymentStatus,
      //   isActive: registration.isActive
      // });
    }

    if (!registration) {
      // console.log('❌ No registration found');
      return res.status(403).json({
        success: false,
        message: 'You are not registered for this exam'
      });
    }

    // Validate registration has required fields
    if (!registration.slotId) {
      // console.log('❌ Registration missing slotId');
      return res.status(400).json({
        success: false,
        message: 'Invalid registration: missing slot information'
      });
    }

    // Check if exam exists and is active
    // console.log('🔍 Fetching exam:', examId);
    const exam = await Exam.findById(examId).populate('questions');
    // console.log('🔍 Exam found:', exam ? 'Yes' : 'No');
    if (exam) {
      // console.log('🔍 Exam details:', {
      //   title: exam.title,
      //   isActive: exam.isActive,
      //   examDate: exam.examDate,
      //   slots: exam.slots?.length || 0,
      //   requiresPayment: exam.requiresPayment
      // });
    }
    
    if (!exam || !exam.isActive) {
      // console.log('❌ Exam not found or not active');
      return res.status(404).json({
        success: false,
        message: 'Exam not found or not active'
      });
    }

    // Check payment access - more flexible validation
    // console.log('🔍 Exam payment check details:', {
    //   examId: exam._id,
    //   requiresPayment: exam.requiresPayment,
    //   courseId: exam.courseId,
    //   price: exam.price
    // });
    
    // Check payment and attempt access
    let hasAccess = false;
    let paymentAttempts = null;
    let availableAttempt = null;

    // console.log('🔍 Exam payment requirements:', {
    //   requiresPayment: exam.requiresPayment,
    //   courseId: exam.courseId,
    //   price: exam.price,
    //   examTitle: exam.title
    // });

    if (!exam.requiresPayment) {
      hasAccess = true;
      // console.log('🔍 Free exam - access granted');
    } else {
      // Check exam payment attempts first
      paymentAttempts = await checkExamPaymentAttempts(studentId, exam._id);
      
      if (paymentAttempts.hasPaidAttempts && paymentAttempts.availableAttempts > 0) {
        // User has paid attempts available
        hasAccess = true;
        availableAttempt = paymentAttempts.availableAttempts[0]; // Get the first available attempt
        // console.log('🔍 Exam payment attempt found:', availableAttempt.attemptNumber);
      } else if (exam.courseId && exam.courseId.toString() !== 'null') {
        // Course-based exam - check course payment
        // console.log('🔍 Checking course-based payment for courseId:', exam.courseId);
        const coursePaymentStatus = await checkCoursePayment(studentId, exam.courseId);
        hasAccess = coursePaymentStatus.hasPaid;
        // console.log('🔍 Course payment check result:', coursePaymentStatus);
      } else {
        // For standalone Tega Exam (no courseId), check if user paid for this specific exam
        // console.log('🔍 Checking standalone TEGA exam payment for examId:', exam._id);
        
        // First check if registration shows payment status as 'paid'
        if (registration.paymentStatus === 'paid') {
          // console.log('✅ Registration shows payment status as paid - granting access');
          hasAccess = true;
        } else {
          // Fallback to TEGA exam payment check
          const tegaExamPaymentStatus = await checkTegaExamPayment(studentId, exam._id);
          hasAccess = tegaExamPaymentStatus.hasPaid;
          // console.log('🔍 Tega exam payment check result:', tegaExamPaymentStatus);
          
          // If still no access, check for any TEGA exam payment (general check)
          if (!hasAccess) {
            // console.log('🔍 Checking for any TEGA exam payment...');
            const generalTegaPaymentStatus = await checkTegaExamPaymentUtil(studentId);
            if (generalTegaPaymentStatus && generalTegaPaymentStatus.hasPaidForTegaExam) {
              // console.log('✅ Found general TEGA exam payment - granting access');
              hasAccess = true;
            }
          }
        }
      }
    }

    // Final safety check: If registration shows payment as 'paid', grant access
    if (!hasAccess && registration.paymentStatus === 'paid') {
      // console.log('✅ Final safety check: Registration paymentStatus is paid - granting access');
      hasAccess = true;
    }

    if (!hasAccess) {
      // console.log('❌ Payment required - access denied');
      // console.log('🔍 Debug info:', {
      //   examId: exam._id,
      //   examTitle: exam.title,
      //   courseId: exam.courseId,
      //   requiresPayment: exam.requiresPayment,
      //   price: exam.price,
      //   hasPaidAttempts: paymentAttempts?.hasPaidAttempts || false,
      //   availableAttempts: paymentAttempts?.availableAttempts?.length || 0,
      //   registrationPaymentStatus: registration.paymentStatus
      // });
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
    // console.log('🔍 Finding slot for registration:', registration.slotId);
    const slot = exam.slots.find(s => s.slotId === registration.slotId);
    // console.log('🔍 Slot found:', slot ? 'Yes' : 'No');
    if (slot) {
      // console.log('🔍 Slot details:', {
      //   slotId: slot.slotId,
      //   startTime: slot.startTime,
      //   isActive: slot.isActive
      // });
    }
    
    if (slot) {
      // Parse slot start time more accurately
      const examDateStr = exam.examDate.toISOString().split('T')[0]; // Get YYYY-MM-DD
      const slotStartTime = new Date(`${examDateStr}T${slot.startTime}:00`);
      const gracePeriodEnd = new Date(slotStartTime.getTime() + (5 * 60 * 1000)); // 5 minutes grace
      
      // console.log('🔍 startExam time check:');
      // console.log(`  - Current time: ${currentTime.toISOString()}`);
      // console.log(`  - Slot start time: ${slotStartTime.toISOString()}`);
      // console.log(`  - Grace period ends: ${gracePeriodEnd.toISOString()}`);
      // console.log(`  - Is before start: ${currentTime < slotStartTime}`);
      // console.log(`  - Is after grace period: ${currentTime > gracePeriodEnd}`);
      
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
          // console.log('🔍 Tega Exam: Allowing access after grace period but within exam duration');
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
    // console.log('🔍 Checking existing attempts for slot:', { studentId, examId, slotId: registration.slotId });
    
    // Get slot info for better error messages
    const currentSlot = exam.slots.find(slot => slot.slotId === registration.slotId);
    const slotTiming = currentSlot ? `${currentSlot.startTime} - ${currentSlot.endTime}` : 'Unknown';
    
    const existingAttempts = await ExamAttempt.find({
      studentId,
      examId,
      slotId: registration.slotId  // Only check attempts for this specific slot
    }).sort({ attemptNumber: -1 }); // Get the highest attempt number
    
    // console.log('🔍 Slot-specific existing attempts found:', existingAttempts.length, 'for slot:', registration.slotId);
    if (existingAttempts.length > 0) {
      // console.log('🔍 Slot-specific existing attempts details:', existingAttempts.map(attempt => ({
      //   attemptNumber: attempt.attemptNumber,
      //   status: attempt.status,
      //   slotId: attempt.slotId,
      //   createdAt: attempt.createdAt
      // })));
    }

    // Check if there's an in-progress attempt for this slot
    const inProgressAttempt = existingAttempts.find(attempt => attempt.status === 'in_progress');
    
    // Check max attempts for this slot - BUT allow if user has paid for more attempts
    const maxAttemptNumber = existingAttempts.length > 0 ? Math.max(...existingAttempts.map(a => a.attemptNumber)) : 0;
    
    // Get payment attempts to check if user has paid for more attempts
    const ExamPaymentAttempt = (await import('../models/ExamPaymentAttempt.js')).default;
    const paidAttempts = await ExamPaymentAttempt.hasPaidAttempts(studentId, examId);
    const availableAttempts = await ExamPaymentAttempt.getAvailableAttempts(studentId, examId);
    
    // console.log('🔍 Payment attempt analysis:', {
    //   maxAttemptNumber,
    //   examMaxAttempts: exam.maxAttempts,
    //   totalPaidAttempts: paidAttempts.length,
    //   availableUnusedAttempts: availableAttempts.length,
    //   hasAvailableAttempt: availableAttempts.length > 0
    // });
    
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
      // console.log('🔍 User has paid for additional attempts - allowing access');
    }
    if (hasAdminRetake) {
      // console.log('🔍 Admin has approved retake for this slot - allowing additional attempt');
    }

    // Create or update exam attempt
    // console.log('🔍 Creating/updating exam attempt...');
    let examAttempt;
    if (inProgressAttempt) {
      // console.log('🔍 Using existing in-progress attempt');
      examAttempt = inProgressAttempt;
    } else {
      // console.log('🔍 Creating new exam attempt');
      
      // Determine attempt number based on payment attempts or existing attempts
      let nextAttemptNumber;
      if (availableAttempt) {
        // Use the attempt number from the paid attempt
        nextAttemptNumber = availableAttempt.attemptNumber;
        // console.log('🔍 Using paid attempt number:', nextAttemptNumber);
      } else {
        // Fallback to existing logic
        nextAttemptNumber = maxAttemptNumber + 1;
        // console.log('🔍 Using calculated attempt number:', nextAttemptNumber);
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
      // console.log('🔍 New exam attempt created/updated with attempt number:', nextAttemptNumber);
      
      // Mark the payment attempt as used if we have one
      if (availableAttempt) {
        const ExamPaymentAttempt = (await import('../models/ExamPaymentAttempt.js')).default;
        await ExamPaymentAttempt.findByIdAndUpdate(availableAttempt._id, {
          isUsed: true,
          usedAt: new Date(),
          examAttemptId: examAttempt._id,
          status: 'exam_started'
        });
        // console.log('🔍 Marked payment attempt as used:', availableAttempt._id);
      }
    }

    // Get questions for the exam
    // console.log('🔍 Getting questions for exam:', {
    //   examId: exam._id,
    //   questionPaperId: exam.questionPaperId,
    //   examQuestions: exam.questions?.length || 0
    // });
    
    let questions = [];
    try {
      if (exam.questionPaperId) {
        // Fetch questions from the question paper
        // console.log('🔍 Fetching questions from question paper:', exam.questionPaperId);
        const QuestionPaper = (await import('../models/QuestionPaper.js')).default;
        const questionPaper = await QuestionPaper.findById(exam.questionPaperId).populate('questions');
        // console.log('🔍 Question paper found:', questionPaper ? 'Yes' : 'No');
        // console.log('🔍 Questions in question paper:', questionPaper?.questions?.length || 0);
        
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
          // console.log('🔍 Mapped questions count:', questions.length);
        } else {
          // console.log('⚠️ Question paper found but no questions in it');
        }
      } else if (exam.questions && exam.questions.length > 0) {
        // Fallback to exam.questions if questionPaperId is not available
        // console.log('🔍 Using fallback - fetching from exam.questions');
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
        // console.log('🔍 Fallback questions count:', questions.length);
      } else {
        // console.log('⚠️ No questionPaperId and no exam.questions found');
      }
    } catch (questionError) {
      // console.error('❌ Error fetching questions:', questionError);
      throw new Error(`Failed to fetch questions: ${questionError.message}`);
    }
    
    // console.log('🔍 Final questions count:', questions.length);
    
    if (questions.length === 0) {
      // console.log('❌ No questions found for exam');
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
    // console.error('❌ Error starting exam:', error);
    // console.error('❌ Error details:', {
    //   message: error.message,
    //   stack: error.stack,
    //   examId: req.params.examId,
    //   studentId: req.studentId
    // });
    
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

    // console.log('💾 saveAnswer called:', {
    //   examId,
    //   studentId,
    //   questionId,
    //   answer,
    //   answerType: typeof answer
    // });

    const examAttempt = await ExamAttempt.findOne({
      studentId,
      examId,
      status: 'in_progress'
    });

    // console.log('🔍 Exam attempt found:', examAttempt ? 'Yes' : 'No');
    if (examAttempt) {
    // console.log('🔍 Exam attempt details:', {
    //   attemptId: examAttempt._id,
    //   currentAnswers: Object.keys(examAttempt.answers || {}).length,
    //   status: examAttempt.status
    // });
    }

    if (!examAttempt) {
      // console.log('❌ No active exam attempt found');
      return res.status(404).json({
        success: false,
        message: 'No active exam attempt found'
      });
    }

    // Update answer
    // console.log('📝 Saving answer:', { questionId, answer });
    examAttempt.answers.set(questionId, answer);
    examAttempt.lastSavedAt = new Date();
    await examAttempt.save();
    
    // console.log('✅ Answer saved successfully. Total answers:', Object.keys(examAttempt.answers || {}).length);

    res.json({
      success: true,
      message: 'Answer saved successfully'
    });
  } catch (error) {
    // console.error('❌ Error saving answer:', error);
    // console.error('❌ Error stack:', error.stack);
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

    // console.log('📤 submitExam called:', {
    //   examId,
    //   studentId,
    //   answersFromBody: Object.keys(answers || {}).length,
    //   markedQuestions: markedQuestions?.length || 0
    // });

    const examAttempt = await ExamAttempt.findOne({
      studentId,
      examId,
      status: 'in_progress'
    });

    // console.log('🔍 Exam attempt found:', examAttempt ? 'Yes' : 'No');
    if (examAttempt) {
      // console.log('🔍 Exam attempt saved answers:', Object.keys(examAttempt.answers || {}).length);
      // console.log('🔍 Comparing answers:', {
      //   fromBody: Object.keys(answers || {}).length,
      //   fromDB: Object.keys(examAttempt.answers || {}).length,
      //   shouldMerge: Object.keys(examAttempt.answers || {}).length > Object.keys(answers || {}).length
      // });
    }

    if (!examAttempt) {
      // console.log('❌ No active exam attempt found');
      return res.status(404).json({
        success: false,
        message: 'No active exam attempt found'
      });
    }

    const exam = await Exam.findById(examId);
    
    if (!exam) {
      // console.log('❌ Exam not found for submission');
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
        // console.log('🔍 Fetching questions from question paper for submission:', exam.questionPaperId);
        const QuestionPaper = (await import('../models/QuestionPaper.js')).default;
        const questionPaper = await QuestionPaper.findById(exam.questionPaperId).populate('questions');
        
        if (questionPaper && questionPaper.questions && questionPaper.questions.length > 0) {
          questions = questionPaper.questions;
          // console.log('🔍 Questions loaded for scoring:', questions.length);
        }
      } else if (exam.questions && exam.questions.length > 0) {
        // Fallback to exam.questions
        // console.log('🔍 Using fallback - fetching from exam.questions for scoring');
        const Question = (await import('../models/Question.js')).default;
        questions = await Question.find({ _id: { $in: exam.questions } });
        // console.log('🔍 Fallback questions loaded for scoring:', questions.length);
      }
    } catch (questionError) {
      // console.error('❌ Error fetching questions for submission:', questionError);
      return res.status(400).json({
        success: false,
        message: 'Failed to load exam questions for submission'
      });
    }

    if (questions.length === 0) {
      // console.log('❌ No questions found in exam for submission');
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
    
    // console.log('🔍 Answer merging:', {
    //   savedAnswers: Object.keys(examAttempt.answers || {}).length,
    //   submittedAnswers: Object.keys(answers || {}).length,
    //   mergedAnswers: Object.keys(mergedAnswers).length
    // });
    
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

    // console.log('✅ Exam submitted with results:', {
    //   totalQuestions: questions.length,
    //   answeredQuestions: Object.keys(mergedAnswers).length,
    //   correctAnswers,
    //   wrongAnswers,
    //   unattempted,
    //   score: totalScore,
    //   percentage: Math.round(percentage * 100) / 100
    // });

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
    // console.error('Error submitting exam:', error);
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

    // console.log('📊 getAllUserExamResults called for student:', studentId);

    // Get all completed AND PUBLISHED exam attempts for the student
    const examAttempts = await ExamAttempt.find({
      studentId,
      status: 'completed',
      published: true // ✅ Only return published results
    })
    .populate('examId', 'title subject examDate duration totalMarks passingMarks')
    .populate('courseId', 'courseName')
    .sort({ createdAt: -1 });

    // console.log(`🔍 Found ${examAttempts.length} published results for student`);

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

    // console.log(`✅ Returning ${results.length} published exam results`);

    res.json({
      success: true,
      results,
      totalExams: results.length,
      totalAttempts: examAttempts.length
    });
  } catch (error) {
    // console.error('Error fetching all user exam results:', error);
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
      // console.error('Error fetching questions:', questionError);
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
    // console.error('Error fetching exam questions:', error);
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

    // console.log('🔍 Checking exam access for:', { examId, studentId });

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
    // console.error('Error checking exam access:', error);
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

    // console.log('📊 getExamResults called:', { examId, studentId });

    // Only return PUBLISHED results to students
    const examAttempts = await ExamAttempt.find({
      studentId,
      examId,
      status: 'completed',
      published: true // ✅ Only return published results
    }).sort({ createdAt: -1 });

    // console.log(`🔍 Found ${examAttempts.length} published results for exam`);

    const exam = await Exam.findById(examId).populate('courseId', 'courseName');

    // Check if there are unpublished results (for informational purposes)
    const unpublishedCount = await ExamAttempt.countDocuments({
      studentId,
      examId,
      status: 'completed',
      published: false
    });

    // console.log(`🔍 Unpublished results: ${unpublishedCount}`);

    res.json({
      success: true,
      exam,
      attempts: examAttempts, // Only show published results
      hasUnpublishedResults: unpublishedCount > 0,
      unpublishedCount: unpublishedCount
    });
  } catch (error) {
    // console.error('Error fetching exam results:', error);
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
    // console.error('Error fetching exam attempts:', error);
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
    // console.error('Error approving retake:', error);
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

    // console.log('🔍 updateExam called:', { examId, adminId, title, courseId });

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

    // console.log('✅ Exam updated successfully:', exam._id);

    res.json({
      success: true,
      message: 'Exam updated successfully',
      exam
    });
  } catch (error) {
    // console.error('Error updating exam:', error);
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

    // console.log('🔍 deleteExam called:', { examId, adminId });

    // Find the exam
    const exam = await Exam.findById(examId);
    if (!exam) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found'
      });
    }

    // Admin can delete any exam (removed permission check)
    // console.log('🔍 Admin permission check passed - any admin can delete any exam');

    // Check if there are any registrations for this exam
    const registrationCount = await ExamRegistration.countDocuments({
      examId,
      isActive: true
    });

    // console.log(`🔍 Found ${registrationCount} registrations for exam ${examId}`);

    // Delete related data (including registrations and attempts)
    // console.log('🔍 Deleting related exam data...');
    
    // Delete all registrations for this exam
    const deletedRegistrations = await ExamRegistration.deleteMany({ examId });
    // console.log(`🔍 Deleted ${deletedRegistrations.deletedCount} registrations`);
    
    // Delete all attempts for this exam
    const deletedAttempts = await ExamAttempt.deleteMany({ examId });
    // console.log(`🔍 Deleted ${deletedAttempts.deletedCount} attempts`);
    
    // Delete the exam
    await Exam.findByIdAndDelete(examId);

    // console.log('✅ Exam deleted successfully:', examId);

    res.json({
      success: true,
      message: `Exam deleted successfully. Removed ${deletedRegistrations.deletedCount} registrations and ${deletedAttempts.deletedCount} attempts.`
    });
  } catch (error) {
    // console.error('Error deleting exam:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete exam'
    });
  }
};

// Admin endpoint to manually mark completed exams as inactive
export const markCompletedExamsInactive = async (req, res) => {
  try {
    // console.log('🔍 markCompletedExamsInactive called by admin:', req.adminId);
    
    await markCompletedExamsAsInactive();
    
    res.json({
      success: true,
      message: 'Completed exams marked as inactive successfully'
    });
  } catch (error) {
    // console.error('Error marking completed exams as inactive:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark completed exams as inactive'
    });
  }
};

// Admin endpoint to reactivate exams that were incorrectly marked as inactive
export const reactivateIncorrectlyInactiveExams = async (req, res) => {
  try {
    // console.log('🔍 reactivateIncorrectlyInactiveExams called by admin:', req.adminId);
    
    const currentTime = new Date();
    const inactiveExams = await Exam.find({ isActive: false });
    
    // console.log(`🔍 Found ${inactiveExams.length} inactive exams to check`);
    
    const examsToReactivate = [];
    
    for (const exam of inactiveExams) {
      // console.log(`🔍 Checking exam: ${exam.title}`);
      
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
      
      // console.log(`🔍 Exam "${exam.title}": end time = ${latestEndTime.toISOString()}, current = ${currentTime.toISOString()}`);
      
      // If exam is not actually completed, mark it for reactivation
      if (currentTime <= latestEndTime) {
        examsToReactivate.push(exam._id);
        // console.log(`✅ Exam "${exam.title}" should be reactivated`);
      }
    }
    
    if (examsToReactivate.length > 0) {
      const result = await Exam.updateMany(
        { _id: { $in: examsToReactivate } },
        { isActive: true }
      );
      
      // console.log(`✅ Reactivated ${result.modifiedCount} exams`);
      
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
    // console.error('Error reactivating exams:', error);
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
    
    // console.log('🔍 Creating exam payment attempt:', { examId, studentId, paymentId, paymentAmount });
    
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
    
    // console.log('✅ Exam payment attempt created:', examPaymentAttempt._id);
    
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
    // console.error('Error creating exam payment attempt:', error);
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
    
    // console.log('🔍 Getting exam payment attempts:', { examId, studentId });
    
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
    // console.error('Error getting exam payment attempts:', error);
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
    // console.log('🔍 Getting exam details for ID:', examId);

    const exam = await Exam.findById(examId).select('-questions -questionPaper'); // Exclude questions and question paper for performance
    
    if (!exam) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found'
      });
    }

    // console.log('✅ Exam found:', {
    //   id: exam._id,
    //   title: exam.title,
    //   isTegaExam: exam.isTegaExam,
    //   examDate: exam.examDate,
    //   duration: exam.duration,
    //   slotsCount: exam.slots?.length || 0
    // });

    res.json({
      success: true,
      exam: exam
    });
  } catch (error) {
    // console.error('Error getting exam by ID:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get exam details'
    });
  }
};
