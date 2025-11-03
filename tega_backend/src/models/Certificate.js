import mongoose from 'mongoose';

const certificateSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: true
  },
  certificateNumber: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  // Student information at time of completion
  studentName: {
    type: String,
    required: true
  },
  studentEmail: {
    type: String,
    required: true
  },
  // Course information at time of completion
  courseName: {
    type: String,
    required: true
  },
  courseDescription: {
    type: String
  },
  // Completion metrics
  completionDate: {
    type: Date,
    required: true,
    default: Date.now
  },
  totalDuration: {
    type: String // e.g., "40 hours"
  },
  finalScore: {
    type: Number, // Percentage
    min: 0,
    max: 100
  },
  grade: {
    type: String,
    enum: ['A+', 'A', 'B+', 'B', 'C+', 'C', 'Pass', 'N/A'],
    default: 'Pass'
  },
  // Certificate URLs
  certificatePdfUrl: {
    type: String // Generated PDF stored in R2
  },
  certificateImageUrl: {
    type: String // Preview image stored in R2
  },
  r2Key: {
    type: String // R2 storage key
  },
  // Verification
  verificationCode: {
    type: String,
    unique: true,
    required: true
  },
  isVerified: {
    type: Boolean,
    default: true
  },
  // Additional data
  skills: [String],
  instructorName: {
    type: String
  },
  instructorSignature: {
    type: String // URL to signature image
  },
  organizationName: {
    type: String,
    default: 'TEGA Learning Platform'
  },
  organizationLogo: {
    type: String // URL to logo
  },
  // Status
  status: {
    type: String,
    enum: ['generated', 'sent', 'downloaded', 'revoked'],
    default: 'generated'
  },
  isActive: {
    type: Boolean,
    default: true
  },
  // Tracking
  viewCount: {
    type: Number,
    default: 0
  },
  downloadCount: {
    type: Number,
    default: 0
  },
  sharedCount: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Indexes
certificateSchema.index({ studentId: 1, courseId: 1 });
certificateSchema.index({ certificateNumber: 1 });
certificateSchema.index({ verificationCode: 1 });
certificateSchema.index({ status: 1, isActive: 1 });

// Generate unique certificate number
certificateSchema.statics.generateCertificateNumber = async function() {
  const prefix = 'TEGA';
  const year = new Date().getFullYear();
  const count = await this.countDocuments();
  const number = String(count + 1).padStart(6, '0');
  return `${prefix}-${year}-${number}`;
};

// Generate verification code
certificateSchema.statics.generateVerificationCode = function() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 12; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
    if (i === 3 || i === 7) code += '-';
  }
  return code;
};

// Calculate grade based on score
certificateSchema.methods.calculateGrade = function() {
  if (!this.finalScore) return 'Pass';
  
  if (this.finalScore >= 95) return 'A+';
  if (this.finalScore >= 90) return 'A';
  if (this.finalScore >= 85) return 'B+';
  if (this.finalScore >= 80) return 'B';
  if (this.finalScore >= 75) return 'C+';
  if (this.finalScore >= 70) return 'C';
  return 'Pass';
};

// Method to increment view count
certificateSchema.methods.incrementViewCount = function() {
  this.viewCount += 1;
  return this.save();
};

// Method to increment download count
certificateSchema.methods.incrementDownloadCount = function() {
  this.downloadCount += 1;
  this.status = 'downloaded';
  return this.save();
};

// Static method to verify certificate
certificateSchema.statics.verifyCertificate = async function(verificationCode) {
  return this.findOne({ 
    verificationCode, 
    isActive: true,
    isVerified: true 
  }).populate('studentId', 'name email')
    .populate('courseId', 'courseName');
};

export default mongoose.model('Certificate', certificateSchema);
