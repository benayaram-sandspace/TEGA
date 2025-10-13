import mongoose from 'mongoose';

const sectionSchema = new mongoose.Schema({
  courseId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: true
  },
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  order: {
    type: Number,
    required: true,
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true
  }
}, {
  timestamps: true
});

// Index for efficient queries
sectionSchema.index({ courseId: 1, order: 1 });
sectionSchema.index({ courseId: 1, isActive: 1 });

// Virtual to get lectures count
sectionSchema.virtual('lecturesCount', {
  ref: 'Lecture',
  localField: '_id',
  foreignField: 'sectionId',
  count: true
});

// Method to get lectures for this section
sectionSchema.methods.getLectures = function() {
  return mongoose.model('Lecture').find({ sectionId: this._id }).sort({ order: 1 });
};

// Static method to get sections by course
sectionSchema.statics.getSectionsByCourse = function(courseId) {
  return this.find({ courseId: courseId, isActive: true }).sort({ order: 1 });
};

export default mongoose.model('Section', sectionSchema);
