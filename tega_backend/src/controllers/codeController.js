import CodeSubmission from '../models/CodeSubmission.js';
import { cacheHelpers, cacheKeys } from '../config/redis.js';

// Judge0 CE configuration
// Sanitize and validate the URL to remove any typos or trailing characters
const getJudge0Url = () => {
  const url = (process.env.JUDGE0_BASE_URL || 'http://localhost:2358').trim();
  // Remove any trailing non-numeric characters after the port number
  const urlMatch = url.match(/^(https?:\/\/[^:]+:\d+)/);
  if (urlMatch) {
    return urlMatch[1];
  }
  // Fallback to default if invalid format
  return 'http://localhost:2358';
};
const JUDGE0_BASE_URL = getJudge0Url();
const JUDGE0_API_KEY = process.env.JUDGE0_API_KEY || null; // Not needed for CE

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

    // Quick health check - verify Judge0 is accessible
    try {
      // Create timeout signal (compatible with older Node.js versions)
      let timeoutSignal;
      if (typeof AbortSignal !== 'undefined' && AbortSignal.timeout) {
        timeoutSignal = AbortSignal.timeout(3000);
      } else {
        const controller = new AbortController();
        timeoutSignal = controller.signal;
        setTimeout(() => controller.abort(), 3000);
      }
      
      const healthCheck = await fetch(`${JUDGE0_BASE_URL}/languages`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          ...(JUDGE0_API_KEY && { 'X-RapidAPI-Key': JUDGE0_API_KEY })
        },
        signal: timeoutSignal
      });
      
      if (!healthCheck.ok) {
        throw new Error(`Judge0 service health check failed: ${healthCheck.statusText}`);
      }
    } catch (healthError) {
      const errorMsg = `Cannot connect to code execution service at ${JUDGE0_BASE_URL}. `;
      const troubleshooting = `Please ensure Judge0 service is running. To restart: cd judge-service && docker-compose restart judge0`;
      throw new Error(`${errorMsg}${troubleshooting}. Error: ${healthError.message}`);
    }

    // Prepare Judge0 request
    // Note: Sending plain text directly due to Windows Docker Desktop limitations
    const judge0Request = {
      language_id,
      source_code,
      stdin
    };

    // Submit code to Judge0 with retry logic for queue full errors
    let submissionResponse;
    let token;
    const maxRetries = 5; // Maximum retry attempts for queue full errors
    let retryCount = 0;
    let lastError = null;
    
    while (retryCount <= maxRetries) {
      try {
        // Create timeout signal for submission (compatible with older Node.js versions)
        let submissionTimeoutSignal;
        if (typeof AbortSignal !== 'undefined' && AbortSignal.timeout) {
          submissionTimeoutSignal = AbortSignal.timeout(10000);
        } else {
          const controller = new AbortController();
          submissionTimeoutSignal = controller.signal;
          setTimeout(() => controller.abort(), 10000);
        }
        
        submissionResponse = await fetch(`${JUDGE0_BASE_URL}/submissions`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            ...(JUDGE0_API_KEY && { 'X-RapidAPI-Key': JUDGE0_API_KEY })
          },
          body: JSON.stringify(judge0Request),
          signal: submissionTimeoutSignal
        });
        
        if (!submissionResponse.ok) {
          const errorText = await submissionResponse.text();
          const isQueueFull = submissionResponse.status === 503 && 
                            (errorText.includes('queue is full') || 
                             errorText.includes('queue is full') ||
                             errorText.toLowerCase().includes('queue'));
          
          // If queue is full and we haven't exceeded max retries, retry with exponential backoff
          if (isQueueFull && retryCount < maxRetries) {
            retryCount++;
            const backoffDelay = Math.min(1000 * Math.pow(2, retryCount - 1), 10000); // Exponential backoff, max 10s
            await new Promise(resolve => setTimeout(resolve, backoffDelay));
            continue; // Retry the request
          }
          
          // If it's a queue full error but we've exhausted retries, provide a helpful message
          if (isQueueFull) {
            throw new Error(`Code execution service queue is full. Please wait a moment and try again. The service is currently processing many requests.`);
          }
          
          // For other errors, throw immediately
          throw new Error(`Judge0 submission failed: ${submissionResponse.statusText} - ${errorText}`);
        }

        const submissionData = await submissionResponse.json();
        token = submissionData.token;
        
        if (!token) {
          throw new Error('Failed to get submission token from Judge0');
        }
        
        // Success! Break out of retry loop
        break;
        
      } catch (fetchError) {
        lastError = fetchError;
        
        // Check if it's a queue full error in the message
        const isQueueFullError = fetchError.message && 
                                 (fetchError.message.includes('queue is full') || 
                                  fetchError.message.toLowerCase().includes('queue'));
        
        // If queue is full and we haven't exceeded max retries, retry with exponential backoff
        if (isQueueFullError && retryCount < maxRetries) {
          retryCount++;
          const backoffDelay = Math.min(1000 * Math.pow(2, retryCount - 1), 10000); // Exponential backoff, max 10s
          await new Promise(resolve => setTimeout(resolve, backoffDelay));
          continue; // Retry the request
        }
        
        // Handle timeout errors
        if (fetchError.name === 'AbortError') {
          throw new Error(`Timeout connecting to code execution service at ${JUDGE0_BASE_URL}`);
        }
        
        // If we've exhausted retries for queue full, provide helpful message
        if (isQueueFullError) {
          throw new Error(`Code execution service queue is full. Please wait a moment and try again. The service is currently processing many requests.`);
        }
        
        // For other errors, throw immediately
        throw new Error(`Cannot connect to code execution service at ${JUDGE0_BASE_URL}. Please ensure Judge0 service is running. Error: ${fetchError.message}`);
      }
    }
    
    // If we exited the loop without a token, throw the last error
    if (!token && lastError) {
      throw lastError;
    }
    


    // Poll for result
    let result = null;
    let attempts = 0;
    const maxAttempts = 30; // 30 seconds timeout
    let consecutiveErrors = 0;
    const maxConsecutiveErrors = 5; // Allow up to 5 consecutive network errors

    while (attempts < maxAttempts) {
      await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second

      try {
        // Create timeout signal for polling (compatible with older Node.js versions)
        let pollingTimeoutSignal;
        if (typeof AbortSignal !== 'undefined' && AbortSignal.timeout) {
          pollingTimeoutSignal = AbortSignal.timeout(5000);
        } else {
          const controller = new AbortController();
          pollingTimeoutSignal = controller.signal;
          setTimeout(() => controller.abort(), 5000);
        }
        
        const resultResponse = await fetch(`${JUDGE0_BASE_URL}/submissions/${token}?base64_encoded=false&fields=stdout,stderr,compile_output,time,memory,status`, {
          headers: {
            ...(JUDGE0_API_KEY && { 'X-RapidAPI-Key': JUDGE0_API_KEY })
          },
          signal: pollingTimeoutSignal
        });

        if (!resultResponse.ok) {
          consecutiveErrors++;
          if (consecutiveErrors >= maxConsecutiveErrors) {
            throw new Error(`Judge0 result fetch failed after ${maxConsecutiveErrors} attempts: ${resultResponse.statusText}`);
          }
          // Continue polling after an error
          attempts++;
          continue;
        }

        // Reset consecutive error counter on success
        consecutiveErrors = 0;
        result = await resultResponse.json();

        // Check if execution is complete
        if (result.status && result.status.id && result.status.id > 2) { // Status 3 and above are terminal states
          break;
        }

        // If status is null or undefined, continue polling
        if (!result.status) {
          attempts++;
          continue;
        }

      } catch (fetchError) {
        consecutiveErrors++;
        
        // If it's a network error and we haven't exceeded max errors, continue polling
        if (consecutiveErrors < maxConsecutiveErrors && 
            (fetchError.name === 'AbortError' || 
             fetchError.message.includes('fetch') || 
             fetchError.message.includes('network') ||
             fetchError.message.includes('ECONNREFUSED'))) {
          attempts++;
          continue;
        }
        
        // If too many consecutive errors, throw
        if (consecutiveErrors >= maxConsecutiveErrors) {
          throw new Error(`Cannot connect to code execution service during polling. Please ensure Judge0 service is running and accessible.`);
        }
        
        // For other errors, throw immediately
        throw fetchError;
      }

      attempts++;
    }

    if (!result || !result.status) {
      throw new Error('Code execution timeout or invalid response from Judge0 service');
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
    const languageName = await getLanguageName(language_id);
    const submission = new CodeSubmission({
      user: userId,
      language: languageName,
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
    // Provide more specific error messages
    let errorMessage = error.message || 'Code execution failed';
    let statusCode = 500;
    
    // Check if it's a queue full error
    if (error.message && (error.message.includes('queue is full') || error.message.toLowerCase().includes('queue'))) {
      errorMessage = error.message.includes('queue is full') 
        ? error.message 
        : 'Code execution service queue is full. Please wait a moment and try again.';
      statusCode = 503; // Service Unavailable
    }
    // Check if it's a network error (Judge0 connection issue)
    else if (error.message && (error.message.includes('fetch') || error.message.includes('ECONNREFUSED') || error.message.includes('network'))) {
      errorMessage = 'Cannot connect to code execution service. Please ensure Judge0 service is running.';
      statusCode = 503;
    }
    // Check if it's a timeout
    else if (error.message && error.message.includes('timeout')) {
      errorMessage = 'Code execution timed out. Your code may be taking too long to execute.';
      statusCode = 504; // Gateway Timeout
    }
    
    res.status(statusCode).json({
      success: false,
      message: errorMessage,
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

    const submission = await CodeSubmission.findById(id);

    if (!submission) {
      return res.status(404).json({
        success: false,
        message: 'Submission not found'
      });
    }

    // Check if user has permission to delete this submission
    // Convert both to strings for comparison
    const submissionUserId = submission.user.toString();
    const requestingUserId = userId.toString();
    
    if (submissionUserId !== requestingUserId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only delete your own submissions.'
      });
    }

    await CodeSubmission.findByIdAndDelete(id);

    res.json({
      success: true,
      message: 'Submission deleted successfully'
    });

  } catch (error) {
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
    res.status(500).json({
      success: false,
      message: 'Failed to fetch user statistics'
    });
  }
};

/**
 * Health check endpoint for Judge0 service
 */
export const checkHealth = async (req, res) => {
  try {
    // Quick health check - verify Judge0 is accessible
    let healthCheck;
    try {
      const controller = new AbortController();
      const timeoutSignal = controller.signal;
      setTimeout(() => controller.abort(), 3000);
      
      healthCheck = await fetch(`${JUDGE0_BASE_URL}/languages`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          ...(JUDGE0_API_KEY && { 'X-RapidAPI-Key': JUDGE0_API_KEY })
        },
        signal: timeoutSignal
      });
    } catch (healthError) {
      return res.status(503).json({
        success: false,
        status: 'unhealthy',
        message: `Cannot connect to Judge0 service at ${JUDGE0_BASE_URL}`,
        error: healthError.message,
        service: 'Judge0',
        url: JUDGE0_BASE_URL
      });
    }
    
    if (!healthCheck.ok) {
      return res.status(503).json({
        success: false,
        status: 'unhealthy',
        message: `Judge0 service returned error: ${healthCheck.statusText}`,
        statusCode: healthCheck.status,
        service: 'Judge0',
        url: JUDGE0_BASE_URL
      });
    }
    
    // Try to get queue status if possible
    let queueInfo = null;
    try {
      // Check if we can get system info (some Judge0 versions support this)
      const statsResponse = await fetch(`${JUDGE0_BASE_URL}/statistics`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          ...(JUDGE0_API_KEY && { 'X-RapidAPI-Key': JUDGE0_API_KEY })
        }
      });
      
      if (statsResponse.ok) {
        queueInfo = await statsResponse.json();
      }
    } catch (statsError) {
      // Statistics endpoint might not be available, that's okay
    }
    
    res.json({
      success: true,
      status: 'healthy',
      message: 'Judge0 service is running',
      service: 'Judge0',
      url: JUDGE0_BASE_URL,
      queueInfo: queueInfo
    });
    
  } catch (error) {
    res.status(503).json({
      success: false,
      status: 'unhealthy',
      message: 'Health check failed',
      error: error.message,
      service: 'Judge0',
      url: JUDGE0_BASE_URL
    });
  }
};

