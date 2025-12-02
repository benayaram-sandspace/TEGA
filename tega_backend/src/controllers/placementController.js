import mongoose from 'mongoose';
import PlacementQuestion from '../models/PlacementQuestion.js';
import CodingQuestion from '../models/CodingQuestion.js';
import SkillAssessmentQuestion from '../models/SkillAssessmentQuestion.js';
import CodingAssessment from '../models/CodingAssessment.js';
import PlacementModule from '../models/PlacementModule.js';
import PlacementProgress from '../models/PlacementProgress.js';
import Student from '../models/Student.js';

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
const JUDGE0_API_KEY = process.env.JUDGE0_API_KEY || null;

// Language ID mapping
const LANGUAGE_IDS = {
  'javascript': 63,
  'python': 71, // Python 3.8.1
  'java': 62,
  'cpp': 54,
  'c': 50
};

// Helper function to calculate time ago
const calculateTimeAgo = (date) => {
  if (!date) return 'Unknown';
  const now = new Date();
  const diffMs = now - new Date(date);
  const diffMins = Math.floor(diffMs / (1000 * 60));
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
  
  if (diffMins < 60) return `${diffMins} ${diffMins === 1 ? 'minute' : 'minutes'} ago`;
  if (diffHours < 24) return `${diffHours} ${diffHours === 1 ? 'hour' : 'hours'} ago`;
  if (diffDays < 30) return `${diffDays} ${diffDays === 1 ? 'day' : 'days'} ago`;
  return `${Math.floor(diffDays / 30)} ${Math.floor(diffDays / 30) === 1 ? 'month' : 'months'} ago`;
};

// Helper function to execute code with Judge0
const executeCodeWithJudge0 = async (sourceCode, language, stdin) => {
  try {
    const languageId = LANGUAGE_IDS[language.toLowerCase()];
    
    if (!languageId) {
      return { success: false, error: `Unsupported language: ${language}` };
    }

    // Quick health check - verify Judge0 is accessible
    try {
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
        return { success: false, error: `Judge0 service health check failed: ${healthCheck.statusText}` };
      }
    } catch (healthError) {
      return { success: false, error: `Cannot connect to code execution service at ${JUDGE0_BASE_URL}. Please ensure Judge0 service is running and accessible.` };
    }

    // Submit code to Judge0
    let submissionResponse;
    let token;
    try {
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
        body: JSON.stringify({ language_id: languageId, source_code: sourceCode, stdin }),
        signal: submissionTimeoutSignal
      });

      if (!submissionResponse.ok) {
        const errorText = await submissionResponse.text();
        return { success: false, error: `Judge0 submission failed: ${errorText}` };
      }

      const submissionData = await submissionResponse.json();
      token = submissionData.token;
      
      if (!token) {
        return { success: false, error: 'Failed to get submission token from Judge0' };
      }
    } catch (fetchError) {
      if (fetchError.name === 'AbortError') {
        return { success: false, error: `Timeout connecting to code execution service at ${JUDGE0_BASE_URL}` };
      }
      return { success: false, error: `Cannot connect to code execution service. Error: ${fetchError.message}` };
    }

    // Poll for result (max 30 seconds)
    let result = null;
    let attempts = 0;
    const maxAttempts = 30;
    let consecutiveErrors = 0;
    const maxConsecutiveErrors = 5;

    while (attempts < maxAttempts) {
      await new Promise(resolve => setTimeout(resolve, 1000));

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
            return { success: false, error: `Judge0 result fetch failed after ${maxConsecutiveErrors} attempts: ${resultResponse.statusText}` };
          }
          // Continue polling after an error
          attempts++;
          continue;
        }

        // Reset consecutive error counter on success
        consecutiveErrors = 0;
        result = await resultResponse.json();

        // Check if execution is complete (status 3 and above are terminal)
        if (result.status && result.status.id && result.status.id > 2) {
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
        
        // If too many consecutive errors, return error
        if (consecutiveErrors >= maxConsecutiveErrors) {
          return { success: false, error: `Cannot connect to code execution service during polling. Please ensure Judge0 service is running and accessible.` };
        }
        
        // For other errors, return immediately
        return { success: false, error: fetchError.message };
      }

      attempts++;
    }

    if (!result || !result.status) {
      return { success: false, error: 'Code execution timeout or invalid response from Judge0 service' };
    }

    // Process result
    return {
      success: true,
      stdout: result.stdout || '',
      stderr: result.stderr || '',
      compile_output: result.compile_output || '',
      time: result.time || 0,
      memory: result.memory || 0,
      status: result.status?.description || 'Unknown'
    };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// ============ ADMIN - Question Management ============

