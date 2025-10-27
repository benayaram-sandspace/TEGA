export const setupInterviewSocket = (io) => {
  io.on('connection', (socket) => {
    // console.log('User connected to interview socket:', socket.id);

    // When user starts an interview
    socket.on('interview:start', (data) => {
      // console.log('Interview started:', data.userId, data.domain);
      
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
      // console.log('Score updated:', data.section, data.score);
      
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
      // console.log('Interview completed:', data.interviewId);
      
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
      // console.log('Leaderboard update requested for:', data.domain);
      
      // Broadcast to all clients
      io.emit('leaderboard:refresh', {
        domain: data.domain,
        timestamp: new Date()
      });
    });

    // Real-time question submitted
    socket.on('interview:questionSubmitted', (data) => {
      // console.log('Question submitted:', data.section);
      
      io.to(`interview-${data.interviewId}`).emit('interview:questionSubmitted', {
        section: data.section,
        timestamp: new Date()
      });
    });

    // Code submission
    socket.on('interview:codeSubmitted', (data) => {
      // console.log('Code submitted for evaluation');
      
      io.to(`interview-${data.interviewId}`).emit('interview:codeSubmitted', {
        language: data.language,
        timestamp: new Date()
      });
    });

    // Disconnection
    socket.on('disconnect', () => {
      // console.log('User disconnected:', socket.id);
    });
  });
};

export default setupInterviewSocket;

