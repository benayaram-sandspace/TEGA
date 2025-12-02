import mongoose from 'mongoose';

const ResumeSchema = new mongoose.Schema({
  student: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: false,
    unique: true
  },
  personalInfo: {
    fullName: { type: String, default: '' },
    email: { type: String, default: '' },
    phone: { type: String, default: '' },
    location: { type: String, default: '' },
    linkedin: { type: String, default: '' },
    summary: { type: String, default: '' },
    title: { type: String, default: '' }
  },
  experience: [
    {
      _id: false,
      id: { type: Number, default: 0 },
      company: { type: String, default: '' },
      position: { type: String, default: '' },
      startDate: { type: String, default: '' },
      endDate: { type: String, default: '' },
      current: { type: Boolean, default: false },
      description: { type: String, default: '' }
    }
  ],
  education: [
    {
      _id: false,
      id: { type: Number, default: 0 },
      institution: { type: String, default: '' },
      degree: { type: String, default: '' },
      field: { type: String, default: '' },
      startDate: { type: String, default: '' },
      endDate: { type: String, default: '' },
      current: { type: Boolean, default: false },
      gpa: { type: String, default: '' }
    }
  ],
  projects: [
    {
      _id: false,
      id: { type: Number, default: 0 },
      name: { type: String, default: '' },
      description: { type: String, default: '' },
      technologies: { type: String, default: '' },
      link: { type: String, default: '' }
    }
  ],
  skills: [
    {
      _id: false,
      id: { type: Number, default: 0 },
      name: { type: String, default: '' }
    }
  ],
  certifications: [
    {
      _id: false,
      id: { type: Number, default: 0 },
      name: { type: String, default: '' },
      issuer: { type: String, default: '' },
      date: { type: String, default: '' },
      link: { type: String, default: '' }
    }
  ],
  achievements: [
    {
      _id: false,
      id: { type: Number, default: 0 },
      title: { type: String, default: '' },
      description: { type: String, default: '' }
    }
  ],
  extracurricularActivities: [
    {
      _id: false,
      id: { type: Number, default: 0 },
      organization: { type: String, default: '' },
      role: { type: String, default: '' },
      description: { type: String, default: '' }
    }
  ],
  languages: [
    {
      _id: false,
      id: { type: Number, default: 0 },
      name: { type: String, default: '' },
      proficiency: { type: String, default: '' }
    }
  ],
  volunteerExperience: [
    {
      _id: false,
      id: { type: Number, default: 0 },
      organization: { type: String, default: '' },
      role: { type: String, default: '' },
      description: { type: String, default: '' }
    }
  ],
  hobbies: [
    {
      _id: false,
      id: { type: Number, default: 0 },
      name: { type: String, default: '' }
    }
  ],
  templateId: { type: String, default: 'default' },
  sections: [{ type: String }],
  // Additional fields that might be sent from frontend
  template: { type: String, default: 'classic' },
  selectedFont: { type: String, default: 'Inter' },
  // Uploaded resume file information (supports both Cloudinary and local storage)
  uploadedResume: {
    cloudinaryId: { type: String },
    url: { type: String },
    r2Key: { type: String },
    filename: { type: String },
    path: { type: String },
    originalName: { type: String },
    size: { type: Number },
    mimetype: { type: String },
    uploadedAt: { type: Date }
  }
}, { timestamps: true });

const Resume = mongoose.model('Resume', ResumeSchema);

export default Resume;
