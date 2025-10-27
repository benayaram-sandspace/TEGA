import MockInterview from '../models/MockInterview.js';
import Student from '../models/Student.js';
import { GoogleGenerativeAI } from '@google/generative-ai';
import fetch from 'node-fetch';

// Check if Google API Key is configured
if (!process.env.GOOGLE_AI_API_KEY) {
  console.warn('⚠️ WARNING: GOOGLE_AI_API_KEY is not set in environment variables');
  console.warn('AI features will be disabled. To enable them, set GOOGLE_AI_API_KEY in your .env file');
  console.warn('Get a free key from: https://ai.google.dev/');
}

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY || 'invalid-key');
const JUDGE0_HOST = process.env.JUDGE0_HOST || 'http://localhost:2358';

// Generate interview questions using Google Gemini
export const generateInterviewQuestions = async (domain, difficulty) => {
  try {
    if (!process.env.GOOGLE_AI_API_KEY) {
      // Return mock questions when AI is not available
      return {
        success: true,
        questions: [
          {
            question: "What is your experience with " + domain + "?",
            type: "technical",
            difficulty: difficulty
          },
          {
            question: "Explain a challenging project you worked on.",
            type: "behavioral",
            difficulty: difficulty
          },
          {
            question: "How do you approach problem-solving?",
            type: "behavioral",
            difficulty: difficulty
          }
        ],
        message: "AI features disabled - using mock questions. Set GOOGLE_AI_API_KEY to enable AI-generated questions."
      };
    }

    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    
    const prompt = `Generate 7 technical interview questions for a ${difficulty} level ${domain} developer. 
    Format as JSON array with { question: "...", difficulty: "${difficulty}" }.
    Include mix of conceptual and practical questions.
    Return ONLY valid JSON, no markdown or extra text.`;
    
    const result = await model.generateContent(prompt);
    const text = result.response.text();
    
    // Try to parse JSON from response
    try {
      const questions = JSON.parse(text);
      return Array.isArray(questions) ? questions : [text];
    } catch {
      // If parsing fails, return a default set
      return [
        { question: `What are the key concepts in ${domain}?`, difficulty },
        { question: `How would you approach a ${difficulty} level ${domain} problem?`, difficulty },
        { question: `What tools and technologies do you use in ${domain}?`, difficulty },
        { question: `Can you explain a recent project in ${domain}?`, difficulty },
        { question: `What best practices do you follow in ${domain}?`, difficulty },
        { question: `How do you handle performance optimization in ${domain}?`, difficulty },
        { question: `What challenges have you faced in ${domain}?`, difficulty }
      ];
    }
  } catch (error) {
    console.error('Error generating questions:', error.message);
    
    // Check if it's an API key error
    if (error.message && error.message.includes('API key')) {
      throw new Error('Interview service not configured. Please check Google API key setup in backend .env file. See GOOGLE_API_SETUP_GUIDE.md for help.');
    }
    
    throw error;
  }
};

// Evaluate answer using Google Gemini
export const evaluateAnswer = async (question, answer, domain) => {
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    
    const prompt = `You are an expert ${domain} interviewer. 
    Question: ${question}
    Candidate's Answer: ${answer}
    
    Evaluate the answer and provide:
    1. Score (0-100)
    2. Feedback (2-3 sentences)
    3. Strengths (what they did well)
    4. Improvements (what to improve)
    
    Format as JSON: { "score": number, "feedback": "string", "strengths": "string", "improvements": "string" }
    Return ONLY valid JSON, no markdown or extra text.`;
    
    const result = await model.generateContent(prompt);
    const text = result.response.text();
    
    try {
      const evaluation = JSON.parse(text);
      return {
        score: Math.min(100, Math.max(0, evaluation.score || 70)),
        feedback: evaluation.feedback || 'Good attempt',
        strengths: evaluation.strengths || 'Good understanding',
        improvements: evaluation.improvements || 'Continue practicing'
      };
    } catch {
      return {
        score: 70,
        feedback: 'Answer recorded and will be reviewed',
        strengths: 'Provided a response',
        improvements: 'Consider more detailed explanations'
      };
    }
  } catch (error) {
    console.error('Error evaluating answer:', error);
    return {
      score: 60,
      feedback: 'Answer recorded',
      strengths: 'Participated',
      improvements: 'Try again'
    };
  }
};

