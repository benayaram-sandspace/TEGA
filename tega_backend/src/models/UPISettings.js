import mongoose from 'mongoose';

const upiSettingsSchema = new mongoose.Schema({
  upiId: {
    type: String,
    required: true,
    trim: true,
    unique: true
  },
  merchantName: {
    type: String,
    required: true,
    trim: true
  },
  isEnabled: {
    type: Boolean,
    default: true
  },
  description: {
    type: String,
    trim: true
  },
  merchantCode: {
    type: String,
    trim: true
  },
  supportedApps: [{
    type: String,
    enum: ['Google Pay', 'PhonePe', 'Paytm', 'BHIM', 'Amazon Pay', 'Other']
  }],
  qrCode: {
    type: String
  },
  webhookUrl: {
    type: String
  },
  apiKey: {
    type: String
  },
  secretKey: {
    type: String
  },
  environment: {
    type: String,
    enum: ['development', 'staging', 'production'],
    default: 'development'
  },
  notificationEmail: {
    type: String,
    trim: true
  },
  autoConfirm: {
    type: Boolean,
    default: false
  },
  minAmount: {
    type: Number,
    default: 1
  },
  maxAmount: {
    type: Number,
    default: 100000
  },
  currency: {
    type: String,
    default: 'INR'
  },
  timezone: {
    type: String,
    default: 'Asia/Kolkata'
  }
}, {
  timestamps: true
});

// Index for better query performance
upiSettingsSchema.index({ isEnabled: 1 });
upiSettingsSchema.index({ environment: 1 });

// Virtual for display name
upiSettingsSchema.virtual('displayName').get(function() {
  return `${this.merchantName} (${this.upiId})`;
});

// Method to check if UPI is configured
upiSettingsSchema.methods.isConfigured = function() {
  return this.isEnabled && this.upiId && this.merchantName;
};

// Method to get QR code data
upiSettingsSchema.methods.getQRData = function(amount, description = '') {
  if (!this.isConfigured()) {
    throw new Error('UPI is not properly configured');
  }
  
  const qrData = {
    upi: this.upiId,
    name: this.merchantName,
    amount: amount,
    note: description || this.description || 'TEGA Course Payment'
  };
  
  return qrData;
};

// Method to validate amount
upiSettingsSchema.methods.validateAmount = function(amount) {
  if (amount < this.minAmount || amount > this.maxAmount) {
    throw new Error(`Amount must be between ₹${this.minAmount} and ₹${this.maxAmount}`);
  }
  return true;
};

// Static method to get active UPI settings
upiSettingsSchema.statics.getActive = function() {
  return this.findOne({ isEnabled: true });
};

// Static method to get settings by environment
upiSettingsSchema.statics.getByEnvironment = function(env) {
  return this.findOne({ environment: env, isEnabled: true });
};

// Pre-save middleware to ensure only one active UPI setting
upiSettingsSchema.pre('save', async function(next) {
  if (this.isEnabled) {
    // Disable other UPI settings
    await this.constructor.updateMany(
      { _id: { $ne: this._id } },
      { $set: { isEnabled: false } }
    );
  }
  next();
});

export default mongoose.model('UPISettings', upiSettingsSchema);