export const createQuestion = async (req, res) => {
  try {
    const questionData = {
      ...req.body,
      createdBy: req.user?.id || req.adminId || req.admin?._id
    };

    let question;
    let questionType = 'placement'; // Default for backward compatibility

    // Determine which model to use based on type and category
    if (questionData.type === 'coding') {
      // Coding questions go to CodingQuestion model
      questionType = 'coding';

    // Clean up empty starterCode if all fields are empty
    if (questionData.starterCode && typeof questionData.starterCode === 'object') {
      const hasAnyCode = Object.values(questionData.starterCode).some(code => code && code.trim());
      if (!hasAnyCode) {
        delete questionData.starterCode;
      }
    }

    // Clean up empty testCases array
    if (questionData.testCases && Array.isArray(questionData.testCases)) {
      questionData.testCases = questionData.testCases.filter(tc => tc && (tc.input || tc.output));
      if (questionData.testCases.length === 0) {
        delete questionData.testCases;
      }
    }

    // Clean up empty hints array
    if (questionData.hints && Array.isArray(questionData.hints)) {
      questionData.hints = questionData.hints.filter(h => h && h.trim());
      if (questionData.hints.length === 0) {
        delete questionData.hints;
      }
    }

      // Remove type field (not needed in CodingQuestion)
      delete questionData.type;
      
      question = new CodingQuestion(questionData);
    } else if (questionData.category === 'assessment' || ['mcq', 'subjective', 'behavioral'].includes(questionData.type)) {
      // Skill assessment questions go to SkillAssessmentQuestion model
      questionType = 'skillAssessment';
      
      // Remove category field (always assessment for this model)
      delete questionData.category;
      
      // Ensure type is valid for SkillAssessmentQuestion
      if (!['mcq', 'subjective', 'behavioral'].includes(questionData.type)) {
        questionData.type = 'mcq'; // Default to mcq if invalid
      }
      
      question = new SkillAssessmentQuestion(questionData);
    } else {
      // All questions must be either coding or skill assessment
      // Reject questions that don't fit either category
      return res.status(400).json({
        success: false,
        message: 'Invalid question type or category. Questions must be either:\n' +
                 '1. Coding questions (type="coding")\n' +
                 '2. Skill assessment questions (category="assessment" OR type="mcq"/"subjective"/"behavioral")',
        error: `Question type "${questionData.type}" and category "${questionData.category}" do not match any valid question type.`
      });
    }

    await question.save();

    res.status(201).json({
      success: true,
      message: 'Question created successfully',
      question,
      questionType
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create question',
      error: error.message,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

export const getAllQuestions = async (req, res) => {
  try {
    const { type, category, difficulty, topic, search, questionType } = req.query;
    
    // If questionType is specified, fetch from specific model
    if (questionType === 'coding') {
    const filter = {};
    if (category) filter.category = category;
      if (difficulty) filter.difficulty = difficulty;
      if (topic) filter.topic = topic;
      if (search) {
        filter.$or = [
          { title: { $regex: search, $options: 'i' } },
          { description: { $regex: search, $options: 'i' } },
          { problemStatement: { $regex: search, $options: 'i' } }
        ];
      }

      const questions = await CodingQuestion.find(filter)
        .populate('createdBy', 'username email')
        .sort({ createdAt: -1 });

      return res.json({
        success: true,
        count: questions.length,
        questions: questions.map(q => ({ ...q.toObject(), questionType: 'coding' })),
        questionType: 'coding'
      });
    } else if (questionType === 'skillAssessment') {
      const filter = {};
      if (type) filter.type = type;
    if (difficulty) filter.difficulty = difficulty;
    if (topic) filter.topic = topic;
    if (search) {
      filter.$or = [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

      const questions = await SkillAssessmentQuestion.find(filter)
      .populate('createdBy', 'username email')
      .sort({ createdAt: -1 });

      return res.json({
      success: true,
      count: questions.length,
        questions: questions.map(q => ({ ...q.toObject(), questionType: 'skillAssessment', category: 'assessment' })),
        questionType: 'skillAssessment'
      });
    }

    // Default: fetch from all models and combine
    const placementFilter = {};
    const codingFilter = {};
    const skillAssessmentFilter = {};
    
    if (type && type !== 'coding') {
      placementFilter.type = type;
      skillAssessmentFilter.type = type;
    }
    if (category && category !== 'assessment') {
      placementFilter.category = category;
      codingFilter.category = category;
    }
    if (difficulty) {
      placementFilter.difficulty = difficulty;
      codingFilter.difficulty = difficulty;
      skillAssessmentFilter.difficulty = difficulty;
    }
    if (topic) {
      placementFilter.topic = topic;
      codingFilter.topic = topic;
      skillAssessmentFilter.topic = topic;
    }

    const searchFilter = search ? {
      $or: [
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ]
    } : {};

    const [placementQuestions, codingQuestions, skillAssessmentQuestions] = await Promise.all([
      PlacementQuestion.find({ ...placementFilter, ...searchFilter })
        .populate('createdBy', 'username email')
        .sort({ createdAt: -1 }),
      CodingQuestion.find({ ...codingFilter, ...searchFilter })
        .populate('createdBy', 'username email')
        .sort({ createdAt: -1 }),
      SkillAssessmentQuestion.find({ ...skillAssessmentFilter, ...searchFilter })
        .populate('createdBy', 'username email')
        .sort({ createdAt: -1 })
    ]);

    // Combine and tag questions
    const allQuestions = [
      ...placementQuestions.map(q => ({ ...q.toObject(), questionType: 'placement' })),
      ...codingQuestions.map(q => ({ ...q.toObject(), questionType: 'coding', type: 'coding' })),
      ...skillAssessmentQuestions.map(q => ({ ...q.toObject(), questionType: 'skillAssessment', category: 'assessment' }))
    ].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.json({
      success: true,
      count: allQuestions.length,
      questions: allQuestions,
      breakdown: {
        placement: placementQuestions.length,
        coding: codingQuestions.length,
        skillAssessment: skillAssessmentQuestions.length
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch questions',
      error: error.message
    });
  }
};

export const getQuestionById = async (req, res) => {
  try {
    const { questionType } = req.query;
    
    let question;
    if (questionType === 'coding') {
      question = await CodingQuestion.findById(req.params.id)
      .populate('createdBy', 'username email');
      if (question) {
        question = { ...question.toObject(), questionType: 'coding', type: 'coding' };
      }
    } else if (questionType === 'skillAssessment') {
      question = await SkillAssessmentQuestion.findById(req.params.id)
        .populate('createdBy', 'username email');
      if (question) {
        question = { ...question.toObject(), questionType: 'skillAssessment', category: 'assessment' };
      }
    } else {
      // Try all models
      question = await PlacementQuestion.findById(req.params.id)
        .populate('createdBy', 'username email');
      if (question) {
        question = { ...question.toObject(), questionType: 'placement' };
      } else {
        question = await CodingQuestion.findById(req.params.id)
          .populate('createdBy', 'username email');
        if (question) {
          question = { ...question.toObject(), questionType: 'coding', type: 'coding' };
        } else {
          question = await SkillAssessmentQuestion.findById(req.params.id)
            .populate('createdBy', 'username email');
          if (question) {
            question = { ...question.toObject(), questionType: 'skillAssessment', category: 'assessment' };
          }
        }
      }
    }

    if (!question) {
      return res.status(404).json({
        success: false,
        message: 'Question not found'
      });
    }

    res.json({
      success: true,
      question
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch question',
      error: error.message
    });
  }
};

export const updateQuestion = async (req, res) => {
  try {
    const updateData = { ...req.body };
    const { questionType } = req.query;
    
    let question;
    let model;

    // Determine which model to use
    if (questionType === 'coding') {
      model = CodingQuestion;
    } else if (questionType === 'skillAssessment') {
      model = SkillAssessmentQuestion;
      // Remove category if present (always assessment)
      delete updateData.category;
    } else {
      // Try to find in all models
      let found = await PlacementQuestion.findById(req.params.id);
      if (found) {
        model = PlacementQuestion;
      } else {
        found = await CodingQuestion.findById(req.params.id);
        if (found) {
          model = CodingQuestion;
        } else {
          found = await SkillAssessmentQuestion.findById(req.params.id);
          if (found) {
            model = SkillAssessmentQuestion;
            delete updateData.category;
          } else {
            return res.status(404).json({
              success: false,
              message: 'Question not found'
            });
          }
        }
      }
    }

    // Clean up empty starterCode if all fields are empty (for coding questions)
    if (updateData.starterCode && typeof updateData.starterCode === 'object') {
      const hasAnyCode = Object.values(updateData.starterCode).some(code => code && code.trim());
      if (!hasAnyCode) {
        delete updateData.starterCode;
      }
    }

    // Clean up empty testCases array (for coding questions)
    if (updateData.testCases && Array.isArray(updateData.testCases)) {
      updateData.testCases = updateData.testCases.filter(tc => tc && (tc.input || tc.output));
      if (updateData.testCases.length === 0) {
        delete updateData.testCases;
      }
    }

    // Clean up empty hints array (for coding questions)
    if (updateData.hints && Array.isArray(updateData.hints)) {
      updateData.hints = updateData.hints.filter(h => h && h.trim());
      if (updateData.hints.length === 0) {
        delete updateData.hints;
      }
    }

    // Remove type field for coding questions (not in schema)
    if (model === CodingQuestion) {
      delete updateData.type;
    }

    question = await model.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!question) {
      return res.status(404).json({
        success: false,
        message: 'Question not found'
      });
    }

    // Add questionType to response
    const questionObj = question.toObject();
    if (model === CodingQuestion) {
      questionObj.questionType = 'coding';
      questionObj.type = 'coding';
    } else if (model === SkillAssessmentQuestion) {
      questionObj.questionType = 'skillAssessment';
      questionObj.category = 'assessment';
    } else {
      questionObj.questionType = 'placement';
    }

    res.json({
      success: true,
      message: 'Question updated successfully',
      question: questionObj
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update question',
      error: error.message,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

export const deleteQuestion = async (req, res) => {
  try {
    const { questionType } = req.query;
    
    let question;
    if (questionType === 'coding') {
      question = await CodingQuestion.findByIdAndDelete(req.params.id);
    } else if (questionType === 'skillAssessment') {
      question = await SkillAssessmentQuestion.findByIdAndDelete(req.params.id);
    } else {
      // Try all models
      question = await PlacementQuestion.findByIdAndDelete(req.params.id);
      if (!question) {
        question = await CodingQuestion.findByIdAndDelete(req.params.id);
      }
      if (!question) {
        question = await SkillAssessmentQuestion.findByIdAndDelete(req.params.id);
      }
    }

    if (!question) {
      return res.status(404).json({
        success: false,
        message: 'Question not found'
      });
    }

    res.json({
      success: true,
      message: 'Question deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete question',
      error: error.message
    });
  }
};

export const bulkUploadQuestions = async (req, res) => {
  try {
    let questions = [];
    let parsingErrors = []; // Declare at function scope

    // Handle Excel file upload
    if (req.file) {
      const XLSX = await import('xlsx');
      
      // Parse Excel file from buffer
      const workbook = XLSX.read(req.file.buffer, { type: 'buffer' });
      const sheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[sheetName];
      
      // Convert to JSON
      const jsonData = XLSX.utils.sheet_to_json(worksheet);
      
      if (!jsonData || jsonData.length === 0) {
      return res.status(400).json({
        success: false,
          message: 'Excel file is empty or has no data'
        });
      }

      // Expected columns (case-insensitive matching)
      // Required columns for all questions
      const requiredColumns = ['Question Title', 'Description', 'Type', 'Topic'];
      
      // Optional columns (different for coding vs MCQ)
      const columnMapping = {
        // Common fields
        'Question Title': 'title',
        'Description': 'description',
        'Type': 'type',
        'Category': 'category',
        'Difficulty': 'difficulty',
        'Time (min)': 'timeLimit',
        'Topic': 'topic',
        'Points': 'points',
        
        // MCQ fields
        'Option 1': 'option1',
        'Option 2': 'option2',
        'Option 3': 'option3',
        'Option 4': 'option4',
        'Correct Answer': 'correctAnswer',
        
        // Coding question fields
        'Problem Statement': 'problemStatement',
        'Constraints': 'constraints',
        'Input Format': 'inputFormat',
        'Output Format': 'outputFormat',
        'Sample Input': 'sampleInput',
        'Sample Output': 'sampleOutput',
        'Test Case 1 Input': 'testCase1Input',
        'Test Case 1 Output': 'testCase1Output',
        'Test Case 2 Input': 'testCase2Input',
        'Test Case 2 Output': 'testCase2Output',
        'Test Case 3 Input': 'testCase3Input',
        'Test Case 3 Output': 'testCase3Output',
        'Starter Code JavaScript': 'starterCodeJS',
        'Starter Code Python': 'starterCodePython',
        'Starter Code Java': 'starterCodeJava',
        'Starter Code C++': 'starterCodeCpp',
        'Starter Code C': 'starterCodeC',
        'Hints': 'hints',
        'Explanation': 'explanation'
      };

      // Get headers from first row
      const headers = Object.keys(jsonData[0] || {});
      
      // Validate required columns
      const missingRequiredColumns = requiredColumns.filter(col => 
        !headers.some(h => h.toLowerCase().trim() === col.toLowerCase().trim())
      );

      if (missingRequiredColumns.length > 0) {
        return res.status(400).json({
          success: false,
          message: `Missing required columns: ${missingRequiredColumns.join(', ')}. Please ensure your Excel file has all required columns.`
        });
      }

      // Map headers to normalized keys
      const headerMap = {};
      headers.forEach(header => {
        const normalizedHeader = header.trim();
        const mappedKey = Object.keys(columnMapping).find(
          key => key.toLowerCase() === normalizedHeader.toLowerCase()
        );
        if (mappedKey) {
          headerMap[normalizedHeader] = columnMapping[mappedKey];
        }
      });

      // Convert Excel rows to question objects with error handling
      let parsedQuestions = [];
      parsingErrors = []; // Reset for this upload
      
      jsonData.forEach((row, index) => {
        try {
          const rowNum = index + 2; // Excel row number (1-indexed, +1 for header)
          
          // Get values using case-insensitive header matching
          const getValue = (key) => {
            const header = Object.keys(headerMap).find(
              h => headerMap[h] === key
            );
            return header ? (row[header] || '').toString().trim() : '';
          };

          const title = getValue('title');
          const description = getValue('description');
          const type = (getValue('type') || 'mcq').toLowerCase();
          const category = (getValue('category') || 'assessment').toLowerCase();
          const difficulty = (getValue('difficulty') || 'medium').toLowerCase();
          const timeLimit = parseInt(getValue('timeLimit')) || 30;
          const topic = getValue('topic');
          const points = parseInt(getValue('points')) || 10;

          // Validate required fields
          if (!title || !description || !topic) {
            throw new Error(`Missing required fields (Title, Description, or Topic)`);
          }

          // Handle coding questions
          if (type === 'coding') {
          const problemStatement = getValue('problemStatement') || description;
          
          // Validate required fields for coding questions
          if (!problemStatement) {
            throw new Error(`Row ${rowNum}: Coding questions require "Problem Statement" field`);
          }
          
          const constraints = getValue('constraints');
          const inputFormat = getValue('inputFormat');
          const outputFormat = getValue('outputFormat');
          const sampleInput = getValue('sampleInput');
          const sampleOutput = getValue('sampleOutput');
          
          // Parse test cases (support up to 3 test cases)
          const testCases = [];
          for (let i = 1; i <= 3; i++) {
            const testInput = getValue(`testCase${i}Input`);
            const testOutput = getValue(`testCase${i}Output`);
            if (testInput && testOutput) {
              testCases.push({
                input: testInput,
                output: testOutput,
                isHidden: false
              });
            }
          }
          
          // Parse starter code for different languages
          const starterCode = {};
          const starterCodeJS = getValue('starterCodeJS');
          const starterCodePython = getValue('starterCodePython');
          const starterCodeJava = getValue('starterCodeJava');
          const starterCodeCpp = getValue('starterCodeCpp');
          const starterCodeC = getValue('starterCodeC');
          
          if (starterCodeJS) starterCode.javascript = starterCodeJS;
          if (starterCodePython) starterCode.python = starterCodePython;
          if (starterCodeJava) starterCode.java = starterCodeJava;
          if (starterCodeCpp) starterCode.cpp = starterCodeCpp;
          if (starterCodeC) starterCode.c = starterCodeC;
          
          // Parse hints (comma-separated or newline-separated)
          const hintsStr = getValue('hints');
          const hints = hintsStr ? hintsStr.split(/[,\n]/).map(h => h.trim()).filter(h => h) : [];
          
          const explanation = getValue('explanation');

          const questionObj = {
            title,
            description,
            type: 'coding',
            category: ['technical', 'interview', 'aptitude', 'logical', 'verbal'].includes(category) 
              ? category 
              : 'technical',
            difficulty: ['easy', 'medium', 'hard'].includes(difficulty) ? difficulty : 'medium',
            topic,
            timeLimit,
            points,
            problemStatement: problemStatement || description,
            constraints: constraints || undefined,
            inputFormat: inputFormat || undefined,
            outputFormat: outputFormat || undefined,
            sampleInput: sampleInput || undefined,
            sampleOutput: sampleOutput || undefined,
            testCases: testCases.length > 0 ? testCases : undefined,
            starterCode: Object.keys(starterCode).length > 0 ? starterCode : undefined,
            hints: hints.length > 0 ? hints : undefined,
            explanation: explanation || undefined,
            isActive: true
          };
          
          parsedQuestions.push(questionObj);
          return; // Exit early for coding questions
        }

        // Handle MCQ/Skill Assessment questions
        const option1 = getValue('option1');
        const option2 = getValue('option2');
        const option3 = getValue('option3');
        const option4 = getValue('option4');
        const correctAnswer = getValue('correctAnswer').trim();

        // Build options array for MCQ questions
        const options = [];
        if (option1) options.push({ text: option1, isCorrect: correctAnswer === option1 });
        if (option2) options.push({ text: option2, isCorrect: correctAnswer === option2 });
        if (option3) options.push({ text: option3, isCorrect: correctAnswer === option3 });
        if (option4) options.push({ text: option4, isCorrect: correctAnswer === option4 });

        // Validate that correct answer matches one of the options (for MCQ)
        if (type === 'mcq' && options.length > 0) {
          const hasCorrect = options.some(opt => opt.isCorrect);
          if (!hasCorrect && correctAnswer) {
            throw new Error(`Row ${rowNum}: Correct Answer "${correctAnswer}" does not match any of the provided options`);
          }
        }

        const questionObj = {
          title,
          description,
          type: type === 'mcq' ? 'mcq' : type,
          category: ['assessment', 'technical', 'interview', 'aptitude', 'logical', 'verbal'].includes(category) 
            ? category 
            : 'assessment',
          difficulty: ['easy', 'medium', 'hard'].includes(difficulty) ? difficulty : 'medium',
          topic,
          timeLimit,
          points,
          options: options.length > 0 ? options : undefined,
          explanation: getValue('explanation') || undefined,
          isActive: true
        };
          
        parsedQuestions.push(questionObj);
        } catch (rowError) {
          // Collect row-level errors instead of throwing immediately
          parsingErrors.push({
            row: index + 2,
            title: row[Object.keys(headerMap).find(h => headerMap[h] === 'title')] || 'Untitled',
            error: rowError.message
          });
        }
      });
      
      // If there are parsing errors and no valid questions, return error
      if (parsingErrors.length > 0 && parsedQuestions.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Failed to parse questions from Excel file',
          errors: parsingErrors
        });
      }
      
      questions = parsedQuestions;

    } else if (req.body.questions && Array.isArray(req.body.questions)) {
      // Handle JSON array upload (existing functionality)
      questions = req.body.questions;
    } else {
      return res.status(400).json({
        success: false,
        message: 'Please provide either an Excel file or a JSON array of questions'
      });
    }

    if (questions.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No questions found to upload'
      });
    }

    // Separate questions by type (NO PlacementQuestion - all questions go to CodingQuestion or SkillAssessmentQuestion)
    const codingQuestions = [];
    const skillAssessmentQuestions = [];
    let errors = parsingErrors || []; // Initialize errors array with parsing errors

    questions.forEach((q, index) => {
      try {
      const questionData = { 
        ...q, 
        createdBy: req.user?.id || req.adminId || req.admin?._id 
      };

      // IMPORTANT: Check type='coding' FIRST - coding questions always go to CodingQuestion
      // regardless of category
      if (q.type === 'coding') {
        // Coding questions - always go to CodingQuestion model
        // Clean up empty starterCode
        if (questionData.starterCode && typeof questionData.starterCode === 'object') {
          const hasAnyCode = Object.values(questionData.starterCode).some(code => code && code.trim());
          if (!hasAnyCode) {
            delete questionData.starterCode;
          }
        }

        // Clean up empty testCases
        if (questionData.testCases && Array.isArray(questionData.testCases)) {
          questionData.testCases = questionData.testCases.filter(tc => tc && (tc.input || tc.output));
          if (questionData.testCases.length === 0) {
            delete questionData.testCases;
          }
        }

        // Clean up empty hints
        if (questionData.hints && Array.isArray(questionData.hints)) {
          questionData.hints = questionData.hints.filter(h => h && h.trim());
          if (questionData.hints.length === 0) {
            delete questionData.hints;
          }
        }

        // Remove fields that don't exist in CodingQuestion schema
        delete questionData.type;
        delete questionData.questionId; // Remove if accidentally included
        delete questionData.question_id; // Remove if accidentally included (with underscore)
        delete questionData._id; // Remove if accidentally included
        
        // Ensure category is valid for CodingQuestion
        if (!['technical', 'interview', 'aptitude', 'logical', 'verbal'].includes(questionData.category)) {
          questionData.category = 'technical'; // Default to technical
        }
        
        // Ensure required fields are present
        if (!questionData.problemStatement) {
          questionData.problemStatement = questionData.description || questionData.title;
        }
        
        codingQuestions.push(questionData);
      } else if (q.category === 'assessment') {
        // Skill assessment questions (MCQ, subjective, behavioral - NOT coding)
        // Remove category field (always assessment for this model)
        delete questionData.category;
        
        // Ensure type is valid for SkillAssessmentQuestion (mcq, subjective, behavioral)
        if (!['mcq', 'subjective', 'behavioral'].includes(questionData.type)) {
          // Default to mcq if invalid type
          questionData.type = 'mcq';
        }
        
        skillAssessmentQuestions.push(questionData);
      } else if (['mcq', 'subjective', 'behavioral'].includes(q.type)) {
        // Questions with mcq/subjective/behavioral type (even without category) go to SkillAssessmentQuestion
        delete questionData.category;
        
        // Ensure type is valid
        if (!['mcq', 'subjective', 'behavioral'].includes(questionData.type)) {
          questionData.type = 'mcq';
        }
        
        skillAssessmentQuestions.push(questionData);
      } else {
        // Invalid question - skip it and log error
        const errorMsg = `Question type "${q.type}" and category "${q.category || 'none'}" are invalid. Must be coding or skill assessment.`;
        errors.push({
          row: questions.indexOf(q) + 1,
          title: q.title || 'Untitled',
          error: errorMsg
        });
      }
      } catch (processError) {
        errors.push({
          row: index + 1,
          title: q.title || 'Untitled',
          error: processError.message || 'Error processing question'
        });
      }
    });

    // Insert into appropriate models (NO PlacementQuestion)
    const results = await Promise.allSettled([
      codingQuestions.length > 0 ? CodingQuestion.insertMany(codingQuestions, { ordered: false }) : Promise.resolve([]),
      skillAssessmentQuestions.length > 0 ? SkillAssessmentQuestion.insertMany(skillAssessmentQuestions, { ordered: false }) : Promise.resolve([])
    ]);

    // Process results
    let totalInserted = 0;
    const breakdown = {
      coding: 0,
      skillAssessment: 0
    };

    results.forEach((result, index) => {
      if (result.status === 'fulfilled') {
        const count = Array.isArray(result.value) ? result.value.length : 0;
        totalInserted += count;
        if (index === 0) breakdown.coding = count;
        else if (index === 1) breakdown.skillAssessment = count;
      } else {
        // Ensure errors array exists before pushing
        if (!errors) errors = [];
        const errorDetails = {
          type: index === 0 ? 'coding' : 'skillAssessment',
          error: result.reason?.message || 'Unknown error',
          stack: result.reason?.stack
        };
        errors.push(errorDetails);
      }
    });

    // Calculate category breakdown for response
    const categoryBreakdown = {};
    questions.forEach(q => {
      const cat = q.category || 'unknown';
      categoryBreakdown[cat] = (categoryBreakdown[cat] || 0) + 1;
    });

    // Ensure errors is always an array
    if (!errors) errors = [];
    
    if (errors.length > 0 && totalInserted === 0) {
      return res.status(500).json({
        success: false,
        message: 'Failed to upload questions',
        errors
      });
    }

    res.status(201).json({
      success: true,
      message: `${totalInserted} questions uploaded successfully`,
      count: totalInserted,
      totalProcessed: questions.length,
      breakdown,
      categoryBreakdown,
      errors: errors && errors.length > 0 ? errors : undefined
    });
  } catch (error) {
    // Handle bulk write errors
    if (error.name === 'BulkWriteError' && error.writeErrors) {
      const insertedCount = error.result?.insertedCount || 0;
      const errorCount = error.writeErrors.length;
      return res.status(207).json({
        success: true,
        message: `Partially successful: ${insertedCount} questions uploaded, ${errorCount} failed`,
        count: insertedCount,
        errors: error.writeErrors.map(e => ({
          row: e.index + 1,
          error: e.errmsg || e.err?.message || 'Unknown error'
        }))
      });
    }

    // Handle validation errors
    if (error.name === 'ValidationError') {
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        error: error.message,
        details: Object.keys(error.errors || {}).map(key => ({
          field: key,
          message: error.errors[key].message
        }))
      });
    }

    // Handle Mongoose errors
    if (error.name === 'MongoError' || error.name === 'MongoServerError' || error.code === 11000) {
      // Handle duplicate key errors (including leftover indexes)
      if (error.code === 11000) {
        const errorMessage = error.message || '';
        if (errorMessage.includes('questionId') || errorMessage.includes('question_id')) {
          const indexName = errorMessage.includes('question_id') ? 'question_id_1' : 'questionId_1';
          return res.status(500).json({
            success: false,
            message: `Database index error: There is a leftover unique index on "${indexName.includes('_') ? 'question_id' : 'questionId'}" in the CodingQuestion collection. Please drop this index from MongoDB.`,
            error: `E11000 duplicate key error on ${indexName.includes('_') ? 'question_id' : 'questionId'} index`,
            solution: `Run this command in MongoDB: db.codingquestions.dropIndex("${indexName}") or run: node scripts/dropQuestionIdIndex.js`,
            code: error.code
          });
        }
      }
      
      return res.status(500).json({
        success: false,
        message: 'Database error occurred',
        error: error.message || 'An unexpected database error occurred',
        code: error.code
      });
    }

    res.status(500).json({
      success: false,
      message: 'Failed to upload questions',
      error: error.message || 'An unexpected error occurred',
      stack: process.env.NODE_ENV === 'development' ? error.stack : undefined,
      name: error.name
    });
  }
};

// ============ ADMIN - Module Management ============

export const createModule = async (req, res) => {
  try {
    const { title, description, moduleType, questions, resources, features, icon, color, order, isActive } = req.body;

    // Validate required fields
    if (!title || !title.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Module title is required'
      });
    }

    if (!description || !description.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Module description is required'
      });
    }

    if (!moduleType) {
      return res.status(400).json({
        success: false,
        message: 'Module type is required'
      });
    }

    // Validate moduleType enum
    const validModuleTypes = ['assessment', 'resume', 'technical', 'interview', 'placement', 'progress'];
    if (!validModuleTypes.includes(moduleType)) {
      return res.status(400).json({
        success: false,
        message: `Module type must be one of: ${validModuleTypes.join(', ')}`
      });
    }

    const moduleData = {
      title: title.trim(),
      description: description.trim(),
      moduleType,
      icon: icon || 'Brain',
      color: color || 'blue',
      order: order || 0,
      isActive: isActive !== undefined ? isActive : true,
      createdBy: req.user?.id || req.adminId || req.admin?._id
    };

    // Ensure questions array is properly formatted (array of ObjectIds)
    if (questions && Array.isArray(questions)) {
      // Filter out null/undefined and convert strings to ObjectIds
      moduleData.questions = questions
        .filter(q => q) // Remove null/undefined
        .map(q => {
          // If it's already an ObjectId, return it
          if (mongoose.Types.ObjectId.isValid(q)) {
            return typeof q === 'string' ? new mongoose.Types.ObjectId(q) : q;
          }
          return null;
        })
        .filter(q => q !== null); // Remove invalid ObjectIds
    } else {
      moduleData.questions = [];
    }

    // Ensure resources array is properly formatted
    if (resources && Array.isArray(resources)) {
      moduleData.resources = resources.filter(r => r && (r.title || r.url)); // Only keep resources with title or url
    } else {
      moduleData.resources = [];
    }

    // Ensure features array is properly formatted
    if (features && Array.isArray(features)) {
      moduleData.features = features.filter(f => f && f.trim()).map(f => f.trim()); // Only keep non-empty strings
    } else {
      moduleData.features = [];
    }

    const module = new PlacementModule(moduleData);
    await module.save();

    // Populate questions for response
    await module.populate('questions');

    res.status(201).json({
      success: true,
      message: 'Module created successfully',
      module
    });
  } catch (error) {
    // Handle validation errors
    if (error.name === 'ValidationError') {
      const validationErrors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        success: false,
        message: 'Validation error',
        error: validationErrors.join(', '),
        details: validationErrors
      });
    }

    // Handle duplicate key errors
    if (error.code === 11000) {
      return res.status(400).json({
        success: false,
        message: 'Module with this title already exists'
      });
    }

    res.status(500).json({
      success: false,
      message: 'Failed to create module',
      error: process.env.NODE_ENV === 'development' ? error.message : 'An error occurred while creating the module'
    });
  }
};

