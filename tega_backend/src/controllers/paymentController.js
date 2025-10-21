import mongoose from 'mongoose';
import Payment from '../models/Payment.js';
import Enrollment from '../models/Enrollment.js';
import RealTimeCourse from '../models/RealTimeCourse.js';
import Student from '../models/Student.js';
import Notification from '../models/Notification.js';
import Admin from '../models/Admin.js';
import Razorpay from 'razorpay';
import crypto from 'crypto';
import UPISettings from '../models/UPISettings.js';
import Offer from '../models/Offer.js';

// Import in-memory storage from auth controller
import { inMemoryUsers, userPayments, userNotifications, userCourseAccess } from './authController.js';

// Check if MongoDB is connected
const isMongoConnected = () => {
  try {
    return Payment.db.readyState === 1;
  } catch (error) {
    return false;
  }
};

// Get offer price for a student's institute
const getOfferPriceForStudent = async (studentId, feature = 'Course') => {
  try {
    if (!isMongoConnected()) {
      return null;
    }

    // Get student's institute
    const student = await Student.findById(studentId);
    if (!student || !student.institute) {
      return null;
    }

    // Escape special regex characters in the college name
    const escapedInstitute = student.institute.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    
    // Check for active offer for this institute and feature (exact match)
    let offer = await Offer.findOne({
      collegeName: { $regex: new RegExp(`^${escapedInstitute}$`, 'i') },
      feature: feature,
      isActive: true
    });

    // If no exact match found, try partial matching
    if (!offer) {
      const allOffers = await Offer.find({
        feature: feature,
        isActive: true
      });
      
      // Try to find a partial match
      const partialMatch = allOffers.find(o => 
        o.collegeName.toLowerCase().includes(student.institute.toLowerCase()) ||
        student.institute.toLowerCase().includes(o.collegeName.toLowerCase())
      );
      
      if (partialMatch) {
        offer = partialMatch;
      }
    }

    if (offer) {
      return offer.fixedAmount;
    }

    return null;
  } catch (error) {
    return null;
  }
};

// Initialize Razorpay with fallback for development
let razorpay = null;
if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
  razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET
  });
} else {
}

// Get all courses with pricing
export const getCourses = async (req, res) => {
  try {
    // Use only RealTimeCourse model
    const RealTimeCourse = (await import('../models/RealTimeCourse.js')).default;
    
    // Get all active courses
    const courses = await RealTimeCourse.find({ 
      isActive: true
    }).select('title courseName description price duration category instructor level')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: courses,
      debug: {
        totalCourses: courses.length,
        activeCoursesCount: courses.length,
        method: 'realtime-only',
        requestInfo: {
          hasUser: !!req.user,
          userRole: req.user?.role || 'none',
          headers: Object.keys(req.headers)
        }
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch courses',
      error: error.message
    });
  }
};

// Get course pricing (RealTimeCourse only)
export const getCoursePricing = async (req, res) => {
  try {
    const RealTimeCourse = (await import('../models/RealTimeCourse.js')).default;
    const courses = await RealTimeCourse.find({ isActive: true })
      .select('title courseName price duration category')
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      data: courses
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch course pricing'
    });
  }
};

