import { supabase } from '../services/supabase.js';
import { generateToken, generateRefreshToken } from '../utils/jwt.js';
import { AppError } from '../middleware/errorHandler.js';
import { logger } from '../utils/logger.js';

export const register = async (req, res, next) => {
  try {
    const { email, password, username, preferredLanguage } = req.body;

    // Register with Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          username,
          preferred_language: preferredLanguage || 'en'
        }
      }
    });

    if (authError) throw new AppError(authError.message, 400);

    // Create user profile in database
    const { data: profile, error: profileError } = await supabase
      .from('users')
      .insert([{
        id: authData.user.id,
        email,
        username,
        preferred_language: preferredLanguage || 'en'
      }])
      .select()
      .single();

    if (profileError) throw new AppError(profileError.message, 400);

    const token = generateToken(authData.user.id);
    const refreshToken = generateRefreshToken(authData.user.id);

    logger.info(`User registered: ${email}`);

    res.status(201).json({
      success: true,
      data: {
        user: {
          id: authData.user.id,
          email,
          username,
          preferredLanguage: preferredLanguage || 'en'
        },
        token,
        refreshToken
      }
    });
  } catch (error) {
    next(error);
  }
};

export const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) throw new AppError('Invalid credentials', 401);

    // Get user profile
    const { data: profile } = await supabase
      .from('users')
      .select('*')
      .eq('id', data.user.id)
      .single();

    const token = generateToken(data.user.id);
    const refreshToken = generateRefreshToken(data.user.id);

    logger.info(`User logged in: ${email}`);

    res.json({
      success: true,
      data: {
        user: profile,
        token,
        refreshToken
      }
    });
  } catch (error) {
    next(error);
  }
};

export const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken: token } = req.body;

    if (!token) throw new AppError('Refresh token required', 400);

    const { data, error } = await supabase.auth.refreshSession({
      refresh_token: token
    });

    if (error) throw new AppError('Invalid refresh token', 401);

    const newToken = generateToken(data.user.id);
    const newRefreshToken = generateRefreshToken(data.user.id);

    res.json({
      success: true,
      data: {
        token: newToken,
        refreshToken: newRefreshToken
      }
    });
  } catch (error) {
    next(error);
  }
};

export const logout = async (req, res, next) => {
  try {
    const { error } = await supabase.auth.signOut();
    if (error) throw new AppError(error.message, 400);

    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    next(error);
  }
};

export const socialLogin = async (req, res, next) => {
  try {
    const { provider } = req.params; // google, apple, facebook
    const { token } = req.body;

    const { data, error } = await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: process.env.OAUTH_REDIRECT_URL
      }
    });

    if (error) throw new AppError(error.message, 400);

    res.json({
      success: true,
      data: {
        url: data.url
      }
    });
  } catch (error) {
    next(error);
  }
};