export const getAllModules = async (req, res) => {
  try {
    const { isActive } = req.query;
    const filter = {};
    
    if (isActive !== undefined) {
      filter.isActive = isActive === 'true';
    }

    const modules = await PlacementModule.find(filter)
      .sort({ order: 1 })
      .lean(); // Use lean() for better performance since we'll manually populate

    // For each module, fetch questions from all three models
    const modulesWithQuestions = await Promise.all(
      modules.map(async (module) => {
        const questionIds = module.questions || [];
        
        if (questionIds.length === 0) {
          return {
            ...module,
            questions: [],
            questionCount: 0
          };
        }

        // Fetch questions from all three models
        const [placementQuestions, codingQuestions, skillAssessmentQuestions] = await Promise.all([
          PlacementQuestion.find({ _id: { $in: questionIds } }).lean(),
          CodingQuestion.find({ _id: { $in: questionIds } }).lean(),
          SkillAssessmentQuestion.find({ _id: { $in: questionIds } }).lean()
        ]);

        // Combine all questions (they're already ObjectIds, so we just need to verify they exist)
        const allQuestions = [
          ...placementQuestions,
          ...codingQuestions,
          ...skillAssessmentQuestions
        ];

        return {
          ...module,
          questions: allQuestions, // Return populated questions
          questionCount: allQuestions.length
        };
      })
    );

    res.json({
      success: true,
      count: modulesWithQuestions.length,
      modules: modulesWithQuestions
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch modules',
      error: error.message
    });
  }
};