// Create payment order (for Razorpay)
export const createPaymentOrder = async (req, res) => {
  try {
    const { courseId, amount } = req.body;
    const userId = req.studentId; // Changed from req.user.id

    // Check if Razorpay is configured
    if (!razorpay) {
      return res.status(400).json({
        success: false,
        message: 'Payment gateway not configured. Please use dummy payment for development.'
      });
    }

    // Validate course
    const course = await RealTimeCourse.findOne({ courseId, isActive: true });
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // Check if user already paid for this course
    const existingPayment = await Payment.hasUserPaidForCourse(userId, courseId);
    if (existingPayment) {
      return res.status(400).json({
        success: false,
        message: 'You have already paid for this course'
      });
    }

    // Create Razorpay order
    const options = {
      amount: amount * 100, // Razorpay expects amount in paise
      currency: 'INR',
      receipt: `receipt_${Date.now()}`,
      notes: {
        courseId: courseId,
        userId: userId.toString()
      }
    };

    const order = await razorpay.orders.create(options);

    // Create payment record
    const payment = new Payment({
      studentId: userId,
      courseId: courseId,
      courseName: course.name,
      amount: amount,
      status: 'pending',
      razorpayOrderId: order.id
    });

    await payment.save();

    res.json({
      success: true,
      data: {
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
        paymentId: payment._id
      }
    });
  } catch (error) {
    console.error('Payment order creation error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create payment order',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Process dummy payment (for development/testing)
export const processDummyPayment = async (req, res) => {
  try {
    const { courseId, paymentMethod, paymentDetails } = req.body;
    const userId = req.studentId; // Changed from req.user.id


    // Validate course (try MongoDB first, fallback to static data)
    let course = null;
    if (isMongoConnected()) {
      try {
        course = await Course.findOne({ courseId, isActive: true });
      } catch (error) {
      }
    }
    
    // Fallback to static course data
    if (!course) {
      const staticCourses = {
        'java-programming': { name: 'Java Programming', price: 799 },
        'python-data-science': { name: 'Python for Data Science', price: 799 },
        'react-development': { name: 'React.js Development', price: 799 },
        'aws-cloud': { name: 'AWS Cloud Practitioner', price: 799 },
        'tega-main-exam': { name: 'Tega Main Exam', price: 799 }
      };
      course = staticCourses[courseId];
    }

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // Check for institute offer price
    const offerPrice = await getOfferPriceForStudent(userId, 'Course');
    const finalPrice = offerPrice !== null ? offerPrice : course.price;
    

    // Check if user already paid for this course
    let existingPayment = false;
    if (isMongoConnected()) {
      try {
        existingPayment = await Payment.hasUserPaidForCourse(userId, courseId);
      } catch (error) {
      }
    }
    
    // Check in-memory storage
    if (!existingPayment && userPayments.has(userId)) {
      const userPaymentHistory = userPayments.get(userId);
      existingPayment = userPaymentHistory.some(payment => 
        payment.courseId === courseId && payment.status === 'completed'
      );
    }

    if (existingPayment) {
      return res.status(400).json({
        success: false,
        message: 'You have already paid for this course'
      });
    }

    // Simulate payment processing delay
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Create payment record (try MongoDB first, fallback to in-memory)
    let payment = null;
    if (isMongoConnected()) {
      try {
        payment = new Payment({
          studentId: userId,
          courseId: courseId,
          courseName: course.name,
          amount: finalPrice,
          originalPrice: course.price,
          offerPrice: offerPrice,
          paymentMethod: paymentMethod,
          status: 'completed',
          description: `Payment for ${course.name}${offerPrice ? ` (Institute Offer: ₹${offerPrice})` : ''}`,
          transactionId: `TXN${Date.now()}${Math.random().toString(36).substr(2, 9).toUpperCase()}`,
          paymentDate: new Date()
        });
        await payment.save();
      } catch (error) {
        payment = null;
      }
    }
    
    // If MongoDB failed, use in-memory storage
    if (!payment) {
              payment = {
          _id: Date.now().toString(),
          studentId: userId,
          courseId: courseId,
          courseName: course.name,
          amount: finalPrice,
          originalPrice: course.price,
          offerPrice: offerPrice,
          paymentMethod: paymentMethod,
          status: 'completed',
          description: `Payment for ${course.name}${offerPrice ? ` (Institute Offer: ₹${offerPrice})` : ''}`,
          transactionId: `TXN${Date.now()}${Math.random().toString(36).substr(2, 9).toUpperCase()}`,
          paymentDate: new Date(),
          createdAt: new Date(),
          updatedAt: new Date()
        };
      
      // Store in user-specific payment history
      if (!userPayments.has(userId)) {
        userPayments.set(userId, []);
      }
      userPayments.get(userId).push(payment);
      
      // Update user course access
      if (!userCourseAccess.has(userId)) {
        userCourseAccess.set(userId, []);
      }
      userCourseAccess.get(userId).push(courseId);
      
    }

    // Create payment success notification (try MongoDB first, fallback to in-memory)
    if (isMongoConnected()) {
      try {
        const notification = new Notification({
          recipient: userId,
          recipientModel: 'Student',
          message: `Payment successful! You have successfully paid ₹${finalPrice} for ${course.name}${offerPrice ? ` (Institute Offer: ₹${offerPrice} instead of ₹${course.price})` : ''}. You can now access the course content and exams.`,
          type: 'payment_success'
        });
        await notification.save();
      } catch (error) {
      }
    }
    
    // Store notification in user-specific storage
    if (!userNotifications.has(userId)) {
      userNotifications.set(userId, []);
    }
    
    const notification = {
      _id: Date.now().toString(),
      recipient: userId,
      recipientModel: 'Student',
      message: `Payment successful! You have successfully paid ₹${finalPrice} for ${course.name}${offerPrice ? ` (Institute Offer: ₹${offerPrice} instead of ₹${course.price})` : ''}. You can now access the course content and exams.`,
      type: 'payment_success',
      isRead: false,
      createdAt: new Date()
    };
    
    userNotifications.get(userId).push(notification);

    // Create admin notification for new payment
    try {
      if (isMongoConnected()) {
        const admin = await Admin.findOne(); // Fetch an admin to send notification to
        if (admin) {
          // Fetch the user who made the payment
          const student = await Student.findById(userId);
          const adminNotification = new Notification({
            recipient: admin._id,
            recipientModel: 'Admin',
            message: `New payment received: ${student?.firstName || student?.email || userId} paid ₹${finalPrice} for ${course.name}${offerPrice ? ` (Institute Offer: ₹${offerPrice} instead of ₹${course.price})` : ''}`,
            type: 'payment_received',
            metadata: {
              paymentId: payment._id || payment.id,
              courseId: courseId,
              amount: finalPrice,
              originalPrice: course.price,
              offerPrice: offerPrice,
              userId: userId
            }
          });
          await adminNotification.save();
        }
      }
    } catch (error) {
    }


    // Broadcast real-time payment update via Socket.IO
    try {
      const io = req.app.get('io');
      if (io) {
        // Broadcast to the specific user's room
        io.to(`user-${userId}`).emit('payment-completed', {
          type: 'payment-completed',
          data: {
            paymentId: payment._id,
            transactionId: payment.transactionId,
            courseId: courseId,
            courseName: course.name,
            amount: payment.amount,
            paymentMethod: payment.paymentMethod,
            status: payment.status,
            date: payment.paymentDate || payment.createdAt,
            userId: userId
          },
          timestamp: new Date().toISOString()
        });

        // Also broadcast to admin rooms for real-time monitoring
        io.to('admin-room').emit('new-payment', {
          type: 'new-payment',
          data: {
            paymentId: payment._id,
            transactionId: payment.transactionId,
            courseId: courseId,
            courseName: course.name,
            amount: payment.amount,
            paymentMethod: payment.paymentMethod,
            status: payment.status,
            date: payment.paymentDate || payment.createdAt,
            userId: userId
          },
          timestamp: new Date().toISOString()
        });

      }
    } catch (socketError) {
    }

    res.json({
      success: true,
      message: 'Payment completed successfully',
      data: {
        paymentId: payment._id,
        transactionId: payment.transactionId,
        courseId: courseId,
        courseName: course.name,
        amount: payment.amount,
        userId: userId
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to process payment'
    });
  }
};

// Verify Razorpay payment
export const verifyPayment = async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

    // Check if Razorpay is configured
    if (!razorpay) {
      return res.status(400).json({
        success: false,
        message: 'Payment gateway not configured'
      });
    }

    // Verify signature
    const body = razorpay_order_id + "|" + razorpay_payment_id;
    const expectedSignature = crypto
      .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET)
      .update(body.toString())
      .digest("hex");

    if (expectedSignature !== razorpay_signature) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment signature'
      });
    }

    // Find and update payment
    const payment = await Payment.findOne({ razorpayOrderId: razorpay_order_id });
    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Payment not found'
      });
    }

    payment.status = 'completed';
    payment.razorpayPaymentId = razorpay_payment_id;
    payment.razorpaySignature = razorpay_signature;
    await payment.save();

    // Increment course enrollment
    const course = await Course.findOne({ courseId: payment.courseId });
    if (course) {
      await course.incrementEnrollment();
    }

    res.json({
      success: true,
      message: 'Payment verified successfully',
      data: {
        paymentId: payment._id,
        transactionId: payment.transactionId,
        courseId: payment.courseId,
        courseName: payment.courseName,
        amount: payment.amount
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to verify payment'
    });
  }
};

