import mongoose from 'mongoose';

const offerSchema = new mongoose.Schema({
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
  description: {
    type: String,
    trim: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true
  },
  lastModifiedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin'
  },
  // Track how many students are linked to this offer
  studentCount: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Index for faster queries
offerSchema.index({ collegeName: 1, feature: 1 });
offerSchema.index({ isActive: 1 });

// Virtual for total revenue
offerSchema.virtual('totalRevenue').get(function() {
  return this.fixedAmount * this.studentCount;
});

// Ensure virtual fields are serialized
offerSchema.set('toJSON', { virtuals: true });

export default mongoose.model('Offer', offerSchema);