/**
 * Get available languages from Judge0 API
 */
export const getLanguages = async (req, res) => {
  try {
    // Check cache first (languages don't change often)
    const cacheKey = cacheKeys.courseContent('judge0-languages', 'global');
    const cachedLanguages = await cacheHelpers.get(cacheKey);
    
    if (cachedLanguages) {
      return res.json({
        success: true,
        data: cachedLanguages,
        cached: true
      });
    }

    // Fetch languages from Judge0 API
    let judge0Response;
    try {
      judge0Response = await fetch(`${JUDGE0_BASE_URL}/languages`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          ...(JUDGE0_API_KEY && { 'X-RapidAPI-Key': JUDGE0_API_KEY })
        }
      });
    } catch (fetchError) {
      // Fallback to common languages if Judge0 is unavailable
      return res.json({
        success: true,
        data: getFallbackLanguages(),
        cached: false,
        warning: 'Judge0 unavailable, using fallback languages'
      });
    }

    if (!judge0Response.ok) {
      // Fallback to common languages
      return res.json({
        success: true,
        data: getFallbackLanguages(),
        cached: false,
        warning: 'Judge0 API error, using fallback languages'
      });
    }

    const judge0Languages = await judge0Response.json();
    
    // Transform Judge0 language format to our format
    const languages = judge0Languages.map(lang => {
      // Map Judge0 language name to our value/extension format
      const languageMapping = getLanguageMapping(lang.id, lang.name);
      
      return {
        id: lang.id,
        name: lang.name,
        value: languageMapping.value,
        extension: languageMapping.extension,
        version: lang.version || null
      };
    });

    // Cache for 24 hours (languages rarely change)
    await cacheHelpers.set(cacheKey, languages, 86400);

    res.json({
      success: true,
      data: languages,
      cached: false
    });

  } catch (error) {
    // Fallback to common languages on any error
    res.json({
      success: true,
      data: getFallbackLanguages(),
      cached: false,
      warning: 'Error fetching from Judge0, using fallback languages'
    });
  }
};

