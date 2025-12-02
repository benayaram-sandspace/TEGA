import razorpay, { verifyRazorpaySignature, verifyWebhookSignature } from '../config/razorpay.js';
import RazorpayPayment from '../models/RazorpayPayment.js';
import UserCourse from '../models/UserCourse.js';
import RealTimeCourse from '../models/RealTimeCourse.js';
import Student from '../models/Student.js';
import Notification from '../models/Notification.js';
import Offer from '../models/Offer.js';

// Helper: find institute offer price for a specific course for a student
const getOfferPriceForStudent = async (studentId, courseId) => {
  try {
    const student = await Student.findById(studentId);
    if (!student || !student.institute) {
      return null;
    }

    const escapedInstitute = student.institute.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    // Exact match first
    let offer = await Offer.findOne({
      instituteName: { $regex: new RegExp(`^${escapedInstitute}$`, 'i') },
      isActive: true,
      validFrom: { $lte: new Date() },
      validUntil: { $gte: new Date() }
    });
    if (!offer) {
      // Try partial match across active offers
      const allOffers = await Offer.find({ 
        isActive: true,
        validFrom: { $lte: new Date() },
        validUntil: { $gte: new Date() }
      });
      offer = allOffers.find(o =>
        o.instituteName.toLowerCase().includes(student.institute.toLowerCase()) ||
        student.institute.toLowerCase().includes(o.instituteName.toLowerCase())
      );
    }

    // Ensure we only apply an offer for the requested course
    if (offer && offer.courseOffers && offer.courseOffers.length > 0 && courseId) {
      const matchingOffer = offer.courseOffers.find(co => {
        try {
          return String(co.courseId) === String(courseId);
        } catch {
          return false;
        }
      });
      if (matchingOffer) {
        return Number(matchingOffer.offerPrice);
      }
    }

    return null;
  } catch (e) {
    return null;
  }
};

