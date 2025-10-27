import mongoose from 'mongoose';

const codeSnippetSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Student',
    required: true
  },
  name: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
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
  code: {
    type: mongoose.Schema.Types.Mixed, // Can be string or object for multi-panel
    required: true
  },
  editorMode: {
    type: String,
    enum: ['single', 'multi'],
    default: 'single'
  },
  description: {
    type: String,
    maxlength: 500,
    default: ''
  },
  tags: [{
    type: String,
    trim: true,
    maxlength: 20
  }],
  isPublic: {
    type: Boolean,
    default: false
  },
  isFavorite: {
    type: Boolean,
    default: false
  },
  usageCount: {
    type: Number,
    default: 0
  },
  lastUsedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Indexes for better performance
codeSnippetSchema.index({ user: 1, createdAt: -1 });
codeSnippetSchema.index({ user: 1, isFavorite: -1 });
codeSnippetSchema.index({ user: 1, language: 1 });
codeSnippetSchema.index({ user: 1, tags: 1 });
codeSnippetSchema.index({ isPublic: 1, language: 1 });

// Virtual for formatted creation date
codeSnippetSchema.virtual('formattedDate').get(function() {
  return this.createdAt.toLocaleDateString();
});

// Method to increment usage count
codeSnippetSchema.methods.incrementUsage = function() {
  this.usageCount += 1;
  this.lastUsedAt = new Date();
  return this.save();
};

// Static method to get user's snippets with pagination
codeSnippetSchema.statics.getUserSnippets = async function(userId, options = {}) {
  const {
    page = 1,
    limit = 20,
    language = null,
    isFavorite = null,
    search = null
  } = options;

  const query = { user: userId };
  
  if (language) query.language = language;
  if (isFavorite !== null) query.isFavorite = isFavorite;
  if (search) {
    query.$or = [
      { name: { $regex: search, $options: 'i' } },
      { description: { $regex: search, $options: 'i' } },
      { tags: { $in: [new RegExp(search, 'i')] } }
    ];
  }

  const skip = (parseInt(page) - 1) * parseInt(limit);

  const snippets = await this.find(query)
    .sort({ isFavorite: -1, lastUsedAt: -1, createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

  const total = await this.countDocuments(query);

  return {
    snippets,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      pages: Math.ceil(total / parseInt(limit))
    }
  };
};

// Static method to get public snippets
codeSnippetSchema.statics.getPublicSnippets = async function(options = {}) {
  const {
    page = 1,
    limit = 20,
    language = null,
    search = null
  } = options;

  const query = { isPublic: true };
  
  if (language) query.language = language;
  if (search) {
    query.$or = [
      { name: { $regex: search, $options: 'i' } },
      { description: { $regex: search, $options: 'i' } },
      { tags: { $in: [new RegExp(search, 'i')] } }
    ];
  }

  const skip = (parseInt(page) - 1) * parseInt(limit);

  const snippets = await this.find(query)
    .populate('user', 'name email')
    .sort({ usageCount: -1, createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit));

  const total = await this.countDocuments(query);

  return {
    snippets,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      pages: Math.ceil(total / parseInt(limit))
    }
  };
};

const CodeSnippet = mongoose.model('CodeSnippet', codeSnippetSchema);

export default CodeSnippet;
