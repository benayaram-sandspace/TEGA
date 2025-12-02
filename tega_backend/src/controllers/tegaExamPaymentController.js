import Payment from '../models/Payment.js';
import Exam from '../models/Exam.js';
import ExamRegistration from '../models/ExamRegistration.js';
import Student from '../models/Student.js';
import Admin from '../models/Admin.js';
import Notification from '../models/Notification.js';
import mongoose from 'mongoose';

// Create Tega Exam payment order
export const createTegaExamPaymentOrder = async (req, res) => {
  try {
    const { examId, amount } = req.body;
    const userId = req.studentId;

    // Validate exam
    const exam = await Exam.findById(examId);
    if (!exam || !exam.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found or not active'
      });
    }

    // Check if this is a Tega Exam
    if (exam.courseId !== null) {
      return res.status(400).json({
        success: false,
        message: 'This is not a Tega Exam'
      });
    }

    // Check if exam requires payment
    if (!exam.requiresPayment) {
      return res.status(400).json({
        success: false,
        message: 'This exam does not require payment'
      });
    }

    // Check if user already paid for this exam
    const existingPayment = await Payment.findOne({
      studentId: userId,
      examId: examId,
      status: 'completed'
    });

    if (existingPayment) {
      return res.status(400).json({
        success: false,
        message: 'You have already paid for this exam'
      });
    }

    // Create payment record
    const payment = new Payment({
      studentId: userId,
      courseId: null, // Tega Exam doesn't have a course
      examId: examId, // Add examId field
      courseName: exam.title, // Use exam title as course name
      amount: amount,
      originalPrice: exam.price,
      currency: 'INR',
      paymentMethod: 'razorpay',
      status: 'pending',
      description: `Payment for Tega Exam: ${exam.title}`,
      examAccess: true,
      validUntil: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) // Valid for 1 year
    });

    await payment.save();

    res.json({
      success: true,
      data: {
        paymentId: payment._id,
        amount: amount,
        currency: 'INR',
        examId: examId,
        examTitle: exam.title
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create payment order'
    });
  }
};

// Process Tega Exam dummy payment (for development/testing)
export const processTegaExamDummyPayment = async (req, res) => {
  try {
    const { examId, paymentMethod, paymentDetails } = req.body;
    const userId = req.studentId;
    // Validate exam
    const exam = await Exam.findById(examId);
    if (!exam || !exam.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Exam not found or not active'
      });
    }

    // Check if this is a Tega Exam
    if (exam.courseId !== null) {
      return res.status(400).json({
        success: false,
        message: 'This is not a Tega Exam'
      });
    }

    // Check if exam requires payment
    if (!exam.requiresPayment) {
      return res.status(400).json({
        success: false,
        message: 'This exam does not require payment'
      });
    }

    // Check if user already paid for this exam
    const existingPayment = await Payment.findOne({
      studentId: userId,
      examId: examId,
      status: 'completed'
    });

    if (existingPayment) {
      return res.status(400).json({
        success: false,
        message: 'You have already paid for this exam'
      });
    }

    // Simulate payment processing delay
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Create payment record
    const payment = new Payment({
      studentId: userId,
      courseId: null, // Tega Exam doesn't have a course
      examId: examId, // Add examId field
      courseName: exam.title, // Use exam title as course name
      amount: exam.price,
      originalPrice: exam.price,
      paymentMethod: paymentMethod || 'dummy',
      status: 'completed',
      description: `Dummy payment for Tega Exam: ${exam.title}`,
      transactionId: `TXN${Date.now()}${Math.random().toString(36).substr(2, 9).toUpperCase()}`,
      paymentDate: new Date(),
      examAccess: true,
      validUntil: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) // Valid for 1 year
    });

    await payment.save();

    // Update exam registration payment status
    await ExamRegistration.findOneAndUpdate(
      { studentId: userId, examId: examId },
      { paymentStatus: 'paid' }
    );

    // Create notification for admin
    const admin = await Admin.findOne();
    if (admin) {
      const notification = new Notification({
        recipient: admin._id,
        recipientModel: 'Admin',
        message: `💰 New Tega Exam Payment Received!\n\nAmount: ₹${exam.price}\nExam: ${exam.title}\nStudent ID: ${userId}\nDate: ${new Date().toLocaleString('en-IN')}`,
        type: 'info'
      });
      await notification.save();
    }

    // Create notification for student
    const student = await Student.findById(userId);
    if (student) {
      const notification = new Notification({
        recipient: userId,
        recipientModel: 'Student',
        message: `   Payment Successful!\n\nYou have successfully paid ₹${exam.price} for the Tega Exam: ${exam.title}\n\nYou can now take the exam.`,
        type: 'success'
      });
      await notification.save();
    }

    res.json({
      success: true,
      message: 'Payment processed successfully',
      data: {
        paymentId: payment._id,
        amount: exam.price,
        examId: examId,
        examTitle: exam.title
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to process payment'
    });
  }
};

// Check if user has paid for Tega Exam
export const checkTegaExamPayment = async (req, res) => {
  try {
    const { examId } = req.params;
    const userId = req.studentId;

    const payment = await Payment.findOne({
      studentId: userId,
      examId: examId,
      status: 'completed'
    });

    res.json({
      success: true,
      data: {
        examId: examId,
        hasPaid: !!payment,
        payment: payment || null
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to check payment status'
    });
  }
};

// Get Tega Exam payment history for user
export const getTegaExamPaymentHistory = async (req, res) => {
  try {
    const userId = req.studentId;

    const payments = await Payment.find({
      studentId: userId,
      examId: { $ne: null }, // Only Tega Exam payments
      status: 'completed'
    })
    .populate('examId', 'title subject')
    .sort({ paymentDate: -1 });

    res.json({
      success: true,
      data: {
        payments: payments
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch payment history'
    });
  }
};