// UPI Payment Verification
export const verifyUPIPayment = async (req, res) => {
  try {
    const { transactionId, amount, courseId, studentId, upiId } = req.body;


    // Validation
    if (!transactionId || !amount || !courseId || !studentId || !upiId) {
      return res.status(400).json({
        success: false,
        message: 'Transaction ID, amount, course ID, student ID, and UPI ID are required'
      });
    }

    // Verify UPI ID matches configured UPI ID
    const upiSettings = await UPISettings.findOne({ isEnabled: true });
    if (!upiSettings || upiSettings.upiId !== upiId) {
      return res.status(400).json({
        success: false,
        message: 'Invalid UPI ID'
      });
    }

    // Get course details
    const course = await Course.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // Check for institute offer price
    const offerPrice = await getOfferPriceForStudent(studentId, 'Course');
    const expectedPrice = offerPrice !== null ? offerPrice : course.price;
    

    // Verify amount matches expected price (either offer price or course price)
    if (expectedPrice !== amount) {
      return res.status(400).json({
        success: false,
        message: `Amount mismatch. Expected: ₹${expectedPrice}${offerPrice ? ` (Institute Offer)` : ''}, Received: ₹${amount}`
      });
    }

    // Check if payment already exists
    const existingPayment = await Payment.findOne({ 
      transactionId,
      studentId,
      courseId
    });

    if (existingPayment) {
      return res.status(400).json({
        success: false,
        message: 'Payment already verified'
      });
    }

    // Create payment record
    const payment = new Payment({
      studentId,
      courseId,
      courseName: course.courseName,
      amount,
      originalPrice: course.price,
      offerPrice: offerPrice,
      currency: 'INR',
      paymentMethod: 'UPI',
      status: 'completed',
      transactionId,
      description: `UPI payment for ${course.courseName}${offerPrice ? ` (Institute Offer: ₹${offerPrice})` : ''}`,
      paymentDate: new Date(),
      examAccess: true,
      validUntil: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) // Valid for 1 year
    });

    await payment.save();

    // Increment course enrollment
    await course.incrementEnrollment();

    // Create notification for admin
    const admin = await Admin.findOne();
    if (admin) {
      
      const notification = new Notification({
        recipient: admin._id,
        recipientModel: 'Admin',
        message: `💰 New UPI Payment Received!\n\nAmount: ₹${amount}\nCourse: ${course.courseName}\nStudent ID: ${studentId}\nTransaction ID: ${transactionId}\nDate: ${new Date().toLocaleString('en-IN')}`,
        type: 'info'
      });
      await notification.save();
    } else {
    }

    // Create notification for student
    const student = await Student.findById(studentId);
    if (student) {
      
      const studentNotification = new Notification({
        recipient: student._id,
        recipientModel: 'Student',
        message: `✅ Payment Successful!\n\nYou are now enrolled in ${course.courseName}\nAmount Paid: ₹${amount}\nTransaction ID: ${transactionId}\nAccess granted for 1 year\n\nYou can now access course content and exams!`,
        type: 'info'
      });
      await studentNotification.save();
    } else {
    }

    res.json({
      success: true,
      message: 'Payment verified successfully',
      payment: {
        id: payment._id,
        transactionId: payment.transactionId,
        amount: payment.amount,
        courseName: payment.courseName,
        status: payment.status,
        paymentDate: payment.paymentDate
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to verify payment'
    });
  }
};

