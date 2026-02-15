import { logger } from '../../utils/logger.js';
import { redis } from '../../services/redis.js';
import { supabase } from '../../services/supabase.js';

export const handleSession = (socket, io) => {
  // Update session settings
  socket.on('update_settings', async (data) => {
    try {
      const { sessionId, settings } = data;
      
      if (!socket.sessionId || socket.sessionId !== sessionId) {
        socket.emit('error', { message: 'Not in this session' });
        return;
      }

      // Store settings in Redis
      await redis.hset(
        `session:${sessionId}:settings`,
        socket.userId,
        JSON.stringify(settings)
      );

      // Notify partner
      socket.to(`session:${sessionId}`).emit('partner_settings_updated', {
        userId: socket.userId,
        settings
      });

      socket.emit('settings_updated', { success: true });
      
      logger.info(`Settings updated for session ${sessionId} by user ${socket.userId}`);
    } catch (error) {
      logger.error('Error updating settings:', error);
      socket.emit('error', { message: 'Failed to update settings' });
    }
  });

  // Send typing indicator
  socket.on('typing', (data) => {
    const { sessionId, isTyping } = data;
    
    if (socket.sessionId === sessionId) {
      socket.to(`session:${sessionId}`).emit('partner_typing', {
        userId: socket.userId,
        isTyping
      });
    }
  });

  // Request session info
  socket.on('get_session_info', async (data) => {
    try {
      const { sessionId } = data;
      
      const sessionData = await redis.get(`session:${sessionId}`);
      if (!sessionData) {
        socket.emit('error', { message: 'Session not found' });
        return;
      }

      const session = JSON.parse(sessionData);
      
      // Get partner info
      const partnerId = session.user_a_id === socket.userId ? session.user_b_id : session.user_a_id;
      let partnerOnline = false;
      
      if (partnerId) {
        const partnerSocketId = await redis.get(`user:${partnerId}:socket`);
        partnerOnline = !!partnerSocketId;
      }

      socket.emit('session_info', {
        session,
        partnerOnline,
        messageCount: await redis.llen(`session:${sessionId}:messages`)
      });
    } catch (error) {
      logger.error('Error getting session info:', error);
      socket.emit('error', { message: 'Failed to get session info' });
    }
  });

  // End session
  socket.on('end_session', async (data) => {
    try {
      const { sessionId } = data;
      
      if (socket.sessionId !== sessionId) {
        socket.emit('error', { message: 'Not in this session' });
        return;
      }

      // Update database
      await supabase
        .from('sessions')
        .update({
          status: 'ended',
          ended_at: new Date().toISOString()
        })
        .eq('id', sessionId);

      // Notify all participants
      io.to(`session:${sessionId}`).emit('session_ended', {
        sessionId,
        endedBy: socket.userId,
        timestamp: Date.now()
      });

      // Clean up Redis
      await redis.del(`session:${sessionId}`);
      await redis.del(`session:${sessionId}:settings`);
      await redis.del(`session:${sessionId}:messages`);

      logger.info(`Session ${sessionId} ended by user ${socket.userId}`);
    } catch (error) {
      logger.error('Error ending session:', error);
      socket.emit('error', { message: 'Failed to end session' });
    }
  });
};
