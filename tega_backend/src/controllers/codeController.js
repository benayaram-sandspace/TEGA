import CodeSubmission from '../models/CodeSubmission.js';
import { cacheHelpers, cacheKeys } from '../config/redis.js';

// Judge0 CE configuration
const JUDGE0_BASE_URL = process.env.JUDGE0_BASE_URL || 'http://localhost:2358';
const JUDGE0_API_KEY = process.env.JUDGE0_API_KEY || null; // Not needed for CE

// console.log('🔧 Judge0 Configuration:', { JUDGE0_BASE_URL, JUDGE0_API_KEY });

/**
 * Execute code using Judge0 CE
 */
export const runCode = async (req, res) => {
  try {
    const { language_id, source_code, stdin = '' } = req.body;
    const userId = req.student?._id || req.studentId || req.user?.id;

    // Validate required fields
    if (!language_id || !source_code) {
      return res.status(400).json({
        success: false,
        message: 'Language ID and source code are required'
      });
    }

    // Validate language ID (basic check)
    if (typeof language_id !== 'number' || language_id < 1) {
      return res.status(400).json({
        success: false,
        message: 'Invalid language ID'
      });
    }

    // Check rate limiting
    const rateLimitKey = cacheKeys.rateLimit(`code-execution:${userId}`, 'minute');
    const currentRequests = await cacheHelpers.incr(rateLimitKey, 60);
    
    if (currentRequests > 30) { // 30 requests per minute
      return res.status(429).json({
        success: false,
        message: 'Rate limit exceeded. Please wait before making another request.'
      });
    }

    // Prepare Judge0 request
    // Note: Sending plain text directly due to Windows Docker Desktop limitations
    const judge0Request = {
      language_id,
      source_code,
      stdin
    };

    // Submit code to Judge0
    // console.log('🚀 Submitting to Judge0:', `${JUDGE0_BASE_URL}/submissions`);
    // console.log('📦 Request body:', judge0Request);
    
    const submissionResponse = await fetch(`${JUDGE0_BASE_URL}/submissions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(JUDGE0_API_KEY && { 'X-RapidAPI-Key': JUDGE0_API_KEY })
      },
      body: JSON.stringify(judge0Request)
    });

    // console.log('📊 Judge0 submission response status:', submissionResponse.status);
    
    if (!submissionResponse.ok) {
      const errorText = await submissionResponse.text();
      // console.error('❌ Judge0 submission failed:', errorText);
      throw new Error(`Judge0 submission failed: ${submissionResponse.statusText} - ${errorText}`);
    }

    const submissionData = await submissionResponse.json();
    const token = submissionData.token;

    // Poll for result
    let result = null;
    let attempts = 0;
    const maxAttempts = 30; // 30 seconds timeout

    while (attempts < maxAttempts) {
      await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second

      const resultResponse = await fetch(`${JUDGE0_BASE_URL}/submissions/${token}`, {
        headers: {
          ...(JUDGE0_API_KEY && { 'X-RapidAPI-Key': JUDGE0_API_KEY })
        }
      });

      if (!resultResponse.ok) {
        throw new Error(`Judge0 result fetch failed: ${resultResponse.statusText}`);
      }

      result = await resultResponse.json();

      // Check if execution is complete
      if (result.status && result.status.id > 2) { // Status 3 and above are terminal states
        break;
      }

      attempts++;
    }

    if (!result) {
      throw new Error('Code execution timeout');
    }

    // Process result
    // Note: Judge0 returns plain text when sent plain text input
    const processedResult = {
      stdout: result.stdout || '',
      stderr: result.stderr || '',
      compile_output: result.compile_output || '',
      time: result.time || 0,
      memory: result.memory || 0,
      status: getStatusText(result.status?.id || 0)
    };


    // Save submission to database
    const submission = new CodeSubmission({
      user: userId,
      language: getLanguageName(language_id),
      language_id,
      source_code,
      stdin,
      stdout: processedResult.stdout,
      stderr: processedResult.stderr,
      status: processedResult.status,
      execution_time: processedResult.time,
      memory_usage: processedResult.memory,
      judge0_token: token
    });

    await submission.save();

    // Cache result for quick access
    const cacheKey = cacheKeys.courseContent(`code-result:${submission._id}`, userId);
    await cacheHelpers.set(cacheKey, processedResult, 300); // 5 minutes

    res.json({
      success: true,
      data: processedResult,
      submission_id: submission._id
    });

  } catch (error) {
    // console.error('Code execution error:', error);
    res.status(500).json({
      success: false,
      message: 'Code execution failed',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

/**
 * Get submission history
 */
export const getSubmissionHistory = async (req, res) => {
  try {
    const { user_id, page = 1, limit = 20 } = req.query;
    const userId = req.student?._id || req.studentId || req.user?.id;

    // Validate userId
    if (!userId) {
      return res.status(400).json({
        success: false,
        message: 'User ID is required'
      });
    }

    // Build query - only user's own submissions
    const query = { user: userId };

    // Pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Get submissions
    const submissions = await CodeSubmission.find(query)
      .populate('user', 'name email')
      .sort({ created_at: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    // Get total count
    const total = await CodeSubmission.countDocuments(query);

    res.json({
      success: true,
      data: submissions,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });

  } catch (error) {
    // console.error('Error fetching submission history:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch submission history'
    });
  }
};

/**
 * Get submission by ID
 */
export const getSubmission = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.student?._id || req.studentId || req.user?.id;

    const submission = await CodeSubmission.findById(id)
      .populate('user', 'name email');

    if (!submission) {
      return res.status(404).json({
        success: false,
        message: 'Submission not found'
      });
    }

    // Check if user has access to this submission
    if (submission.user._id.toString() !== userId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    res.json({
      success: true,
      data: submission
    });

  } catch (error) {
    // console.error('Error fetching submission:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch submission'
    });
  }
};

/**
 * Delete submission by ID
 */
export const deleteSubmission = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.student?._id || req.studentId || req.user?.id;

    // console.log('🗑️ Delete submission request:', { id, userId });
    // console.log('🔍 User ID types:', { 
    //   userId: typeof userId, 
    //   userIdValue: userId,
    //   reqStudent: req.student,
    //   reqStudentId: req.studentId,
    //   reqUser: req.user
    // });

    const submission = await CodeSubmission.findById(id);

    if (!submission) {
      // console.log('❌ Submission not found:', id);
      return res.status(404).json({
        success: false,
        message: 'Submission not found'
      });
    }

    // console.log('📝 Found submission:', { 
    //   id: submission._id, 
    //   submissionUserId: submission.user.toString(), 
    //   requestingUserId: userId,
    //   userIdMatch: submission.user.toString() === userId
    // });

    // Check if user has permission to delete this submission
    // Convert both to strings for comparison
    const submissionUserId = submission.user.toString();
    const requestingUserId = userId.toString();
    
    // console.log('🔍 Final comparison:', {
    //   submissionUserId,
    //   requestingUserId,
    //   areEqual: submissionUserId === requestingUserId
    // });
    
    if (submissionUserId !== requestingUserId) {
      // console.log('❌ Access denied - user mismatch');
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only delete your own submissions.'
      });
    }

    await CodeSubmission.findByIdAndDelete(id);
    // console.log('✅ Submission deleted successfully:', id);

    res.json({
      success: true,
      message: 'Submission deleted successfully'
    });

  } catch (error) {
    // console.error('❌ Error deleting submission:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete submission'
    });
  }
};

/**
 * Get user statistics
 */
export const getUserStats = async (req, res) => {
  try {
    const userId = req.student?._id || req.studentId || req.user?.id;

    // Check cache first
    const cacheKey = cacheKeys.userSession(`user-stats:${userId}`);
    const cachedStats = await cacheHelpers.get(cacheKey);
    
    if (cachedStats) {
      return res.json({
        success: true,
        data: cachedStats
      });
    }

    // Get stats from database
    const stats = await CodeSubmission.getUserStats(userId);

    // Cache for 10 minutes
    await cacheHelpers.set(cacheKey, stats, 600);

    res.json({
      success: true,
      data: stats
    });

  } catch (error) {
    // console.error('Error fetching user stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user statistics'
    });
  }
};

/**
 * Get available languages
 */
export const getLanguages = async (req, res) => {
  try {
    const languages = [
      { id: 63, name: 'JavaScript', value: 'javascript', extension: 'js' },
      { id: 71, name: 'Python', value: 'python', extension: 'py' },
      { id: 62, name: 'Java', value: 'java', extension: 'java' },
      { id: 54, name: 'C++', value: 'cpp', extension: 'cpp' },
      { id: 50, name: 'C', value: 'c', extension: 'c' },
      { id: 51, name: 'C#', value: 'csharp', extension: 'cs' },
      { id: 68, name: 'PHP', value: 'php', extension: 'php' },
      { id: 78, name: 'Rust', value: 'rust', extension: 'rs' },
      { id: 72, name: 'Ruby', value: 'ruby', extension: 'rb' },
      { id: 60, name: 'Go', value: 'go', extension: 'go' },
      { id: 74, name: 'TypeScript', value: 'typescript', extension: 'ts' },
      { id: 73, name: 'R', value: 'r', extension: 'r' },
      { id: 80, name: 'Racket', value: 'racket', extension: 'rkt' },
      { id: 79, name: 'Erlang', value: 'erlang', extension: 'erl' },
      { id: 82, name: 'SQL', value: 'sql', extension: 'sql' },
      { id: 83, name: 'Swift', value: 'swift', extension: 'swift' },
      { id: 84, name: 'Kotlin', value: 'kotlin', extension: 'kt' },
      { id: 85, name: 'Scala', value: 'scala', extension: 'scala' },
      { id: 86, name: 'Perl', value: 'perl', extension: 'pl' },
      { id: 87, name: 'Clojure', value: 'clojure', extension: 'clj' },
      { id: 88, name: 'Haskell', value: 'haskell', extension: 'hs' },
      { id: 89, name: 'OCaml', value: 'ocaml', extension: 'ml' },
      { id: 90, name: 'F#', value: 'fsharp', extension: 'fs' },
      { id: 91, name: 'Dart', value: 'dart', extension: 'dart' },
      { id: 92, name: 'Elixir', value: 'elixir', extension: 'ex' },
      { id: 93, name: 'Julia', value: 'julia', extension: 'jl' },
      { id: 94, name: 'Nim', value: 'nim', extension: 'nim' },
      { id: 95, name: 'Crystal', value: 'crystal', extension: 'cr' },
      { id: 96, name: 'Zig', value: 'zig', extension: 'zig' },
      { id: 97, name: 'Lua', value: 'lua', extension: 'lua' },
      { id: 98, name: 'Pascal', value: 'pascal', extension: 'pas' },
      { id: 99, name: 'Fortran', value: 'fortran', extension: 'f90' },
      { id: 100, name: 'COBOL', value: 'cobol', extension: 'cob' },
      { id: 101, name: 'Assembly', value: 'assembly', extension: 'asm' },
      { id: 102, name: 'Bash', value: 'bash', extension: 'sh' },
      { id: 103, name: 'PowerShell', value: 'powershell', extension: 'ps1' },
      { id: 104, name: 'V', value: 'v', extension: 'v' },
      { id: 105, name: 'Brainfuck', value: 'brainfuck', extension: 'bf' },
      { id: 106, name: 'Whitespace', value: 'whitespace', extension: 'ws' },
      { id: 107, name: 'TCL', value: 'tcl', extension: 'tcl' },
      { id: 108, name: 'Prolog', value: 'prolog', extension: 'pro' },
      { id: 109, name: 'Smalltalk', value: 'smalltalk', extension: 'st' },
      { id: 110, name: 'Lisp', value: 'lisp', extension: 'lisp' },
      { id: 111, name: 'Scheme', value: 'scheme', extension: 'scm' },
      { id: 112, name: 'Forth', value: 'forth', extension: 'fth' },
      { id: 113, name: 'Ada', value: 'ada', extension: 'adb' },
      { id: 114, name: 'D', value: 'd', extension: 'd' },
      { id: 115, name: 'Vala', value: 'vala', extension: 'vala' }
    ];

    res.json({
      success: true,
      data: languages
    });

  } catch (error) {
    // console.error('Error fetching languages:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch languages'
    });
  }
};

// Helper functions
function getStatusText(statusId) {
  const statusMap = {
    1: 'In Queue',
    2: 'Processing',
    3: 'Accepted',
    4: 'Wrong Answer',
    5: 'Time Limit Exceeded',
    6: 'Compilation Error',
    7: 'Runtime Error (SIGSEGV)',
    8: 'Internal Error',
    9: 'Exec Format Error',
    10: 'Output Limit Exceeded',
    11: 'Runtime Error (NZEC)',
    12: 'Runtime Error (SIGXFSZ)',
    13: 'Runtime Error (Other)',
    14: 'Exec Format Error'
  };
  return statusMap[statusId] || 'Unknown';
}

function getLanguageName(languageId) {
  const languageMap = {
    45: 'assembly',
    46: 'bash',
    47: 'basic',
    48: 'c',
    49: 'c',
    50: 'c',
    51: 'csharp',
    52: 'css',
    53: 'clojure',
    54: 'cpp',
    55: 'dart',
    56: 'html', // HTML language mapping
    57: 'json',
    58: 'fsharp',
    59: 'elixir',
    60: 'go',
    61: 'haskell',
    62: 'java',
    63: 'javascript',
    64: 'erlang',
    65: 'kotlin',
    66: 'matlab',
    67: 'lua',
    68: 'php',
    69: 'powershell',
    70: 'perl',
    71: 'python',
    72: 'ruby',
    73: 'rust',
    74: 'typescript',
    75: 'c',
    76: 'csharp',
    77: 'cpp',
    78: 'kotlin',
    79: 'erlang',
    80: 'r',
    81: 'scala',
    82: 'sql',
    83: 'swift',
    84: 'xml',
    85: 'yaml',
    86: 'markdown',
    87: 'dockerfile',
    88: 'zig',
    89: 'nim',
    90: 'crystal',
    91: 'julia',
    92: 'd',
    93: 'prolog',
    94: 'ocaml',
    95: 'scheme',
    96: 'racket',
    97: 'lisp',
    98: 'forth',
    99: 'vhdl',
    100: 'verilog'
  };
  return languageMap[languageId] || 'javascript'; // Default to javascript instead of unknown
}