// Get UPI Payment Status
export const getUPIPaymentStatus = async (req, res) => {
  try {
    const { transactionId } = req.params;

    const payment = await Payment.findOne({ transactionId });
    
    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Payment not found'
      });
    }

    res.json({
      success: true,
      payment: {
        id: payment._id,
        transactionId: payment.transactionId,
        amount: payment.amount,
        courseName: payment.courseName,
        status: payment.status,
        paymentDate: payment.paymentDate,
        studentId: payment.studentId
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get payment status'
    });
  }
};

// Get user's payment history
export const getPaymentHistory = async (req, res) => {
  try {
    const userId = req.studentId; // Changed from req.user.id
    
    
    // Try MongoDB first, fallback to in-memory storage
    let oldPayments = [];
    let razorpayPayments = [];
    
    if (isMongoConnected()) {
      try {
        // Get payments from old Payment model
        oldPayments = await Payment.find({ studentId: userId })
          .sort({ createdAt: -1 })
          .populate('studentId', 'username email firstName lastName');
        
        
        // Get payments from new Payment model
        // Payment model already imported at top
        razorpayPayments = await Payment.find({ studentId: userId })
          .sort({ createdAt: -1 })
          .populate('studentId', 'username email firstName lastName');
        
        
      } catch (error) {
      }
    }
    
    // Get from in-memory storage if MongoDB failed or not connected
    if (oldPayments.length === 0 && userPayments.has(userId)) {
      oldPayments = userPayments.get(userId);
    }

    // Normalize both payment types to a common format
    const normalizedOldPayments = oldPayments.map(payment => ({
      _id: payment._id,
      studentId: payment.studentId,
      courseId: payment.courseId,
      courseName: payment.courseName,
      amount: payment.amount,
      currency: payment.currency || 'INR',
      paymentMethod: payment.paymentMethod,
      status: payment.status,
      transactionId: payment.transactionId,
      paymentDate: payment.paymentDate,
      description: payment.description,
      examAccess: payment.examAccess,
      validUntil: payment.validUntil,
      upiId: payment.upiId,
      upiReferenceId: payment.upiReferenceId,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
      source: 'old_payment'
    }));

    const normalizedPayments = razorpayPayments.map(payment => ({
      _id: payment._id,
      studentId: payment.studentId,
      courseId: payment.courseId,
      courseName: payment.courseName,
      amount: payment.amount,
      currency: payment.currency || 'INR',
      paymentMethod: 'Razorpay',
      status: payment.status,
      transactionId: payment.transactionId || payment.razorpayPaymentId,
      paymentDate: payment.paymentDate,
      description: payment.description,
      examAccess: payment.examAccess,
      validUntil: payment.validUntil,
      razorpayOrderId: payment.razorpayOrderId,
      razorpayPaymentId: payment.razorpayPaymentId,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
      source: 'razorpay_payment'
    }));

    // Combine and sort by creation date
    const allPayments = [...normalizedOldPayments, ...normalizedPayments]
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));


    res.json({
      success: true,
      data: allPayments
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch payment history'
    });
  }
};

