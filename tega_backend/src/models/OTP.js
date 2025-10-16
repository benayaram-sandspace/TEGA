const mongoose = require('mongoose');

const otpSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    index: true
  },
  otp: {
    type: String,
    required: true,
    trim: true // Ensure whitespace is trimmed when saving
  },
  purpose: {
    type: String,
    enum: ['registration', 'password-reset'],
    required: true
  },
  expires: {
    type: Date,
    required: true
  },
  attempts: {
    type: Number,
    default: 0
  },
  userData: {
    type: mongoose.Schema.Types.Mixed,
    default: null
  }
}, { timestamps: true });

// Automatically expire documents after they're no longer valid
otpSchema.index({ expires: 1 }, { expireAfterSeconds: 0 });

const OTP = mongoose.model('OTP', otpSchema);

module.exports = OTP;