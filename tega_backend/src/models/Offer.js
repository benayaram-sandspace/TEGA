import mongoose from 'mongoose';

const offerSchema = new mongoose.Schema({
  instituteName: {
    type: String,
    required: true,
    trim: true,
    index: true
  },
  courseOffers: [{
    courseId: {
      type: String, // Changed from ObjectId to String to support default courses
      required: true
    },
    courseName: {
    type: String,
    required: true,
    trim: true
  },
    originalPrice: {
      type: Number,
      required: true,
      min: 0
    },
    offerPrice: {
      type: Number,
      required: true,
      min: 0
    },
    discountPercentage: {
      type: Number,
      min: 0,
      max: 100,
      default: 0
    },
    isActive: {
      type: Boolean,
      default: true
    }
  }],
  tegaExamOffers: [{
    examId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Exam',
      required: true
    },
    examTitle: {
      type: String,
      required: true,
      trim: true
    },
    slotId: {
      type: String,
      default: null // null means offer applies to all slots, otherwise specific slot
    },
    originalPrice: {
      type: Number,
      required: true,
      min: 0
    },
    offerPrice: {
      type: Number,
      required: true,
      min: 0
    },
    discountPercentage: {
      type: Number,
      min: 0,
      max: 100,
      default: 0
    },
    isActive: {
      type: Boolean,
      default: true
    }
  }],
  validFrom: {
    type: Date,
    default: Date.now
  },
  validUntil: {
    type: Date,
    required: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdBy: {
    type: String, // Changed from ObjectId to String to handle both admin IDs and user IDs
    required: true
  },
  description: {
    type: String,
    trim: true,
    maxlength: 500
  },
  maxStudents: {
    type: Number,
    default: null // null means unlimited
  },
  enrolledStudents: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Indexes for better performance
offerSchema.index({ instituteName: 1, isActive: 1 });
offerSchema.index({ validUntil: 1 });
offerSchema.index({ 'courseOffers.courseId': 1 });
offerSchema.index({ 'tegaExamOffers.examId': 1 });

// Virtual for checking if offer is currently valid
offerSchema.virtual('isValid').get(function() {
  const now = new Date();
  return this.isActive && 
         this.validFrom <= now && 
         this.validUntil >= now;
});

// Method to check if student can use this offer
offerSchema.methods.canStudentUseOffer = function(studentInstitute) {
  return this.instituteName.toLowerCase() === studentInstitute.toLowerCase() && 
         this.isValid && 
         (this.maxStudents === null || this.enrolledStudents < this.maxStudents);
};

// Method to get course offer for a specific course
offerSchema.methods.getCourseOffer = function(courseId) {
  const courseOffer = this.courseOffers.find(offer => 
    offer.courseId.toString() === courseId.toString() && offer.isActive
  );
  return courseOffer;
};

// Method to get Tega Exam offer for a specific exam and slot
offerSchema.methods.getTegaExamOffer = function(examId, slotId = null) {
  // Find offers for this exam
  const examOffers = this.tegaExamOffers.filter(offer => 
    offer.examId.toString() === examId.toString() && offer.isActive
  );
  
  if (examOffers.length === 0) {
    return null;
  }
  
  // If slotId is provided, look for slot-specific offer first
  if (slotId) {
    const slotSpecificOffer = examOffers.find(offer => offer.slotId === slotId);
    if (slotSpecificOffer) {
      return slotSpecificOffer;
    }
  }
  
  // Return general offer (slotId = null) if no slot-specific offer found
  const generalOffer = examOffers.find(offer => !offer.slotId || offer.slotId === null);
  return generalOffer || null;
};

// Static method to find active offers for an institute
offerSchema.statics.findActiveOffersForInstitute = function(instituteName) {
  const now = new Date();
  return this.find({
    instituteName: instituteName,
    isActive: true,
    validFrom: { $lte: now },
    validUntil: { $gte: now }
  }).populate('courseOffers.courseId', 'courseName price');
};

// Static method to get offer for specific course and institute
offerSchema.statics.getCourseOfferForInstitute = function(instituteName, courseId) {
  const now = new Date();
  return this.findOne({
    instituteName: instituteName,
    isActive: true,
    validFrom: { $lte: now },
    validUntil: { $gte: now },
    'courseOffers.courseId': courseId,
    'courseOffers.isActive': true
  }).populate('courseOffers.courseId', 'courseName price');
};

// Static method to get Tega Exam offer for institute
offerSchema.statics.getTegaExamOfferForInstitute = function(instituteName) {
  const now = new Date();
  return this.findOne({
    instituteName: instituteName,
    isActive: true,
    validFrom: { $lte: now },
    validUntil: { $gte: now },
    'tegaExamOffer.isActive': true
  });
};

// Pre-save middleware to calculate discount percentage
offerSchema.pre('save', function(next) {
  // Calculate discount percentage for course offers
  this.courseOffers.forEach(offer => {
    if (offer.originalPrice > 0) {
      offer.discountPercentage = Math.round(((offer.originalPrice - offer.offerPrice) / offer.originalPrice) * 100);
    }
  });

  // Calculate discount percentage for Tega Exam offers (new structure)
  if (this.tegaExamOffers && this.tegaExamOffers.length > 0) {
    this.tegaExamOffers.forEach(tegaExamOffer => {
      if (tegaExamOffer.originalPrice > 0) {
        tegaExamOffer.discountPercentage = Math.round(
          ((tegaExamOffer.originalPrice - tegaExamOffer.offerPrice) / tegaExamOffer.originalPrice) * 100
        );
      }
    });
  }

  // Calculate discount percentage for Tega Exam offer (old structure - backward compatibility)
  if (this.tegaExamOffer && this.tegaExamOffer.originalPrice > 0) {
    this.tegaExamOffer.discountPercentage = Math.round(
      ((this.tegaExamOffer.originalPrice - this.tegaExamOffer.offerPrice) / this.tegaExamOffer.originalPrice) * 100
    );
  }

  next();
});

// Method to increment enrolled students count
offerSchema.methods.incrementEnrollment = function() {
  if (this.maxStudents === null || this.enrolledStudents < this.maxStudents) {
    this.enrolledStudents += 1;
    return this.save();
  }
  throw new Error('Maximum students limit reached for this offer');
};

// Method to decrement enrolled students count
offerSchema.methods.decrementEnrollment = function() {
  if (this.enrolledStudents > 0) {
    this.enrolledStudents -= 1;
    return this.save();
  }
  throw new Error('No enrolled students to decrement');
};

const Offer = mongoose.model('Offer', offerSchema);

export default Offer;