export const updateModule = async (req, res) => {
  try {
    const { title, description, moduleType, questions, resources, features, icon, color, order, isActive } = req.body;
    const updateData = {};

    // Only update fields that are provided
    if (title !== undefined) updateData.title = title.trim();
    if (description !== undefined) updateData.description = description.trim();
    if (moduleType !== undefined) {
      // Validate moduleType enum
      const validModuleTypes = ['assessment', 'resume', 'technical', 'interview', 'placement', 'progress'];
      if (!validModuleTypes.includes(moduleType)) {
        return res.status(400).json({
          success: false,
          message: `Module type must be one of: ${validModuleTypes.join(', ')}`
        });
      }
      updateData.moduleType = moduleType;
    }
    if (icon !== undefined) updateData.icon = icon;
    if (color !== undefined) updateData.color = color;
    if (order !== undefined) updateData.order = order;
    if (isActive !== undefined) updateData.isActive = isActive;

    // Ensure questions array is properly formatted (array of ObjectIds)
    if (questions !== undefined) {
      if (Array.isArray(questions)) {
        // Filter out null/undefined and convert strings to ObjectIds
        updateData.questions = questions
          .filter(q => q) // Remove null/undefined
          .map(q => {
            // If it's already an ObjectId, return it
            if (mongoose.Types.ObjectId.isValid(q)) {
              return typeof q === 'string' ? new mongoose.Types.ObjectId(q) : q;
            }
            return null;
          })
          .filter(q => q !== null); // Remove invalid ObjectIds
      } else {
        updateData.questions = [];
      }
    }

    // Ensure resources array is properly formatted
    if (resources !== undefined) {
      if (Array.isArray(resources)) {
        updateData.resources = resources.filter(r => r && (r.title || r.url)); // Only keep resources with title or url
      } else {
        updateData.resources = [];
      }
    }

    // Ensure features array is properly formatted
    if (features !== undefined) {
      if (Array.isArray(features)) {
        updateData.features = features.filter(f => f && f.trim()).map(f => f.trim()); // Only keep non-empty strings
      } else {
        updateData.features = [];
      }
    }

    const module = await PlacementModule.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!module) {
      return res.status(404).json({
        success: false,
        message: 'Module not found'
      });
    }

    // Populate questions for response
    await module.populate('questions');

    res.json({
      success: true,
      message: 'Module updated successfully',
      module
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update module',
      error: error.message
    });
  }
};

export const deleteModule = async (req, res) => {
  try {
    const module = await PlacementModule.findByIdAndDelete(req.params.id);

    if (!module) {
      return res.status(404).json({
        success: false,
        message: 'Module not found'
      });
    }

    res.json({
      success: true,
      message: 'Module deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete module',
      error: error.message
    });
  }
};

// ============ STUDENT - Access & Progress ============

export const getStudentModules = async (req, res) => {
  try {
    
    const studentId = req.studentId || req.student?._id || req.user?.id;
    
    if (!studentId) {
      return res.status(400).json({
        success: false,
        message: 'Student ID not found in request'
      });
    }
    
    const modules = await PlacementModule.find({ isActive: true })
      .select('-questions')
      .sort({ order: 1 });

    // Get student progress
    let progress = await PlacementProgress.findOne({ studentId });

    if (!progress) {
      // Create initial progress record
      progress = new PlacementProgress({
        studentId,
        moduleProgress: modules.map(m => ({
          moduleId: m._id,
          status: 'not-started',
          progress: 0
        }))
      });
      await progress.save();
    }

    // Merge modules with progress
    const modulesWithProgress = modules.map(module => {
      const moduleProgress = progress.moduleProgress.find(
        mp => mp.moduleId.toString() === module._id.toString()
      );
      
      return {
        ...module.toObject(),
        status: moduleProgress?.status || 'not-started',
        progress: moduleProgress?.progress || 0
      };
    });

    // Calculate achievements
    const completedModules = modulesWithProgress.filter(m => m.status === 'completed').length;
    const totalModulesCount = modules.length;
    const achievements = [
      {
        title: 'Assessment Master',
        description: 'Complete all skill assessments',
        progress: completedModules,
        total: totalModulesCount,
        completed: completedModules >= totalModulesCount && totalModulesCount > 0
      },
      {
        title: 'Code Warrior',
        description: 'Solve 100 coding problems',
        progress: progress.codingProblemsSolved || 0,
        total: 100,
        completed: (progress.codingProblemsSolved || 0) >= 100
      },
      {
        title: 'Interview Pro',
        description: 'Complete 10 mock interviews',
        progress: progress.mockInterviewsCompleted || 0,
        total: 10,
        completed: (progress.mockInterviewsCompleted || 0) >= 10
      },
      {
        title: 'Project Builder',
        description: 'Complete 5 projects',
        progress: progress.projectsCompleted || 0,
        total: 5,
        completed: (progress.projectsCompleted || 0) >= 5
      },
      {
        title: 'Consistent Learner',
        description: 'Maintain 30 day learning streak',
        progress: progress.learningStreak || 0,
        total: 30,
        completed: (progress.learningStreak || 0) >= 30
      }
    ];

    // Get recent activities from question attempts (last 10)
    const recentActivities = [];
    if (progress.questionAttempts && progress.questionAttempts.length > 0) {
      const last10Attempts = progress.questionAttempts.slice(-10);
      const questionIds = last10Attempts.map(a => a.questionId);
      
      // Fetch questions from all three models
      const [placementQuestions, codingQuestions, skillAssessmentQuestions] = await Promise.all([
        PlacementQuestion.find({ _id: { $in: questionIds } }).lean(),
        CodingQuestion.find({ _id: { $in: questionIds } }).lean(),
        SkillAssessmentQuestion.find({ _id: { $in: questionIds } }).lean()
      ]);
      
      // Create a map for quick lookup (combine all questions)
      const questionMap = {};
      [...placementQuestions, ...codingQuestions, ...skillAssessmentQuestions].forEach(q => {
        questionMap[q._id.toString()] = q;
      });
      
      // Map attempts to activities
      const activities = last10Attempts.map((attempt) => {
        const question = questionMap[attempt.questionId.toString()];
        if (!question) return null;
        
        const timeAgo = calculateTimeAgo(attempt.attemptedAt);
        
        // Determine question type
        let questionType = 'question';
        if (question.problemStatement || question.testCases) {
          questionType = 'coding';
        } else if (question.category === 'assessment' || question.type === 'behavioral') {
          questionType = 'assessment';
        } else if (question.type === 'coding') {
          questionType = 'coding';
        }
        
        return {
          title: question.title || question.problemStatement || 'Question Attempt',
          type: questionType,
          points: attempt.pointsEarned || 0,
          time: timeAgo
        };
      }).filter(Boolean);
      
      recentActivities.push(...activities.slice(0, 4));
    }

    res.json({
      success: true,
      modules: modulesWithProgress,
      overallProgress: {
        assessmentCompleted: progress.assessmentCompleted,
        codingProblemsSolved: progress.codingProblemsSolved,
        mockInterviewsCompleted: progress.mockInterviewsCompleted,
        projectsCompleted: progress.projectsCompleted,
        learningStreak: progress.learningStreak,
        totalPoints: progress.totalPoints
      },
      achievements,
      recentActivities
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch modules',
      error: error.message
    });
  }
};

