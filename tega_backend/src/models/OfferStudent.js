import mongoose from 'mongoose';

const offerStudentSchema = new mongoose.Schema({
  offerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Offer',
    required: true
  },
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  // Store offer details for quick access
  collegeName: {
    type: String,
    required: true,
    trim: true
  },
  feature: {
    type: String,
    required: true,
    enum: ['Course', 'Job', 'Resume', 'Exam'],
    trim: true
  },
  fixedAmount: {
    type: Number,
    required: true,
    min: 0
  },
  // Track when student was added to offer
  addedAt: {
    type: Date,
    default: Date.now
  },
  addedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true
  },
  // Track payment status if applicable
  paymentStatus: {
    type: String,
    enum: ['pending', 'paid', 'free'],
    default: 'free'
  },
  // Track if student has used the offer
  isUsed: {
    type: Boolean,
    default: false
  },
  usedAt: {
    type: Date
  }
}, {
  timestamps: true
});

// Compound index to prevent duplicate student-offer combinations
offerStudentSchema.index({ offerId: 1, studentId: 1 }, { unique: true });

// Index for faster queries
offerStudentSchema.index({ collegeName: 1, feature: 1 });
offerStudentSchema.index({ studentId: 1 });
offerStudentSchema.index({ addedBy: 1 });

export default mongoose.model('OfferStudent', offerStudentSchema);
