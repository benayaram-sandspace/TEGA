import mongoose from 'mongoose';
import Payment from '../models/Payment.js';
import RealTimeCourse from '../models/RealTimeCourse.js'; // Updated to use RealTimeCourse
import Student from '../models/Student.js';
import Notification from '../models/Notification.js';
import Admin from '../models/Admin.js'; // Import Admin model
import Razorpay from 'razorpay';
import crypto from 'crypto';
import UPISettings from '../models/UPISettings.js'; // Import UPISettings model
import Offer from '../models/Offer.js'; // Import Offer model
import Exam from '../models/Exam.js'; // Import Exam model for TEGA exams
import RazorpayPayment from '../models/RazorpayPayment.js'; // Import RazorpayPayment model

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

    // Escape special regex characters in the institute name
    const escapedInstitute = student.institute.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    
    // Check for active offer for this institute (exact match first)
    let offer = await Offer.findOne({
      instituteName: { $regex: new RegExp(`^${escapedInstitute}$`, 'i') },
      isActive: true,
      validFrom: { $lte: new Date() },
      validUntil: { $gte: new Date() }
    });

    // If no exact match found, try partial matching
    if (!offer) {
      const allOffers = await Offer.find({
        isActive: true,
        validFrom: { $lte: new Date() },
        validUntil: { $gte: new Date() }
      });

      // Try to find a partial match
      const partialMatch = allOffers.find(o => 
        o.instituteName.toLowerCase().includes(student.institute.toLowerCase()) ||
        student.institute.toLowerCase().includes(o.instituteName.toLowerCase())
      );
      
      if (partialMatch) {
        offer = partialMatch;
      }
    }

    if (offer) {
      // For course offers, we need to find the specific course offer
      // This function is called for general course pricing, so we return the first available course offer price
      if (offer.courseOffers && offer.courseOffers.length > 0) {
        const firstCourseOffer = offer.courseOffers[0];
        return firstCourseOffer.offerPrice;
      }
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
    // Check MongoDB connection state
    const connectionState = mongoose.connection.readyState;
    // Wait for connection if not ready
    if (connectionState !== 1) {
      await new Promise((resolve, reject) => {
        if (connectionState === 1) {
          resolve();
        } else {
          const timeout = setTimeout(() => {
            reject(new Error('MongoDB connection timeout'));
          }, 10000); // 10 second timeout
          
          mongoose.connection.once('connected', () => {
            clearTimeout(timeout);
            resolve();
          });
          
          mongoose.connection.once('error', (err) => {
            clearTimeout(timeout);
            reject(err);
          });
        }
      });
    }
    
    // First, let's check if we can find any courses at all
    const totalCourses = await RealTimeCourse.countDocuments({});
    // Check published courses
    const publishedCoursesCount = await RealTimeCourse.countDocuments({ status: 'published' });
    // Try to get all courses first
    const allCourses = await RealTimeCourse.find({});
    // Log first course structure for debugging
    if (allCourses.length > 0) {
    }
    
    // Get published courses (RealTimeCourse uses 'status' field instead of 'isActive')
    const regularCourses = await RealTimeCourse.find({ 
      status: 'published' 
    }).select('title description price estimatedDuration category instructor level status');
    // Map RealTimeCourse fields to expected frontend format
    const mappedCourses = regularCourses.map(course => ({
      _id: course._id,
      courseName: course.title, // Map title to courseName for frontend compatibility
      name: course.title, // Also provide as 'name' for compatibility
      title: course.title,
      description: course.description,
      price: course.price,
      duration: course.estimatedDuration ? 
        `${course.estimatedDuration.hours}h ${course.estimatedDuration.minutes}m` : 
        'N/A', // Map estimatedDuration to duration string
      category: course.category,
      instructor: course.instructor?.name || 'TEGA Instructor',
      level: course.level,
      status: course.status
    }));
    
    // Get Tega Exam separately for payment page (if it exists as a RealTimeCourse)
    const tegaExam = await RealTimeCourse.findOne({ 
      title: 'Tega Exam',
      status: 'published' 
    });
    
    // Combine regular courses with Tega Exam for payment page
    const courses = [...mappedCourses];
    if (tegaExam) {
      const mappedTegaExam = {
        _id: tegaExam._id,
        courseName: tegaExam.title,
        name: tegaExam.title,
        title: tegaExam.title,
        description: tegaExam.description,
        price: tegaExam.price,
        duration: tegaExam.estimatedDuration ? 
          `${tegaExam.estimatedDuration.hours}h ${tegaExam.estimatedDuration.minutes}m` : 
          'N/A',
        category: tegaExam.category,
        instructor: tegaExam.instructor?.name || 'TEGA Instructor',
        level: tegaExam.level,
        status: tegaExam.status
      };
      courses.push(mappedTegaExam);
    }
    if (courses.length === 0) {
      // Let's return all courses instead of just published ones for debugging
      const fallbackCourses = await RealTimeCourse.find({ 
        status: 'published'
      }).select('title description price estimatedDuration category instructor level status');
      // Map fallback courses to expected format
      const mappedFallbackCourses = fallbackCourses.map(course => ({
        _id: course._id,
        courseName: course.title,
        name: course.title,
        title: course.title,
        description: course.description,
        price: course.price,
        duration: course.estimatedDuration ? 
          `${course.estimatedDuration.hours}h ${course.estimatedDuration.minutes}m` : 
          'N/A',
        category: course.category,
        instructor: course.instructor?.name || 'TEGA Instructor',
        level: course.level,
        status: course.status
      }));
      
      res.json({
        success: true,
        data: mappedFallbackCourses,
        debug: {
          totalCourses,
          publishedCoursesCount,
          method: 'fallback',
          requestInfo: {
            hasUser: !!req.user,
            userRole: req.user?.role || 'none',
            headers: Object.keys(req.headers)
          }
        }
      });
    } else {
      res.json({
        success: true,
        data: courses,
        debug: {
          totalCourses,
          publishedCoursesCount,
          method: 'getPublishedCourses',
          requestInfo: {
            hasUser: !!req.user,
            userRole: req.user?.role || 'none',
            headers: Object.keys(req.headers)
          }
        }
      });
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch courses',
      error: error.message
    });
  }
};