export const getModuleQuestions = async (req, res) => {
  try {
    const { moduleId } = req.params;
    const { difficulty, topic } = req.query;

    const module = await PlacementModule.findById(moduleId);

    if (!module || !module.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Module not found or inactive'
      });
    }

    // Get question IDs from module
    const questionIds = module.questions || [];

    if (questionIds.length === 0) {
      return res.json({
        success: true,
        module: {
          _id: module._id,
          title: module.title,
          description: module.description,
          moduleType: module.moduleType
        },
        questions: []
      });
    }

    // Fetch questions from all three models
    const [placementQuestions, codingQuestions, skillAssessmentQuestions] = await Promise.all([
      PlacementQuestion.find({ _id: { $in: questionIds }, isActive: true }).lean(),
      CodingQuestion.find({ _id: { $in: questionIds }, isActive: true }).lean(),
      SkillAssessmentQuestion.find({ _id: { $in: questionIds }, isActive: true }).lean()
    ]);

    // Combine all questions and tag them with their type
    const allQuestions = [
      ...placementQuestions.map(q => ({ ...q, questionType: 'placement', type: q.type || 'mcq' })),
      ...codingQuestions.map(q => ({ ...q, questionType: 'coding', type: 'coding' })),
      ...skillAssessmentQuestions.map(q => ({ ...q, questionType: 'skillAssessment', type: q.type || 'mcq', category: 'assessment' }))
    ];

    // Filter by difficulty and topic if provided
    let filteredQuestions = allQuestions;
    if (difficulty) {
      filteredQuestions = filteredQuestions.filter(q => q.difficulty === difficulty);
    }
    if (topic) {
      filteredQuestions = filteredQuestions.filter(q => q.topic === topic);
    }

    // Remove sensitive data for students
    const sanitizedQuestions = filteredQuestions.map(q => {
      const qObj = { ...q };
      
      // For MCQ, don't send correct answers
      if (qObj.type === 'mcq' && qObj.options) {
        qObj.options = qObj.options.map(opt => ({
          text: opt.text,
          _id: opt._id
        }));
      }
      
      // For coding, hide test case outputs
      if (qObj.testCases) {
        qObj.testCases = qObj.testCases.filter(tc => !tc.isHidden).map(tc => ({
          input: tc.input,
          output: tc.output
        }));
      }
      
      // For skill assessment MCQ, don't send correct answers
      if (qObj.questionType === 'skillAssessment' && qObj.type === 'mcq' && qObj.options) {
        qObj.options = qObj.options.map(opt => ({
          text: opt.text,
          _id: opt._id
        }));
      }
      
      delete qObj.explanation;
      return qObj;
    });

    res.json({
      success: true,
      module: {
        _id: module._id,
        title: module.title,
        description: module.description,
        moduleType: module.moduleType
      },
      questions: sanitizedQuestions
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch questions',
      error: error.message
    });
  }
};

export const submitAnswer = async (req, res) => {
  try {
    const { questionId, answer, code, language, timeTaken } = req.body;
    const studentId = req.studentId || req.student?._id || req.user?.id;

    // Try to find question in all three models
    let question = await PlacementQuestion.findById(questionId);
    let questionType = 'placement';
    
    if (!question) {
      question = await CodingQuestion.findById(questionId);
      if (question) {
        questionType = 'coding';
      }
    }
    
    if (!question) {
      question = await SkillAssessmentQuestion.findById(questionId);
      if (question) {
        questionType = 'skillAssessment';
      }
    }

    if (!question) {
      return res.status(404).json({
        success: false,
        message: 'Question not found'
      });
    }

    let isCorrect = false;
    let pointsEarned = 0;
    let feedback = '';

    // Check answer based on question type
    let testResults = []; // Initialize for coding questions
    
    // Determine if this is a coding question (from CodingQuestion model or has coding fields)
    const isCodingQuestion = questionType === 'coding' || question.problemStatement || question.testCases;
    
    // Determine if this is an MCQ question
    const isMcqQuestion = (question.type === 'mcq' || (questionType === 'skillAssessment' && question.type === 'mcq')) && question.options;
    
    // Determine if this is a subjective/behavioral question (text answer)
    const isSubjectiveQuestion = question.type === 'subjective' || question.type === 'behavioral';
    
    if (isMcqQuestion) {
      const selectedOption = question.options.find(opt => opt._id.toString() === answer);
      isCorrect = selectedOption && selectedOption.isCorrect;
      if (isCorrect) {
        pointsEarned = question.points || 10;
        feedback = 'Correct answer!';
      } else {
        feedback = 'Incorrect answer. ' + (question.explanation || '');
      }
    } else if (isCodingQuestion) {
      // Execute code with Judge0 against test cases
      if (!code || !language) {
        return res.status(400).json({
          success: false,
          message: 'Code and language are required for coding questions'
        });
      }

      // Run code against all test cases
      if (question.testCases && question.testCases.length > 0) {
        let passedTests = 0;
        
        for (const testCase of question.testCases) {
          const executionResult = await executeCodeWithJudge0(code, language, testCase.input);
          
          if (!executionResult.success) {
            feedback = executionResult.error;
            isCorrect = false;
            pointsEarned = 0;
            break;
          }

          // Check if output matches expected output (trim whitespace)
          const actualOutput = (executionResult.stdout || '').trim();
          const expectedOutput = testCase.output.trim();
          const testPassed = actualOutput === expectedOutput;
          
          testResults.push({
            input: testCase.input,
            expected: expectedOutput,
            actual: actualOutput,
            passed: testPassed
          });

          if (testPassed) {
            passedTests++;
          }
        }

        // Calculate score based on passed tests
        const passRate = passedTests / question.testCases.length;
        isCorrect = passRate === 1; // All tests must pass for full credit
        pointsEarned = isCorrect ? question.points : Math.round(question.points * passRate * 0.5); // 50% partial credit for partial pass
        
        if (isCorrect) {
          feedback = `All ${passedTests} test cases passed! Great job!`;
        } else if (passedTests > 0) {
          feedback = `Only ${passedTests}/${question.testCases.length} test cases passed. Keep trying!`;
        } else {
          feedback = 'None of the test cases passed. Check your logic and try again.';
        }

        // Add execution details to feedback
        if (testResults.length > 0 && testResults[0].actual) {
          feedback += ` Test result: ${testResults[0].actual.substring(0, 50)}${testResults[0].actual.length > 50 ? '...' : ''}`;
        }
      } else {
        // No test cases - just execute to check for compilation errors
        const executionResult = await executeCodeWithJudge0(code, language, '');
        
        if (!executionResult.success) {
          feedback = `Compilation error: ${executionResult.error}`;
          isCorrect = false;
          pointsEarned = 0;
        } else if (executionResult.stderr || executionResult.compile_output) {
          feedback = `Runtime error: ${executionResult.stderr || executionResult.compile_output}`;
          isCorrect = false;
          pointsEarned = Math.round(question.points * 0.25); // 25% for attempting
        } else {
          feedback = 'Code executed successfully! (No test cases configured)';
          isCorrect = true;
          pointsEarned = question.points;
        }
      }
    } else if (isSubjectiveQuestion) {
      // For subjective/behavioral questions, accept any answer (manual review later)
      // For now, give partial credit if answer is provided
      if (answer && answer.trim().length > 10) {
        isCorrect = true; // Mark as correct if substantial answer provided
        pointsEarned = question.points || 10;
        feedback = 'Answer submitted successfully! This will be reviewed manually.';
      } else {
        isCorrect = false;
        pointsEarned = 0;
        feedback = 'Please provide a more detailed answer (at least 10 characters).';
      }
    } else {
      // Fallback for other question types
      feedback = 'Question type not supported for automatic grading.';
      isCorrect = false;
      pointsEarned = 0;
    }

    // Update student progress
    let progress = await PlacementProgress.findOne({ studentId });
    
    if (!progress) {
      progress = new PlacementProgress({ studentId });
    }

    // Check if this question was already solved correctly by this student
    const previouslySolved = progress.questionAttempts.some(
      attempt => attempt.questionId.toString() === questionId.toString() && attempt.isCorrect
    );

    // Store the original points earned for the response
    const originalPointsEarned = pointsEarned;
    
    // Calculate points to add to total (may be 0 if question was already solved correctly)
    let pointsToAdd = 0;
    
    // Award points if:
    // 1. Points were earned (correct answer OR partial credit for coding) AND
    // 2. The student hasn't already solved this problem before (for full credit only)
    // Note: For partial credit on coding questions, we still award points even if not fully correct
    if (pointsEarned > 0) {
      // Check if this is a repeat attempt of a previously fully solved question
      if (isCorrect && previouslySolved) {
        // Don't award points again for a question already solved correctly
        pointsToAdd = 0;
      } else {
        // Award points for:
        // - First correct answer
        // - Partial credit on coding questions (even if not fully correct)
        // - First attempt on subjective questions
        pointsToAdd = pointsEarned;
        progress.totalPoints += pointsToAdd;
        
        // Only increment solved count for fully correct answers
        if (isCorrect && (isCodingQuestion || questionType === 'coding')) {
          progress.codingProblemsSolved += 1;
        }
      }
    }

    const newAttempt = {
      questionId,
      attemptedAt: new Date(),
      isCorrect,
      timeTaken,
      answer,
      code,
      language,
      pointsEarned: originalPointsEarned, // Store original points earned for this attempt
      pointsAdded: pointsToAdd // Store points actually added to total (for accurate tracking)
    };
    
    progress.questionAttempts.push(newAttempt);

    await progress.save();

    res.json({
      success: true,
      isCorrect,
      pointsEarned: originalPointsEarned, // Return the points earned for this attempt
      pointsAdded: pointsToAdd, // Return the points actually added to total (0 if already solved)
      feedback,
      explanation: isCorrect ? question.explanation : undefined,
      totalPoints: progress.totalPoints,
      testResults: testResults || undefined, // Include detailed test case results
      totalTestCases: question.testCases?.length || 0,
      passedTestCases: testResults ? testResults.filter(t => t.passed).length : 0,
      attemptId: progress.questionAttempts[progress.questionAttempts.length - 1]._id // Return the newly created attempt ID
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to submit answer',
      error: error.message
    });
  }
};

