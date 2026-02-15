import { createClient } from '@supabase/supabase-js';
import { config } from '../config/index.js';
import { logger } from '../utils/logger.js';

// For demo mode - create a mock client if Supabase is not configured
let supabase;

if (!config.supabase.url || !config.supabase.anonKey || config.supabase.url.includes('demo')) {
  logger.warn('⚠️  Supabase not configured - using DEMO MODE');
  logger.warn('⚠️  To use real database, sign up at https://supabase.com and update .env');
  
  // Create mock Supabase client for demo
  supabase = {
    from: (table) => ({
      select: () => ({ data: [], error: null, single: () => ({ data: null, error: null }) }),
      insert: () => ({ data: [], error: null, select: () => ({ data: [], error: null, single: () => ({ data: null, error: null }) }) }),
      update: () => ({ data: [], error: null, eq: () => ({ data: [], error: null, select: () => ({ data: [], error: null, single: () => ({ data: null, error: null }) }) }) }),
      delete: () => ({ data: [], error: null, eq: () => ({ data: [], error: null }) }),
      eq: () => ({ data: [], error: null, single: () => ({ data: null, error: null }) }),
      or: () => ({ data: [], error: null }),
      order: () => ({ data: [], error: null }),
      range: () => ({ data: [], error: null }),
    }),
    auth: {
      signUp: () => ({ data: { user: { id: 'demo-user-id' } }, error: null }),
      signInWithPassword: () => ({ data: { user: { id: 'demo-user-id' } }, error: null }),
      signOut: () => ({ error: null }),
      refreshSession: () => ({ data: { user: { id: 'demo-user-id' } }, error: null }),
      signInWithOAuth: () => ({ data: { url: 'https://demo-oauth.com' }, error: null }),
    }
  };
  
  logger.info('✅ Demo mode initialized - app will work without database');
} else {
  supabase = createClient(
    config.supabase.url,
    config.supabase.anonKey,
    {
      auth: {
        autoRefreshToken: true,
        persistSession: false
      }
    }
  );
  logger.info('✅ Supabase client initialized');
}

export { supabase };
