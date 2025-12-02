import mongoose from 'mongoose';

const packageTransactionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  packageId: {
    type: String, // Reference to package offer
    required: true
  },
  packageName: {
    type: String,
    required: true
  },
  enrolledCourses: [{
    courseId: {
      type: String,
      required: true
    },
    courseName: {
      type: String,
      required: true
    }
  }],
  includedExam: {
    examId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Exam',
      default: null
    },
    examTitle: {
      type: String,
      default: null
    }
  },
  purchaseDate: {
    type: Date,
    default: Date.now
  },
  expiryDate: {
    type: Date,
    required: true
  },
  paymentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'RazorpayPayment',
    required: true
  },
  amount: {
    type: Number,
    required: true
  },
  status: {
    type: String,
    enum: ['active', 'expired', 'cancelled'],
    default: 'active'
  }
}, {
  timestamps: true
});

// Indexes
packageTransactionSchema.index({ userId: 1, status: 1 });
packageTransactionSchema.index({ expiryDate: 1 });
packageTransactionSchema.index({ packageId: 1 });

// Method to check if package is still valid
packageTransactionSchema.methods.isValid = function() {
  return this.status === 'active' && new Date() < this.expiryDate;
};

const PackageTransaction = mongoose.model('PackageTransaction', packageTransactionSchema);

export default PackageTransaction;

