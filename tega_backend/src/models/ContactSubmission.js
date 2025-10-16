import mongoose from 'mongoose';

const contactSubmissionSchema = new mongoose.Schema({
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
  email: {
    type: String,
    required: true,
    trim: true,
    lowercase: true
  },
  phone: {
    type: String,
    required: true,
    trim: true
  },
  subject: {
    type: String,
    required: true,
    enum: ['general', 'course', 'enrollment', 'support', 'feedback', 'partnership'],
    default: 'general'
  },
  message: {
    type: String,
    required: true,
    trim: true
  },
  source: {
    type: String,
    required: true,
    enum: ['contact_page', 'home_page'],
    default: 'contact_page'
  },
  status: {
    type: String,
    enum: ['new', 'in_progress', 'resolved', 'closed'],
    default: 'new'
  },
  adminNotes: {
    type: String,
    default: ''
  },
  submittedAt: {
    type: Date,
    default: Date.now
  },
  lastUpdated: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Index for better query performance
contactSubmissionSchema.index({ email: 1, submittedAt: -1 });
contactSubmissionSchema.index({ status: 1, submittedAt: -1 });
contactSubmissionSchema.index({ source: 1, submittedAt: -1 });

export default mongoose.model('ContactSubmission', contactSubmissionSchema);
