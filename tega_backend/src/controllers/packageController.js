import PackageTransaction from '../models/PackageTransaction.js';
import Offer from '../models/Offer.js';
import Enrollment from '../models/Enrollment.js';
import UserCourse from '../models/UserCourse.js';
import RazorpayPayment from '../models/RazorpayPayment.js';
import RealTimeCourse from '../models/RealTimeCourse.js';
import Student from '../models/Student.js';

// Purchase package and auto-enroll user
export const purchasePackage = async (req, res) => {
  try {
    const { packageId } = req.body;
    const userId = req.studentId;

    if (!packageId || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Package ID and user ID are required'
      });
    }

    // Find the package offer
    const offer = await Offer.findOne({ 'packageOffers._id': packageId });

    if (!offer) {
      return res.status(404).json({
        success: false,
        message: 'Package offer not found'
      });
    }

    const packageOffer = offer.packageOffers.id(packageId);

    if (!packageOffer) {
      return res.status(404).json({
        success: false,
        message: 'Package offer not found'
      });
    }

    if (!packageOffer.isActive) {
      return res.status(400).json({
        success: false,
        message: 'Package offer is not active'
      });
    }

    // Verify user's institute matches
    const student = await Student.findById(userId);
    if (!student) {
      return res.status(404).json({
        success: false,
        message: 'Student not found'
      });
    }

    if (student.institute !== packageOffer.instituteName) {
      return res.status(403).json({
        success: false,
        message: 'This package is not available for your institute'
      });
    }

    // Check if user already purchased this package
    const existingTransaction = await PackageTransaction.findOne({
      userId,
      packageId: packageId.toString(),
      status: 'active'
    });

    if (existingTransaction && new Date() < existingTransaction.expiryDate) {
      return res.status(400).json({
        success: false,
        message: 'You already have an active subscription for this package'
      });
    }

    // Use the validUntil date from package offer
    const expiryDate = new Date(packageOffer.validUntil);

    // Enroll user in all included courses
    const enrolledCourses = [];
    for (const courseData of packageOffer.includedCourses) {
      const courseId = courseData.courseId;

      // Skip if courseId is a default course
      if (courseId.startsWith('default-')) {
        enrolledCourses.push({
          courseId: courseId,
          courseName: courseData.courseName
        });
        continue;
      }

      // Check if already enrolled
      const existingEnrollment = await Enrollment.findOne({
        studentId: userId,
        courseId: courseId
      });

      if (!existingEnrollment) {
        // Create enrollment
        const enrollment = new Enrollment({
          studentId: userId,
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
        // Update existing enrollment expiry if package expiry is later
        if (!existingEnrollment.accessExpiresAt || existingEnrollment.accessExpiresAt < expiryDate) {
          existingEnrollment.accessExpiresAt = expiryDate;
          existingEnrollment.isActive = true;
          existingEnrollment.status = 'active';
          await existingEnrollment.save();
        }
      }

      // Also create/update UserCourse record
      let userCourse = await UserCourse.findOne({
        studentId: userId,
        courseId: courseId
      });

      if (!userCourse) {
        // Create a dummy payment record for UserCourse
        const dummyPayment = new RazorpayPayment({
          studentId: userId,
          courseId: courseId,
          courseName: courseData.courseName,
          amount: 0,
          status: 'completed',
          description: `Package purchase: ${packageOffer.packageName}`
        });
        await dummyPayment.save();

        userCourse = new UserCourse({
          studentId: userId,
          courseId: courseId,
          courseName: courseData.courseName,
          paymentId: dummyPayment._id,
          accessExpiresAt: expiryDate
        });
        await userCourse.save();
      } else {
        // Update expiry if package expiry is later
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

    // If exam is included, grant access (exam access is typically handled through payment records)
    let examData = null;
    if (packageOffer.includedExam && packageOffer.includedExam.examId) {
      examData = {
        examId: packageOffer.includedExam.examId,
        examTitle: packageOffer.includedExam.examTitle
      };

      // Create a payment record for exam access (similar to regular exam purchase)
      const examPayment = new RazorpayPayment({
        studentId: userId,
        courseId: null,
        courseName: packageOffer.includedExam.examTitle,
        amount: 0, // Free via package
        status: 'completed',
        description: `Package purchase: ${packageOffer.packageName}`,
        examId: packageOffer.includedExam.examId,
        examAccess: true,
        isTegaExam: true,
        validUntil: expiryDate
      });
      await examPayment.save();
    }

    // Create package transaction record (will be linked to actual payment later)
    // For now, we'll use a temporary payment ID and update it after payment verification
    const packageTransaction = new PackageTransaction({
      userId,
      packageId: packageId.toString(),
      packageName: packageOffer.packageName,
      enrolledCourses,
      includedExam: examData,
      purchaseDate: new Date(),
      expiryDate,
      paymentId: null, // Will be set after payment verification
      amount: packageOffer.price,
      status: 'active'
    });

    await packageTransaction.save();

    res.json({
      success: true,
      message: 'Package enrollment initiated. Complete payment to activate.',
      data: {
        packageId: packageId.toString(),
        packageName: packageOffer.packageName,
        enrolledCourses,
        includedExam: examData,
        expiryDate,
        transactionId: packageTransaction._id,
        amount: packageOffer.price
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to process package purchase',
      error: error.message
    });
  }
};

// Complete package purchase after payment verification
export const completePackagePurchase = async (req, res) => {
  try {
    const { packageId, paymentId } = req.body;
    const userId = req.studentId;

    if (!packageId || !paymentId || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Package ID, payment ID, and user ID are required'
      });
    }

    // Find package transaction
    const transaction = await PackageTransaction.findOne({
      userId,
      packageId: packageId.toString(),
      status: 'active'
    });

    if (!transaction) {
      return res.status(404).json({
        success: false,
        message: 'Package transaction not found'
      });
    }

    // Verify payment
    const payment = await RazorpayPayment.findById(paymentId);
    if (!payment || payment.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Payment not verified or not completed'
      });
    }

    // Link payment to transaction
    transaction.paymentId = paymentId;
    await transaction.save();

    res.json({
      success: true,
      message: 'Package purchase completed successfully',
      data: {
        transactionId: transaction._id,
        packageName: transaction.packageName,
        enrolledCourses: transaction.enrolledCourses,
        includedExam: transaction.includedExam,
        expiryDate: transaction.expiryDate
      }
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to complete package purchase',
      error: error.message
    });
  }
};

// Get user's package transactions
export const getUserPackageTransactions = async (req, res) => {
  try {
    const userId = req.studentId;

    const transactions = await PackageTransaction.find({
      userId,
      status: 'active'
    }).sort({ purchaseDate: -1 });

    res.json({
      success: true,
      data: transactions
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch package transactions',
      error: error.message
    });
  }
};