// Check if user has paid for a course (unified check for both old and new payment systems)
export const checkCourseAccess = async (req, res) => {
  try {
    const { courseId } = req.params;
    const userId = req.studentId;
    
    
    // Convert string IDs to ObjectId if needed
    let userIdObj, courseIdObj;
    try {
      userIdObj = typeof userId === 'string' ? new mongoose.Types.ObjectId(userId) : userId;
      courseIdObj = typeof courseId === 'string' ? new mongoose.Types.ObjectId(courseId) : courseId;
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID or course ID format'
      });
    }

    let hasAccess = false;
    let accessSource = 'none';

    // Debug: Check what's actually in the database
    try {
      console.log(`🔍 Debug: Checking database for user ${userIdObj} and course ${courseIdObj}`);
      
      // Check all payments for this user
      const allUserPayments = await Payment.find({ studentId: userIdObj });
      console.log(`💰 Found ${allUserPayments.length} payments for user:`, allUserPayments.map(p => ({ id: p._id, courseId: p.courseId, courseName: p.courseName, status: p.status })));
      
      // Check all Enrollments for this user
      const allEnrollments = await Enrollment.find({ studentId: userIdObj });
      console.log(`📚 Found ${allEnrollments.length} enrollments for user:`, allEnrollments.map(e => ({ id: e._id, courseId: e.courseId, courseName: e.courseName, status: e.status })));
      
      // Check if course exists
      const RealTimeCourse = (await import('../models/RealTimeCourse.js')).default;
      const course = await RealTimeCourse.findById(courseIdObj);
      console.log(`📖 Course found:`, course ? { id: course._id, title: course.title, courseName: course.courseName } : 'Not found');
      
    } catch (error) {
      console.error('❌ Debug error:', error);
    }

    // Check old Payment system
    try {
      const hasPaidOld = await Payment.hasUserPaidForCourse(userIdObj, courseIdObj);
      if (hasPaidOld) {
        hasAccess = true;
        accessSource = 'old_payment';
      } else {
      }
    } catch (error) {
    }

    // Check new Razorpay/Enrollment system
    if (!hasAccess) {
      try {
        // Enrollment model already imported at top
        const hasPaidNew = await Enrollment.hasAccess(userIdObj, courseIdObj);
        if (hasPaidNew) {
          hasAccess = true;
          accessSource = 'razorpay_payment';
        } else {
        }
      } catch (error) {
      }
    }

    // Check Payment model directly as fallback
    if (!hasAccess) {
      try {
        // Payment model already imported at top
        const razorpayPayment = await Payment.findOne({
          studentId: userIdObj,
          courseId: courseIdObj,
          status: 'completed'
        });
        if (razorpayPayment) {
          hasAccess = true;
          accessSource = 'razorpay_payment_direct';
          console.log(`✅ Access granted via direct payment check: ${razorpayPayment._id}`);
        } else {
          console.log(`❌ No direct payment found for course ${courseId}`);
        }
      } catch (error) {
        console.error('❌ Error checking direct payment:', error);
      }
    }

    // Final fallback: Check by course name if course exists
    if (!hasAccess) {
      try {
        const RealTimeCourse = (await import('../models/RealTimeCourse.js')).default;
        const course = await RealTimeCourse.findById(courseIdObj);
        
        if (course) {
          // Check if user has paid for any course with similar name
          const paymentByCourseName = await Payment.findOne({
            studentId: userIdObj,
            courseName: course.title || course.courseName,
            status: 'completed'
          });
          
          if (paymentByCourseName) {
            hasAccess = true;
            accessSource = 'payment_by_name';
            console.log(`✅ Access granted via payment by course name: ${paymentByCourseName._id}`);
          } else {
            console.log(`❌ No payment found by course name: ${course.title || course.courseName}`);
          }
        }
      } catch (error) {
        console.error('❌ Error checking payment by course name:', error);
      }
    }


    res.json({
      success: true,
      data: {
        courseId: courseId,
        hasAccess: hasAccess,
        accessSource: accessSource
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to check course access'
    });
  }
};

