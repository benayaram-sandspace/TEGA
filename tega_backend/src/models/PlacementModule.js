import mongoose from 'mongoose';

const placementModuleSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  moduleType: {
    type: String,
    enum: ['assessment', 'resume', 'technical', 'interview', 'placement', 'progress'],
    required: true
  },
  icon: String,
  color: String,
  order: {
    type: Number,
    default: 0
  },
  features: [String],
  resources: [{
    title: String,
    type: { type: String, enum: ['video', 'article', 'pdf', 'link'] },
    url: String,
    description: String,
    duration: Number // in minutes
  }],
  questions: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'PlacementQuestion'
  }],
  isActive: {
    type: Boolean,
    default: true
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin'
  }
}, {
  timestamps: true
});

placementModuleSchema.index({ moduleType: 1, isActive: 1 });
placementModuleSchema.index({ order: 1 });

const PlacementModule = mongoose.model('PlacementModule', placementModuleSchema);

export default PlacementModule;

