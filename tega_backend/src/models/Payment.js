import mongoose from 'mongoose';

const paymentSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'RealTimeCourse',
    required: false // Made optional for Tega Exam payments
  },
  examId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Exam',
    required: false // For Tega Exam payments
  },
  courseName: {
    type: String,
    required: true
  },
  amount: {
    type: Number,
    required: true,
    min: 0
  },
  originalPrice: {
    type: Number,
    min: 0
  },
  offerPrice: {
    type: Number,
    min: 0
  },
  currency: {
    type: String,
    default: 'INR'
  },
  paymentMethod: {
    type: String,
    enum: ['razorpay', 'stripe', 'paypal', 'manual', 'card', 'upi', 'netbanking', 'Google Pay UPI'],
    default: 'razorpay'
  },
  status: {
    type: String,
    enum: ['pending', 'completed', 'failed', 'refunded', 'cancelled'],
    default: 'pending'
  },
  // Razorpay specific fields
  razorpayOrderId: {
    type: String,
    unique: true,
    sparse: true
  },
  razorpayPaymentId: {
    type: String,
    unique: true,
    sparse: true
  },
  razorpaySignature: {
    type: String
  },
  razorpayReceipt: {
    type: String
  },
  razorpayNotes: {
    type: mongoose.Schema.Types.Mixed
  },
  transactionId: {
    type: String,
    unique: true,
    sparse: true
  },
  paymentDate: {
    type: Date,
    default: Date.now
  },
  description: {
    type: String,
    trim: true
  },
  receiptUrl: {
    type: String
  },
  // For exam access verification
  examAccess: {
    type: Boolean,
    default: true
  },
  validUntil: {
    type: Date
  },
  // UPI specific fields
  upiId: {
    type: String,
    trim: true
  },
  upiReferenceId: {
    type: String,
    trim: true
  },
  failureReason: {
    type: String,
    trim: true
  },
  // Enhanced refund tracking
  refundDetails: {
    refundId: {
      type: String,
      trim: true
    },
    refundAmount: {
      type: Number,
      min: 0
    },
    refundReason: {
      type: String,
      trim: true
    },
    refundDate: {
      type: Date
    },
    refundStatus: {
      type: String,
      enum: ['initiated', 'processed', 'failed'],
      default: 'initiated'
    }
  }
}, {
  timestamps: true
});

// Static method to check if a user has paid for a specific course
paymentSchema.statics.hasUserPaidForCourse = async function (studentId, courseId) {
  const payment = await this.findOne({
    studentId: studentId,
    courseId: courseId,
    status: 'completed'
  });
  return !!payment;
};

// Static method to get all paid courses for a user
paymentSchema.statics.getUserPaidCourses = async function (studentId) {
  const payments = await this.find({
    studentId: studentId,
    status: 'completed'
  }).distinct('courseId');
  return payments;
};

// Static method to check for existing successful payment
paymentSchema.statics.checkExistingPayment = async function(studentId, courseId) {
  return await this.findOne({
    studentId,
    courseId,
    status: 'completed'
  });
};

// Static method to find payment by Razorpay order ID
paymentSchema.statics.findByOrderId = async function(orderId) {
  return await this.findOne({ razorpayOrderId: orderId });
};

// Static method to find payment by Razorpay payment ID
paymentSchema.statics.findByPaymentId = async function(paymentId) {
  return await this.findOne({ razorpayPaymentId: paymentId });
};

// Static method to get payment analytics
paymentSchema.statics.getPaymentAnalytics = async function(dateRange = 30) {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - dateRange);
  
  const analytics = await this.aggregate([
    {
      $match: {
        paymentDate: { $gte: startDate }
      }
    },
    {
      $group: {
        _id: null,
        totalRevenue: { $sum: '$amount' },
        totalTransactions: { $sum: 1 },
        completedPayments: {
          $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
        },
        failedPayments: {
          $sum: { $cond: [{ $eq: ['$status', 'failed'] }, 1, 0] }
        },
        refundedPayments: {
          $sum: { $cond: [{ $eq: ['$status', 'refunded'] }, 1, 0] }
        },
        avgTransactionValue: { $avg: '$amount' }
      }
    },
    {
      $project: {
        _id: 0,
        totalRevenue: 1,
        totalTransactions: 1,
        completedPayments: 1,
        failedPayments: 1,
        refundedPayments: 1,
        avgTransactionValue: { $round: ['$avgTransactionValue', 2] },
        successRate: {
          $round: [
            { $multiply: [{ $divide: ['$completedPayments', '$totalTransactions'] }, 100] },
            2
          ]
        }
      }
    }
  ]);
  
  return analytics[0] || {
    totalRevenue: 0,
    totalTransactions: 0,
    completedPayments: 0,
    failedPayments: 0,
    refundedPayments: 0,
    avgTransactionValue: 0,
    successRate: 0
  };
};

// Index for efficient querying
paymentSchema.index({ studentId: 1, courseId: 1 });
paymentSchema.index({ status: 1, paymentDate: 1 });
paymentSchema.index({ transactionId: 1 });
paymentSchema.index({ studentId: 1, courseId: 1, status: 1 });
paymentSchema.index({ razorpayOrderId: 1 });
paymentSchema.index({ razorpayPaymentId: 1 });

export default mongoose.model('Payment', paymentSchema);
