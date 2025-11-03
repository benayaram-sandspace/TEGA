import MockInterview from '../models/MockInterview.js';
import Student from '../models/Student.js';
import { generateWithOllama, checkOllamaAvailability, ensureModelAvailable, getModelForTask } from '../config/ollama.js';

let ollamaAvailable = false;
checkOllamaAvailability().then(result => {
  ollamaAvailable = result.available;
});

export const generateFollowUpQuestion = async (conversationHistory, domain, difficulty, currentTopic) => {
  try {
    if (!ollamaAvailable) {
      const mockQuestions = {
        technical: [
          "Can you elaborate on that approach?",
          "What challenges did you face with that solution?",
          "How would you optimize that for better performance?",
          "What alternative methods did you consider?",
          "Can you walk me through the implementation details?"
        ],
        behavioral: [
          "How did that experience shape your approach to similar problems?",
          "What would you do differently if you faced that situation again?",
          "How did you handle the team dynamics in that project?",
          "What was the most valuable lesson you learned?",
          "How did you measure the success of that project?"
        ],
        problem_solving: [
          "What was your first step when you encountered this problem?",
          "How did you break down the problem into smaller parts?",
          "What resources did you use to research the solution?",
          "How did you validate your approach?",
          "What would you do if you had more time/resources?"
        ]
      };
      const topicQuestions = mockQuestions[currentTopic] || mockQuestions.technical;
      return { success: true, question: topicQuestions[Math.floor(Math.random() * topicQuestions.length)], topic: currentTopic, difficulty };
    }

    const conversationContext = conversationHistory
      .slice(-5)
      .map(exchange => `Interviewer: ${exchange.question}\nStudent: ${exchange.answer}`)
      .join('\n\n');

    const prompt = `You are conducting a ${difficulty} level ${domain} technical interview. 

CONVERSATION HISTORY:
${conversationContext}

CURRENT TOPIC: ${currentTopic}

Based on the student's last response, generate a natural follow-up question that:
1. Builds on their answer
2. Goes deeper into the topic
3. Tests their understanding
4. Feels like a natural conversation
5. Is appropriate for ${difficulty} level
6. Relates to ${domain} development

Return ONLY the question text, no additional formatting or explanation.`;

    const result = await generateWithOllama(prompt, currentTopic, { temperature: 0.8 });
    if (!result.success) throw new Error(result.error);
    return { success: true, question: result.content.trim(), topic: currentTopic, difficulty };
  } catch (error) {
    const fallbackQuestions = [
      "That's interesting. Can you tell me more about that?",
      "How did you approach that particular challenge?",
      "What was your thought process behind that decision?",
      "Can you walk me through how you would implement that?",
      "What would you do differently if you had to do it again?"
    ];
    return { success: true, question: fallbackQuestions[Math.floor(Math.random() * fallbackQuestions.length)], topic: currentTopic, difficulty };
  }
};

export const analyzeResponse = async (response, currentTopic, domain, difficulty) => {
  try {
    if (!ollamaAvailable) {
      const technicalKeywords = ['code','programming','algorithm','function','class','method','database','API','framework'];
      const behavioralKeywords = ['team','project','challenge','learned','experience','worked','managed','led'];
      const problemSolvingKeywords = ['problem','solution','approach','debug','fix','optimize','improve'];
      const responseLower = response.toLowerCase();
      if (technicalKeywords.some(k => responseLower.includes(k))) return { nextTopic: 'technical', confidence: 0.7 };
      if (behavioralKeywords.some(k => responseLower.includes(k))) return { nextTopic: 'behavioral', confidence: 0.6 };
      if (problemSolvingKeywords.some(k => responseLower.includes(k))) return { nextTopic: 'problem_solving', confidence: 0.8 };
      return { nextTopic: currentTopic, confidence: 0.5 };
    }

    const prompt = `Analyze this student's interview response and determine the best next topic to explore.

STUDENT RESPONSE: "${response}"
CURRENT TOPIC: ${currentTopic}
DOMAIN: ${domain}
DIFFICULTY: ${difficulty}

Respond in JSON format:
{"nextTopic":"technical|behavioral|problem_solving","confidence":0.8,"reasoning":"..."}`;

    const result = await generateWithOllama(prompt, 'analytical', { temperature: 0.3 });
    if (!result.success) throw new Error(result.error);
    try {
      const analysis = JSON.parse(result.content);
      return { nextTopic: analysis.nextTopic || currentTopic, confidence: analysis.confidence || 0.5, reasoning: analysis.reasoning || 'Ollama analysis' };
    } catch {
      return { nextTopic: currentTopic, confidence: 0.5, reasoning: 'Parse error' };
    }
  } catch {
    return { nextTopic: currentTopic, confidence: 0.5, reasoning: 'Analysis error' };
  }
};

