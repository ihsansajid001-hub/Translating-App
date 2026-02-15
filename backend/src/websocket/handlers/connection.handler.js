import { logger } from '../../utils/logger.js';
import { redis } from '../../services/redis.js';

export const handleConnection = (socket, io) => {
  // Join session room
  socket.on('join_session', async (data) => {
    try {
      const { sessionId } = data;
      
      if (!sessionId) {
        socket.emit('error', { message: 'Session ID required' });
        return;
      }

      // Get session from Redis
      const sessionData = await redis.get(`session:${sessionId}`);
      if (!sessionData) {
        socket.emit('error', { message: 'Session not found' });
        return;
      }

      const session = JSON.parse(sessionData);

      // Verify user is part of session
      if (session.user_a_id !== socket.userId && session.user_b_id !== socket.userId) {
        socket.emit('error', { message: 'Unauthorized' });
        return;
      }

      // Join room
      socket.join(`session:${sessionId}`);
      socket.sessionId = sessionId;

      // Store user's socket in Redis
      await redis.setex(
        `user:${socket.userId}:socket`,
        3600,
        socket.id
      );

      // Notify user
      socket.emit('session_joined', {
        sessionId,
        status: session.status,
        language: session.user_a_id === socket.userId ? session.language_a : session.language_b
      });

      // Notify partner if they're connected
      const partnerId = session.user_a_id === socket.userId ? session.user_b_id : session.user_a_id;
      if (partnerId) {
        const partnerSocketId = await redis.get(`user:${partnerId}:socket`);
        if (partnerSocketId) {
          io.to(partnerSocketId).emit('partner_connected', {
            userId: socket.userId,
            sessionId
          });
        }
      }

      logger.info(`User ${socket.userId} joined session ${sessionId}`);
    } catch (error) {
      logger.error('Error joining session:', error);
      socket.emit('error', { message: 'Failed to join session' });
    }
  });

  // Leave session
  socket.on('leave_session', async (data) => {
    try {
      const { sessionId } = data;
      
      socket.leave(`session:${sessionId}`);
      await redis.del(`user:${socket.userId}:socket`);

      // Notify partner
      socket.to(`session:${sessionId}`).emit('partner_disconnected', {
        userId: socket.userId,
        sessionId
      });

      socket.emit('session_left', { sessionId });
      
      logger.info(`User ${socket.userId} left session ${sessionId}`);
    } catch (error) {
      logger.error('Error leaving session:', error);
    }
  });

  // Get connection status
  socket.on('get_status', async () => {
    try {
      const activeConnections = await redis.scard('active:connections');
      
      socket.emit('status', {
        connected: true,
        userId: socket.userId,
        sessionId: socket.sessionId,
        activeConnections,
        timestamp: Date.now()
      });
    } catch (error) {
      logger.error('Error getting status:', error);
    }
  });
};