// Get user's paid courses (unified from both Payment and Payment models)
export const getUserPaidCourses = async (req, res) => {
  try {
    const userId = req.studentId; // Changed from req.user.id
    
    
    // Try MongoDB first, fallback to in-memory storage
    let oldPaidCourses = [];
    let razorpayPaidCourses = [];
    // Note: Do NOT shadow the imported in-memory map `userCourseAccess` from authController
    // Use a differently named variable for the array of course IDs fetched from Enrollment model
    let userCourseAccessIds = [];
    
    if (isMongoConnected()) {
      try {
        // Get paid courses from old Payment model
        oldPaidCourses = await Payment.getUserPaidCourses(userId);
        
        // Get paid courses from new Payment model
        // Payment model already imported at top
        const razorpayPayments = await Payment.find({ 
          studentId: userId, 
          status: 'completed' 
        });
        razorpayPaidCourses = razorpayPayments.map(payment => payment.courseId);
        
        // Get paid courses from Enrollment model
        // Enrollment model already imported at top
        const userCourses = await Enrollment.getActiveCourses(userId);
        // Map to raw ids, handling populated documents
        userCourseAccessIds = userCourses
          .map(userCourse => (userCourse.courseId && userCourse.courseId._id) ? userCourse.courseId._id : userCourse.courseId)
          .filter(Boolean);
        
      } catch (error) {
      }
    }
    
    // Get from in-memory storage if MongoDB failed or not connected
    if (oldPaidCourses.length === 0 && userCourseAccess.has(userId)) {
      oldPaidCourses = userCourseAccess.get(userId);
    }

    // Combine and deduplicate course IDs from all sources
    const allPaidCourseIds = [...new Set([...oldPaidCourses, ...razorpayPaidCourses, ...userCourseAccessIds])];

    // Normalize all course ids to primitive values first
    const normalizedPaidIds = [...new Set([...oldPaidCourses, ...razorpayPaidCourses, ...userCourseAccessIds]
      .map(id => (id && id._id) ? id._id : id))];

    // Get course details (try MongoDB first, then supplement with static data for string IDs)
    let courses = [];
    if (isMongoConnected()) {
      try {
        // Separate valid ObjectIds from legacy string course identifiers to avoid CastError
        const objectIdCourseIds = normalizedPaidIds
          .filter(id => mongoose.Types.ObjectId.isValid(id))
          .map(id => new mongoose.Types.ObjectId(id));
        const stringCourseIds = normalizedPaidIds
          .filter(id => !mongoose.Types.ObjectId.isValid(id) && typeof id === 'string');

        let coursesById = [];
        if (objectIdCourseIds.length > 0) {
          // Use RealTimeCourse model instead of Course
          const RealTimeCourse = (await import('../models/RealTimeCourse.js')).default;
          coursesById = await RealTimeCourse.find({ _id: { $in: objectIdCourseIds } });
        }

        courses = [...coursesById];

        // Supplement with static definitions for legacy string IDs
        if (stringCourseIds.length > 0) {
          const staticCoursesMap = {
            'java-programming': { courseId: 'java-programming', courseName: 'Java Programming', price: 799, duration: '4 weeks', category: 'Programming', description: '' },
            'python-data-science': { courseId: 'python-data-science', courseName: 'Python for Data Science', price: 799, duration: '4 weeks', category: 'Programming', description: '' },
            'react-development': { courseId: 'react-development', courseName: 'React.js Development', price: 799, duration: '4 weeks', category: 'Programming', description: '' },
            'aws-cloud': { courseId: 'aws-cloud', courseName: 'AWS Cloud Practitioner', price: 799, duration: '4 weeks', category: 'Cloud', description: '' },
            'tega-main-exam': { courseId: 'tega-main-exam', courseName: 'Tega Main Exam', price: 799, duration: '—', category: 'Exam', description: '' }
          };

          const supplemental = stringCourseIds
            .map(cid => staticCoursesMap[cid])
            .filter(Boolean)
            .map(c => ({
              _id: c.courseId, // keep identifier for client mapping
              courseId: c.courseId,
              courseName: c.courseName,
              price: c.price,
              duration: c.duration,
              category: c.category,
              description: c.description,
              isActive: true
            }));

          courses = [...courses, ...supplemental];
        }

        // Remove duplicates based on stringified id
        const uniqueCourses = courses.filter((course, index, self) => 
          index === self.findIndex(c => (c._id?.toString ? c._id.toString() : c._id) === (course._id?.toString ? course._id.toString() : course._id))
        );
        courses = uniqueCourses;
        
      } catch (error) {
      }
    }
    
    // Fallback to static course data when nothing resolved above
    if (courses.length === 0) {
      const staticCourses = {
        'java-programming': { courseId: 'java-programming', name: 'Java Programming', price: 799 },
        'python-data-science': { courseId: 'python-data-science', name: 'Python for Data Science', price: 799 },
        'react-development': { courseId: 'react-development', name: 'React.js Development', price: 799 },
        'aws-cloud': { courseId: 'aws-cloud', name: 'AWS Cloud Practitioner', price: 799 },
        'tega-main-exam': { courseId: 'tega-main-exam', name: 'Tega Main Exam', price: 799 }
      };
      
      courses = normalizedPaidIds.map(courseId => staticCourses[courseId]).filter(Boolean);
    }


    // Normalize for client expectations: include both id and courseId
    const normalizedCourses = courses.map((c) => ({
      id: c._id?.toString ? c._id.toString() : c._id,
      courseId: (c.courseId?.toString ? c.courseId.toString() : c.courseId) || (c._id?.toString ? c._id.toString() : c._id),
      courseName: c.courseName || c.name,
      price: c.price,
      duration: c.duration,
      category: c.category,
      description: c.description,
      isActive: c.isActive !== false
    }));

    res.json({
      success: true,
      data: normalizedCourses
    });
  } catch (error) {
    // Soft-fail with empty list to avoid breaking the client UI after refresh
    res.json({ success: true, data: [] });
  }
};

