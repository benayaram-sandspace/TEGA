import mongoose from 'mongoose';

const adminSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  gender: {
    type: String,
    enum: ['Male', 'Female', 'Other']
  },
  acceptTerms: {
    type: Boolean,
    required: true,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  role: {
    type: String,
    default: 'admin'
  }
}, {
  timestamps: true
});

export default mongoose.model('Admin', adminSchema);