/**
 * Fallback languages when Judge0 is unavailable
 */
function getFallbackLanguages() {
  return [
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
    { id: 74, name: 'TypeScript', value: 'typescript', extension: 'ts' }
  ];
}

/**
 * Map Judge0 language name to our value/extension format
 */
function getLanguageMapping(id, name) {
  // Normalize name for matching
  const normalizedName = name.toLowerCase().replace(/[^a-z0-9]/g, '');
  
  // Common mappings
  const mappings = {
    'javascript': { value: 'javascript', extension: 'js' },
    'nodejs': { value: 'javascript', extension: 'js' },
    'python': { value: 'python', extension: 'py' },
    'python3': { value: 'python', extension: 'py' },
    'java': { value: 'java', extension: 'java' },
    'cpp': { value: 'cpp', extension: 'cpp' },
    'c++': { value: 'cpp', extension: 'cpp' },
    'c': { value: 'c', extension: 'c' },
    'csharp': { value: 'csharp', extension: 'cs' },
    'c#': { value: 'csharp', extension: 'cs' },
    'php': { value: 'php', extension: 'php' },
    'rust': { value: 'rust', extension: 'rs' },
    'ruby': { value: 'ruby', extension: 'rb' },
    'go': { value: 'go', extension: 'go' },
    'typescript': { value: 'typescript', extension: 'ts' },
    'r': { value: 'r', extension: 'r' },
    'sql': { value: 'sql', extension: 'sql' },
    'swift': { value: 'swift', extension: 'swift' },
    'kotlin': { value: 'kotlin', extension: 'kt' },
    'scala': { value: 'scala', extension: 'scala' },
    'perl': { value: 'perl', extension: 'pl' },
    'clojure': { value: 'clojure', extension: 'clj' },
    'haskell': { value: 'haskell', extension: 'hs' },
    'ocaml': { value: 'ocaml', extension: 'ml' },
    'fsharp': { value: 'fsharp', extension: 'fs' },
    'f#': { value: 'fsharp', extension: 'fs' },
    'dart': { value: 'dart', extension: 'dart' },
    'elixir': { value: 'elixir', extension: 'ex' },
    'julia': { value: 'julia', extension: 'jl' },
    'nim': { value: 'nim', extension: 'nim' },
    'crystal': { value: 'crystal', extension: 'cr' },
    'zig': { value: 'zig', extension: 'zig' },
    'lua': { value: 'lua', extension: 'lua' },
    'bash': { value: 'bash', extension: 'sh' },
    'powershell': { value: 'powershell', extension: 'ps1' }
  };

  // Try exact match first
  if (mappings[normalizedName]) {
    return mappings[normalizedName];
  }

  // Try partial match
  for (const [key, value] of Object.entries(mappings)) {
    if (normalizedName.includes(key) || key.includes(normalizedName)) {
      return value;
    }
  }

  // Default: create value from name
  const value = normalizedName.replace(/[^a-z0-9]/g, '');
  const extension = value.substring(0, 3);
  return { value, extension };
}

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