// Process refund
export const processRefund = async (req, res) => {
  try {
    const { paymentId, refundReason } = req.body;
    const userId = req.studentId; // Changed from req.user.id

    const payment = await Payment.findOne({ _id: paymentId, userId });
    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Payment not found'
      });
    }

    if (payment.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Payment is not completed'
      });
    }

    // Process refund through Razorpay if applicable
    if (payment.razorpayPaymentId && razorpay) {
      const refund = await razorpay.payments.refund(payment.razorpayPaymentId, {
        amount: payment.amount * 100,
        notes: {
          reason: refundReason
        }
      });

      payment.refundDetails = {
        refundId: refund.id,
        refundAmount: payment.amount,
        refundReason: refundReason,
        refundDate: new Date()
      };
    }

    payment.status = 'refunded';
    await payment.save();

    res.json({
      success: true,
      message: 'Refund processed successfully',
      data: {
        paymentId: payment._id,
        refundId: payment.refundDetails?.refundId,
        refundAmount: payment.refundDetails?.refundAmount
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to process refund'
    });
  }
};

// Get payment statistics (for admin)
export const getPaymentStats = async (req, res) => {
  try {
    const stats = await Payment.aggregate([
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          totalAmount: { $sum: '$amount' }
        }
      }
    ]);

    const totalPayments = await Payment.countDocuments();
    const totalRevenue = await Payment.aggregate([
      { $match: { status: 'completed' } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ]);

    res.json({
      success: true,
      data: {
        stats: stats,
        totalPayments: totalPayments,
        totalRevenue: totalRevenue[0]?.total || 0
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch payment statistics'
    });
  }
};