export const generateOpeningQuestion = async (domain, difficulty) => {
  try {
    if (!ollamaAvailable) {
      const openingQuestions = {
        Frontend: [
          "Tell me about yourself and your experience with frontend development.",
          "What got you interested in frontend development?",
          "Walk me through your frontend development journey."
        ],
        Backend: [
          "Tell me about yourself and your backend development experience.",
          "What aspects of backend development do you find most interesting?",
          "How did you get started with backend development?"
        ],
        Fullstack: [
          "Tell me about yourself and your full-stack development experience.",
          "What's your preferred approach to full-stack development?",
          "How do you balance frontend and backend development?"
        ],
        Mobile: [
          "Tell me about yourself and your mobile development experience.",
          "What platforms do you work with in mobile development?",
          "How did you get into mobile app development?"
        ],
        DevOps: [
          "Tell me about yourself and your DevOps experience.",
          "What aspects of infrastructure and automation interest you most?",
          "How did you get started with DevOps practices?"
        ],
        'Data Science': [
          "Tell me about yourself and your data science experience.",
          "What got you interested in data science and analytics?",
          "Walk me through your data science journey."
        ]
      };
      const questions = openingQuestions[domain] || openingQuestions.Frontend;
      return { success: true, question: questions[Math.floor(Math.random() * questions.length)], topic: 'introduction' };
    }
    return { success: true, question: `Tell me about yourself and your experience with ${domain} development.`, topic: 'introduction' };
  } catch {
    return { success: true, question: `Tell me about yourself and your experience with ${domain} development.`, topic: 'introduction' };
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
    const interview = new MockInterview({
      studentId: userId,
      domain,
      difficulty: difficulty || 'medium',
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
    res.json({ success: true, interviewId: interview._id, studentId: userId, domain, difficulty, currentQuestion: openingQuestion.question, currentTopic: 'introduction', timeLimit: effectiveTimeLimit, message: 'Interview started successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: `Failed to start interview: ${error.message}`, error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error' });
  }
};

export const submitAnswer = async (req, res) => {
  try {
    const { interviewId, answer } = req.body;
    const userId = req.studentId || req.student?._id || req.user?.id || req.user?._id;
    if (!userId) return res.status(401).json({ success: false, message: 'Not authenticated' });
    if (!interviewId || !answer) return res.status(400).json({ success: false, message: 'Interview ID and answer are required' });
    const interview = await MockInterview.findOne({ _id: interviewId, studentId: userId, status: 'in-progress' });
    if (!interview) return res.status(404).json({ success: false, message: 'Interview not found or already completed' });
    const elapsedMinutes = (new Date() - interview.startedAt) / (1000 * 60);
    if (elapsedMinutes >= interview.timeLimit) {
      interview.status = 'completed';
      await interview.save();
      return res.status(400).json({ success: false, message: 'Interview time limit exceeded' });
    }
    const conversationEntry = { question: interview.sections.conversation.currentQuestion, answer, timestamp: new Date(), topic: interview.sections.conversation.currentTopic };
    interview.sections.conversation.history.push(conversationEntry);
    const analysis = await analyzeResponse(answer, interview.sections.conversation.currentTopic, interview.domain, interview.difficulty);
    const followUpQuestion = await generateFollowUpQuestion(interview.sections.conversation.history, interview.domain, interview.difficulty, analysis.nextTopic);
    interview.sections.conversation.currentQuestion = followUpQuestion.question;
    interview.sections.conversation.currentTopic = analysis.nextTopic;
    if (!interview.sections.conversation.topicsCovered.includes(analysis.nextTopic)) {
      interview.sections.conversation.topicsCovered.push(analysis.nextTopic);
    }
    await interview.save();
    const progress = Math.min((elapsedMinutes / interview.timeLimit) * 100, 100);
    const questionsAnswered = interview.sections.conversation.history.length;
    res.json({ success: true, nextQuestion: followUpQuestion.question, currentTopic: analysis.nextTopic, topicsCovered: interview.sections.conversation.topicsCovered, progress: Math.round(progress), timeRemaining: Math.max(0, interview.timeLimit - elapsedMinutes), questionsAnswered, analysis: { nextTopic: analysis.nextTopic, confidence: analysis.confidence, reasoning: analysis.reasoning } });
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
    await interview.save();
    res.json({ success: true, interviewId: interview._id, duration: interview.duration, scores, topicsCovered: interview.sections.conversation.topicsCovered, totalQuestions: interview.sections.conversation.history.length, message: 'Interview completed successfully' });
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
    const communicationScore = Math.min(100, (totalQuestions * 10) + (topicsCovered * 5));
    const technicalScore = topicsCovered >= 3 ? 85 : topicsCovered >= 2 ? 70 : 60;
    const problemSolvingScore = topicsCovered >= 2 ? 80 : 65;
    const timeManagementScore = duration <= 40 ? 90 : duration <= 45 ? 75 : 60;
    if (ollamaAvailable) {
      try {
        const conversationText = conversation.map(ex => `Q: ${ex.question}\nA: ${ex.answer}`).join('\n\n');
        const prompt = `Analyze this ${domain} interview conversation and provide scores (0-100) for each category.`;
        const result = await generateWithOllama(prompt, 'analytical', { temperature: 0.3 });
        if (result.success) {
          try {
            const aiScores = JSON.parse(result.content);
            return {
              communication: aiScores.communication || communicationScore,
              technicalKnowledge: aiScores.technicalKnowledge || technicalScore,
              problemSolving: aiScores.problemSolving || problemSolvingScore,
              timeManagement: aiScores.timeManagement || timeManagementScore,
              overallFit: aiScores.overallFit || 75,
              feedback: aiScores.feedback || 'Good interview performance with room for improvement.',
              aiAnalyzed: true,
              model: result.model
            };
          } catch {}
        }
      } catch {}
    }
    return {
      communication: communicationScore,
      technicalKnowledge: technicalScore,
      problemSolving: problemSolvingScore,
      timeManagement: timeManagementScore,
      overallFit: Math.round((communicationScore + technicalScore + problemSolvingScore + timeManagementScore) / 4),
      feedback: `Good interview performance. Covered ${topicsCovered} topics in ${Math.round(duration)} minutes.`,
      aiAnalyzed: false
    };
  } catch {
    return { communication: 70, technicalKnowledge: 70, problemSolving: 70, timeManagement: 70, overallFit: 70, feedback: 'Interview completed successfully.', aiAnalyzed: false };
  }
};