// Get available TEGA exams for payment (filtered by time)
export const getAvailableTegaExams = async (req, res) => {
  try {
    const now = new Date();
    // Find all active TEGA exams
    const allTegaExams = await Exam.find({
      isTegaExam: true,
      isActive: true,
      requiresPayment: true
    });
    // Filter exams based on payment deadline (5 minutes before exam start)
    const availableExams = [];
    
    for (const exam of allTegaExams) {
      // Check if exam has slots
      if (!exam.slots || exam.slots.length === 0) {
        continue;
      }
      
      // Filter slots based on availability (5 minutes before slot start for registration)
      // and 5 minutes before earliest slot for payment visibility
      const availableSlots = [];
      let earliestSlotTime = null;
      
      for (const slot of exam.slots) {
        if (!slot.isActive) continue;
        
        // Parse slot start time
        const [hours, minutes] = slot.startTime.split(':').map(Number);
        const slotDateTime = new Date(exam.examDate);
        slotDateTime.setHours(hours, minutes, 0, 0);
        // Calculate slot registration cutoff (5 minutes before slot start)
        const slotRegistrationCutoff = new Date(slotDateTime.getTime() - 5 * 60 * 1000);
        
        // Check if slot is still available for registration
        const isSlotAvailable = now < slotRegistrationCutoff;
        if (isSlotAvailable) {
          availableSlots.push({
            ...slot.toObject(),
            slotDateTime: slotDateTime.toISOString(),
            registrationCutoff: slotRegistrationCutoff.toISOString(),
            availableSeats: slot.maxParticipants - (slot.registeredStudents?.length || 0)
          });
          
          // Track earliest slot time for payment cutoff
          if (!earliestSlotTime || slotDateTime < earliestSlotTime) {
            earliestSlotTime = slotDateTime;
          }
        }
      }
      
      // If no slots are available for registration, skip the exam
      if (availableSlots.length === 0) {
        continue;
      }
      
      if (!earliestSlotTime) {
        continue;
      }
      // Calculate payment cutoff time (5 minutes before earliest available slot)
      const paymentCutoff = new Date(earliestSlotTime.getTime() - 5 * 60 * 1000);
      // Check if current time is before the payment cutoff
      if (now < paymentCutoff) {
        availableExams.push({
          ...exam.toObject(),
          slots: availableSlots, // Replace with filtered slots
          paymentCutoff: paymentCutoff.toISOString(),
          earliestSlotTime: earliestSlotTime.toISOString(),
          totalAvailableSlots: availableSlots.length
        });
      } else {
      }
    }
    res.json({
      success: true,
      data: availableExams,
      currentTime: now.toISOString(),
      debug: {
        totalTegaExams: allTegaExams.length,
        availableForPayment: availableExams.length,
        message: 'Payment visible until 5min before earliest slot. Individual slots hidden 5min before their start time.'
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch available TEGA exams',
      error: error.message
    });
  }
};

// Get course pricing
export const getCoursePricing = async (req, res) => {
  try {
    const pricing = await Course.getCoursePricing();
    res.json({
      success: true,
      data: pricing
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
    const course = await RealTimeCourse.findOne({ _id: courseId, status: 'published' });
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found or not published'
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
    res.status(500).json({
      success: false,
      message: 'Failed to create payment order'
    });
  }
};

// Process dummy payment (for development/testing)
export const processDummyPayment = async (req, res) => {
  try {
    const { courseId, paymentMethod, paymentDetails, offerInfo } = req.body;
    const userId = req.studentId; // Changed from req.user.id
    // Validate course (try MongoDB first, fallback to static data)
    let course = null;
    if (isMongoConnected()) {
      try {
        course = await RealTimeCourse.findOne({ _id: courseId, status: 'published' });
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

    // Determine final price - use offer info from frontend if available, otherwise check backend offers
    let finalPrice = course.price;
    let offerDetails = null;
    
    if (offerInfo && offerInfo.hasOffer) {
      finalPrice = offerInfo.offerPrice;
      offerDetails = {
        originalPrice: offerInfo.originalPrice,
        offerPrice: offerInfo.offerPrice,
        discountPercentage: offerInfo.discountPercentage,
        instituteName: offerInfo.instituteName
      };
    } else {
      // Fallback to backend offer checking
      const offerPrice = await getOfferPriceForStudent(userId, 'Course');
      if (offerPrice !== null) {
        finalPrice = offerPrice;
        offerDetails = {
          originalPrice: course.price,
          offerPrice: offerPrice,
          discountPercentage: Math.round(((course.price - offerPrice) / course.price) * 100)
        };
      }
    }

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
          originalPrice: offerDetails ? offerDetails.originalPrice : course.price,
          offerPrice: offerDetails ? offerDetails.offerPrice : null,
          paymentMethod: paymentMethod,
          status: 'completed',
          description: `Payment for ${course.name}${offerDetails ? ` (Institute Offer: ${offerDetails.discountPercentage}% off)` : ''}`,
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
          originalPrice: offerDetails ? offerDetails.originalPrice : course.price,
          offerPrice: offerDetails ? offerDetails.offerPrice : null,
          paymentMethod: paymentMethod,
          status: 'completed',
          description: `Payment for ${course.name}${offerDetails ? ` (Institute Offer: ${offerDetails.discountPercentage}% off)` : ''}`,
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
    const course = await RealTimeCourse.findById(payment.courseId);
    if (course) {
      course.enrollmentCount = (course.enrollmentCount || 0) + 1;
      await course.save();
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
    const course = await RealTimeCourse.findById(courseId);
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
        // Get payments from new RazorpayPayment model
        const RazorpayPayment = (await import('../models/RazorpayPayment.js')).default;
        razorpayPayments = await RazorpayPayment.find({ studentId: userId })
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

    const normalizedRazorpayPayments = razorpayPayments.map(payment => ({
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
    const allPayments = [...normalizedOldPayments, ...normalizedRazorpayPayments]
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
      // Check all payments for this user
      const allUserPayments = await Payment.find({ studentId: userIdObj });
      // Check all RazorpayPayments for this user
      const RazorpayPayment = (await import('../models/RazorpayPayment.js')).default;
      const allUserRazorpayPayments = await RazorpayPayment.find({ studentId: userIdObj });
      // Check all UserCourses for this user
      const UserCourse = (await import('../models/UserCourse.js')).default;
      const allUserCourses = await UserCourse.find({ studentId: userIdObj });
    } catch (error) {
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

    // Check new Razorpay/UserCourse system
    if (!hasAccess) {
      try {
        const UserCourse = (await import('../models/UserCourse.js')).default;
        const hasPaidNew = await UserCourse.hasAccess(userIdObj, courseIdObj);
        if (hasPaidNew) {
          hasAccess = true;
          accessSource = 'razorpay_payment';
        } else {
        }
      } catch (error) {
      }
    }

    // Check RazorpayPayment model directly as fallback
    if (!hasAccess) {
      try {
        const RazorpayPayment = (await import('../models/RazorpayPayment.js')).default;
        const razorpayPayment = await RazorpayPayment.findOne({
          studentId: userIdObj,
          courseId: courseIdObj,
          status: 'completed'
        });
        if (razorpayPayment) {
          hasAccess = true;
          accessSource = 'razorpay_payment_direct';
        } else {
        }
      } catch (error) {
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

// Get user's paid courses (unified from both Payment and RazorpayPayment models)
// Check if user has paid for Tega exam
// Utility function to check TEGA exam payment (can be called from other controllers)
export const checkTegaExamPaymentUtil = async (userId) => {
  try {
    let hasPaidForTegaExam = false;
    let paymentSource = null;
    let paymentDetails = null;
    
    // Debug: Check all payments for this user to see what's in the database
    const RazorpayPayment = (await import('../models/RazorpayPayment.js')).default;
    const allPayments = await RazorpayPayment.find({ studentId: userId });
    allPayments.forEach((payment, index) => {
    });
    
    if (isMongoConnected()) {
      try {
        // Check Payment model for Tega exam payments (where examAccess is true and courseId is null)
        const tegaPayment = await Payment.findOne({
          studentId: userId,
          examAccess: true,
          courseId: null, // Tega exam has no courseId
          status: 'completed'
        });
        
        if (tegaPayment) {
          hasPaidForTegaExam = true;
          paymentSource = 'payment';
          paymentDetails = {
            paymentId: tegaPayment._id,
            amount: tegaPayment.amount,
            paymentDate: tegaPayment.paymentDate,
            validUntil: tegaPayment.validUntil
          };
        }
        
        // Also check RazorpayPayment model for Tega exam payments
        if (!hasPaidForTegaExam) {
          const RazorpayPayment = (await import('../models/RazorpayPayment.js')).default;
          
          // First, check for explicit Tega exam payments using isTegaExam flag
          const tegaRazorpayPayment = await RazorpayPayment.findOne({
            studentId: userId,
            isTegaExam: true,
            status: 'completed'
          });
          // Also check for any completed payments that might be TEGA exam payments
          const anyCompletedPayment = await RazorpayPayment.findOne({
            studentId: userId,
            status: 'completed'
          });
          if (anyCompletedPayment) {
          }
          
          if (tegaRazorpayPayment) {
            hasPaidForTegaExam = true;
            paymentSource = 'razorpay';
            paymentDetails = {
              paymentId: tegaRazorpayPayment._id,
              amount: tegaRazorpayPayment.amount,
              paymentDate: tegaRazorpayPayment.paymentDate,
              validUntil: tegaRazorpayPayment.validUntil
            };
          } else {
            // Fallback: Check for payments with examAccess=true and no courseId (legacy TEGA exam payments)
            const legacyTegaPayment = await RazorpayPayment.findOne({
              studentId: userId,
              examAccess: true,
              courseId: null,
              status: 'completed'
            });
            if (legacyTegaPayment) {
              hasPaidForTegaExam = true;
              paymentSource = 'razorpay_legacy';
              paymentDetails = {
                paymentId: legacyTegaPayment._id,
                amount: legacyTegaPayment.amount,
                paymentDate: legacyTegaPayment.paymentDate,
                validUntil: legacyTegaPayment.validUntil
              };
            } else {
              // Additional fallback: Check for payments with examAccess=true but only if they're specifically for TEGA exams
              // This is more restrictive to avoid false positives from regular course payments
              const anyExamAccessPayment = await RazorpayPayment.findOne({
                studentId: userId,
                examAccess: true,
                status: 'completed',
                $or: [
                  { courseId: null }, // Standalone TEGA exam payments
                  { courseName: { $regex: /tega|TEGA/i } } // Payments to courses with "TEGA" in the name
                ]
              });
              if (anyExamAccessPayment) {
              }
          
              if (anyExamAccessPayment) {
                // Double-check: Make sure this is actually a TEGA exam payment, not a regular course
                if (!anyExamAccessPayment.courseId || 
                    (anyExamAccessPayment.courseName && anyExamAccessPayment.courseName.toLowerCase().includes('tega'))) {
                  hasPaidForTegaExam = true;
                  paymentSource = 'razorpay_exam_access';
                  paymentDetails = {
                    paymentId: anyExamAccessPayment._id,
                    amount: anyExamAccessPayment.amount,
                    paymentDate: anyExamAccessPayment.paymentDate,
                    validUntil: anyExamAccessPayment.validUntil,
                    courseName: anyExamAccessPayment.courseName
                  };
                } else {
                }
              } else {
              }
            }
          }
          
          // Note: Removed high-amount payment check as it was incorrectly treating 
          // any payment ≥₹799 as TEGA exam payment, even if it was for a regular course
          // Now checking for the correct TEGA exam price of ₹1
          
          // If still no payment found, check for payments to "Tega Exam" course
          if (!hasPaidForTegaExam) {
            const Course = (await import('../models/Course.js')).default;
            const tegaExamCourse = await Course.findOne({ 
              courseName: { $in: ['Tega Exam', 'TEGA Exam', 'tega exam', 'Tega Main Exam', 'TEGA Main Exam', 'tega main exam'] } // Match both TEGA exam courses
            });
            
            if (tegaExamCourse) {
              // Check RazorpayPayment with more flexible criteria
              const tegaCoursePayment = await RazorpayPayment.findOne({
                studentId: userId,
                courseId: tegaExamCourse._id,
                status: 'completed'
                // Remove amount restriction to catch all payments
              });
              
              if (tegaCoursePayment) {
                hasPaidForTegaExam = true;
                paymentSource = 'razorpay_tega_course';
                paymentDetails = {
                  paymentId: tegaCoursePayment._id,
                  amount: tegaCoursePayment.amount,
                  paymentDate: tegaCoursePayment.paymentDate,
                  validUntil: tegaCoursePayment.validUntil,
                  courseName: tegaCoursePayment.courseName
                };
              } else {
                // Also check Payment model for this course
                const Payment = (await import('../models/Payment.js')).default;
                const tegaCoursePaymentLegacy = await Payment.findOne({
                  studentId: userId,
                  courseId: tegaExamCourse._id,
                  status: 'completed'
                  // Remove amount restriction to catch all payments
                });
                
                if (tegaCoursePaymentLegacy) {
                  hasPaidForTegaExam = true;
                  paymentSource = 'payment_tega_course';
                  paymentDetails = {
                    paymentId: tegaCoursePaymentLegacy._id,
                    amount: tegaCoursePaymentLegacy.amount,
                    paymentDate: tegaCoursePaymentLegacy.paymentDate,
                    validUntil: tegaCoursePaymentLegacy.validUntil,
                    note: 'Payment for TEGA exam course (legacy)'
                  };
                } else {
                }
              }
            } else {
            }
          }
        }
        
      } catch (error) {
      }
    }
    if (hasPaidForTegaExam) {
    }
    
    return {
      success: true,
      hasPaidForTegaExam,
      paymentSource,
      paymentDetails
    };
    
  } catch (error) {
    return {
      success: false,
      hasPaidForTegaExam: false,
      message: 'Failed to check Tega exam payment status'
    };
  }
};

// Express route handler for TEGA exam payment check
export const checkTegaExamPayment = async (req, res) => {
  try {
    const userId = req.studentId;
    const result = await checkTegaExamPaymentUtil(userId);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to check Tega exam payment status'
    });
  }
};

export const getUserPaidCourses = async (req, res) => {
  try {
    const userId = req.studentId; // Changed from req.user.id
    // Try MongoDB first, fallback to in-memory storage
    let oldPaidCourses = [];
    let razorpayPaidCourses = [];
    // Note: Do NOT shadow the imported in-memory map `userCourseAccess` from authController
    // Use a differently named variable for the array of course IDs fetched from UserCourse model
    let userCourseAccessIds = [];
    
    if (isMongoConnected()) {
      try {
        // Get paid courses from old Payment model
        oldPaidCourses = await Payment.getUserPaidCourses(userId);
        // Get paid courses from new RazorpayPayment model
        const RazorpayPayment = (await import('../models/RazorpayPayment.js')).default;
        const razorpayPayments = await RazorpayPayment.find({ 
          studentId: userId, 
          status: 'completed' 
        });
        razorpayPaidCourses = razorpayPayments.map(payment => payment.courseId);
        // Get paid courses from UserCourse model
        const UserCourse = (await import('../models/UserCourse.js')).default;
        const userCourses = await UserCourse.getActiveCourses(userId);
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
              // Use RealTimeCourse instead of Course
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
      courseName: c.courseName || c.name || c.title, // Map RealTimeCourse title to courseName
      name: c.name || c.title, // Also provide as 'name' for compatibility
      title: c.title, // RealTimeCourse uses 'title'
      price: c.price,
      duration: c.duration || (c.estimatedDuration ? 
        `${c.estimatedDuration.hours}h ${c.estimatedDuration.minutes}m` : 
        'N/A'), // Map RealTimeCourse estimatedDuration to duration string
      category: c.category,
      description: c.description,
      isActive: c.isActive !== false,
      status: c.status // RealTimeCourse uses 'status' instead of 'isActive'
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

// Get course-specific offer price
export const getCourseSpecificOffer = async (req, res) => {
  try {
    const { studentId, courseId } = req.params;
    if (!isMongoConnected()) {
      return res.json({
        success: true,
        data: {
          hasOffer: false,
          offerPrice: null,
          message: 'Database not connected'
        }
      });
    }

    // Get student's institute
    const student = await Student.findById(studentId);
    if (!student || !student.institute) {
      return res.json({
        success: true,
        data: {
          hasOffer: false,
          offerPrice: null,
          message: 'Student not found or no institute'
        }
      });
    }

    // Get course details
    const RealTimeCourse = (await import('../models/RealTimeCourse.js')).default;
    const course = await RealTimeCourse.findById(courseId);
    if (!course) {
      return res.json({
        success: true,
        data: {
          hasOffer: false,
          offerPrice: null,
          message: 'Course not found'
        }
      });
    }
    // Escape special regex characters in the institute name
    const escapedInstitute = student.institute.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    
    // Check for active offer for this institute with this specific course
    const Offer = (await import('../models/Offer.js')).default;
    let offer = await Offer.findOne({
      instituteName: { $regex: new RegExp(`^${escapedInstitute}$`, 'i') },
      isActive: true,
      validFrom: { $lte: new Date() },
      validUntil: { $gte: new Date() },
      'courseOffers.courseId': courseId
    });
    // If no exact match found, try partial matching
    if (!offer) {
      const allOffers = await Offer.find({
        isActive: true,
        validFrom: { $lte: new Date() },
        validUntil: { $gte: new Date() },
        'courseOffers.courseId': courseId
      });
      // Try to find a partial match
      const partialMatch = allOffers.find(o => 
        o.instituteName.toLowerCase().includes(student.institute.toLowerCase()) ||
        student.institute.toLowerCase().includes(o.instituteName.toLowerCase())
      );
      
      if (partialMatch) {
        offer = partialMatch;
      }
    }

    if (offer) {
      // Find the specific course offer
      const courseOffer = offer.courseOffers.find(co => co.courseId.toString() === courseId);
      if (courseOffer) {
        return res.json({
          success: true,
          data: {
            hasOffer: true,
            offerPrice: courseOffer.offerPrice,
            originalPrice: course.price,
            discountPercentage: Math.round(((course.price - courseOffer.offerPrice) / course.price) * 100),
            message: `Course-specific offer available: ₹${courseOffer.offerPrice}`
          }
        });
      }
    }
    return res.json({
      success: true,
      data: {
        hasOffer: false,
        offerPrice: null,
        message: 'No course-specific offer available'
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get course-specific offer'
    });
  }
};

// Get TEGA exam-specific offer price
export const getTegaExamSpecificOffer = async (req, res) => {
  try {
    const { studentId, examId } = req.params;
    const { slotId } = req.query; // Get slotId from query params
    if (!isMongoConnected()) {
      return res.json({
        success: true,
        data: {
          hasOffer: false,
          offerPrice: null,
          message: 'Database not connected'
        }
      });
    }

    // Get student's institute
    const student = await Student.findById(studentId);
    if (!student || !student.institute) {
      return res.json({
        success: true,
        data: {
          hasOffer: false,
          offerPrice: null,
          message: 'Student not found or no institute'
        }
      });
    }

    // Get exam details
    const Exam = (await import('../models/Exam.js')).default;
    const exam = await Exam.findById(examId);
    if (!exam) {
      return res.json({
        success: true,
        data: {
          hasOffer: false,
          offerPrice: null,
          message: 'TEGA exam not found'
        }
      });
    }
    // Escape special regex characters in the institute name
    const escapedInstitute = student.institute.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    // Check for active offer for this institute with TEGA exam offers
    const Offer = (await import('../models/Offer.js')).default;
    
    // Debug: Check what offers exist in the database
    const allOffers = await Offer.find({ isActive: true });
    allOffers.forEach((offer, index) => {
    });
    
    let offer = await Offer.findOne({
      instituteName: { $regex: new RegExp(`^${escapedInstitute}$`, 'i') },
      isActive: true,
      validFrom: { $lte: new Date() },
      validUntil: { $gte: new Date() },
      $or: [
        { 'tegaExamOffers.examId': examId, 'tegaExamOffers.isActive': true },
        { 'tegaExamOffer.examId': examId, 'tegaExamOffer.isActive': true }
      ]
    });
    // If no exact match found, try partial matching
    if (!offer) {
      const allOffers = await Offer.find({
        isActive: true,
        validFrom: { $lte: new Date() },
        validUntil: { $gte: new Date() },
        $or: [
          { 'tegaExamOffers.examId': examId, 'tegaExamOffers.isActive': true },
          { 'tegaExamOffer.examId': examId, 'tegaExamOffer.isActive': true }
        ]
      });
      // Try to find a partial match
      const partialMatch = allOffers.find(o => 
        o.instituteName.toLowerCase().includes(student.institute.toLowerCase()) ||
        student.institute.toLowerCase().includes(o.instituteName.toLowerCase())
      );
      
      if (partialMatch) {
        offer = partialMatch;
      }
    }

    // Check for new structure (tegaExamOffers array) with slot support
    if (offer && offer.tegaExamOffers && offer.tegaExamOffers.length > 0) {
      // Use the Offer model method to get slot-specific or general offer
      const tegaExamOffer = offer.getTegaExamOffer(examId, slotId);

      if (tegaExamOffer) {
        const offerPrice = tegaExamOffer.offerPrice;
        const originalPrice = tegaExamOffer.originalPrice || exam.price;
        return res.json({
          success: true,
          data: {
            hasOffer: true,
            offerPrice: offerPrice,
            originalPrice: originalPrice,
            slotId: tegaExamOffer.slotId,
            discountPercentage: tegaExamOffer.discountPercentage || Math.round(((originalPrice - offerPrice) / originalPrice) * 100),
            offerType: slotId ? 'TEGA Exam (Slot-Specific)' : 'TEGA Exam (All Slots)',
            message: `TEGA exam${slotId ? ' slot-specific' : ''} offer available: ₹${offerPrice}`
          }
        });
      }
    }

    // Check for old structure (tegaExamOffer single object) - backward compatibility
    if (offer && offer.tegaExamOffer && offer.tegaExamOffer.isActive) {
      const offerPrice = offer.tegaExamOffer.offerPrice;
      const originalPrice = offer.tegaExamOffer.originalPrice || exam.price;
      return res.json({
        success: true,
        data: {
          hasOffer: true,
          offerPrice: offerPrice,
          originalPrice: originalPrice,
          discountPercentage: offer.tegaExamOffer.discountPercentage || Math.round(((originalPrice - offerPrice) / originalPrice) * 100),
          offerType: 'TEGA Exam',
          message: `TEGA exam-specific offer available: ₹${offerPrice}`
        }
      });
    }
    return res.json({
      success: true,
      data: {
        hasOffer: false,
        offerPrice: null,
        message: 'No TEGA exam-specific offer available'
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get TEGA exam-specific offer'
    });
  }
};

// Get paid slots for a specific exam and student
export const getPaidSlotsForExam = async (req, res) => {
  try {
    const { examId } = req.params;
    const studentId = req.studentId;
    // Get paid slots from RazorpayPayment
    const paidSlots = await RazorpayPayment.getPaidSlotsForExam(studentId, examId);
    res.json({
      success: true,
      data: paidSlots,
      message: `Found ${paidSlots.length} paid slot(s)`
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get paid slots',
      error: error.message
    });
  }
};

// Check if user has paid for a specific slot
export const checkSlotPayment = async (req, res) => {
  try {
    const { examId, slotId } = req.params;
    const studentId = req.studentId;
    const hasPaid = await RazorpayPayment.hasUserPaidForSlot(studentId, examId, slotId);
    res.json({
      success: true,
      data: {
        hasPaid,
        examId,
        slotId,
        studentId
      },
      message: hasPaid ? 'Slot payment found' : 'No payment found for this slot'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to check slot payment',
      error: error.message
    });
  }
};

// Get payment details for all TEGA exams for a student (with slot information)
export const getTegaExamPayments = async (req, res) => {
  try {
    const studentId = req.studentId;
    const payments = await RazorpayPayment.find({
      studentId,
      isTegaExam: true,
      status: 'completed'
    }).populate('examId', 'title examDate');
    
    const paymentDetails = payments.map(p => ({
      examId: p.examId?._id,
      examTitle: p.examId?.title,
      examDate: p.examId?.examDate,
      slotId: p.slotId,
      slotDateTime: p.slotDateTime,
      amount: p.amount,
      paymentDate: p.paymentDate,
      transactionId: p.razorpayPaymentId
    }));
    res.json({
      success: true,
      data: paymentDetails,
      count: paymentDetails.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get TEGA exam payments',
      error: error.message
    });
  }
};
