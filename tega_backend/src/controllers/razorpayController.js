import razorpay, { verifyRazorpaySignature, verifyWebhookSignature } from '../config/razorpay.js';
import Payment from '../models/Payment.js';
import Enrollment from '../models/Enrollment.js';
import RealTimeCourse from '../models/RealTimeCourse.js';
import Student from '../models/Student.js';
import Notification from '../models/Notification.js';
import Offer from '../models/Offer.js';

// Helper: find institute offer price for a student (feature: Course)
const getOfferPriceForStudent = async (studentId) => {
  try {
    const student = await Student.findById(studentId);
    if (!student || !student.institute) return null;

    const escapedInstitute = student.institute.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

    // Exact match first
    let offer = await Offer.findOne({
      collegeName: { $regex: new RegExp(`^${escapedInstitute}$`, 'i') },
      feature: 'Course',
      isActive: true
    });

    if (!offer) {
      // Try partial match across active Course offers
      const allOffers = await Offer.find({ feature: 'Course', isActive: true });
      offer = allOffers.find(o =>
        o.collegeName.toLowerCase().includes(student.institute.toLowerCase()) ||
        student.institute.toLowerCase().includes(o.collegeName.toLowerCase())
      );
    }

    return offer ? offer.fixedAmount : null;
  } catch (e) {
    return null;
  }
};

// Create Razorpay order
export const createOrder = async (req, res) => {
  try {
    
    const { courseId, examId, examTitle, attemptNumber, isRetake } = req.body;
    const studentId = req.studentId; // From studentAuth middleware


    // Check if Razorpay is configured
    if (!razorpay) {
      return res.status(503).json({
        success: false,
        message: 'Payment service not configured. Please contact administrator.',
        error: 'Razorpay API keys not configured'
      });
    }

    // Check if user already has access to this course (skip for exam payments)
    if (!examId) {
      const existingPayment = await Payment.checkExistingPayment(studentId, courseId);
      if (existingPayment) {
        return res.status(400).json({
          success: false,
          message: 'You already have access to this course',
          data: {
            paymentId: existingPayment._id,
            status: existingPayment.status,
            courseName: existingPayment.courseName
          }
        });
      }
    }

    // Fetch course details - try both Course and RealTimeCourse models
    let course = await Course.findById(courseId);
    let isRealTimeCourse = false;
    
    if (!course) {
      // Try RealTimeCourse model
      const RealTimeCourse = (await import('../models/RealTimeCourse.js')).default;
      course = await RealTimeCourse.findById(courseId);
      isRealTimeCourse = true;
    }
    
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

    // Check if course is active (different field names for different models)
    const isActive = course.isActive || (course.status === 'published');
    if (!isActive) {
      return res.status(400).json({
        success: false,
        message: 'Course is not available for purchase'
      });
    }

    // Determine amount: prefer institute offer if available
    let amountToCharge = course.price || 0;
    
    console.log('💰 Course pricing details:', {
      courseId,
      courseName: course.courseName || course.title,
      originalPrice: course.price,
      isFree: course.isFree,
      amountToCharge
    });
    
    // For free courses, don't create payment order
    if (course.isFree || amountToCharge === 0) {
      return res.status(400).json({
        success: false,
        message: 'This is a free course. No payment required.'
      });
    }
    
    // Validate amount
    if (amountToCharge <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid course price. Please contact administrator.'
      });
    }
    
    try {
      const offerPrice = await getOfferPriceForStudent(studentId);
      if (offerPrice !== null && offerPrice >= 0) {
        amountToCharge = offerPrice;
      }
    } catch (_) {}

    // Create Razorpay order
    // Fetch student once for notes
    const studentDoc = await Student.findById(studentId);
    
    // Get course name - handle both Course and RealTimeCourse models
    const courseName = course.courseName || course.title || 'Course';
    
    const orderOptions = {
      amount: amountToCharge * 100, // Razorpay expects amount in paise
      currency: 'INR',
      receipt: `TEGA_${Date.now().toString().slice(-8)}_${studentId.toString().slice(-8)}`, // Max 40 chars
      notes: {
        studentId: studentId.toString(),
        courseId: courseId.toString(),
        courseName: examId ? examTitle || 'Exam Payment' : courseName,
        studentEmail: studentDoc?.email,
        studentName: (studentDoc?.firstName && studentDoc?.lastName)
          ? `${studentDoc.firstName} ${studentDoc.lastName}`
          : (studentDoc?.studentName || studentDoc?.username),
        examId: examId || null,
        attemptNumber: attemptNumber || null,
        isRetake: isRetake || false
      }
    };

    console.log('🔍 Creating Razorpay order with options:', orderOptions);
    const order = await razorpay.orders.create(orderOptions);
    console.log('✅ Razorpay order created successfully:', order.id);

    // Save payment record to database
    const payment = new Payment({
      studentId,
      courseId,
      courseName: examId ? examTitle || 'Exam Payment' : courseName,
      amount: amountToCharge,
      currency: 'INR',
      razorpayOrderId: order.id,
      razorpayReceipt: order.receipt,
      razorpayNotes: order.notes,
      status: 'pending',
      description: examId ? `Payment for exam: ${examTitle || 'Exam'}` : `Payment for course: ${courseName}`,
      examAccess: !!examId,
      examId: examId || null,
      attemptNumber: attemptNumber || null,
      isRetake: isRetake || false
    });
    // Store user identity on pending record for easier reconciliation
    payment.metadata = {
      studentEmail: studentDoc?.email,
      studentName: (studentDoc?.firstName && studentDoc?.lastName)
        ? `${studentDoc.firstName} ${studentDoc.lastName}`
        : (studentDoc?.studentName || studentDoc?.username)
    };

    await payment.save();


    res.json({
      success: true,
      message: 'Order created successfully',
      data: {
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
        receipt: order.receipt,
        paymentId: payment._id,
        chargedAmount: amountToCharge
      }
    });

  } catch (error) {
    console.error('❌ Razorpay order creation failed:', error);
    console.error('❌ Error details:', {
      message: error.message,
      code: error.code,
      statusCode: error.statusCode,
      response: error.response
    });
    
    res.status(500).json({
      success: false,
      message: 'Failed to create order',
      error: error.message,
      details: process.env.NODE_ENV === 'development' ? {
        code: error.code,
        statusCode: error.statusCode,
        response: error.response
      } : undefined
    });
  }
};

