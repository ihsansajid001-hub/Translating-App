import { supabase } from '../services/supabase.js';
import { AppError } from '../middleware/errorHandler.js';

export const getProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;

    const { data: profile, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) throw new AppError(error.message, 400);

    res.json({
      success: true,
      data: profile
    });
  } catch (error) {
    next(error);
  }
};

export const updateProfile = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { username, preferredLanguage } = req.body;

    const updates = {};
    if (username) updates.username = username;
    if (preferredLanguage) updates.preferred_language = preferredLanguage;

    const { data: profile, error } = await supabase
      .from('users')
      .update(updates)
      .eq('id', userId)
      .select()
      .single();

    if (error) throw new AppError(error.message, 400);

    res.json({
      success: true,
      data: profile
    });
  } catch (error) {
    next(error);
  }
};

export const getUserStats = async (req, res, next) => {
  try {
    const userId = req.user.id;

    // Get session count
    const { data: sessions, error: sessionError } = await supabase
      .from('sessions')
      .select('id, status, created_at')
      .or(`user_a_id.eq.${userId},user_b_id.eq.${userId}`);

    if (sessionError) throw new AppError(sessionError.message, 400);

    // Get translation count
    const { data: translations, error: translationError } = await supabase
      .from('translation_logs')
      .select('id, total_latency')
      .eq('user_id', userId);

    if (translationError) throw new AppError(translationError.message, 400);

    const stats = {
      totalSessions: sessions.length,
      activeSessions: sessions.filter(s => s.status === 'active').length,
      totalTranslations: translations.length,
      averageLatency: translations.reduce((sum, t) => sum + (t.total_latency || 0), 0) / translations.length || 0
    };

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    next(error);
  }
};
