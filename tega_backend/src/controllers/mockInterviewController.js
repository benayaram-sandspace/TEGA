// Minimal mock interview controller to unblock server startup.
// Replace with real implementations as backend is built out.

export async function startInterview(req, res) {
  try {
    const { role = 'general', difficulty = 'medium' } = req.body || {};
    return res.status(200).json({
      success: true,
      interviewId: 'mock-' + Date.now(),
      role,
      difficulty,
      firstQuestion: {
        id: 'q1',
        type: 'behavioral',
        prompt: 'Tell me about yourself.',
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to start interview' });
  }
}

export async function submitAnswer(req, res) {
  try {
    const { interviewId, questionId, answer } = req.body || {};
    return res.status(200).json({
      success: true,
      interviewId,
      questionId,
      feedback: {
        score: 0.8,
        notes: 'Clear structure and relevant experience. Could add more measurable outcomes.',
      },
      nextQuestion: {
        id: 'q2',
        type: 'technical',
        prompt: 'Explain event loop in JavaScript.',
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to submit answer' });
  }
}

export async function submitCode(req, res) {
  try {
    const { interviewId, questionId, code } = req.body || {};
    return res.status(200).json({
      success: true,
      interviewId,
      questionId,
      result: {
        testsPassed: 3,
        testsTotal: 3,
        remarks: 'Efficient solution with good time complexity.',
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to submit code' });
  }
}

export async function completeInterview(req, res) {
  try {
    const { interviewId } = req.body || {};
    return res.status(200).json({
      success: true,
      interviewId,
      report: {
        overallScore: 82,
        strengths: ['Communication', 'Problem Solving'],
        improvements: ['System Design depth'],
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to complete interview' });
  }
}

export async function getInterviewStats(req, res) {
  try {
    const { userId } = req.params || {};
    return res.status(200).json({
      success: true,
      userId,
      stats: {
        totalInterviews: 3,
        averageScore: 78,
        lastInterviewAt: new Date().toISOString(),
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch stats' });
  }
}

export async function getLeaderboard(req, res) {
  try {
    return res.status(200).json({
      success: true,
      leaderboard: [
        { userId: 'u1', name: 'Alice', score: 92 },
        { userId: 'u2', name: 'Bob', score: 89 },
        { userId: 'u3', name: 'Charlie', score: 87 },
      ],
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch leaderboard' });
  }
}


