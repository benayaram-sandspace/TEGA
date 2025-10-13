import mongoose from 'mongoose';

const mockInterviewSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  interviewType: {
    type: String,
    enum: ['technical', 'behavioral', 'hr', 'system-design'],
    required: true
  },
  company: String,
  jobRole: String,
  questions: [{
    questionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'PlacementQuestion'
    },
    answer: String,
    feedback: String,
    rating: {
      type: Number,
      min: 1,
      max: 5
    }
  }],
  overallRating: {
    type: Number,
    min: 1,
    max: 5
  },
  feedback: String,
  strengths: [String],
  improvements: [String],
  duration: Number, // in minutes
  completedAt: Date,
  score: Number
}, {
  timestamps: true
});

mockInterviewSchema.index({ studentId: 1, createdAt: -1 });

const MockInterview = mongoose.model('MockInterview', mockInterviewSchema);

export default MockInterview;

