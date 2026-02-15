import { nanoid } from 'nanoid';
import { supabase } from '../services/supabase.js';
import { redis } from '../services/redis.js';
import { AppError } from '../middleware/errorHandler.js';
import { logger } from '../utils/logger.js';

// Generate 6-digit session code
const generateSessionCode = () => {
  return nanoid(6).toUpperCase();
};

export const createSession = async (req, res, next) => {
  try {
    const { language } = req.body;
    const userId = req.user.id;

    const sessionCode = generateSessionCode();

    // Create session in database
    const { data: session, error } = await supabase
      .from('sessions')
      .insert([{
        session_code: sessionCode,
        user_a_id: userId,
        language_a: language,
        status: 'waiting'
      }])
      .select()
      .single();

    if (error) throw new AppError(error.message, 400);

    // Store in Redis for fast lookup
    await redis.setex(
      `session:${session.id}`,
      3600, // 1 hour TTL
      JSON.stringify(session)
    );

    await redis.setex(
      `session:code:${sessionCode}`,
      3600,
      session.id
    );

    logger.info(`Session created: ${sessionCode} by user ${userId}`);

    res.status(201).json({
      success: true,
      data: {
        sessionId: session.id,
        sessionCode,
        wsUrl: `${process.env.WS_URL || 'ws://localhost:3001'}?sessionId=${session.id}`
      }
    });
  } catch (error) {
    next(error);
  }
};

export const joinSession = async (req, res, next) => {
  try {
    const { sessionCode, language } = req.body;
    const userId = req.user.id;

    // Get session ID from Redis
    const sessionId = await redis.get(`session:code:${sessionCode}`);
    if (!sessionId) throw new AppError('Session not found', 404);

    // Get session from database
    const { data: session, error: fetchError } = await supabase
      .from('sessions')
      .select('*')
      .eq('id', sessionId)
      .single();

    if (fetchError || !session) throw new AppError('Session not found', 404);

    if (session.status !== 'waiting') {
      throw new AppError('Session is not available', 400);
    }

    if (session.user_a_id === userId) {
      throw new AppError('Cannot join your own session', 400);
    }

    // Update session with second user
    const { data: updatedSession, error: updateError } = await supabase
      .from('sessions')
      .update({
        user_b_id: userId,
        language_b: language,
        status: 'active',
        started_at: new Date().toISOString()
      })
      .eq('id', sessionId)
      .select()
      .single();

    if (updateError) throw new AppError(updateError.message, 400);

    // Update Redis cache
    await redis.setex(
      `session:${sessionId}`,
      3600,
      JSON.stringify(updatedSession)
    );

    logger.info(`User ${userId} joined session ${sessionCode}`);

    res.json({
      success: true,
      data: {
        sessionId: updatedSession.id,
        partnerId: session.user_a_id,
        wsUrl: `${process.env.WS_URL || 'ws://localhost:3001'}?sessionId=${updatedSession.id}`
      }
    });
  } catch (error) {
    next(error);
  }
};

export const getSession = async (req, res, next) => {
  try {
    const { sessionId } = req.params;
    const userId = req.user.id;

    // Try Redis first
    let session = await redis.get(`session:${sessionId}`);
    
    if (session) {
      session = JSON.parse(session);
    } else {
      // Fallback to database
      const { data, error } = await supabase
        .from('sessions')
        .select('*')
        .eq('id', sessionId)
        .single();

      if (error || !data) throw new AppError('Session not found', 404);
      session = data;
    }

    // Check if user is part of this session
    if (session.user_a_id !== userId && session.user_b_id !== userId) {
      throw new AppError('Unauthorized', 403);
    }

    res.json({
      success: true,
      data: session
    });
  } catch (error) {
    next(error);
  }
};

export const endSession = async (req, res, next) => {
  try {
    const { sessionId } = req.params;
    const userId = req.user.id;

    const { data: session, error: fetchError } = await supabase
      .from('sessions')
      .select('*')
      .eq('id', sessionId)
      .single();

    if (fetchError || !session) throw new AppError('Session not found', 404);

    // Check authorization
    if (session.user_a_id !== userId && session.user_b_id !== userId) {
      throw new AppError('Unauthorized', 403);
    }

    // Update session status
    const { error: updateError } = await supabase
      .from('sessions')
      .update({
        status: 'ended',
        ended_at: new Date().toISOString()
      })
      .eq('id', sessionId);

    if (updateError) throw new AppError(updateError.message, 400);

    // Remove from Redis
    await redis.del(`session:${sessionId}`);
    if (session.session_code) {
      await redis.del(`session:code:${session.session_code}`);
    }

    logger.info(`Session ended: ${sessionId}`);

    res.json({
      success: true,
      message: 'Session ended successfully'
    });
  } catch (error) {
    next(error);
  }
};

export const getSessionHistory = async (req, res, next) => {
  try {
    const { sessionId } = req.params;
    const userId = req.user.id;
    const { limit = 50, offset = 0 } = req.query;

    // Verify user access
    const { data: session } = await supabase
      .from('sessions')
      .select('user_a_id, user_b_id')
      .eq('id', sessionId)
      .single();

    if (!session || (session.user_a_id !== userId && session.user_b_id !== userId)) {
      throw new AppError('Unauthorized', 403);
    }

    // Get translation history
    const { data: translations, error } = await supabase
      .from('translation_logs')
      .select('*')
      .eq('session_id', sessionId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw new AppError(error.message, 400);

    res.json({
      success: true,
      data: translations
    });
  } catch (error) {
    next(error);
  }
};

export const getActiveSessions = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const { data: sessions, error } = await supabase
      .from('sessions')
      .select('*')
      .or(`user_a_id.eq.${userId},user_b_id.eq.${userId}`)
      .eq('status', 'active')
      .order('created_at', { ascending: false });

    if (error) throw new AppError(error.message, 400);

    res.json({
      success: true,
      data: sessions
    });
  } catch (error) {
    next(error);
  }
};
