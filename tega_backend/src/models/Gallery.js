import mongoose from 'mongoose';

const gallerySchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  alt: {
    type: String,
    required: true,
    trim: true
  },
  category: {
    type: String,
    required: true,
    default: 'Events',
    trim: true
  },
  customCategory: {
    type: String,
    trim: true,
    default: ''
  },
  imageUrl: {
    type: String,
    required: true
  },
  r2Key: {
    type: String,
    required: false // Optional if using external URLs
  },
  date: {
    type: Date,
    required: true,
    default: Date.now
  },
  height: {
    type: String,
    enum: ['tall', 'medium', 'short'],
    default: 'medium'
  },
  featured: {
    type: Boolean,
    default: false
  },
  order: {
    type: Number,
    default: 0
  },
  isActive: {
    type: Boolean,
    default: true
  },
  uploadedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true
  }
}, {
  timestamps: true
});

// Index for faster queries
gallerySchema.index({ category: 1, isActive: 1 });
gallerySchema.index({ featured: 1, isActive: 1 });
gallerySchema.index({ order: 1 });

const Gallery = mongoose.model('Gallery', gallerySchema);

export default Gallery;