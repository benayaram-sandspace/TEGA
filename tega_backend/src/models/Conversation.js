import mongoose from 'mongoose';

const conversationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true,
    index: true
  },
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 200
  },
  messages: [{
    role: {
      type: String,
      enum: ['user', 'assistant', 'system'],
      required: true
    },
    content: {
      type: String,
      required: true
    },
    timestamp: {
      type: Date,
      default: Date.now
    }
  }],
  model: {
    type: String,
    default: 'phi',
    trim: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastMessageAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  collection: 'conversations'
});

// Index for faster queries
conversationSchema.index({ userId: 1, lastMessageAt: -1 });
conversationSchema.index({ userId: 1, isActive: 1 });

// Update lastMessageAt before saving
conversationSchema.pre('save', function(next) {
  if (this.messages && this.messages.length > 0) {
    this.lastMessageAt = this.messages[this.messages.length - 1].timestamp || Date.now();
  }
  next();
});

// Virtual for message count
conversationSchema.virtual('messageCount').get(function() {
  return this.messages ? this.messages.length : 0;
});

// Method to add a message
conversationSchema.methods.addMessage = function(role, content) {
  this.messages.push({
    role,
    content,
    timestamp: new Date()
  });
  this.lastMessageAt = new Date();
  return this.save();
};

// Static method to get user conversations
conversationSchema.statics.getUserConversations = function(userId, limit = 20) {
  return this.find({ userId, isActive: true })
    .sort({ lastMessageAt: -1 })
    .limit(limit)
    .select('title lastMessageAt messageCount');
};

// Static method to delete old conversations
conversationSchema.statics.deleteOldConversations = function(daysOld = 90) {
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - daysOld);
  return this.deleteMany({ lastMessageAt: { $lt: cutoffDate } });
};

const Conversation = mongoose.model('Conversation', conversationSchema);

export default Conversation;
