import MockInterview from '../models/MockInterview.js';
import Student from '../models/Student.js';
import { generateWithOllama, checkOllamaAvailability, ensureModelAvailable, getModelForTask } from '../config/ollama.js';
import { GoogleGenerativeAI } from '@google/generative-ai';

let ollamaAvailable = false;
let ollamaCheckError = null;

// Function to get Gemini API key (called at runtime)
function getGeminiApiKey() {
  return process.env.GEMINI_API_KEY;
}

// Function to get Gemini AI instance (called at runtime)
function getGeminiAI() {
  const apiKey = getGeminiApiKey();
  return apiKey ? new GoogleGenerativeAI(apiKey) : null;
}

// Helper function to call Gemini API (non-streaming)
async function callGemini(prompt) {
  try {
    const genAI = getGeminiAI();
    if (!genAI) {
      throw new Error('Gemini AI not initialized - GEMINI_API_KEY not set');
    }
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });
    
    const result = await model.generateContent(prompt);
    const response = await result.response;
    let text = response.text();
    
    // Strip markdown code blocks if present (Gemini sometimes wraps JSON in ```json ... ```)
    text = text.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '').trim();
    
    return text;
  } catch (error) {
    throw new Error(`Gemini error: ${error.message}`);
  }
}

// Helper function to try Gemini first, then fallback to Ollama
async function generateWithAI(prompt, task = 'general', options = {}) {
  const geminiApiKey = getGeminiApiKey();
  
  // Try Gemini first if API key is available
  if (geminiApiKey) {
    try {
      const response = await callGemini(prompt);
      return {
        success: true,
        content: response,
        model: 'gemini-2.0-flash'
      };
    } catch (geminiError) {
      // If Gemini fails, fall through to Ollama
      if (!ollamaAvailable) {
        throw new Error(`Gemini failed and Ollama is not available: ${geminiError.message}`);
      }
    }
  }
  
  // Fallback to Ollama
  if (!ollamaAvailable) {
    throw new Error('Neither Gemini nor Ollama is available. Please set GEMINI_API_KEY or ensure Ollama service is running.');
  }
  
  return await generateWithOllama(prompt, task, options);
}

// Check Ollama availability and update status
checkOllamaAvailability()
  .then(result => {
    ollamaAvailable = result.available;
    if (!result.available) {
      ollamaCheckError = result.error || 'Ollama service not reachable';
    } else {
      ensureModelAvailable(process.env.OLLAMA_MODEL || 'llama2').catch(err => err);
    }
  })
  .catch(err => {
    ollamaAvailable = false;
    ollamaCheckError = err.message;
  });

