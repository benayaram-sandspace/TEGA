export const setupInterviewSocket = (io) => {
  io.on('connection', (socket) => {
    // When user starts an interview
    socket.on('interview:start', (data) => {
      // Broadcast to others
      socket.broadcast.emit('interview:started', {
        userId: data.userId,
        domain: data.domain,
        interviewId: data.interviewId,
        timestamp: new Date()
      });

      // Join user to room for this interview
      socket.join(`interview-${data.interviewId}`);
    });

    // When a score is updated
    socket.on('interview:scoreUpdate', (data) => {
      // Broadcast to interview room
      io.to(`interview-${data.interviewId}`).emit('interview:scoreUpdated', {
        userId: data.userId,
        section: data.section,
        score: data.score,
        timestamp: new Date()
      });
    });

    // When user completes interview
    socket.on('interview:complete', (data) => {
      // Broadcast completion
      socket.broadcast.emit('interview:completed', {
        userId: data.userId,
        interviewId: data.interviewId,
        overallScore: data.overallScore,
        domain: data.domain,
        timestamp: new Date()
      });

      // Leave interview room
      socket.leave(`interview-${data.interviewId}`);
    });

    // Leaderboard update request
    socket.on('leaderboard:update', (data) => {
      // Broadcast to all clients
      io.emit('leaderboard:refresh', {
        domain: data.domain,
        timestamp: new Date()
      });
    });

    // Real-time question submitted
    socket.on('interview:questionSubmitted', (data) => {
      io.to(`interview-${data.interviewId}`).emit('interview:questionSubmitted', {
        section: data.section,
        timestamp: new Date()
      });
    });

    // Code submission
    socket.on('interview:codeSubmitted', (data) => {
      io.to(`interview-${data.interviewId}`).emit('interview:codeSubmitted', {
        language: data.language,
        timestamp: new Date()
      });
    });

    // Disconnection
    socket.on('disconnect', () => {
    });
  });
};

export default setupInterviewSocket;
