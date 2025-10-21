import mongoose from 'mongoose';

const announcementSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200
  },
  message: {
    type: String,
    required: true,
    trim: true,
    maxlength: 2000
  },
  priority: {
    type: String,
    enum: ['low', 'normal', 'high', 'urgent'],
    default: 'normal'
  },
  audience: {
    type: String,
    enum: ['all', 'specific_course', 'specific_year'],
    default: 'all'
  },
  targetAudience: {
    course: String,
    yearOfStudy: Number
  },
  university: {
    type: String,
    required: true,
    trim: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Principal',
    required: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  expiresAt: {
    type: Date,
    default: null
  },
  attachments: [{
    filename: String,
    url: String,
    fileType: String,
    fileSize: Number
  }]
}, {
  timestamps: true
});

// Index for efficient queries
announcementSchema.index({ university: 1, isActive: 1, createdAt: -1 });
announcementSchema.index({ createdBy: 1, createdAt: -1 });

const Announcement = mongoose.model('Announcement', announcementSchema);

export default Announcement;
