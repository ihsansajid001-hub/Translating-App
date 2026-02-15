import { verifyToken } from '../utils/jwt.js';
import { supabase } from '../services/supabase.js';
import { AppError } from './errorHandler.js';

export const authenticate = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (!token) {
      throw new AppError('Authentication required', 401);
    }

    const decoded = verifyToken(token);
    
    // Verify user exists
    const { data: user, error } = await supabase
      .from('users')
      .select('id, email, username, preferred_language')
      .eq('id', decoded.userId)
      .single();

    if (error || !user) {
      throw new AppError('Invalid token', 401);
    }

    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      next(new AppError('Invalid token', 401));
    } else if (error.name === 'TokenExpiredError') {
      next(new AppError('Token expired', 401));
    } else {
      next(error);
    }
  }
};