export const generateFollowUpQuestion = async (conversationHistory, domain, difficulty, currentTopic) => {
  try {
    const lastEntry = conversationHistory[conversationHistory.length - 1];
    const lastAnswer = lastEntry?.answer || '';
    const lastScore = lastEntry?.score || 0;
    const lastQuestion = lastEntry?.question || '';

    // Check if answer is too short or unclear - ask for clarification using AI
    if (lastAnswer.trim().length < 20) {
      const clarificationPrompt = `You are Steve, a friendly AI interviewer. The student's answer was too brief (less than 20 characters). Generate ONE concise clarification question (max 2 sentences) asking them to provide more detail. Include a brief acknowledgment like "Got it" or "I see" before the question. Return ONLY the question text, no additional formatting.`;
      
      const clarificationResult = await generateWithAI(clarificationPrompt, 'creative', { temperature: 0.8 });
      if (!clarificationResult.success) throw new Error(clarificationResult.error);
      
      let clarificationQuestion = clarificationResult.content.trim();
      clarificationQuestion = clarificationQuestion.replace(/^["']|["']$/g, '').trim();
      
      return { 
        success: true, 
        question: clarificationQuestion, 
        topic: currentTopic, 
        difficulty 
      };
    }

    const conversationContext = conversationHistory
      .slice(-3)
      .map(exchange => `{ Q: "${exchange.question}", A: "${exchange.answer}"${exchange.score ? `, Score: ${exchange.score}` : ''} }`)
      .join(', ');

    const prompt = `Variable Name,Description,Example Value
DOMAIN,The interview subject.,${domain}
DIFFICULTY,Current adaptive difficulty level.,${difficulty}
CURRENT_TOPIC,The topic of the last question asked.,${currentTopic}
CONVERSATION_HISTORY,The last N question/answer pairs.,"[${conversationContext}]"
LAST_ANSWER,The exact answer the student just submitted.,"${lastAnswer}"
LAST_SCORE,The score assigned to the last answer.,${lastScore}

**ROLE:** You are Steve, a friendly and professional AI interviewer on the TEGA Learning Platform conducting a ${difficulty} level ${domain} mock interview.

**INSTRUCTIONS:**
1. Acknowledge the student's last answer briefly ("Got it", "Good point", "That makes sense", "Interesting", "I see") before asking the next question.
2. Generate ONE concise follow-up question (max 2 sentences) that:
   - Builds naturally on their previous answer
   - Goes deeper into the topic (${currentTopic}) or explores a related aspect
   - Tests their understanding in a conversational way
   - Is appropriate for ${difficulty} level difficulty
   - Relates to ${domain} domain
   - If they mentioned projects or challenges, ask about specific details, technologies used, problems solved, or lessons learned
   - If they mentioned technologies or tools, ask about implementation details, best practices, or real-world applications
   ${lastScore >= 85 ? `- Since they scored well (${lastScore}), you can ask a more challenging follow-up that tests deeper knowledge.` : ''}
   ${lastScore < 60 ? `- Since they struggled (${lastScore}), ask a simpler, more guiding question to help them express their knowledge.` : ''}
3. Do NOT repeat the student's answer.
4. Do NOT generate the student's response.
5. Keep questions clear, conversational, and supportive.
6. Vary question types: ask about projects, challenges, real-world applications, technical details, problem-solving approaches, and best practices.

**OUTPUT:** Return ONLY the question text with a brief acknowledgment, no additional formatting. Example: "Got it. Can you walk me through how you would implement that?"`;

    const result = await generateWithAI(prompt, 'creative', { temperature: 0.8 });
    if (!result.success) throw new Error(result.error);
    
    let question = result.content.trim();
    // Remove any quotes or extra formatting
    question = question.replace(/^["']|["']$/g, '').trim();
    
    return { success: true, question, topic: currentTopic, difficulty };
  } catch (error) {
    // No fallback - throw error if AI fails
    throw new Error(`Failed to generate follow-up question: ${error.message}`);
  }
};

// Free sentiment analysis using keyword matching (fallback when Ollama unavailable)
const analyzeSentiment = (text) => {
  const positiveWords = ['excellent', 'great', 'successful', 'achieved', 'improved', 'solved', 'learned', 'enjoyed', 'confident', 'good', 'well', 'best', 'perfect', 'love', 'amazing'];
  const negativeWords = ['difficult', 'challenging', 'problem', 'issue', 'failed', 'struggled', 'hard', 'couldn\'t', 'didn\'t', 'wasn\'t', 'bad', 'worst', 'hate', 'terrible'];
  const textLower = text.toLowerCase();
  const positiveCount = positiveWords.filter(word => textLower.includes(word)).length;
  const negativeCount = negativeWords.filter(word => textLower.includes(word)).length;
  if (positiveCount > negativeCount) return 'positive';
  if (negativeCount > positiveCount) return 'negative';
  return 'neutral';
};

// Free confidence scoring based on answer length, keywords, and structure
const calculateConfidence = (answer, topic) => {
  const answerLength = answer.split(' ').length;
  const hasTechnicalTerms = ['function', 'method', 'class', 'algorithm', 'data', 'structure', 'pattern', 'design', 'system', 'architecture'].some(term => answer.toLowerCase().includes(term));
  const hasExamples = ['example', 'for instance', 'such as', 'like', 'when', 'in my'].some(phrase => answer.toLowerCase().includes(phrase));
  const hasStructure = ['first', 'second', 'then', 'finally', 'because', 'therefore', 'however'].some(word => answer.toLowerCase().includes(word));
  
  let confidence = 0.5; // base
  if (answerLength >= 20) confidence += 0.15; // detailed answers
  if (hasTechnicalTerms) confidence += 0.15; // technical knowledge
  if (hasExamples) confidence += 0.1; // concrete examples
  if (hasStructure) confidence += 0.1; // organized thinking
  
  return Math.min(1.0, Math.max(0.0, confidence));
};

// Per-answer scoring during interview - Uses Gemini or Ollama
const scoreAnswer = async (question, answer, topic, domain, difficulty) => {
  try {

    // Enhanced Ollama-based scoring with detailed criteria
    const prompt = `Variable Name,Description,Example Value
DOMAIN,The interview subject.,${domain}
DIFFICULTY,Current adaptive difficulty level.,${difficulty}
CURRENT_TOPIC,The topic of the last question asked.,${topic}
QUESTION ASKED,The exact question that was asked.,"${question}"
CANDIDATE ANSWER,The exact answer the student just submitted.,"${answer}"

**ROLE:** Technical Answer Scorer.
**DOMAIN:** ${domain}
**QUESTION TOPIC:** ${topic}
**QUESTION DIFFICULTY:** ${difficulty}

**QUESTION ASKED:** "${question}"

**CANDIDATE ANSWER:** "${answer}"

**INSTRUCTIONS:**
1.  **Assign Score (0-100):** Assign a single numerical score from 0 (very poor/incorrect) to 100 (expert/perfect answer) based on the criteria below.
2.  **Scoring Criteria:**
    * **Technical Accuracy (50%):** Is the information correct? Are the concepts, technologies, and approaches mentioned accurate?
    * **Completeness & Depth (30%):** Did they cover all key aspects? Is the depth appropriate for a '${difficulty}' question? Did they mention projects, challenges, or real-world applications?
    * **Clarity & Structure (20%):** Is the answer well-structured, clear, and easy to follow? Can they articulate complex ideas clearly?
3.  **Feedback:** Provide a brief, constructive paragraph (3-4 sentences max) summarizing the answer's quality. Mention:
    - What they did well (technical accuracy, examples, projects, challenges)
    - What could be improved (missing details, unclear explanations, lack of depth)
    - How they can strengthen their response
4.  **Strengths/Improvements:** Identify 1-2 specific strengths and 1-2 areas for improvement. Consider:
    - Technical knowledge demonstrated
    - Use of examples, projects, or challenges
    - Problem-solving approach
    - Communication effectiveness
5.  **Sentiment:** Analyze the sentiment of the candidate's language (positive, neutral, negative).
6.  **Confidence:** Estimate the confidence level of the candidate's answer based on the language and detail (0.0 for low confidence, 1.0 for very high confidence).

**REQUIRED JSON OUTPUT SCHEMA:**
{
  "score": "The single numerical score (0-100).",
  "feedback": "A constructive summary of the answer's quality (paragraph).",
  "sentiment": "The detected emotional tone (positive, neutral, negative).",
  "confidence": "An estimated confidence level (0.0 to 1.0).",
  "strengths": [
    "A specific strength identified in the answer (e.g., 'Correctly mentioned memoization')."
  ],
  "improvements": [
    "A specific area for improvement (e.g., 'Did not discuss the use of context API for state')."
  ]
}

**GENERATE RESPONSE NOW:**`;

    const result = await generateWithAI(prompt, 'analytical', { temperature: 0.3 });
    if (!result.success) throw new Error(result.error);
    
    try {
      // Clean the response - remove markdown code blocks if present
      let cleanedContent = result.content.trim();
      cleanedContent = cleanedContent.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '').trim();
      
      // Try to extract JSON if there's extra text
      const jsonMatch = cleanedContent.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        cleanedContent = jsonMatch[0];
      }
      
      const analysis = JSON.parse(cleanedContent);
      return {
        score: Math.min(100, Math.max(0, analysis.score || 70)),
        feedback: analysis.feedback || 'Good answer.',
        sentiment: analysis.sentiment || analyzeSentiment(answer),
        confidence: Math.min(1.0, Math.max(0.0, analysis.confidence || 0.5)),
        strengths: analysis.strengths || [],
        improvements: analysis.improvements || []
      };
    } catch (parseError) {
      throw new Error(`Failed to parse AI scoring response: ${parseError.message}`);
    }
  } catch (error) {
    throw new Error(`Failed to score answer: ${error.message}`);
  }
};

// Adaptive difficulty adjustment (FREE - based on performance)
// Uses average of recent scores for stability - prevents erratic difficulty changes
const adjustDifficulty = (currentDifficulty, lastScore, recentScores) => {
  // Need at least 3 scores to make a reliable decision
  if (recentScores.length < 3) return currentDifficulty;
  
  // Calculate average of recent scores (last 3-5 scores)
  const recentScoreAverage = recentScores.length > 0
    ? recentScores.slice(-5).reduce((sum, s) => sum + s, 0) / recentScores.slice(-5).length
    : 0;
  
  let nextDifficulty = currentDifficulty;
  
  // --- Increase Difficulty Logic (based on average, more conservative) ---
  // Only increase if consistently performing well (average >= 90 for easy->medium, >= 80 for medium->hard)
  if (recentScoreAverage >= 90 && currentDifficulty === 'easy') {
    nextDifficulty = 'medium';
  } else if (recentScoreAverage >= 80 && currentDifficulty === 'medium') {
    nextDifficulty = 'hard';
  }
  // OR: Increase if ALL of the last 3 scores were > 85 (very consistent performance)
  else if (recentScores.length >= 3 && 
           recentScores.slice(-3).every(s => s > 85) && 
           currentDifficulty === 'easy') {
    nextDifficulty = 'medium';
  } else if (recentScores.length >= 3 && 
             recentScores.slice(-3).every(s => s > 85) && 
             currentDifficulty === 'medium') {
    nextDifficulty = 'hard';
  }
  
  // --- Decrease Difficulty Logic (based on average, more conservative) ---
  // Only decrease if consistently struggling (average <= 55 for hard->medium, <= 45 for medium->easy)
  else if (recentScoreAverage <= 55 && currentDifficulty === 'hard') {
    nextDifficulty = 'medium';
  } else if (recentScoreAverage <= 45 && currentDifficulty === 'medium') {
    nextDifficulty = 'easy';
  }
  // OR: Decrease if ALL of the last 3 scores were < 50 (very consistent struggle)
  else if (recentScores.length >= 3 && 
           recentScores.slice(-3).every(s => s < 50) && 
           currentDifficulty === 'hard') {
    nextDifficulty = 'medium';
  } else if (recentScores.length >= 3 && 
             recentScores.slice(-3).every(s => s < 50) && 
             currentDifficulty === 'medium') {
    nextDifficulty = 'easy';
  }
  
  return nextDifficulty;
};

export const analyzeResponse = async (response, currentTopic, domain, difficulty) => {
  try {
    const prompt = `Analyze this student's interview response and determine the best next topic to explore.

STUDENT RESPONSE: "${response}"
CURRENT TOPIC: ${currentTopic}
DOMAIN: ${domain}
DIFFICULTY: ${difficulty}

Respond in JSON format:
{"nextTopic":"technical|behavioral|problem_solving","confidence":0.8,"reasoning":"..."}`;

    const result = await generateWithAI(prompt, 'analytical', { temperature: 0.3 });
    if (!result.success) throw new Error(result.error);
    
    try {
      // Clean the response - remove markdown code blocks if present
      let cleanedContent = result.content.trim();
      cleanedContent = cleanedContent.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '').trim();
      
      // Try to extract JSON if there's extra text
      const jsonMatch = cleanedContent.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        cleanedContent = jsonMatch[0];
      }
      
      const analysis = JSON.parse(cleanedContent);
      return { 
        nextTopic: analysis.nextTopic || currentTopic, 
        confidence: analysis.confidence || 0.5, 
        reasoning: analysis.reasoning || 'AI analysis' 
      };
    } catch (parseError) {
      throw new Error(`Failed to parse AI response: ${parseError.message}`);
    }
  } catch (error) {
    throw new Error(`Failed to analyze response: ${error.message}`);
  }
};