// Verify payment
export const verifyPayment = async (req, res) => {
  try {
    
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
    const studentId = req.studentId;


    // Verify signature
    const isSignatureValid = verifyRazorpaySignature(
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature
    );

    if (!isSignatureValid) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment signature'
      });
    }

    // Find payment record
    const payment = await Payment.findByOrderId(razorpay_order_id);
    
    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Payment record not found'
      });
    }


    if (payment.studentId.toString() !== studentId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized access to payment record'
      });
    }

    // Update payment record
    payment.status = 'completed';
    payment.razorpayPaymentId = razorpay_payment_id;
    payment.razorpaySignature = razorpay_signature;
    payment.transactionId = razorpay_payment_id;
    payment.paymentDate = new Date();
    payment.examAccess = true;
    payment.validUntil = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000); // 1 year

    const savedPayment = await payment.save();

    // Create user course access
    const userCourse = new Enrollment({
      studentId: payment.studentId,
      courseId: payment.courseId,
      courseName: payment.courseName,
      paymentId: payment._id,
      accessExpiresAt: payment.validUntil
    });

    const savedEnrollment = await userCourse.save();

    // Enrollment record already created above, no need to duplicate

    // Send notifications
    await sendPaymentNotifications(payment);


    res.json({
      success: true,
      message: 'Payment verified successfully',
      data: {
        paymentId: payment._id,
        status: payment.status,
        courseName: payment.courseName,
        amount: payment.amount,
        transactionId: payment.transactionId,
        examAccess: payment.examAccess,
        validUntil: payment.validUntil
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to verify payment',
      error: error.message
    });
  }
};

// Webhook handler
export const handleWebhook = async (req, res) => {
  try {
    const signature = req.headers['x-razorpay-signature'];
    const body = JSON.stringify(req.body);


    // Verify webhook signature
    const isSignatureValid = verifyWebhookSignature(body, signature);
    if (!isSignatureValid) {
      return res.status(400).json({ success: false, message: 'Invalid signature' });
    }

    const { event, payload } = req.body;

    if (event === 'payment.captured') {
      await handlePaymentCaptured(payload.payment.entity);
    } else if (event === 'payment.failed') {
      await handlePaymentFailed(payload.payment.entity);
    }

    res.json({ success: true, message: 'Webhook processed' });

  } catch (error) {
    res.status(500).json({ success: false, message: 'Webhook processing failed' });
  }
};

