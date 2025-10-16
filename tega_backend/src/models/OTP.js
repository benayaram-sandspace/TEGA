import mongoose from 'mongoose';

const otpSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    lowercase: true,
    trim: true
  },
  otp: {
    type: String,
    required: true,
    length: 6
  },
  type: {
    type: String,
    enum: ['registration', 'password_reset', 'login', 'verification'],
    required: true,
    default: 'verification'
  },
  purpose: {
    type: String,
    enum: ['email_verification', 'password_reset', 'two_factor_auth', 'account_recovery'],
    required: true,
    default: 'email_verification'
  },
  expiresAt: {
    type: Date,
    required: true,
    default: () => new Date(Date.now() + 5 * 60 * 1000) // 5 minutes from now
  },
  attempts: {
    type: Number,
    default: 0,
    max: 3
  },
  isUsed: {
    type: Boolean,
    default: false
  },
  usedAt: {
    type: Date
  },
  ipAddress: {
    type: String
  },
  userAgent: {
    type: String
  }
}, {
  timestamps: true
});

// Indexes for better performance
otpSchema.index({ email: 1, type: 1 });
otpSchema.index({ email: 1, purpose: 1 });
otpSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // TTL index
otpSchema.index({ otp: 1, email: 1 });

// Static method to generate OTP
otpSchema.statics.generateOTP = async function(email, type = 'verification', purpose = 'email_verification', ipAddress = null, userAgent = null) {
  try {
    // Invalidate any existing OTPs for this email and type
    await this.updateMany(
      { email, type, isUsed: false },
      { isUsed: true, usedAt: new Date() }
    );

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Create new OTP record
    const otpRecord = new this({
      email,
      otp,
      type,
      purpose,
      ipAddress,
      userAgent
    });

    await otpRecord.save();
    
    return {
      otp,
      expiresAt: otpRecord.expiresAt,
      id: otpRecord._id
    };
  } catch (error) {
    throw new Error(`Failed to generate OTP: ${error.message}`);
  }
};

// Static method to verify OTP
otpSchema.statics.verifyOTP = async function(email, otp, type = 'verification', purpose = 'email_verification') {
  try {
    const otpRecord = await this.findOne({
      email,
      otp,
      type,
      purpose,
      isUsed: false,
      expiresAt: { $gt: new Date() },
      attempts: { $lt: 3 }
    });

    if (!otpRecord) {
      // Increment attempts for any existing OTPs for this email
      await this.updateMany(
        { email, type, purpose, isUsed: false },
        { $inc: { attempts: 1 } }
      );
      return { success: false, message: 'Invalid or expired OTP' };
    }

    // Mark OTP as used
    otpRecord.isUsed = true;
    otpRecord.usedAt = new Date();
    await otpRecord.save();

    return { success: true, message: 'OTP verified successfully' };
  } catch (error) {
    throw new Error(`Failed to verify OTP: ${error.message}`);
  }
};

// Static method to check if OTP exists and is valid
otpSchema.statics.isValidOTP = async function(email, otp, type = 'verification', purpose = 'email_verification') {
  try {
    const otpRecord = await this.findOne({
      email,
      otp,
      type,
      purpose,
      isUsed: false,
      expiresAt: { $gt: new Date() },
      attempts: { $lt: 3 }
    });

    return !!otpRecord;
  } catch (error) {
    return false;
  }
};

// Static method to get OTP attempts for an email
otpSchema.statics.getAttempts = async function(email, type = 'verification', purpose = 'email_verification') {
  try {
    const otpRecord = await this.findOne({
      email,
      type,
      purpose,
      isUsed: false,
      expiresAt: { $gt: new Date() }
    }).sort({ createdAt: -1 });

    return otpRecord ? otpRecord.attempts : 0;
  } catch (error) {
    return 0;
  }
};

// Static method to clean up expired OTPs
otpSchema.statics.cleanupExpired = async function() {
  try {
    const result = await this.deleteMany({
      $or: [
        { expiresAt: { $lt: new Date() } },
        { attempts: { $gte: 3 } }
      ]
    });
    
    return result.deletedCount;
  } catch (error) {
    throw new Error(`Failed to cleanup expired OTPs: ${error.message}`);
  }
};

// Static method to get OTP statistics
otpSchema.statics.getStats = async function(email = null) {
  try {
    const match = email ? { email } : {};
    
    const stats = await this.aggregate([
      { $match: match },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          used: { $sum: { $cond: ['$isUsed', 1, 0] } },
          expired: { $sum: { $cond: [{ $lt: ['$expiresAt', new Date()] }, 1, 0] } },
          active: { $sum: { $cond: [{ $and: [{ $eq: ['$isUsed', false] }, { $gt: ['$expiresAt', new Date()] }] }, 1, 0] } }
        }
      }
    ]);

    return stats[0] || { total: 0, used: 0, expired: 0, active: 0 };
  } catch (error) {
    throw new Error(`Failed to get OTP stats: ${error.message}`);
  }
};

// Method to check if OTP is expired
otpSchema.methods.isExpired = function() {
  return this.expiresAt < new Date();
};

// Method to check if OTP has exceeded attempts
otpSchema.methods.hasExceededAttempts = function() {
  return this.attempts >= 3;
};

// Method to increment attempts
otpSchema.methods.incrementAttempts = async function() {
  this.attempts += 1;
  return await this.save();
};

export default mongoose.model('OTP', otpSchema);
