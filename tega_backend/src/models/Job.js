import mongoose from 'mongoose';

const jobSchema = new mongoose.Schema({
  title: { type: String, required: true, trim: true },
  description: { type: String, required: true },
  company: { type: String, required: true, trim: true },
  location: { type: String, trim: true },
  salary: { type: Number },
  // Extended fields used by controller
  deadline: { type: Date },
  requirements: { type: [String], default: [] },
  benefits: { type: [String], default: [] },
  jobType: { type: String, enum: ['full-time', 'part-time', 'contract', 'internship'], default: 'full-time' },
  experience: { type: String },
  applicationLink: { type: String },
  postingType: { type: String, enum: ['job', 'internship'], default: 'job' },
  postedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin' },
  // Status flags
  status: { type: String, enum: ['open', 'closed', 'paused', 'active', 'inactive', 'expired'], default: 'open' },
  isActive: { type: Boolean, default: true },
}, { timestamps: true });

// Indexes
jobSchema.index({ isActive: 1, status: 1, createdAt: -1 });
// Text index for search across title/description/company/location
jobSchema.index({ title: 'text', description: 'text', company: 'text', location: 'text' });

export default mongoose.model('Job', jobSchema);


