import mongoose from 'mongoose';
import { randomUUID } from 'crypto';

const sandspaceDriveSchema = new mongoose.Schema({
  // Unique Identifier
  registrationId: {
    type: String,
    unique: true,
    default: () => randomUUID(),
    required: true
  },
  
  // Personal Information
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true,
    match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email address']
  },
  firstName: {
    type: String,
    required: true,
    trim: true
  },
  lastName: {
    type: String,
    required: true,
    trim: true
  },
  fatherHusbandName: {
    type: String,
    required: true,
    trim: true
  },
  dateOfBirth: {
    type: Date,
    required: true
  },
  gender: {
    type: String,
    required: true,
    enum: ['Male', 'Female', 'Other'],
    trim: true
  },
  maritalStatus: {
    type: String,
    required: true,
    enum: ['Single', 'Married', 'Divorced', 'Widowed'],
    trim: true
  },
  
  // Contact Information
  mobile: {
    type: String,
    required: true,
    trim: true,
    match: [/^[0-9]{10}$/, 'Please enter a valid 10-digit mobile number']
  },
  alternateMobile: {
    type: String,
    required: true,
    trim: true,
    match: [/^[0-9]{10}$/, 'Please enter a valid 10-digit mobile number']
  },
  
  // Present Address
  presentAddress: {
    doorNoStreet: {
      type: String,
      required: true,
      trim: true
    },
    cityVillage: {
      type: String,
      required: true,
      trim: true
    },
    district: {
      type: String,
      required: true,
      trim: true
    },
    state: {
      type: String,
      required: true,
      trim: true
    },
    pinCode: {
      type: String,
      required: true,
      trim: true,
      match: [/^[0-9]{6}$/, 'Please enter a valid 6-digit pin code']
    }
  },
  
  // Permanent Address
  permanentAddress: {
    doorNoStreet: {
      type: String,
      required: true,
      trim: true
    },
    cityVillage: {
      type: String,
      required: true,
      trim: true
    },
    district: {
      type: String,
      required: true,
      trim: true
    },
    state: {
      type: String,
      required: true,
      trim: true
    },
    pinCode: {
      type: String,
      required: true,
      trim: true,
      match: [/^[0-9]{6}$/, 'Please enter a valid 6-digit pin code']
    }
  },
  
  sameAddress: {
    type: Boolean,
    default: false
  },
  
  // Additional Information
  fatherOccupation: {
    type: String,
    required: true,
    trim: true
  },
  
  // Education Section
  education: [{
    institution: {
      type: String,
      required: true,
      trim: true
    },
    degree: {
      type: String,
      required: true,
      trim: true
    },
    fieldOfStudy: {
      type: String,
      trim: true
    },
    startYear: {
      type: Number,
      required: true
    },
    endYear: {
      type: Number
    },
    isCurrent: {
      type: Boolean,
      default: false
    },
    percentage: {
      type: Number
    },
    description: {
      type: String,
      trim: true
    }
  }],
  
  // Skills Section
  skills: [{
    name: {
      type: String,
      required: true,
      trim: true
    },
    level: {
      type: String,
      enum: ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
      default: 'Intermediate'
    }
  }],
  
  // Registration Metadata
  registeredAt: {
    type: Date,
    default: Date.now
  },
  
  // Status
  status: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending'
  },
  notes: {
    type: String,
    trim: true
  }
}, {
  timestamps: true
});

// Index for faster lookups
sandspaceDriveSchema.index({ email: 1 });
sandspaceDriveSchema.index({ mobile: 1 });
sandspaceDriveSchema.index({ registrationId: 1 });
sandspaceDriveSchema.index({ registeredAt: -1 });

// Pre-save middleware to ensure unique email
sandspaceDriveSchema.pre('save', async function(next) {
  if (this.isNew || this.isModified('email')) {
    try {
      // Use this.constructor instead of mongoose.model to avoid potential issues
      const existing = await this.constructor.findOne({ 
        email: this.email,
        _id: { $ne: this._id }
      });
      if (existing) {
        const error = new Error('Email already registered');
        error.statusCode = 400;
        return next(error);
      }
    } catch (error) {
      return next(error);
    }
  }
  next();
});

const SandspaceDrive = mongoose.model('SandspaceDrive', sandspaceDriveSchema);

export default SandspaceDrive;

