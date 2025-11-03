import mongoose from 'mongoose';

const codeSubmissionSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  language: {
    type: String,
    required: true,
    enum: [
      'javascript', 'python', 'java', 'cpp', 'c', 'csharp', 'php', 'rust', 
      'ruby', 'go', 'typescript', 'r', 'sql', 'bash', 'powershell', 'swift', 
      'kotlin', 'scala', 'perl', 'clojure', 'haskell', 'ocaml', 'fsharp', 
      'dart', 'elixir', 'julia', 'nim', 'crystal', 'zig', 'lua', 'pascal', 
      'fortran', 'cobol', 'assembly', 'v', 'brainfuck', 'whitespace', 'tcl', 
      'prolog', 'smalltalk', 'lisp', 'scheme', 'forth', 'ada', 'd', 'vala',
      'html', 'css', 'json', 'xml', 'yaml', 'markdown', 'dockerfile', 'vhdl', 'verilog'
    ]
  },
  language_id: {
    type: Number,
    required: true
  },
  source_code: {
    type: String,
    required: true
  },
  stdin: {
    type: String,
    default: ''
  },
  stdout: {
    type: String,
    default: ''
  },
  stderr: {
    type: String,
    default: ''
  },
  status: {
    type: String,
    enum: [
      'In Queue', 'Processing', 'Accepted', 'Wrong Answer', 'Time Limit Exceeded', 
      'Compilation Error', 'Runtime Error', 'Runtime Error (SIGSEGV)', 'Runtime Error (NZEC)', 
      'Runtime Error (SIGXFSZ)', 'Runtime Error (Other)', 'Internal Error', 
      'Exec Format Error', 'Output Limit Exceeded', 'Unknown'
    ],
    default: 'In Queue'
  },
  execution_time: {
    type: Number,
    default: 0
  },
  memory_usage: {
    type: Number,
    default: 0
  },
  judge0_token: {
    type: String,
    default: null
  },
  created_at: {
    type: Date,
    default: Date.now
  },
  updated_at: {
    type: Date,
    default: Date.now
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes for better performance
codeSubmissionSchema.index({ user: 1, created_at: -1 });
codeSubmissionSchema.index({ language: 1 });
codeSubmissionSchema.index({ status: 1 });
codeSubmissionSchema.index({ created_at: -1 });

// Virtual for formatted execution time
codeSubmissionSchema.virtual('formatted_time').get(function() {
  if (this.execution_time < 1000) {
    return `${this.execution_time}ms`;
  } else {
    return `${(this.execution_time / 1000).toFixed(2)}s`;
  }
});

// Virtual for formatted memory usage
codeSubmissionSchema.virtual('formatted_memory').get(function() {
  if (this.memory_usage < 1024) {
    return `${this.memory_usage}KB`;
  } else {
    return `${(this.memory_usage / 1024).toFixed(2)}MB`;
  }
});

// Method to get submission statistics
codeSubmissionSchema.statics.getUserStats = async function(userId) {
  const stats = await this.aggregate([
    { $match: { user: new mongoose.Types.ObjectId(userId) } },
    {
      $group: {
        _id: null,
        totalSubmissions: { $sum: 1 },
        languages: { $addToSet: '$language' },
        avgExecutionTime: { $avg: '$execution_time' },
        avgMemoryUsage: { $avg: '$memory_usage' },
        successRate: {
          $avg: {
            $cond: [{ $eq: ['$status', 'Accepted'] }, 1, 0]
          }
        }
      }
    }
  ]);

  return stats[0] || {
    totalSubmissions: 0,
    languages: [],
    avgExecutionTime: 0,
    avgMemoryUsage: 0,
    successRate: 0
  };
};

// Pre-save middleware
codeSubmissionSchema.pre('save', function(next) {
  const now = new Date();
  this.updated_at = now;
  this.updatedAt = now;
  if (!this.createdAt) {
    this.createdAt = this.created_at || now;
  }
  next();
});

const CodeSubmission = mongoose.model('CodeSubmission', codeSubmissionSchema);

export default CodeSubmission;
