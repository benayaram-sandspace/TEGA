import mongoose from 'mongoose';

const mockInterviewSchema = new mongoose.Schema({
  studentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },

  domain: {
    type: String,
    enum: ['Frontend', 'Backend', 'Full-Stack', 'Mobile', 'Data Science', 'DevOps'],
    required: true
  },
  difficulty: {
    type: String,
    enum: ['easy', 'medium', 'hard'],
    default: 'medium'
  },
  duration: { type: Number, default: 45 },
  status: {
    type: String,
    enum: ['scheduled', 'in-progress', 'completed', 'cancelled'],
    default: 'scheduled'
  },
  
  // Interview Sections
  sections: {
    selfIntroduction: {
      question: String,
      response: String,
      score: { type: Number, min: 0, max: 100 },
      feedback: String,
      duration: { type: Number, default: 300 }
    },
    projectDiscussion: {
      questions: [String],
      responses: [String],
      score: { type: Number, min: 0, max: 100 },
      feedback: String,
      duration: { type: Number, default: 420 }
    },
    domainQuestions: {
      questions: [{
        questionId: mongoose.Schema.Types.ObjectId,
        question: String,
        difficulty: String,
        response: String,
        score: { type: Number, min: 0, max: 100 },
        feedback: String
      }],
      totalScore: { type: Number, min: 0, max: 100 }
    },
    codingChallenge: {
      problems: [{
        problemId: mongoose.Schema.Types.ObjectId,
        language: String,
        code: String,
        testCases: [{
          input: String,
          expected: String,
          actual: String,
          passed: Boolean
        }],
        score: { type: Number, min: 0, max: 100 },
        executionTime: Number,
        memory: Number
      }],
      totalScore: { type: Number, min: 0, max: 100 }
    }
  },
  
  // Overall Scores
  scores: {
    communication: { type: Number, min: 0, max: 100 },
    technicalKnowledge: { type: Number, min: 0, max: 100 },
    problemSolving: { type: Number, min: 0, max: 100 },
    codeQuality: { type: Number, min: 0, max: 100 },
    timeManagement: { type: Number, min: 0, max: 100 },
    engagement: { type: Number, min: 0, max: 100 },
    overall: { type: Number, min: 0, max: 100 }
  },
  
  // Feedback & Insights
  feedback: String,
  improvements: [String],
  strengths: [String],
  
  // Timestamps
  scheduledAt: Date,
  startedAt: Date,
  completedAt: Date,
  
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

// Index for student interview history
mockInterviewSchema.index({ studentId: 1, createdAt: -1 });

// Index for leaderboard queries
mockInterviewSchema.index({ domain: 1, 'scores.overall': -1 });

// Index for completed interviews
mockInterviewSchema.index({ status: 1, completedAt: -1 });

export default mongoose.model('MockInterview', mockInterviewSchema);
