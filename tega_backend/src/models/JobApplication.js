import mongoose from 'mongoose';

const jobApplicationSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  jobId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Job',
    required: true
  },
  clicked: {
    type: Boolean,
    default: true
  },
  confirmedApplied: {
    type: Boolean,
    default: false
  },
  status: {
    type: String,
    enum: ['Not Applied', 'Clicked Apply (Pending Confirmation)', 'Applied'],
    default: 'Clicked Apply (Pending Confirmation)'
  },
  clickedAt: {
    type: Date,
    default: Date.now
  },
  confirmedAt: {
    type: Date
  },
  proofFile: {
    type: String,
    default: null
  }
}, {
  timestamps: true
});

jobApplicationSchema.index({ studentId: 1, jobId: 1 }, { unique: true });

export default mongoose.model('JobApplication', jobApplicationSchema);
