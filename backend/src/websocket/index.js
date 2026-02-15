import { logger } from '../utils/logger.js';
import { verifyToken } from '../utils/jwt.js';
import { redis } from '../services/redis.js';
import { handleConnection } from './handlers/connection.handler.js';
import { handleTranslation } from './handlers/translation.handler.js';
import { handleSession } from './handlers/session.handler.js';

export const setupWebSocket = (io) => {
  // Authentication middleware
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token || socket.handshake.query.token;
      
      if (!token) {
        return next(new Error('Authentication required'));
      }

      const decoded = verifyToken(token);
      socket.userId = decoded.userId;
      socket.sessionId = socket.handshake.query.sessionId;
      
      next();
    } catch (error) {
      logger.error('WebSocket auth error:', error);
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    logger.info(`Client connected: ${socket.id}, User: ${socket.userId}`);

    // Track active connections
    redis.sadd('active:connections', socket.id);
    redis.setex(`connection:${socket.id}`, 3600, JSON.stringify({
      userId: socket.userId,
      sessionId: socket.sessionId,
      connectedAt: new Date().toISOString()
    }));

    // Connection handlers
    handleConnection(socket, io);
    
    // Session handlers
    handleSession(socket, io);
    
    // Translation handlers
    handleTranslation(socket, io);

    // Heartbeat
    socket.on('heartbeat', () => {
      socket.emit('heartbeat', { timestamp: Date.now() });
    });

    // Disconnect
    socket.on('disconnect', (reason) => {
      logger.info(`Client disconnected: ${socket.id}, Reason: ${reason}`);
      redis.srem('active:connections', socket.id);
      redis.del(`connection:${socket.id}`);
    });

    // Error handling
    socket.on('error', (error) => {
      logger.error(`Socket error for ${socket.id}:`, error);
    });
  });

  logger.info('✅ WebSocket server configured');
};
