// Mock interview controller - Leaderboard functionality
// Note: Conversational interview routes are handled by interviewController.js

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