export const getStudentProgress = async (req, res) => {
  try {
    const studentId = req.studentId || req.student?._id || req.user?.id;
    
    let progress = await PlacementProgress.findOne({ studentId })
      .populate('moduleProgress.moduleId', 'title moduleType');

    if (!progress) {
      progress = new PlacementProgress({ studentId });
      await progress.save();
    }

    res.json({
      success: true,
      progress
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch progress',
      error: error.message
    });
  }
};

export const updateModuleProgress = async (req, res) => {
  try {
    const { moduleId, status, progress: progressValue } = req.body;
    const studentId = req.studentId || req.student?._id || req.user?.id;

    // Validate required fields
    if (!moduleId) {
      return res.status(400).json({
        success: false,
        message: 'Module ID is required'
      });
    }

    if (!status) {
      return res.status(400).json({
        success: false,
        message: 'Status is required'
      });
    }

    if (!studentId) {
      return res.status(401).json({
        success: false,
        message: 'Student ID is required'
      });
    }

    // Validate moduleId format
    if (!mongoose.Types.ObjectId.isValid(moduleId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid module ID format'
      });
    }

    let progress = await PlacementProgress.findOne({ studentId });
    
    if (!progress) {
      progress = new PlacementProgress({ studentId });
    }

    // Get module details to check if it's an assessment
    const module = await PlacementModule.findById(moduleId);
    
    if (!module) {
      return res.status(404).json({
        success: false,
        message: 'Module not found'
      });
    }

    const isAssessmentModule = module && module.moduleType === 'assessment';

    const moduleProgressIndex = progress.moduleProgress.findIndex(
      mp => mp.moduleId.toString() === moduleId
    );

    if (moduleProgressIndex >= 0) {
      progress.moduleProgress[moduleProgressIndex].status = status;
      progress.moduleProgress[moduleProgressIndex].progress = progressValue;
      
      if (status === 'completed') {
        progress.moduleProgress[moduleProgressIndex].completedAt = new Date();
        
        // Mark assessment as completed if this is an assessment module
        if (isAssessmentModule) {
          progress.assessmentCompleted = true;
        }
      } else if (status === 'in-progress' && !progress.moduleProgress[moduleProgressIndex].startedAt) {
        progress.moduleProgress[moduleProgressIndex].startedAt = new Date();
      }
    } else {
      progress.moduleProgress.push({
        moduleId,
        status,
        progress: progressValue,
        startedAt: status !== 'not-started' ? new Date() : undefined,
        completedAt: status === 'completed' ? new Date() : undefined
      });
      
      // Mark assessment as completed if this is an assessment module and status is completed
      if (isAssessmentModule && status === 'completed') {
        progress.assessmentCompleted = true;
      }
    }

    await progress.save();

    res.json({
      success: true,
      message: 'Progress updated successfully',
      progress
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update progress',
      error: process.env.NODE_ENV === 'development' ? error.message : 'An error occurred while updating progress'
    });
  }
};

export const deleteSubmission = async (req, res) => {
  try {
    const { attemptId } = req.params;
    const studentId = req.studentId || req.student?._id || req.user?.id;

    const progress = await PlacementProgress.findOne({ studentId });
    
    if (!progress) {
      return res.status(404).json({
        success: false,
        message: 'Progress not found'
      });
    }

    // Find and remove the question attempt
    const attemptIndex = progress.questionAttempts.findIndex(
      attempt => attempt._id.toString() === attemptId
    );

    if (attemptIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'Submission not found'
      });
    }

    const deletedAttempt = progress.questionAttempts[attemptIndex];
    
    // Remove the attempt
    progress.questionAttempts.splice(attemptIndex, 1);
    
    // If the deleted attempt was correct and was counted towards points, recalculate totals
    // Note: We don't decrement points here because the student already earned them
    // This is just a cleanup operation for their submission history
    
    await progress.save();

    res.json({
      success: true,
      message: 'Submission deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete submission',
      error: error.message
    });
  }
};

// ============ STUDENT - Coding Questions ============

export const runCode = async (req, res) => {
  try {
    const { code, language, stdin } = req.body;

    if (!code || !language) {
      return res.status(400).json({
        success: false,
        message: 'Code and language are required'
      });
    }


    const executionResult = await executeCodeWithJudge0(code, language, stdin || '');

    if (!executionResult.success) {
      return res.status(400).json({
        success: false,
        message: executionResult.error
      });
    }

    res.json({
      success: true,
      output: executionResult.stdout,
      error: executionResult.stderr || executionResult.compile_output,
      time: executionResult.time,
      memory: executionResult.memory,
      status: executionResult.status
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to execute code',
      error: error.message
    });
  }
};

export const getCodingQuestions = async (req, res) => {
  try {
    const { category, difficulty, topic, search, company, tag } = req.query;
    
    // IMPORTANT: Fetch ONLY from CodingQuestion model (separate table)
    // CodingQuestion model does NOT have a 'type' field - all records are coding questions
    const filter = { isActive: { $ne: false } }; // Only active questions (true, undefined, or null)
    if (category) filter.category = category;
    if (difficulty) filter.difficulty = difficulty;
    if (topic) filter.topic = topic;
    
    // Company filter
    if (company) {
      filter.companies = { $in: [company] };
    }
    
    // Tag filter
    if (tag) {
      filter.tags = { $in: [tag] };
    }
    
    // Search filter
    if (search) {
      filter.$or = [
        { title: { $regex: search, $options: 'i' } },
        { problemStatement: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } }
      ];
    }

    const codingQuestions = await CodingQuestion.find(filter)
      .select('-createdBy') // Don't expose admin info
      .sort({ createdAt: -1 });

    // Sanitize questions - hide test cases and other sensitive info
    const sanitizedQuestions = codingQuestions.map(q => {
      const qObj = q.toObject ? q.toObject() : q; // Handle both Mongoose documents and plain objects
      
      // Remove explanation
      delete qObj.explanation;
      
      // Hide test cases from students (only show for display, not the actual test cases used for evaluation)
      if (qObj.testCases) {
        qObj.testCases = undefined;
      }
      
      return qObj;
    });

    res.json({
      success: true,
      count: sanitizedQuestions.length,
      questions: sanitizedQuestions
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch coding questions',
      error: error.message
    });
  }
};

// ============ ADMIN - Statistics ============

export const getPlacementStats = async (req, res) => {
  try {
    const [placementCount, codingCount, skillAssessmentCount] = await Promise.all([
      PlacementQuestion.countDocuments(),
      CodingQuestion.countDocuments(),
      SkillAssessmentQuestion.countDocuments()
    ]);
    const totalQuestions = placementCount + codingCount + skillAssessmentCount;
    const totalModules = await PlacementModule.countDocuments();
    const activeStudents = await PlacementProgress.countDocuments({
      lastActivityDate: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
    });

    // Calculate completion rate
    const totalStudentsWithProgress = await PlacementProgress.countDocuments();
    const completedModulesCount = await PlacementProgress.aggregate([
      { $unwind: '$moduleProgress' },
      { $match: { 'moduleProgress.status': 'completed' } },
      { $count: 'completedCount' }
    ]);
    
    const totalPossibleCompletions = totalStudentsWithProgress * totalModules;
    const completionRate = totalPossibleCompletions > 0 
      ? Math.round(((completedModulesCount[0]?.completedCount || 0) / totalPossibleCompletions) * 100)
      : 0;

    // Calculate top performer score
    const topScoreResult = await PlacementProgress.aggregate([
      { $unwind: '$questionAttempts' },
      { $group: { _id: '$studentId', maxScore: { $max: '$questionAttempts.pointsEarned' } } },
      { $sort: { maxScore: -1 } },
      { $limit: 1 }
    ]);
    const topScore = topScoreResult.length > 0 ? Math.round(topScoreResult[0].maxScore) : 0;

    // Calculate average time per assessment
    const avgTimeResult = await PlacementProgress.aggregate([
      { $unwind: '$questionAttempts' },
      { $match: { 'questionAttempts.timeTaken': { $exists: true, $gt: 0 } } },
      { $group: { _id: null, avgTime: { $avg: '$questionAttempts.timeTaken' } } }
    ]);
    const averageTime = avgTimeResult.length > 0 ? Math.round(avgTimeResult[0].avgTime) : 0;

    // Calculate average score across all attempts
    const avgScoreResult = await PlacementProgress.aggregate([
      { $unwind: '$questionAttempts' },
      { $group: { _id: null, avgScore: { $avg: '$questionAttempts.pointsEarned' } } }
    ]);
    const averageScore = avgScoreResult.length > 0 ? Math.round(avgScoreResult[0].avgScore) : 0;

    // Get questions by category from all models
    const [placementByCategory, codingByCategory] = await Promise.all([
      PlacementQuestion.aggregate([{ $group: { _id: '$category', count: { $sum: 1 } } }]),
      CodingQuestion.aggregate([{ $group: { _id: '$category', count: { $sum: 1 } } }])
    ]);
    
    // Combine category counts
    const questionsByCategory = {};
    [...placementByCategory, ...codingByCategory].forEach(item => {
      questionsByCategory[item._id] = (questionsByCategory[item._id] || 0) + item.count;
    });
    // Add skill assessment count
    if (skillAssessmentCount > 0) {
      questionsByCategory['assessment'] = (questionsByCategory['assessment'] || 0) + skillAssessmentCount;
    }

    // Get questions by difficulty from all models
    const [placementByDifficulty, codingByDifficulty, skillAssessmentByDifficulty] = await Promise.all([
      PlacementQuestion.aggregate([{ $group: { _id: '$difficulty', count: { $sum: 1 } } }]),
      CodingQuestion.aggregate([{ $group: { _id: '$difficulty', count: { $sum: 1 } } }]),
      SkillAssessmentQuestion.aggregate([{ $group: { _id: '$difficulty', count: { $sum: 1 } } }])
    ]);
    
    // Combine difficulty counts
    const questionsByDifficulty = {};
    [...placementByDifficulty, ...codingByDifficulty, ...skillAssessmentByDifficulty].forEach(item => {
      questionsByDifficulty[item._id] = (questionsByDifficulty[item._id] || 0) + item.count;
    });

    res.json({
      success: true,
      stats: {
        totalQuestions,
        totalModules,
        activeStudents,
        completionRate,
        topScore,
        averageTime,
        averageScore,
        questionsByCategory,
        questionsByDifficulty
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch statistics',
      error: error.message
    });
  }
};

// Get Skill Assessment Questions for Students
export const getStudentSkillAssessments = async (req, res) => {
  try {
    // IMPORTANT: Fetch from SkillAssessmentQuestion model (separate table)
    const skillAssessmentQuestions = await SkillAssessmentQuestion.find({
      isActive: { $ne: false } // Only active questions (true, undefined, or null)
    })
      .select('-explanation')
      .sort({ createdAt: -1 })
      .lean();
    
    // Validate question types - SkillAssessmentQuestion should only have: mcq, subjective, behavioral
    const invalidQuestions = skillAssessmentQuestions.filter(q => 
      !['mcq', 'subjective', 'behavioral'].includes(q.type)
    );
    if (invalidQuestions.length > 0) {
      // Invalid types detected; they will be filtered out below
    }
    
    // Filter out any invalid types (shouldn't happen, but safety check)
    const questions = skillAssessmentQuestions.filter(q => 
      ['mcq', 'subjective', 'behavioral'].includes(q.type)
    );

    // Group questions by topic for better organization
    const questionsByTopic = {};
    (questions || []).forEach(q => {
      const topic = q.topic || 'General';
      if (!questionsByTopic[topic]) {
        questionsByTopic[topic] = [];
      }
      // Sanitize MCQ options (remove correct answers)
      if (q.type === 'mcq' && q.options && Array.isArray(q.options)) {
        q.options = q.options.map(opt => ({
          text: opt.text,
          _id: opt._id
        }));
      }
      questionsByTopic[topic].push({
        ...q,
        questionType: 'skillAssessment',
        category: 'assessment'
      });
    });

    // Check modules that contain skill assessment questions
    // Include questions from both SkillAssessmentQuestion and PlacementQuestion (for migration)
    const allModules = await PlacementModule.find({ isActive: true }).lean();
    const skillAssessmentQuestionIds = (questions || []).map(q => q._id?.toString()).filter(Boolean);
    
    // Get all valid SkillAssessmentQuestion IDs from database
    const allSkillAssessmentIds = await SkillAssessmentQuestion.find({})
      .select('_id')
      .lean()
      .then(ids => ids.map(q => q._id.toString()));
    
    // Get student progress for module status and assessment history
    const studentId = req.studentId || req.student?._id || req.user?.id;
    let studentProgress = null;
    if (studentId) {
      studentProgress = await PlacementProgress.findOne({ studentId }).lean();
    }
    
    // For each module, check if it has skill assessment questions
    const modulesWithSkillAssessments = [];
    if (skillAssessmentQuestionIds.length > 0 && allModules.length > 0) {
      for (const module of allModules) {
        const moduleQuestionIds = (module.questions || []).map(q => {
          if (typeof q === 'object' && q._id) {
            return q._id.toString();
          }
          return q.toString();
        }).filter(Boolean);
        
        // Check if any module question IDs exist in either SkillAssessmentQuestion or PlacementQuestion (assessment)
        const skillAssessmentIdsInModule = moduleQuestionIds.filter(id => 
          skillAssessmentQuestionIds.includes(id) // Include both migrated and unmigrated questions
        );
        
        if (skillAssessmentIdsInModule.length > 0) {
          // Get module progress for this student
          const moduleProgress = studentProgress?.moduleProgress?.find(
            mp => mp.moduleId?.toString() === module._id.toString()
          );
          
          // Get question attempts for this module's questions
          const moduleAttempts = studentProgress?.questionAttempts?.filter(attempt => 
            skillAssessmentIdsInModule.includes(attempt.questionId?.toString())
          ) || [];
          
          // Calculate assessment stats
          const totalAttempts = moduleAttempts.length;
          const correctAnswers = moduleAttempts.filter(a => a.isCorrect).length;
          const totalPoints = moduleAttempts.reduce((sum, a) => sum + (a.pointsEarned || 0), 0);
          const lastAttempt = moduleAttempts.length > 0 
            ? moduleAttempts.sort((a, b) => new Date(b.attemptedAt) - new Date(a.attemptedAt))[0]
            : null;
          
          modulesWithSkillAssessments.push({
            _id: module._id,
            title: module.title || 'Untitled Module',
            description: module.description || '',
            moduleType: module.moduleType || 'assessment',
            questionCount: skillAssessmentIdsInModule.length,
            // Student progress
            status: moduleProgress?.status || 'not-started',
            progress: moduleProgress?.progress || 0,
            startedAt: moduleProgress?.startedAt,
            completedAt: moduleProgress?.completedAt,
            // Assessment history
            assessmentHistory: {
              totalAttempts,
              correctAnswers,
              totalPoints,
              lastAttempt: lastAttempt ? {
                attemptedAt: lastAttempt.attemptedAt,
                isCorrect: lastAttempt.isCorrect,
                pointsEarned: lastAttempt.pointsEarned
              } : null
            }
          });
        }
      }
    }
    
    const response = {
      success: true,
      questions: questions || [],
      questionsByTopic: questionsByTopic || {},
      modules: modulesWithSkillAssessments || [],
      totalQuestions: (questions || []).length
    };
    
    res.json(response);
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch skill assessment questions',
      error: error.message
    });
  }
};

