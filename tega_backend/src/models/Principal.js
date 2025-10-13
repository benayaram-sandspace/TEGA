import mongoose from 'mongoose';

const principalSchema = new mongoose.Schema({
  principalName: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  gender: {
    type: String,
    required: true,
    enum: ['male', 'female', 'other', 'Male', 'Female', 'Other']
  },
  university: {
    type: String,
    required: true,
    trim: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  resetPasswordToken: {
    type: String
  },
  resetPasswordExpires: {
    type: Date
  },
  role: {
    type: String,
    default: 'principal'
  }
}, {
  timestamps: true
});

export default mongoose.model('Principal', principalSchema);