export const generateOpeningQuestion = async (domain, difficulty) => {
  try {
    const prompt = `You are Steve, a friendly and professional AI interviewer on the TEGA Learning Platform. 
You are interviewing a fresher for ${domain}. Your goal is to make them feel comfortable, confident, and engaged.

Generate ONLY a JSON object with these fields:
1. welcomeMessage: 2-3 sentences, warm and encouraging, introduce yourself as Steve
2. question: 1-2 sentences, open-ended but simple enough for a fresher
3. difficulty: 'easy', 'medium', or 'hard' based on the difficulty parameter
4. expectedTopics: 1-2 keywords/topics the question covers
5. followUpHint: Optional short hint if the student struggles

Important:
- Return ONLY valid JSON, no markdown, no code blocks, no extra text
- Be professional, friendly, and conversational
- Keep welcomeMessage short and encouraging, question simple and clear

Format:
{
  "welcomeMessage": "...",
  "question": "...",
  "difficulty": "...",
  "expectedTopics": ["...", "..."],
  "followUpHint": "..."
}`;

    const result = await generateWithAI(prompt, 'creative', { temperature: 0.8 });

    if (!result.success) throw new Error(result.error || 'Failed to generate opening question');

    let cleanedContent = result.content.trim();
    cleanedContent = cleanedContent.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '').trim();
    const jsonMatch = cleanedContent.match(/\{[\s\S]*\}/);
    if (jsonMatch) cleanedContent = jsonMatch[0];

    const parsed = JSON.parse(cleanedContent);
    if (!parsed.welcomeMessage || !parsed.question) {
      throw new Error('AI response missing required fields (welcomeMessage or question)');
    }

    return {
      success: true,
      welcomeMessage: parsed.welcomeMessage,
      question: parsed.question,
      difficulty: parsed.difficulty || difficulty,
      expectedTopics: parsed.expectedTopics || [domain],
      followUpHint: parsed.followUpHint || 'You can give a small example to explain your answer.',
      topic: 'introduction'
    };

  } catch (error) {
    throw new Error(`Failed to generate opening question: ${error.message}`);
  }
};