// Migrate questions from PlacementQuestion to correct tables
export const migrateQuestionsFromPlacementTable = async (req, res) => {
  try {
    // Find all questions in PlacementQuestion
    const allPlacementQuestions = await PlacementQuestion.find({}).lean();
    
    const questionsToMigrate = {
      coding: [],
      skillAssessment: [],
      other: []
    };
    
    // Categorize questions
    for (const question of allPlacementQuestions) {
      const questionData = { ...question };
      delete questionData._id; // Remove _id, will get new one
      delete questionData.__v;
      
      if (question.type === 'coding') {
        // Coding questions go to CodingQuestion
        // Remove type and category fields (not in CodingQuestion schema)
        delete questionData.type;
        delete questionData.category;
        
        // Clean up empty starterCode
        if (questionData.starterCode && typeof questionData.starterCode === 'object') {
          const hasAnyCode = Object.values(questionData.starterCode).some(code => code && code.trim());
          if (!hasAnyCode) {
            delete questionData.starterCode;
          }
        }
        
        // Clean up empty testCases
        if (questionData.testCases && Array.isArray(questionData.testCases)) {
          questionData.testCases = questionData.testCases.filter(tc => tc && (tc.input || tc.output));
          if (questionData.testCases.length === 0) {
            delete questionData.testCases;
          }
        }
        
        // Clean up empty hints
        if (questionData.hints && Array.isArray(questionData.hints)) {
          questionData.hints = questionData.hints.filter(h => h && h.trim());
          if (questionData.hints.length === 0) {
            delete questionData.hints;
          }
        }
        
        questionsToMigrate.coding.push({
          oldId: question._id,
          data: questionData
        });
      } else if (question.category === 'assessment') {
        // Skill assessment questions go to SkillAssessmentQuestion
        delete questionData.category;
        
        // Ensure type is valid for SkillAssessmentQuestion
        if (!['mcq', 'subjective', 'behavioral'].includes(questionData.type)) {
          questionData.type = 'mcq'; // Default to mcq
        }
        
        questionsToMigrate.skillAssessment.push({
          oldId: question._id,
          data: questionData
        });
      } else {
        // Other questions stay in PlacementQuestion (for backward compatibility)
        questionsToMigrate.other.push({
          oldId: question._id,
          data: questionData
        });
      }
    }
    
    // Migrate coding questions
    const codingMigrationMap = {}; // oldId -> newId
    if (questionsToMigrate.coding.length > 0) {
      const codingData = questionsToMigrate.coding.map(q => q.data);
      const insertedCoding = await CodingQuestion.insertMany(codingData, { ordered: false });
      
      questionsToMigrate.coding.forEach((q, index) => {
        codingMigrationMap[q.oldId.toString()] = insertedCoding[index]._id.toString();
      });
    }
    
    // Migrate skill assessment questions
    const skillAssessmentMigrationMap = {}; // oldId -> newId
    if (questionsToMigrate.skillAssessment.length > 0) {
      const skillAssessmentData = questionsToMigrate.skillAssessment.map(q => q.data);
      const insertedSkillAssessment = await SkillAssessmentQuestion.insertMany(skillAssessmentData, { ordered: false });
      
      questionsToMigrate.skillAssessment.forEach((q, index) => {
        skillAssessmentMigrationMap[q.oldId.toString()] = insertedSkillAssessment[index]._id.toString();
      });
    }
    
    // Update module references
    const allModules = await PlacementModule.find({}).lean();
    let modulesUpdated = 0;
    
    for (const module of allModules) {
      if (!module.questions || module.questions.length === 0) continue;
      
      const updatedQuestionIds = module.questions.map(q => {
        const questionId = (typeof q === 'object' && q._id) ? q._id.toString() : q.toString();
        
        // Check if this question was migrated
        if (codingMigrationMap[questionId]) {
          return codingMigrationMap[questionId];
        }
        if (skillAssessmentMigrationMap[questionId]) {
          return skillAssessmentMigrationMap[questionId];
        }
        
        // Not migrated, keep original ID
        return questionId;
      });
      
      // Update module if any IDs changed
      const hasChanges = updatedQuestionIds.some((newId, index) => {
        const oldId = (typeof module.questions[index] === 'object' && module.questions[index]._id) 
          ? module.questions[index]._id.toString() 
          : module.questions[index].toString();
        return newId !== oldId;
      });
      
      if (hasChanges) {
        await PlacementModule.findByIdAndUpdate(module._id, {
          questions: updatedQuestionIds
        });
        modulesUpdated++;
      }
    }
    
    // Delete migrated questions from PlacementQuestion
    const idsToDelete = [
      ...questionsToMigrate.coding.map(q => q.oldId),
      ...questionsToMigrate.skillAssessment.map(q => q.oldId)
    ];
    
    if (idsToDelete.length > 0) {
      await PlacementQuestion.deleteMany({ _id: { $in: idsToDelete } });
    }
    
    const summary = {
      totalFound: allPlacementQuestions.length,
      codingMigrated: questionsToMigrate.coding.length,
      skillAssessmentMigrated: questionsToMigrate.skillAssessment.length,
      otherRemaining: questionsToMigrate.other.length,
      modulesUpdated: modulesUpdated,
      questionsDeleted: idsToDelete.length
    };
    
    res.json({
      success: true,
      message: 'Migration completed successfully',
      summary
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Migration failed',
      error: error.message
    });
  }
};

export const getCodingLeaderboard = async (req, res) => {
  try {
    const { limit = 50 } = req.query;
    const currentUserId = req.studentId || req.student?._id || req.user?.id;

    // Start from students collection to get all students, then left join with PlacementProgress
    const leaderboard = await Student.aggregate([
      {
        $lookup: {
          from: 'placementprogresses',
          localField: '_id',
          foreignField: 'studentId',
          as: 'progress'
        }
      },
      { $unwind: { path: '$progress', preserveNullAndEmptyArrays: true } },
      {
        $project: {
          userId: '$_id',
          firstName: 1,
          lastName: 1,
          username: 1,
          email: 1,
          institute: 1,
          course: 1,
          totalPoints: { $ifNull: ['$progress.totalPoints', 0] },
          codingProblemsSolved: { $ifNull: ['$progress.codingProblemsSolved', 0] },
          learningStreak: { $ifNull: ['$progress.learningStreak', 0] },
          lastActivityDate: '$progress.lastActivityDate'
        }
      },
      {
        $sort: {
          totalPoints: -1,
          codingProblemsSolved: -1,
          learningStreak: -1
        }
      },
      { $limit: parseInt(limit) }
    ]);

    // Add rank to each entry
    const leaderboardWithRank = leaderboard.map((entry, index) => ({
      ...entry,
      rank: index + 1
    }));

    res.json({
      success: true,
      leaderboard: leaderboardWithRank
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch leaderboard',
      error: error.message
    });
  }
};

