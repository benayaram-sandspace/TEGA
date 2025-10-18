import mongoose from 'mongoose';

// Format: TEGA + 10 random digits
// Example: TEGA1909250006, TEGA8473920156, etc.
async function generateStudentId() {
  try {
    let studentId;
    let attempts = 0;
    const maxAttempts = 10;
    
    do {
      // Generate 10 random digits
      const randomDigits = Math.floor(Math.random() * 10000000000).toString().padStart(10, '0');
      studentId = `TEGA${randomDigits}`;
      
      // Check if this ID already exists
      const existing = await mongoose.model('Student').findOne({ studentId });
      if (!existing) {
        break; // Found a unique ID
      }
      
      attempts++;
      if (attempts >= maxAttempts) {
        // If we can't find a unique ID after max attempts, use timestamp fallback
        const timestamp = Date.now().toString().slice(-10);
        studentId = `TEGA${timestamp}`;
        break;
      }
    } while (attempts < maxAttempts);
    
    return studentId;
  } catch (error) {
    // Fallback with timestamp if sequence generation fails
    const timestamp = Date.now().toString().slice(-10);
    return `TEGA${timestamp}`;
  }
}

const studentSchema = new mongoose.Schema({
  // Excel import fields (in exact order as specified)
  username: { type: String, required: true, unique: true, trim: true },
  // studentId is optional and will be auto-generated if not provided
  studentId: { 
    type: String, 
    unique: true, 
    sparse: true, 
    trim: true, 
    default: undefined // Using undefined instead of null to prevent validation
  },
  studentName: { type: String, trim: true },
  firstName: { type: String, trim: true },
  lastName: { type: String, trim: true },
  email: { type: String, required: true, unique: true, trim: true, lowercase: true },
  phone: { type: String, trim: true },
  password: { type: String, required: true },
  institute: { type: String, trim: true },
  course: { type: String, trim: true },
  major: { type: String, trim: true },
  yearOfStudy: { type: Number },
  dob: { type: Date },
  gender: { type: String, enum: ['Male', 'Female', 'Other'] },
  address: { type: String, trim: true },
  landmark: { type: String, trim: true },
  zipcode: { type: String, trim: true },
  city: { type: String, trim: true },
  district: { type: String, trim: true },
  
  // Additional fields for backward compatibility
  contactNumber: { type: String, trim: true }, // Alternative phone field
  acceptTerms: { type: Boolean, required: true },
  
  // Profile photo
  profilePhoto: { type: String },
  
  // Additional profile fields
  title: { type: String, trim: true },
  summary: { type: String, trim: true },
  linkedin: { type: String, trim: true },
  website: { type: String, trim: true },
  github: { type: String, trim: true },
  
  // Dynamic arrays for profile sections
  projects: [{
    title: { type: String, trim: true },
    description: { type: String, trim: true },
    url: { type: String, trim: true },
    technologies: [String],
    startDate: { type: Date },
    endDate: { type: Date }
  }],
  
  achievements: [{
    title: { type: String, trim: true },
    description: { type: String, trim: true },
    date: { type: Date },
    issuer: { type: String, trim: true }
  }],
  
  education: [{
    institution: { type: String, trim: true },
    degree: { type: String, trim: true },
    fieldOfStudy: { type: String, trim: true },
    startYear: { type: Number },
    endYear: { type: Number },
    gpa: { type: Number },
    description: { type: String, trim: true }
  }],
  
  experience: [{
    company: { type: String, trim: true },
    role: { type: String, trim: true },
    description: { type: String, trim: true },
    startDate: { type: Date },
    endDate: { type: Date },
    current: { type: Boolean, default: false },
    location: { type: String, trim: true }
  }],
  
  skills: [{
    name: { type: String, trim: true },
    level: { type: String, enum: ['Beginner', 'Intermediate', 'Advanced', 'Expert'], default: 'Intermediate' }
  }],
  
  certifications: [{
    name: { type: String, trim: true },
    issuer: { type: String, trim: true },
    date: { type: Date },
    url: { type: String, trim: true }
  }],
  
  languages: [{
    name: { type: String, trim: true },
    proficiency: { type: String, enum: ['Basic', 'Conversational', 'Fluent', 'Native'], default: 'Conversational' }
  }],
  
  hobbies: [{
    name: { type: String, trim: true },
    description: { type: String, trim: true }
  }],
  
  volunteerExperience: [{
    organization: { type: String, trim: true },
    role: { type: String, trim: true },
    description: { type: String, trim: true },
    startDate: { type: Date },
    endDate: { type: Date },
    current: { type: Boolean, default: false }
  }],
  
  extracurricularActivities: [{
    activity: { type: String, trim: true },
    role: { type: String, trim: true },
    description: { type: String, trim: true },
    startDate: { type: Date },
    endDate: { type: Date }
  }],
  
  role: {
    type: String,
    enum: ['student', 'principal', 'admin'],
    default: 'student',
    required: true
  },
  
  isAutoGeneratedId: {
    type: Boolean,
    default: false
  },

  // Account status and approval fields
  accountStatus: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'suspended'],
    default: 'approved' // Default to approved for existing users
  },
  isActive: {
    type: Boolean,
    default: true
  },
  approvedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    default: null
  },
  approvedAt: {
    type: Date,
    default: null
  },
  rejectionReason: {
    type: String,
    default: null
  }
}, { timestamps: true });

// Pre-save hook to generate student ID if not provided
// Using 'validate' hook to ensure it runs before validation
studentSchema.pre('validate', async function(next) {
  // Only generate ID if it's a new student and no ID was provided
  if (this.isNew && !this.studentId) {
    try {
      // Generate a new student ID
      const newStudentId = await generateStudentId();
      
      // Check if the generated ID already exists (just to be safe)
      const existing = await this.constructor.findOne({ studentId: newStudentId });
      if (existing) {
        // If it exists, try one more time with a different ID
        this.studentId = await generateStudentId();
      } else {
        this.studentId = newStudentId;
      }
      
      this.isAutoGeneratedId = true;
    } catch (error) {
      // If there's an error generating the ID, use a fallback with timestamp
      const timestamp = Date.now().toString().slice(-10);
      this.studentId = `TEGA${timestamp}`;
      this.isAutoGeneratedId = true;
    }
  }
  next();
});

const Student = mongoose.model('Student', studentSchema);

export default Student;