// Handle payment captured webhook
const handlePaymentCaptured = async (paymentEntity) => {
  try {
    const { id: razorpay_payment_id, order_id: razorpay_order_id } = paymentEntity;


    // Find payment record
    const payment = await Payment.findByOrderId(razorpay_order_id);
    if (!payment) {
      return;
    }

    if (payment.status === 'completed') {
      return;
    }

    // Update payment record
    payment.status = 'completed';
    payment.razorpayPaymentId = razorpay_payment_id;
    payment.transactionId = razorpay_payment_id;
    payment.paymentDate = new Date();
    payment.examAccess = true;
    payment.validUntil = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);

    await payment.save();

    // Create user course access
    const existingEnrollment = await Enrollment.findOne({
      studentId: payment.studentId,
      courseId: payment.courseId
    });

    if (!existingEnrollment) {
      const userCourse = new Enrollment({
        studentId: payment.studentId,
        courseId: payment.courseId,
        courseName: payment.courseName,
        paymentId: payment._id,
        accessExpiresAt: payment.validUntil
      });

      await userCourse.save();
    }

    // Enrollment record already created above, no need to duplicate

    // Send notifications
    await sendPaymentNotifications(payment);


  } catch (error) {
  }
};

// Handle payment failed webhook
const handlePaymentFailed = async (paymentEntity) => {
  try {
    const { id: razorpay_payment_id, order_id: razorpay_order_id } = paymentEntity;


    // Find payment record
    const payment = await Payment.findByOrderId(razorpay_order_id);
    if (!payment) {
      return;
    }

    // Update payment record
    payment.status = 'failed';
    payment.razorpayPaymentId = razorpay_payment_id;
    payment.transactionId = razorpay_payment_id;
    payment.failureReason = 'Payment failed';
    payment.paymentDate = new Date();

    await payment.save();


  } catch (error) {
  }
};

// Get payment status
export const getPaymentStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const studentId = req.studentId;

    const payment = await Payment.findByOrderId(orderId);
    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Payment not found'
      });
    }

    if (payment.studentId.toString() !== studentId.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Unauthorized access'
      });
    }

    res.json({
      success: true,
      data: {
        paymentId: payment._id,
        status: payment.status,
        courseName: payment.courseName,
        amount: payment.amount,
        transactionId: payment.transactionId,
        examAccess: payment.examAccess,
        validUntil: payment.validUntil,
        createdAt: payment.createdAt
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get payment status',
      error: error.message
    });
  }
};

// Get user's payment history
export const getPaymentHistory = async (req, res) => {
  try {
    const studentId = req.studentId;

    const payments = await Payment.find({ studentId })
      .sort({ createdAt: -1 })
      .populate('courseId', 'name description price duration category');

    res.json({
      success: true,
      data: payments
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to get payment history',
      error: error.message
    });
  }
};

// Send payment notifications
const sendPaymentNotifications = async (payment) => {
  try {
    const student = await Student.findById(payment.studentId);

    // Student notification
    const studentNotification = new Notification({
      recipient: payment.studentId,
      recipientModel: 'Student',
      message: `Payment successful! You now have access to ${payment.courseName}`,
      type: 'payment_success',
      data: {
        paymentId: payment._id,
        courseName: payment.courseName,
        amount: payment.amount,
        transactionId: payment.transactionId
      }
    });

    await studentNotification.save();

    // Admin notification
    const adminNotification = new Notification({
      recipient: 'admin', // You might want to get actual admin ID
      recipientModel: 'Admin',
      message: `New payment received: ${student?.firstName} ${student?.lastName} paid ₹${payment.amount} for ${payment.courseName}`,
      type: 'payment_received',
      data: {
        studentId: payment.studentId,
        studentName: `${student?.firstName} ${student?.lastName}`,
        courseName: payment.courseName,
        amount: payment.amount,
        transactionId: payment.transactionId
      }
    });

    await adminNotification.save();


  } catch (error) {
  }
};