// ============ ADMIN - Coding Assessment Management ============

export const createCodingAssessment = async (req, res) => {
  try {
    const assessmentData = {
      ...req.body,
      createdBy: req.user?.id || req.adminId || req.admin?._id
    };

    // Validate that questions array exists and is not empty
    if (!assessmentData.questions || !Array.isArray(assessmentData.questions) || assessmentData.questions.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'At least one coding question is required for the assessment'
      });
    }

    // Validate that all question IDs exist and are coding questions
    const questions = await CodingQuestion.find({
      _id: { $in: assessmentData.questions },
      isActive: true
    });

    if (questions.length !== assessmentData.questions.length) {
      return res.status(400).json({
        success: false,
        message: 'One or more question IDs are invalid or inactive'
      });
    }

    const assessment = new CodingAssessment(assessmentData);
    await assessment.save();

    // Populate questions for response
    await assessment.populate('questions', 'title difficulty topic points');

    res.status(201).json({
      success: true,
      message: 'Coding assessment created successfully',
      assessment
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to create coding assessment',
      error: error.message
    });
  }
};

export const getAllCodingAssessments = async (req, res) => {
  try {
    const { isActive, isPublished, category, difficulty } = req.query;
    
    const filter = {};
    if (isActive !== undefined) filter.isActive = isActive === 'true';
    if (isPublished !== undefined) filter.isPublished = isPublished === 'true';
    if (category) filter.category = category;
    if (difficulty) filter.difficulty = difficulty;

    const assessments = await CodingAssessment.find(filter)
      .populate('questions', 'title difficulty topic points timeLimit')
      .populate('createdBy', 'username email')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      count: assessments.length,
      assessments
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch coding assessments',
      error: error.message
    });
  }
};

export const getCodingAssessmentById = async (req, res) => {
  try {
    const assessment = await CodingAssessment.findById(req.params.id)
      .populate('questions')
      .populate('createdBy', 'username email');

    if (!assessment) {
      return res.status(404).json({
        success: false,
        message: 'Coding assessment not found'
      });
    }

    res.json({
      success: true,
      assessment
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch coding assessment',
      error: error.message
    });
  }
};

export const updateCodingAssessment = async (req, res) => {
  try {
    const updateData = { ...req.body };

    // If questions are being updated, validate them
    if (updateData.questions && Array.isArray(updateData.questions)) {
      if (updateData.questions.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'At least one coding question is required'
        });
      }

      const questions = await CodingQuestion.find({
        _id: { $in: updateData.questions },
        isActive: true
      });

      if (questions.length !== updateData.questions.length) {
        return res.status(400).json({
          success: false,
          message: 'One or more question IDs are invalid or inactive'
        });
      }
    }

    const assessment = await CodingAssessment.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true, runValidators: true }
    )
      .populate('questions', 'title difficulty topic points timeLimit')
      .populate('createdBy', 'username email');

    if (!assessment) {
      return res.status(404).json({
        success: false,
        message: 'Coding assessment not found'
      });
    }

    res.json({
      success: true,
      message: 'Coding assessment updated successfully',
      assessment
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update coding assessment',
      error: error.message
    });
  }
};

export const deleteCodingAssessment = async (req, res) => {
  try {
    const assessment = await CodingAssessment.findByIdAndDelete(req.params.id);

    if (!assessment) {
      return res.status(404).json({
        success: false,
        message: 'Coding assessment not found'
      });
    }

    res.json({
      success: true,
      message: 'Coding assessment deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to delete coding assessment',
      error: error.message
    });
  }
};

// ============ STUDENT - Coding Assessment ============

export const getStudentCodingAssessments = async (req, res) => {
  try {
    // Get only published and active assessments
    const now = new Date();
    const assessments = await CodingAssessment.find({
      isActive: true,
      isPublished: true,
      $and: [
        {
          $or: [
            { startDate: null },
            { startDate: { $lte: now } }
          ]
        },
        {
          $or: [
            { endDate: null },
            { endDate: { $gte: now } }
          ]
        }
      ]
    })
      .populate('questions', 'title difficulty topic points timeLimit')
      .select('-createdBy') // Don't expose admin info
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      count: assessments.length,
      assessments
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch coding assessments',
      error: error.message
    });
  }
};

export const getCodingAssessmentQuestions = async (req, res) => {
  try {
    const { assessmentId } = req.params;
    const studentId = req.studentId || req.student?._id || req.user?.id;

    const assessment = await CodingAssessment.findById(assessmentId)
      .populate('questions');

    if (!assessment || !assessment.isActive || !assessment.isPublished) {
      return res.status(404).json({
        success: false,
        message: 'Assessment not found or not available'
      });
    }

    // Check if assessment is within date range
    const now = new Date();
    if (assessment.startDate && assessment.startDate > now) {
      return res.status(403).json({
        success: false,
        message: 'Assessment has not started yet'
      });
    }
    if (assessment.endDate && assessment.endDate < now) {
      return res.status(403).json({
        success: false,
        message: 'Assessment has ended'
      });
    }

    // Sanitize questions - hide test cases and other sensitive info
    const sanitizedQuestions = assessment.questions.map(q => {
      const qObj = q.toObject();
      
      // Remove explanation
      delete qObj.explanation;
      
      // Hide test cases from students (only show sample I/O)
      if (qObj.testCases) {
        qObj.testCases = undefined;
      }
      
      // Use assessment's questionTimeLimit if set, otherwise use question's timeLimit
      if (assessment.questionTimeLimit) {
        qObj.timeLimit = assessment.questionTimeLimit;
      }
      
      return qObj;
    });

    res.json({
      success: true,
      assessment: {
        _id: assessment._id,
        title: assessment.title,
        description: assessment.description,
        instructions: assessment.instructions,
        totalTimeLimit: assessment.totalTimeLimit,
        questionTimeLimit: assessment.questionTimeLimit,
        totalPoints: assessment.totalPoints,
        passingScore: assessment.passingScore
      },
      questions: sanitizedQuestions
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch assessment questions',
      error: error.message
    });
  }
};

export const submitCodingAssessment = async (req, res) => {
  try {
    const { assessmentId, answers } = req.body; // answers: [{ questionId, code, language }]
    const studentId = req.studentId || req.student?._id || req.user?.id;

    if (!answers || !Array.isArray(answers) || answers.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Please provide answers for at least one question'
      });
    }

    const assessment = await CodingAssessment.findById(assessmentId)
      .populate('questions');

    if (!assessment || !assessment.isActive || !assessment.isPublished) {
      return res.status(404).json({
        success: false,
        message: 'Assessment not found or not available'
      });
    }

    // Get or create student progress
    let progress = await PlacementProgress.findOne({ studentId });
    if (!progress) {
      progress = new PlacementProgress({ studentId });
    }

    let totalPointsEarned = 0;
    let totalPossiblePoints = 0;
    const results = [];

    // Evaluate each answer
    for (const answer of answers) {
      const question = assessment.questions.find(q => q._id.toString() === answer.questionId);
      if (!question) continue;

      totalPossiblePoints += question.points || assessment.pointsPerQuestion;

      // Execute code and check test cases
      if (question.testCases && question.testCases.length > 0) {
        let passedTests = 0;
        const testResults = [];

        for (const testCase of question.testCases) {
          const executionResult = await executeCodeWithJudge0(answer.code, answer.language, testCase.input);

          if (!executionResult.success) {
            testResults.push({
              input: testCase.input,
              expected: testCase.output,
              actual: executionResult.error || 'Execution failed',
              passed: false
            });
            continue;
          }

          const actualOutput = (executionResult.stdout || '').trim();
          const expectedOutput = testCase.output.trim();
          const testPassed = actualOutput === expectedOutput;

          testResults.push({
            input: testCase.input,
            expected: expectedOutput,
            actual: actualOutput,
            passed: testPassed
          });

          if (testPassed) {
            passedTests++;
          }
        }

        const passRate = passedTests / question.testCases.length;
        const isCorrect = passRate === 1;
        const pointsEarned = isCorrect 
          ? (question.points || assessment.pointsPerQuestion)
          : Math.round((question.points || assessment.pointsPerQuestion) * passRate * 0.5);

        totalPointsEarned += pointsEarned;

        results.push({
          questionId: question._id,
          questionTitle: question.title,
          isCorrect,
          pointsEarned,
          totalPoints: question.points || assessment.pointsPerQuestion,
          testResults,
          passedTests,
          totalTests: question.testCases.length
        });

        // Save attempt to progress
        progress.questionAttempts.push({
          questionId: question._id,
          attemptedAt: new Date(),
          isCorrect,
          timeTaken: answer.timeTaken || 0,
          code: answer.code,
          language: answer.language,
          pointsEarned
        });
      }
    }

    // Update progress
    progress.totalPoints += totalPointsEarned;
    progress.codingProblemsSolved += results.filter(r => r.isCorrect).length;
    progress.lastActivityDate = new Date();
    await progress.save();

    // Calculate overall score
    const scorePercentage = totalPossiblePoints > 0 
      ? Math.round((totalPointsEarned / totalPossiblePoints) * 100)
      : 0;
    const passed = scorePercentage >= assessment.passingScore;

    res.json({
      success: true,
      score: totalPointsEarned,
      totalScore: totalPossiblePoints,
      scorePercentage,
      passed,
      passingScore: assessment.passingScore,
      results,
      totalPoints: progress.totalPoints
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to submit assessment',
      error: error.message
    });
  }
};

export default {
  createQuestion,
  getAllQuestions,
  getQuestionById,
  updateQuestion,
  deleteQuestion,
  bulkUploadQuestions,
  runCode,
  getCodingQuestions,
  createModule,
  getAllModules,
  updateModule,
  deleteModule,
  getStudentModules,
  getModuleQuestions,
  submitAnswer,
  getStudentProgress,
  updateModuleProgress,
  deleteSubmission,
  getPlacementStats,
  getCodingLeaderboard,
  createCodingAssessment,
  getAllCodingAssessments,
  getCodingAssessmentById,
  updateCodingAssessment,
  deleteCodingAssessment,
  getStudentCodingAssessments,
  getCodingAssessmentQuestions,
  submitCodingAssessment,
  getStudentSkillAssessments,
  migrateQuestionsFromPlacementTable
};