// Create Razorpay order
export const createOrder = async (req, res) => {
  try {
    const { courseId, examId, examTitle, attemptNumber, isRetake, offerInfo, slotId, packageId } = req.body;
    const studentId = req.studentId; // From studentAuth middleware
    // Check if Razorpay is configured
    if (!razorpay) {
      return res.status(503).json({
        success: false,
        message: 'Payment service not configured. Please contact administrator.',
        error: 'Razorpay API keys not configured'
      });
    }
    // Handle TEGA exam payments vs course payments vs package payments
    let course = null;
    let amountToCharge = 0;
    let courseName = '';
    let isTegaExam = false;
    let isPackage = false;
    let packageData = null;

    // Check if this is a package purchase
    if (packageId) {
      try {
        isPackage = true;
        const Offer = (await import('../models/Offer.js')).default;
        const mongoose = (await import('mongoose')).default;
        
        // Try to find package offer - packageId could be ObjectId string or regular string
        let offer = null;
        let packageOffer = null;
        
        // First try with the packageId as-is
        offer = await Offer.findOne({ 'packageOffers._id': packageId });
        
        if (!offer) {
          // Try converting to ObjectId if it's a valid ObjectId format
          if (mongoose.Types.ObjectId.isValid(packageId)) {
            offer = await Offer.findOne({ 'packageOffers._id': new mongoose.Types.ObjectId(packageId) });
          }
        }
        
        if (!offer) {
          // Last attempt: find any offer with package offers and match by string comparison
          const allOffers = await Offer.find({ 'packageOffers.0': { $exists: true } });
          for (const o of allOffers) {
            const pkg = o.packageOffers.find(p => {
              const pkgIdStr = p._id.toString();
              return pkgIdStr === packageId || p._id.equals?.(packageId);
            });
            if (pkg) {
              offer = o;
              packageOffer = pkg;
              break;
            }
          }
        } else {
          packageOffer = offer.packageOffers.id(packageId);
          if (!packageOffer && offer.packageOffers.length > 0) {
            // Try finding by string comparison if .id() didn't work
            packageOffer = offer.packageOffers.find(p => p._id.toString() === packageId);
          }
        }
        
        if (!offer || !packageOffer) {
          return res.status(404).json({
            success: false,
            message: 'Package offer not found',
            debug: {
              packageId,
              offerFound: !!offer,
              packageOfferFound: !!packageOffer
            }
          });
        }

        if (!packageOffer.isActive) {
          return res.status(400).json({
            success: false,
            message: 'Package offer is not active'
          });
        }

        // Verify user's institute matches
        const student = await Student.findById(studentId);
        if (!student) {
          return res.status(404).json({
            success: false,
            message: 'Student not found'
          });
        }

        // Use flexible institute matching
        const studentInstitute = (student.institute || '').toLowerCase().trim();
        const packageInstitute = (packageOffer.instituteName || '').toLowerCase().trim();
        
        if (studentInstitute !== packageInstitute && !studentInstitute.includes(packageInstitute) && !packageInstitute.includes(studentInstitute)) {
          return res.status(403).json({
            success: false,
            message: 'This package is not available for your institute'
          });
        }

        // Check if user already has active package access
        const PackageTransaction = (await import('../models/PackageTransaction.js')).default;
        const existingTransaction = await PackageTransaction.findOne({
          userId: studentId,
          packageId: packageOffer._id.toString(),
          status: 'active',
          expiryDate: { $gt: new Date() }
        });

        if (existingTransaction) {
          return res.status(400).json({
            success: false,
            message: 'You already have an active subscription for this package'
          });
        }

        amountToCharge = packageOffer.price;
        courseName = packageOffer.packageName;
        packageData = {
          packageId: packageOffer._id.toString(),
          packageName: packageOffer.packageName,
          includedCourses: packageOffer.includedCourses || [],
          includedExam: packageOffer.includedExam || null,
          validUntil: packageOffer.validUntil
        };
      } catch (packageError) {
        return res.status(500).json({
          success: false,
          message: 'Error processing package purchase',
          error: packageError.message,
          stack: process.env.NODE_ENV === 'development' ? packageError.stack : undefined
        });
      }
    } else if (examId && (!courseId || courseId === 'null' || courseId === '')) {
      // TEGA exam payment (standalone exam)
      isTegaExam = true;
      const Exam = (await import('../models/Exam.js')).default;
      const exam = await Exam.findById(examId);
      if (!exam) {
        return res.status(404).json({
          success: false,
          message: 'TEGA exam not found'
        });
      }

      if (!exam.isTegaExam) {
        return res.status(400).json({
          success: false,
          message: 'This is not a TEGA exam'
        });
      }

      // Check if user already paid for this TEGA exam
      const existingPayment = await RazorpayPayment.checkExistingPayment(studentId, null, examId);
      if (existingPayment) {
        return res.status(400).json({
          success: false,
          message: 'You already have access to this TEGA exam',
          data: {
            paymentId: existingPayment._id,
            status: existingPayment.status,
            courseName: existingPayment.courseName
          }
        });
      }

      // Use the price set when creating the TEGA exam
      amountToCharge = exam.price || exam.effectivePrice || 1999;
      courseName = exam.title || 'TEGA Main Exam';
    } else if (courseId && courseId !== 'null' && courseId !== '') {
      // Course payment (existing logic)
      const existingPayment = await RazorpayPayment.checkExistingPayment(studentId, courseId);
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

      course = await RealTimeCourse.findById(courseId);
    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found'
      });
    }

      if (course.status !== 'published') {
        return res.status(400).json({
          success: false,
          message: 'Course is not available for purchase'
        });
      }

      courseName = course.title;
    } else if (!examId && !courseId && !packageId) {
      return res.status(400).json({
        success: false,
        message: 'Either courseId, examId, or packageId must be provided'
      });
    }

    // Determine amount based on payment type
    let offerDetails = null;

    if (isPackage) {
      // Package payment - amount already set from packageOffer
      // No additional offer processing needed
    } else if (isTegaExam) {
      // TEGA exam payment - use frontend offer info if available, otherwise check backend offers
      // First, check if frontend sent offer info (preferred)
      if (offerInfo && offerInfo.hasOffer) {
        amountToCharge = offerInfo.offerPrice;
        offerDetails = {
          originalPrice: offerInfo.originalPrice,
          offerPrice: offerInfo.offerPrice,
          discountPercentage: offerInfo.discountPercentage,
          offerType: offerInfo.offerType || 'frontend-provided'
        };
      } else {
        // Fallback to backend offer checking
        try {
        // Check for TEGA exam-specific offers for this student's institute
        // Get student details first
        const Student = (await import('../models/Student.js')).default;
        const student = await Student.findById(studentId);
        
        if (!student) {
          return;
        }
        // Check for active offers for this institute with TEGA exam offers
        const Offer = (await import('../models/Offer.js')).default;
        const escapedInstitute = student.institute.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        
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
        // If no exact match, try partial matching
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
          
          const partialMatch = allOffers.find(o => 
            o.instituteName.toLowerCase().includes(student.institute.toLowerCase()) ||
            student.institute.toLowerCase().includes(o.instituteName.toLowerCase())
          );
          
          if (partialMatch) {
            offer = partialMatch;
          }
        }
        
        if (offer) {
          // Check for new structure (tegaExamOffers array) with slot support
          if (offer.tegaExamOffers && offer.tegaExamOffers.length > 0) {
            // Use the Offer model method to get slot-specific or general offer
            const tegaExamOffer = offer.getTegaExamOffer(examId, slotId);
            if (tegaExamOffer && tegaExamOffer.isActive) {
              amountToCharge = tegaExamOffer.offerPrice;
              offerDetails = {
                originalPrice: tegaExamOffer.originalPrice,
                offerPrice: tegaExamOffer.offerPrice,
                discountPercentage: tegaExamOffer.discountPercentage,
                instituteName: offer.instituteName,
                slotId: tegaExamOffer.slotId
              };
            }
          }
          // Check for old structure (tegaExamOffer single object)
          else if (offer.tegaExamOffer && offer.tegaExamOffer.examId.toString() === examId && offer.tegaExamOffer.isActive) {
            amountToCharge = offer.tegaExamOffer.offerPrice;
            offerDetails = {
              originalPrice: offer.tegaExamOffer.originalPrice,
              offerPrice: offer.tegaExamOffer.offerPrice,
              discountPercentage: offer.tegaExamOffer.discountPercentage,
              instituteName: offer.instituteName
            };
          }
        } else {
        }
        } catch (error) {
        }
      }
    } else {
      // Course payment - apply offer logic
      // Prefer frontend offer finalPrice -> offerPrice -> course.offerPrice -> course.price
      const rawCoursePrice = Number(course?.price) || 0;
      const rawCourseOfferPrice = Number(course?.offerPrice);
      const rawFrontendFinalPrice = Number(offerInfo?.finalPrice);
      const rawFrontendOfferPrice = Number(offerInfo?.offerPrice);

      // Choose best available amount in rupees
      const preferredAmount =
        (offerInfo && offerInfo.hasOffer && !Number.isNaN(rawFrontendFinalPrice) && rawFrontendFinalPrice > 0)
          ? rawFrontendFinalPrice
          : (!Number.isNaN(rawFrontendOfferPrice) && rawFrontendOfferPrice > 0)
            ? rawFrontendOfferPrice
            : (!Number.isNaN(rawCourseOfferPrice) && rawCourseOfferPrice > 0)
              ? rawCourseOfferPrice
              : rawCoursePrice;

      amountToCharge = Number(preferredAmount);
      // Build offerDetails if we used an offer
      if (offerInfo && offerInfo.hasOffer && (rawFrontendFinalPrice > 0 || rawFrontendOfferPrice > 0)) {
        offerDetails = {
          originalPrice: Number(offerInfo.originalPrice) || undefined,
          offerPrice: rawFrontendOfferPrice || rawFrontendFinalPrice,
          discountPercentage: offerInfo.discountPercentage,
          instituteName: offerInfo.instituteName
        };
      } else {
        // Fallback to backend offer lookup (old system)
        try {
          const offerPrice = await getOfferPriceForStudent(studentId, courseId);
          if (offerPrice !== null && offerPrice >= 0) {
            amountToCharge = Number(offerPrice);
          }
        } catch (error) {
        }
      }

      // Final guard: ensure we never send 0/NaN to Razorpay; use course base price instead
      if (!amountToCharge || Number.isNaN(amountToCharge) || amountToCharge <= 0) {
        amountToCharge = rawCoursePrice > 0 ? rawCoursePrice : 1; // last-resort guard
      }
    }

    // Create Razorpay order
    // Fetch student once for notes (ensure it's fetched regardless of payment type)
    let studentDoc = null;
    try {
      studentDoc = await Student.findById(studentId);
    } catch (studentError) {
      // Continue without student doc, will use minimal info
    }
    
    // Validate amount before creating order
    if (!amountToCharge || isNaN(amountToCharge) || amountToCharge <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment amount',
        error: `Amount must be greater than 0, got: ${amountToCharge}`
      });
    }

    const orderOptions = {
      amount: Math.round(amountToCharge * 100), // Razorpay expects amount in paise (must be integer)
      currency: 'INR',
      receipt: isPackage
        ? `TEGA_PACKAGE_${Date.now().toString().slice(-8)}_${studentId.toString().slice(-8)}`
        : isTegaExam 
        ? `TEGA_EXAM_${Date.now().toString().slice(-8)}_${studentId.toString().slice(-8)}`
        : `TEGA_COURSE_${Date.now().toString().slice(-8)}_${studentId.toString().slice(-8)}`,
      notes: {
        studentId: studentId.toString(),
        courseId: isPackage ? null : (isTegaExam ? null : (courseId?.toString() || null)),
        courseName: courseName || 'Package',
        studentEmail: studentDoc?.email || '',
        studentName: (studentDoc?.firstName && studentDoc?.lastName)
          ? `${studentDoc.firstName} ${studentDoc.lastName}`
          : (studentDoc?.studentName || studentDoc?.username || 'Student'),
        examId: examId || null,
        attemptNumber: attemptNumber || null,
        isRetake: isRetake || false,
        isTegaExam: isTegaExam,
        packageId: packageId || null,
        isPackage: isPackage
      }
    };

    let order;
    try {
      order = await razorpay.orders.create(orderOptions);
    } catch (orderError) {
      return res.status(500).json({
        success: false,
        message: 'Failed to create Razorpay order',
        error: orderError.message,
        stack: process.env.NODE_ENV === 'development' ? orderError.stack : undefined
      });
    }
    
    // Determine examAccess - must be boolean, not ObjectId
    let hasExamAccess = false;
    if (isTegaExam) {
      hasExamAccess = true;
    } else if (examId) {
      hasExamAccess = true;
    } else if (isPackage && packageData?.includedExam?.examId) {
      hasExamAccess = true; // Package includes exam
    }
    
    // Handle courseId - for packages, we need to handle it properly
    let paymentCourseId = null;
    if (!isPackage && !isTegaExam && courseId) {
      paymentCourseId = courseId;
    } else if (isPackage) {
      // For packages, courseId can be null or we can set it to the first course ID
      // Check schema requirement - if required, we'll use a placeholder
      paymentCourseId = packageData?.includedCourses?.[0]?.courseId || null;
    }
    
    // Save payment record to database
    const payment = new RazorpayPayment({
      studentId,
      courseId: paymentCourseId,
      courseName: courseName,
      amount: amountToCharge,
      originalPrice: isPackage ? amountToCharge : (isTegaExam ? (offerDetails ? offerDetails.originalPrice : amountToCharge) : (offerDetails ? offerDetails.originalPrice : (course?.price || amountToCharge))),
      offerPrice: offerDetails ? offerDetails.offerPrice : null,
      currency: 'INR',
      razorpayOrderId: order.id,
      razorpayReceipt: order.receipt,
      razorpayNotes: order.notes,
      status: 'pending',
      description: isPackage
        ? `Payment for package: ${courseName}`
        : isTegaExam 
        ? `Payment for TEGA exam: ${courseName}${offerDetails ? ` (Institute Offer: ${offerDetails.discountPercentage}% off)` : ''}`
        : `Payment for course: ${courseName}${offerDetails ? ` (Institute Offer: ${offerDetails.discountPercentage}% off)` : ''}`,
      examAccess: hasExamAccess, // This is now a proper boolean
      examId: isPackage ? (packageData?.includedExam?.examId || null) : (examId || null),
      attemptNumber: attemptNumber || null,
      isRetake: isRetake || false,
      isTegaExam: isTegaExam,
      isPackage: isPackage,
      packageId: packageId || null,
      packageData: packageData || null
    });
    // Store user identity on pending record for easier reconciliation
    payment.metadata = {
      studentEmail: studentDoc?.email,
      studentName: (studentDoc?.firstName && studentDoc?.lastName)
        ? `${studentDoc.firstName} ${studentDoc.lastName}`
        : (studentDoc?.studentName || studentDoc?.username)
    };

    try {
      await payment.save();
    } catch (saveError) {
      return res.status(500).json({
        success: false,
        message: 'Failed to save payment record',
        error: saveError.message,
        stack: process.env.NODE_ENV === 'development' ? saveError.stack : undefined
      });
    }
    const response = {
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
    };
    res.json(response);

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create order',
      error: error.message,
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
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
    const payment = await RazorpayPayment.findByOrderId(razorpay_order_id);
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
    // Set validUntil based on payment type
    if (payment.isPackage && payment.packageData?.validUntil) {
      payment.validUntil = new Date(payment.packageData.validUntil);
    } else {
      payment.validUntil = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000); // 1 year default
    }
    const savedPayment = await payment.save();

    // Handle package purchase enrollment
    if (payment.isPackage && payment.packageId && payment.packageData) {
      const { completePackagePurchase } = await import('../controllers/packageController.js');
      const PackageTransaction = (await import('../models/PackageTransaction.js')).default;
      
      // Find existing transaction or create new one
      let transaction = await PackageTransaction.findOne({
        userId: payment.studentId,
        packageId: payment.packageId.toString(),
        status: 'active'
      });

      if (!transaction) {
        try {
          // Transaction was created in purchasePackage, but we need to create it here if missing
          const Offer = (await import('../models/Offer.js')).default;
          const mongoose = (await import('mongoose')).default;
        
        // Try multiple ways to find the package
        let offer = await Offer.findOne({ 'packageOffers._id': payment.packageId });
        let packageOffer = null;
        
        if (offer) {
          packageOffer = offer.packageOffers.id(payment.packageId);
        } else {
          // Try with ObjectId conversion
          if (mongoose.Types.ObjectId.isValid(payment.packageId)) {
            offer = await Offer.findOne({ 'packageOffers._id': new mongoose.Types.ObjectId(payment.packageId) });
            if (offer) {
              packageOffer = offer.packageOffers.id(payment.packageId);
            }
          }
          
          // Last attempt: search all offers
          if (!packageOffer) {
            const allOffers = await Offer.find({ 'packageOffers.0': { $exists: true } });
            for (const o of allOffers) {
              const pkg = o.packageOffers.find(p => 
                p._id.toString() === payment.packageId || p._id.equals?.(payment.packageId)
              );
              if (pkg) {
                offer = o;
                packageOffer = pkg;
                break;
              }
            }
          }
        }
        
        if (offer && packageOffer) {
          const expiryDate = new Date(packageOffer.validUntil);

          // Enroll in all courses
          const enrolledCourses = [];
          const Enrollment = (await import('../models/Enrollment.js')).default;
          
          for (const courseData of packageOffer.includedCourses) {
            const courseId = courseData.courseId;
            if (!courseId.startsWith('default-')) {
              let enrollment = await Enrollment.findOne({
                studentId: payment.studentId,
                courseId: courseId
              });

              if (!enrollment) {
                enrollment = new Enrollment({
                  studentId: payment.studentId,
                  courseId: courseId,
                  courseName: courseData.courseName,
                  isPaid: true,
                  enrolledAt: new Date(),
                  status: 'active',
                  accessExpiresAt: expiryDate,
                  isActive: true
                });
                await enrollment.save();
              } else {
                if (!enrollment.accessExpiresAt || enrollment.accessExpiresAt < expiryDate) {
                  enrollment.accessExpiresAt = expiryDate;
                  enrollment.isActive = true;
                  enrollment.status = 'active';
                  await enrollment.save();
                }
              }

              // Also create/update UserCourse
              let userCourse = await UserCourse.findOne({
                studentId: payment.studentId,
                courseId: courseId
              });

              if (!userCourse) {
                userCourse = new UserCourse({
                  studentId: payment.studentId,
                  courseId: courseId,
                  courseName: courseData.courseName,
                  paymentId: payment._id,
                  accessExpiresAt: expiryDate
                });
                await userCourse.save();
              } else {
                if (!userCourse.accessExpiresAt || userCourse.accessExpiresAt < expiryDate) {
                  userCourse.accessExpiresAt = expiryDate;
                  userCourse.isActive = true;
                  await userCourse.save();
                }
              }

              enrolledCourses.push({
                courseId: courseId,
                courseName: courseData.courseName
              });
            }
          }

          // Handle exam if included - grant access by creating payment record
          let examData = null;
          if (packageOffer.includedExam && packageOffer.includedExam.examId) {
            examData = {
              examId: packageOffer.includedExam.examId,
              examTitle: packageOffer.includedExam.examTitle
            };
            
            // Create exam payment record to grant access
            const examPayment = new RazorpayPayment({
              studentId: payment.studentId,
              courseId: null,
              courseName: packageOffer.includedExam.examTitle,
              amount: 0, // Free via package
              status: 'completed',
              description: `Package purchase: ${packageOffer.packageName}`,
              examId: packageOffer.includedExam.examId,
              examAccess: true,
              isTegaExam: true,
              validUntil: expiryDate,
              paymentDate: new Date(),
              razorpayPaymentId: `package-${payment._id}`,
              transactionId: `package-${payment._id}`
            });
            
            // Check if exam payment already exists
            const existingExamPayment = await RazorpayPayment.findOne({
              studentId: payment.studentId,
              examId: packageOffer.includedExam.examId,
              status: 'completed'
            });
            
            if (!existingExamPayment) {
              await examPayment.save();
            }
          }

          transaction = new PackageTransaction({
            userId: payment.studentId,
            packageId: payment.packageId.toString(),
            packageName: packageOffer.packageName,
            enrolledCourses,
            includedExam: examData,
            purchaseDate: new Date(),
            expiryDate,
            paymentId: payment._id,
            amount: packageOffer.price,
            status: 'active'
          });
          await transaction.save();
        }
      } catch (enrollmentError) {
      }
      } else {
        // Update existing transaction with payment ID
        transaction.paymentId = payment._id;
        await transaction.save();
      }
    }

    // Create user course access (only for course payments, not TEGA exams or packages)
    if (!payment.isTegaExam && !payment.isPackage && payment.courseId) {
    const userCourse = new UserCourse({
      studentId: payment.studentId,
      courseId: payment.courseId,
      courseName: payment.courseName,
      paymentId: payment._id,
      accessExpiresAt: payment.validUntil
    });
    const savedUserCourse = await userCourse.save();
    // CRITICAL: Also create Enrollment record for RealTimeCourse access control
    const Enrollment = (await import('../models/Enrollment.js')).default;
    const enrollment = new Enrollment({
      studentId: payment.studentId,
      courseId: payment.courseId,
      courseName: payment.courseName,
      isPaid: true,
      enrolledAt: new Date(),
      status: 'active',
      accessExpiresAt: payment.validUntil,
      isActive: true
    });
    const savedEnrollment = await enrollment.save();
    } else if (payment.isTegaExam) {
    }

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
    const payment = await RazorpayPayment.findByOrderId(razorpay_order_id);
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

    // Create user course access (only for course payments, not TEGA exams)
    if (!payment.isTegaExam && payment.courseId) {
    const existingUserCourse = await UserCourse.findOne({
      studentId: payment.studentId,
      courseId: payment.courseId
    });

    if (!existingUserCourse) {
      const userCourse = new UserCourse({
        studentId: payment.studentId,
        courseId: payment.courseId,
        courseName: payment.courseName,
        paymentId: payment._id,
        accessExpiresAt: payment.validUntil
      });

      await userCourse.save();
      }
    } else if (payment.isTegaExam) {
    }

    // Ensure Enrollment exists and is valid (includes required fields)
    if (!payment.isTegaExam && payment.courseId) {
      try {
        const Enrollment = (await import('../models/Enrollment.js')).default;
        const existingEnrollment = await Enrollment.findOne({ studentId: payment.studentId, courseId: payment.courseId });
        if (!existingEnrollment) {
          const enrollment = new Enrollment({
            studentId: payment.studentId,
            courseId: payment.courseId,
            courseName: payment.courseName,
            isPaid: true,
            enrolledAt: new Date(),
            status: 'active',
            accessExpiresAt: payment.validUntil,
            isActive: true
          });
          await enrollment.save();
        }
      } catch (e) {
        // swallow to not break webhook; access paths can backfill on next login
      }
    }

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
    const payment = await RazorpayPayment.findByOrderId(razorpay_order_id);
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

    const payment = await RazorpayPayment.findByOrderId(orderId);
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

    const payments = await RazorpayPayment.find({ studentId })
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