/**
 * Generates a full multi-step adaptive mock interview for freshers.
 * @param {string} domain - The interview domain (e.g., "Web Development", "Data Science")
 * @param {string} difficulty - "easy" | "medium" | "hard"
 * @param {string} candidateName - Optional, for personalization
 * @returns {Promise<Object>} - Structured JSON mock interview session
 */
export const generateFullMockInterview = async (domain, difficulty, candidateName = "Candidate") => {
  try {
    const prompt = `
You are Steve, a professional and friendly AI interviewer. Conduct a complete mock interview for a fresher in the domain: ${domain}.

Structure the interview as a multi-step session (5-10 steps) including:

1. Warm introduction and icebreaker (personalized to ${candidateName})
2. Ask about education and recent projects
3. Domain-specific questions (start easy, then medium, then advanced)
4. Behavioral / situational questions
5. Mini-project or problem-solving simulation (if applicable)
6. Feedback, praise for good answers, and suggestions for improvement
7. Closing summary highlighting strengths and improvement areas

IMPORTANT:
- Return ONLY valid JSON, no explanations, no markdown
- Format:
{
  "session": [
    {
      "type": "introduction"|"background"|"domain"|"behavioral"|"project"|"closing",
      "question"?: "string",
      "feedback"?: "string",
      "suggestion"?: "string",
      "content"?: "string"
    }
  ]
}
- Each domain or project question should have a placeholder for feedback and suggestions (AI can fill them in real-time if you want)
- Keep questions conversational, natural, and brief
- Praise specifics when candidate performs well (e.g., project implementation, clear explanation)
- Suggestions should be constructive and actionable
`;

    const result = await generateWithAI(prompt, 'creative', { temperature: 0.8 });
    if (!result.success) {
      throw new Error(result.error || 'AI failed to generate full mock interview');
    }

    // Clean AI response and parse JSON
    let cleanedContent = result.content.trim();
    cleanedContent = cleanedContent.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '').trim();
    const jsonMatch = cleanedContent.match(/\{[\s\S]*\}/);
    if (!jsonMatch) throw new Error('Could not find JSON in AI response');

    const parsed = JSON.parse(jsonMatch[0]);
    if (!parsed.session || !Array.isArray(parsed.session)) {
      throw new Error('AI response JSON is missing "session" array');
    }

    return parsed;

  } catch (error) {
    throw new Error(`Failed to generate full mock interview: ${error.message}`);
  }
};