/**
 * Get language name/value from language ID
 * This will use cached Judge0 languages or fallback mapping
 */
let languageIdCache = null;

async function getLanguageName(languageId) {
  try {
    // Try to get from cache if available
    if (!languageIdCache) {
      const cacheKey = cacheKeys.courseContent('judge0-languages', 'global');
      const cachedLanguages = await cacheHelpers.get(cacheKey);
      
      if (cachedLanguages && Array.isArray(cachedLanguages)) {
        languageIdCache = {};
        cachedLanguages.forEach(lang => {
          languageIdCache[lang.id] = lang.value || lang.name.toLowerCase();
        });
      }
    }

    // If we have cached languages, use them
    if (languageIdCache && languageIdCache[languageId]) {
      return languageIdCache[languageId];
    }

    // Fallback: Try to fetch from Judge0 (if cache miss)
    if (!languageIdCache) {
      try {
        const response = await fetch(`${JUDGE0_BASE_URL}/languages/${languageId}`, {
          headers: {
            ...(JUDGE0_API_KEY && { 'X-RapidAPI-Key': JUDGE0_API_KEY })
          }
        });
        
        if (response.ok) {
          const lang = await response.json();
          const mapping = getLanguageMapping(lang.id, lang.name);
          return mapping.value;
        }
      } catch (error) {
        // Ignore fetch errors, use fallback
      }
    }
  } catch (error) {
    // Use fallback on any error
  }

  // Final fallback: static mapping for common languages
  const fallbackMap = {
    50: 'c',
    51: 'csharp',
    54: 'cpp',
    60: 'go',
    62: 'java',
    63: 'javascript',
    68: 'php',
    71: 'python',
    72: 'ruby',
    73: 'r',
    74: 'typescript',
    78: 'rust',
    82: 'sql',
    83: 'swift',
    84: 'kotlin'
  };

  return fallbackMap[languageId] || 'javascript';
}