// Get offer price for a student
export const getOfferPrice = async (req, res) => {
  try {
    const { studentId, feature = 'Course' } = req.params;
    
    
    const offerPrice = await getOfferPriceForStudent(studentId, feature);
    
    if (offerPrice !== null) {
    } else {
    }
    
    res.json({
      success: true,
      data: {
        studentId,
        feature,
        offerPrice,
        hasOffer: offerPrice !== null,
        message: offerPrice !== null ? `Institute offer available: ₹${offerPrice}` : 'No institute offer available'
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get offer price'
    });
  }
};

// Get all payments for admin with totals
export const getAllPayments = async (req, res) => {
  try {
    let payments = [];

    if (isMongoConnected()) {
      try {
        payments = await Payment.find({})
          .sort({ createdAt: -1 })
          .populate('studentId', 'username email firstName lastName'); // Populate student details
      } catch (error) {
      }
    }

    if (payments.length === 0) {
      // Flatten in-memory payments from userPayments map
      const all = [];
      for (const [, userPayList] of userPayments.entries()) {
        all.push(...userPayList);
      }
      // Sort by createdAt desc if present
      payments = all.sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0));
    }

    const totals = payments.reduce(
      (acc, p) => {
        acc.count += 1;
        if (p.status === 'completed') acc.totalRevenue += Number(p.amount || 0);
        acc.byStatus[p.status] = (acc.byStatus[p.status] || 0) + 1;
        return acc;
      },
      { count: 0, totalRevenue: 0, byStatus: {} }
    );

    res.json({ success: true, data: payments, totals });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch payments' });
  }
};