export const startInterview = async (req, res) => {
  try {
    const { domain, difficulty, timeLimit } = req.body;
    const userId = req.studentId || req.student?._id || req.user?.id || req.user?._id;
    if (!userId) return res.status(401).json({ success: false, message: 'Not authenticated - Student ID not found' });
    if (!domain) return res.status(400).json({ success: false, message: 'Domain is required' });
    // Validate time limit if provided (allowed 10-60 minutes)
    let effectiveTimeLimit = 40;
    if (typeof timeLimit === 'number') {
      effectiveTimeLimit = Math.max(10, Math.min(60, Math.round(timeLimit)));
    }
    const openingQuestion = await generateOpeningQuestion(domain, difficulty || 'medium');
    const effectiveDifficulty = difficulty || 'medium';
    const interview = new MockInterview({
      studentId: userId,
      domain,
      difficulty: effectiveDifficulty,
      currentDifficulty: effectiveDifficulty,
      startedAt: new Date(),
      status: 'in-progress',
      interviewType: 'conversational',
      conversationHistory: [],
      currentTopic: 'introduction',
      timeLimit: effectiveTimeLimit,
      sections: {
        conversation: {
          history: [],
          currentQuestion: openingQuestion.question,
          currentTopic: 'introduction',
          topicsCovered: ['introduction'],
          startTime: new Date()
        }
      }
    });
    await interview.save();
    res.json({ 
      success: true, 
      interviewId: interview._id, 
      studentId: userId, 
      domain, 
      difficulty, 
      welcomeMessage: openingQuestion.welcomeMessage || null,
      currentQuestion: openingQuestion.question, 
      currentTopic: 'introduction', 
      timeLimit: effectiveTimeLimit, 
      message: 'Interview started successfully' 
    });
  } catch (error) {
    res.status(500).json({ success: false, message: `Failed to start interview: ${error.message}`, error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error' });
  }
};

export const submitAnswer = async (req, res) => {
  try {
    const { interviewId, answer, responseTime } = req.body; // responseTime in seconds
    const userId = req.studentId || req.student?._id || req.user?.id || req.user?._id;
    if (!userId) return res.status(401).json({ success: false, message: 'Not authenticated' });
    if (!interviewId || !answer) return res.status(400).json({ success: false, message: 'Interview ID and answer are required' });
    
    // Clean and validate answer
    let cleanedAnswer = typeof answer === 'string' ? answer.trim() : String(answer).trim();
    
    // Remove common noise words and patterns
    const noisePatterns = [
      /\b(start|stop|pause|resume)\s+/gi,
      /\s+(start|stop|pause|resume)\b/gi,
      /\b(okay|ok|yeah|uh|um|ah|er)\s+/gi,
    ];
    
    for (const pattern of noisePatterns) {
      cleanedAnswer = cleanedAnswer.replace(pattern, ' ').trim();
    }
    
    // Remove excessive whitespace
    cleanedAnswer = cleanedAnswer.replace(/\s+/g, ' ').trim();
    
    // Validate answer is not empty or too short after cleaning
    if (cleanedAnswer.length < 3) {
      return res.status(400).json({ success: false, message: 'Answer must be at least 3 characters long after filtering' });
    }
    
    // Check if answer contains only noise words
    const noiseWords = ['start', 'stop', 'pause', 'resume', 'okay', 'ok', 'yeah'];
    const answerWords = cleanedAnswer.toLowerCase().split(/\s+/);
    const allNoise = answerWords.every(word => noiseWords.includes(word.replace(/[.,!?;:]/g, '')));
    if (allNoise && answerWords.length <= 5) {
      return res.status(400).json({ success: false, message: 'Answer appears to contain only noise words. Please provide a meaningful response.' });
    }
    
    // Use cleaned answer
    const finalAnswer = cleanedAnswer;
    
    const interview = await MockInterview.findOne({ _id: interviewId, studentId: userId, status: 'in-progress' });
    if (!interview) return res.status(404).json({ success: false, message: 'Interview not found or already completed' });
    const elapsedMinutes = (new Date() - interview.startedAt) / (1000 * 60);
    if (elapsedMinutes >= interview.timeLimit) {
      interview.status = 'completed';
      await interview.save();
      return res.status(400).json({ success: false, message: 'Interview time limit exceeded' });
    }
    
    // Score this answer (FREE - uses Ollama or keyword fallback)
    const currentQuestion = interview.sections.conversation.currentQuestion;
    const currentTopic = interview.sections.conversation.currentTopic;
    const answerScore = await scoreAnswer(currentQuestion, finalAnswer, currentTopic, interview.domain, interview.currentDifficulty || interview.difficulty);
    
    // Create conversation entry with scoring
    const conversationEntry = {
      question: currentQuestion,
      answer: finalAnswer,
      timestamp: new Date(),
      topic: currentTopic,
      score: answerScore.score,
      feedback: answerScore.feedback,
      sentiment: answerScore.sentiment,
      confidence: answerScore.confidence,
      responseTime: responseTime || null
    };
    interview.sections.conversation.history.push(conversationEntry);
    
    // Analyze response for next topic
    const analysis = await analyzeResponse(finalAnswer, currentTopic, interview.domain, interview.currentDifficulty || interview.difficulty);
    
    // Adaptive difficulty adjustment (FREE) - based on average of recent scores
    const recentScores = interview.sections.conversation.history.slice(-5).map(h => h.score || 70);
    const newDifficulty = adjustDifficulty(interview.currentDifficulty || interview.difficulty, answerScore.score, recentScores);
    
    // CRITICAL: Update difficulty in interview document BEFORE generating next question
    interview.currentDifficulty = newDifficulty;
    await interview.save(); // Save to ensure state is persisted
    
    // Generate follow-up question with ADJUSTED difficulty (explicitly passed)
    const followUpQuestion = await generateFollowUpQuestion(
      interview.sections.conversation.history,
      interview.domain,
      newDifficulty, // Use the newly adjusted difficulty
      analysis.nextTopic
    );
    
    interview.sections.conversation.currentQuestion = followUpQuestion.question;
    interview.sections.conversation.currentTopic = analysis.nextTopic;
    if (!interview.sections.conversation.topicsCovered.includes(analysis.nextTopic)) {
      interview.sections.conversation.topicsCovered.push(analysis.nextTopic);
    }
    
    await interview.save();
    
    const progress = Math.min((elapsedMinutes / interview.timeLimit) * 100, 100);
    const questionsAnswered = interview.sections.conversation.history.length;
    const averageScore = recentScores.length > 0 ? Math.round(recentScores.reduce((a, b) => a + b, 0) / recentScores.length) : answerScore.score;
    
    res.json({
      success: true,
      nextQuestion: followUpQuestion.question,
      currentTopic: analysis.nextTopic,
      topicsCovered: interview.sections.conversation.topicsCovered,
      progress: Math.round(progress),
      timeRemaining: Math.max(0, interview.timeLimit - elapsedMinutes),
      questionsAnswered,
      answerScore: {
        score: answerScore.score,
        feedback: answerScore.feedback,
        sentiment: answerScore.sentiment,
        confidence: answerScore.confidence
      },
      difficulty: newDifficulty,
      averageScore,
      analysis: {
        nextTopic: analysis.nextTopic,
        confidence: analysis.confidence,
        reasoning: analysis.reasoning
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: `Failed to submit answer: ${error.message}`, error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error' });
  }
};

export const completeInterview = async (req, res) => {
  try {
    const { interviewId } = req.body;
    const userId = req.studentId || req.student?._id || req.user?.id || req.user?._id;
    if (!userId) return res.status(401).json({ success: false, message: 'Not authenticated' });
    const interview = await MockInterview.findOne({ _id: interviewId, studentId: userId, status: 'in-progress' });
    if (!interview) return res.status(404).json({ success: false, message: 'Interview not found or already completed' });
    interview.status = 'completed';
    interview.completedAt = new Date();
    interview.duration = (interview.completedAt - interview.startedAt) / (1000 * 60);
    const scores = await calculateScores(interview);
    interview.scores = scores;
    interview.feedback = scores.feedback;
    interview.strengths = scores.strengths || [];
    interview.improvements = scores.improvements || [];
    await interview.save();
    res.json({
      success: true,
      interviewId: interview._id,
      duration: interview.duration,
      scores,
      topicsCovered: interview.sections.conversation.topicsCovered,
      totalQuestions: interview.sections.conversation.history.length,
      feedback: scores.feedback,
      strengths: scores.strengths,
      improvements: scores.improvements,
      message: 'Interview completed successfully'
    });
  } catch (error) {
    res.status(500).json({ success: false, message: `Failed to complete interview: ${error.message}`, error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error' });
  }
};

const calculateScores = async (interview) => {
  try {
    const conversation = interview.sections.conversation.history;
    const domain = interview.domain;
    const difficulty = interview.difficulty;
    const totalQuestions = conversation.length;
    const topicsCovered = interview.sections.conversation.topicsCovered.length;
    const duration = interview.duration;
    
    // Calculate average scores from per-answer scoring
    const avgScore = conversation.length > 0 
      ? Math.round(conversation.reduce((sum, entry) => sum + (entry.score || 70), 0) / conversation.length)
      : 70;
    const avgConfidence = conversation.length > 0
      ? conversation.reduce((sum, entry) => sum + (entry.confidence || 0.5), 0) / conversation.length
      : 0.5;
    
    // Base scores (fallback when AI unavailable)
    const communicationScore = Math.min(100, Math.max(40, avgScore + (avgConfidence * 20)));
    const technicalScore = topicsCovered >= 3 ? 85 : topicsCovered >= 2 ? 70 : 60;
    const problemSolvingScore = topicsCovered >= 2 ? 80 : 65;
    const timeManagementScore = duration <= 40 ? 90 : duration <= 45 ? 75 : 60;
    const engagementScore = Math.min(100, Math.round(avgConfidence * 100));

    // Enhanced AI-based analysis (Gemini or Ollama)
    try {
        // Format conversation history with all per-answer details
        const conversationHistoryFormatted = conversation.map(ex => ({
          question: ex.question,
          answer: ex.answer,
          score: ex.score || 'N/A',
          topic: ex.topic || 'general',
          feedback: ex.feedback || '',
          sentiment: ex.sentiment || 'neutral',
          confidence: ex.confidence || 0.5,
          responseTime: ex.responseTime || null
        }));
        
        const conversationText = conversation
          .map(ex => `Q: ${ex.question}\nA: ${ex.answer}\nScore: ${ex.score || 'N/A'}\nFeedback: ${ex.feedback || ''}\nTopic: ${ex.topic || 'general'}\nSentiment: ${ex.sentiment || 'neutral'}\nConfidence: ${ex.confidence || 0.5}\nResponseTime: ${ex.responseTime || 'N/A'}s`)
          .join('\n\n---\n\n');
        
        const prompt = `Variable Name,Description,Example Value
DOMAIN,The interview subject.,${domain}
DIFFICULTY,The initial difficulty setting.,${difficulty}
CONVERSATION_HISTORY,The entire, rich history of Q/A pairs, including per-answer scores and feedback.,${JSON.stringify(conversationHistoryFormatted)}

**ROLE:** Chief Interview Analyst.
**DOMAIN:** ${domain}
**INITIAL DIFFICULTY:** ${difficulty}

**FULL CONVERSATION HISTORY (Including per-answer scores):**
${conversationText}

**INSTRUCTIONS:**
1.  **Analyze and Assign Scores (0-100):** Based on the entire history, assign a final score (0-100) for each of the following categories, using the individual answer scores as a primary guide:
    * \`communication\` (Clarity, use of jargon, structure, confidence, response time, ability to articulate thoughts).
    * \`technicalKnowledge\` (Accuracy, depth, breadth of knowledge related to ${domain}, understanding of core concepts, familiarity with technologies/tools).
    * \`problemSolving\` (Structure, approach, and efficiency of proposed solutions, ability to break down complex problems, logical thinking).
    * \`timeManagement\` (Pacing, conciseness, and adherence to the time limit implied by response times).
    * \`engagement\` (Enthusiasm, ability to follow complex questions, self-correction, active participation, ability to discuss projects and challenges).
2.  **Overall Score:** Calculate an overall average score.
3.  **Feedback Summary:** Generate a concise, professional, and encouraging overall summary (max 4-5 sentences) that:
    - Highlights their overall performance
    - Mentions their technical knowledge and communication skills
    - References specific topics, projects, or challenges they discussed
    - Provides encouragement and actionable guidance
4.  **Final Strengths & Improvements:** Extract the 3 most significant **strengths** and the 3 most critical **improvements** from the per-answer feedback history. Consider:
    - Technical knowledge demonstrated
    - Projects and challenges discussed
    - Problem-solving approaches
    - Communication clarity
    - Areas needing development

**REQUIRED JSON OUTPUT SCHEMA:**
{
  "scores": {
    "communication": "Final score 0-100.",
    "technicalKnowledge": "Final score 0-100.",
    "problemSolving": "Final score 0-100.",
    "timeManagement": "Final score 0-100.",
    "engagement": "Final score 0-100.",
    "overall": "Final average score 0-100."
  },
  "feedback": "The overall summary paragraph.",
  "strengths": [
    "Most significant strength 1.",
    "Most significant strength 2.",
    "Most significant strength 3."
  ],
  "improvements": [
    "Most critical improvement 1.",
    "Most critical improvement 2.",
    "Most critical improvement 3."
  ]
}

**GENERATE RESPONSE NOW:**`;

        const result = await generateWithAI(prompt, 'analytical', { temperature: 0.3 });
        if (!result.success) {
          throw new Error(result.error || 'Failed to generate evaluation with AI');
        }
        
        try {
          // Clean the response - remove markdown code blocks if present
          let cleanedContent = result.content.trim();
          cleanedContent = cleanedContent.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/\s*```$/i, '').trim();
          
          // Try to extract JSON if there's extra text
          const jsonMatch = cleanedContent.match(/\{[\s\S]*\}/);
          if (jsonMatch) {
            cleanedContent = jsonMatch[0];
          }
          
          const aiAnalysis = JSON.parse(cleanedContent);
          
          // Handle both old format (flat) and new format (nested scores object)
          const scores = aiAnalysis.scores || {};
          const overallScore = scores.overall || aiAnalysis.overall || Math.round((communicationScore + technicalScore + problemSolvingScore + timeManagementScore + engagementScore) / 5);
          
            return {
            communication: Math.min(100, Math.max(0, scores.communication || aiAnalysis.communication || communicationScore)),
            technicalKnowledge: Math.min(100, Math.max(0, scores.technicalKnowledge || aiAnalysis.technicalKnowledge || technicalScore)),
            problemSolving: Math.min(100, Math.max(0, scores.problemSolving || aiAnalysis.problemSolving || problemSolvingScore)),
            timeManagement: Math.min(100, Math.max(0, scores.timeManagement || aiAnalysis.timeManagement || timeManagementScore)),
            engagement: Math.min(100, Math.max(0, scores.engagement || aiAnalysis.engagement || engagementScore)),
            overall: Math.min(100, Math.max(0, overallScore)),
            feedback: aiAnalysis.feedback || `Good interview performance. Covered ${topicsCovered} topics in ${Math.round(duration)} minutes.`,
            strengths: aiAnalysis.strengths || ['Good communication', 'Relevant experience', 'Clear thinking'],
            improvements: aiAnalysis.improvements || ['Add more technical depth', 'Provide specific examples', 'Improve time management'],
              aiAnalyzed: true,
              model: result.model
            };
        } catch (parseError) {
          throw new Error(`Failed to parse AI evaluation response: ${parseError.message}`);
        }
      } catch (aiError) {
        throw new Error(`AI evaluation failed: ${aiError.message}`);
      }
  } catch (error) {
    throw new Error(`Failed to calculate interview scores: ${error.message}`);
  }
};