// Execute code via Judge0
export const executeCode = async (code, languageId, testCases) => {
  try {
    // Language ID mapping for Judge0
    const languageMap = {
      'javascript': 63,
      'python': 71,
      'java': 62,
      'cpp': 54,
      'c': 50
    };

    const langId = languageMap[languageId] || 63; // Default to JavaScript

    const submission = await fetch(`${JUDGE0_HOST}/submissions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        source_code: code,
        language_id: langId,
        stdin: testCases[0]?.input || ''
      })
    }).then(res => res.json());
    
    if (!submission || !submission.token) {
      throw new Error('Failed to submit code to Judge0');
    }

    // Poll for result
    let result;
    let attempts = 0;
    const maxAttempts = 30;

    while (attempts < maxAttempts) {
      result = await fetch(`${JUDGE0_HOST}/submissions/${submission.token}`)
        .then(res => res.json());
      
      if (result.status.id > 2) break; // Status > 2 means finished
      
      attempts++;
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    return result;
  } catch (error) {
    console.error('Code execution error:', error);
    return {
      status: { id: 4, description: 'Execution Error' },
      stdout: '',
      stderr: error.message
    };
  }
};

// Start interview
export const startInterview = async (req, res) => {
  try {
    const { domain, difficulty } = req.body;
    // Extract studentId from authenticated request - try multiple possible locations
    const userId = req.studentId || req.student?._id || req.user?.id || req.user?._id;

    if (!userId) {
      return res.status(401).json({ 
        success: false, 
        message: 'Not authenticated - Student ID not found' 
      });
    }

    if (!domain) {
      return res.status(400).json({ 
        success: false, 
        message: 'Domain is required' 
      });
    }

    // Create interview with proper studentId
    const interview = new MockInterview({
      studentId: userId,
      domain,
      difficulty: difficulty || 'medium',
      startedAt: new Date(),
      status: 'in-progress'
    });
    
    // Generate questions
    const questions = await generateInterviewQuestions(domain, difficulty || 'medium');
    
    interview.sections.domainQuestions.questions = questions.map(q => ({
      question: q.question || q,
      difficulty: q.difficulty || difficulty || 'medium'
    }));
    
    interview.sections.selfIntroduction.question = `Please introduce yourself and tell us about your background in ${domain}.`;
    interview.sections.projectDiscussion.questions = [
      'Tell us about your most recent project',
      'What technologies did you use and why?',
      'What was the biggest challenge and how did you solve it?'
    ];
    
    await interview.save();
    
    // Verify interview was saved with correct studentId
    const savedInterview = await MockInterview.findById(interview._id);
    
    res.json({
      success: true,
      interviewId: interview._id,
      studentId: userId,
      domain,
      difficulty,
      questions: interview.sections,
      message: 'Interview started successfully'
    });
  } catch (error) {
    console.error('Error starting interview:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message || 'Failed to start interview',
      error: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

// Submit answer
export const submitAnswer = async (req, res) => {
  try {
    const { interviewId, section, answer } = req.body;
    const userId = req.studentId || req.student?._id || req.user?.id || req.user?._id;
    
    if (!interviewId || !section || !answer) {
      return res.status(400).json({ 
        success: false, 
        message: 'interviewId, section, and answer are required' 
      });
    }

    const interview = await MockInterview.findById(interviewId);
    if (!interview) {
      return res.status(404).json({ 
        success: false, 
        message: 'Interview not found' 
      });
    }

    // Verify the user owns this interview
    if (interview.studentId.toString() !== userId.toString()) {
      return res.status(403).json({ 
        success: false, 
        message: 'Unauthorized: You cannot submit answers for this interview' 
      });
    }
    
    // Evaluate answer
    const question = interview.sections[section]?.question || 
                     interview.sections[section]?.questions?.[0] || 
                     'Tell me more';
    const evaluation = await evaluateAnswer(question, answer, interview.domain);
    
    // Store response
    if (interview.sections[section]) {
      interview.sections[section].response = answer;
      interview.sections[section].score = evaluation.score;
      interview.sections[section].feedback = evaluation.feedback;
    }
    
    await interview.save();
    
    res.json({
      success: true,
      score: evaluation.score,
      feedback: evaluation.feedback,
      strengths: evaluation.strengths,
      improvements: evaluation.improvements
    });
  } catch (error) {
    console.error('Error submitting answer:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message || 'Failed to submit answer',
      error: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

// Submit code solution
export const submitCode = async (req, res) => {
  try {
    const { interviewId, code, language, testCases } = req.body;
    const userId = req.studentId || req.student?._id || req.user?.id || req.user?._id;

    if (!interviewId || !code || !language) {
      return res.status(400).json({ 
        success: false, 
        message: 'interviewId, code, and language are required' 
      });
    }

    const interview = await MockInterview.findById(interviewId);
    if (!interview) {
      return res.status(404).json({ 
        success: false, 
        message: 'Interview not found' 
      });
    }

    // Verify the user owns this interview
    if (interview.studentId.toString() !== userId.toString()) {
      return res.status(403).json({ 
        success: false, 
        message: 'Unauthorized: You cannot submit code for this interview' 
      });
    }

    // Execute code
    const result = await executeCode(code, language, testCases || []);

    // Calculate score based on test results
    let score = 0;
    if (result.status?.id === 3) { // Accepted
      score = 100;
    } else if (result.status?.id < 3) { // Compilation error or similar
      score = 0;
    } else {
      score = 50;
    }

    // Store code submission
    if (interview.sections.codingChallenge.problems.length === 0) {
      interview.sections.codingChallenge.problems.push({
        language,
        code,
        testCases: testCases || [],
        score,
        executionTime: result.time || 0,
        memory: result.memory || 0
      });
    }

    await interview.save();

    res.json({
      success: true,
      score,
      result: {
        status: result.status?.description || 'Unknown',
        stdout: result.stdout || '',
        stderr: result.stderr || '',
        time: result.time || 0,
        memory: result.memory || 0
      }
    });
  } catch (error) {
    console.error('Error submitting code:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message || 'Failed to submit code',
      error: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

// Complete interview and generate report
export const completeInterview = async (req, res) => {
  try {
    const { interviewId } = req.body;
    const userId = req.studentId || req.student?._id || req.user?.id || req.user?._id;
    
    if (!interviewId) {
      return res.status(400).json({ 
        success: false, 
        message: 'interviewId is required' 
      });
    }

    const interview = await MockInterview.findById(interviewId);
    if (!interview) {
      return res.status(404).json({ 
        success: false, 
        message: 'Interview not found' 
      });
    }

    // Verify the user owns this interview
    if (interview.studentId.toString() !== userId.toString()) {
      return res.status(403).json({ 
        success: false, 
        message: 'Unauthorized: You cannot complete this interview' 
      });
    }

    interview.status = 'completed';
    interview.completedAt = new Date();
    
    // Calculate overall score
    const allScores = [];
    if (interview.sections.selfIntroduction.score) allScores.push(interview.sections.selfIntroduction.score);
    if (interview.sections.projectDiscussion.score) allScores.push(interview.sections.projectDiscussion.score);
    if (interview.sections.domainQuestions.totalScore) allScores.push(interview.sections.domainQuestions.totalScore);
    if (interview.sections.codingChallenge.totalScore) allScores.push(interview.sections.codingChallenge.totalScore);

    const overall = allScores.length > 0 
      ? Math.round(allScores.reduce((a, b) => a + b) / allScores.length)
      : 0;

    interview.scores.communication = interview.sections.selfIntroduction.score || 0;
    interview.scores.technicalKnowledge = interview.sections.projectDiscussion.score || 0;
    interview.scores.problemSolving = interview.sections.domainQuestions.totalScore || 0;
    interview.scores.codeQuality = interview.sections.codingChallenge.totalScore || 0;
    interview.scores.timeManagement = 75; // Default
    interview.scores.engagement = 80; // Default
    interview.scores.overall = overall;
    
    // Generate final feedback
    interview.feedback = `Interview completed successfully. Overall score: ${overall}/100. Continue practicing to improve your skills.`;
    interview.improvements = [
      'Practice more coding problems',
      'Work on explaining your thought process',
      'Study domain-specific best practices'
    ];
    interview.strengths = [
      'Completed the interview',
      'Provided answers to all sections'
    ];

    await interview.save();
    
    res.json({
      success: true,
      interviewId,
      studentId: userId,
      scores: interview.scores,
      feedback: interview.feedback
    });
  } catch (error) {
    console.error('Error completing interview:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message || 'Failed to complete interview',
      error: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

// Get interview stats
export const getInterviewStats = async (req, res) => {
  try {
    const { userId } = req.params;
    const authenticatedUserId = req.studentId || req.student?._id || req.user?.id || req.user?._id;

    if (!userId) {
      return res.status(400).json({ 
        success: false, 
        message: 'userId is required' 
      });
    }

    // Verify user can only access their own stats (or admin access)
    if (authenticatedUserId.toString() !== userId && !req.isAdmin) {
      return res.status(403).json({ 
        success: false, 
        message: 'Unauthorized: You can only access your own interview stats' 
      });
    }

    const interviews = await MockInterview.find({ studentId: userId })
      .sort({ createdAt: -1 });
    
    const stats = {
      totalInterviews: interviews.length,
      completedInterviews: interviews.filter(i => i.status === 'completed').length,
      averageScore: interviews.length > 0 
        ? Math.round(interviews.reduce((sum, i) => sum + (i.scores.overall || 0), 0) / interviews.length)
        : 0,
      improvementTrend: interviews.slice(0, 5).map(i => i.scores.overall),
      recentInterviews: interviews.slice(0, 5).map(i => ({
        _id: i._id,
        domain: i.domain,
        difficulty: i.difficulty,
        score: i.scores.overall,
        status: i.status,
        completedAt: i.completedAt,
        startedAt: i.startedAt
      }))
    };
    
    res.json({ 
      success: true, 
      stats 
    });
  } catch (error) {
    console.error('Error fetching stats:', error);
    res.status(500).json({ 
      success: false, 
      message: error.message || 'Failed to fetch interview stats',
      error: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
};

// Get leaderboard
export const getLeaderboard = async (req, res) => {
  try {
    const { domain } = req.query;

    let query = { status: 'completed' };
    if (domain) query.domain = domain;

    const interviews = await MockInterview.find(query)
      .populate('studentId', 'username studentName')
      .sort({ 'scores.overall': -1 })
      .limit(10);

    // Group by student and calculate average
    const studentStats = {};
    interviews.forEach(interview => {
      const studentId = interview.studentId._id;
      if (!studentStats[studentId]) {
        studentStats[studentId] = {
          name: interview.studentId.studentName || interview.studentId.username,
          domain: interview.domain,
          scores: [],
          count: 0
        };
      }
      studentStats[studentId].scores.push(interview.scores.overall);
      studentStats[studentId].count++;
    });

    const leaderboard = Object.values(studentStats)
      .map((stat, idx) => ({
        rank: idx + 1,
        name: stat.name,
        domain: stat.domain,
        averageScore: Math.round(stat.scores.reduce((a, b) => a + b) / stat.scores.length),
        totalInterviews: stat.count
      }))
      .sort((a, b) => b.averageScore - a.averageScore);

    res.json({ success: true, leaderboard });
  } catch (error) {
    console.error('Error fetching leaderboard:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

