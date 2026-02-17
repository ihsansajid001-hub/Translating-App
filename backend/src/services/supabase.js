import { createClient } from '@supabase/supabase-js';
import { config } from '../config/index.js';
import { logger } from '../utils/logger.js';

// For demo mode - create a mock client if Supabase is not configured
let supabase;

const isValidSupabaseConfig = config.supabase.url && 
  config.supabase.anonKey && 
  !config.supabase.url.includes('demo') &&
  !config.supabase.url.includes('your-project') &&
  config.supabase.anonKey.startsWith('eyJ');

if (!isValidSupabaseConfig) {
  logger.warn('⚠️  Supabase not configured - using DEMO MODE');
  logger.warn('⚠️  To use real database, sign up at https://supabase.com and update .env');
  
  // Create mock Supabase client for demo
  supabase = {
    from: (table) => ({
      select: (columns) => ({
        eq: (column, value) => ({
          single: () => ({ data: null, error: null }),
          data: [],
          error: null
        }),
        single: () => ({ data: null, error: null }),
        data: [],
        error: null
      }),
      insert: (data) => ({
        select: (columns) => ({
          single: () => ({ data: null, error: null }),
          data: [],
          error: null
        }),
        data: [],
        error: null
      }),
      update: (data) => ({
        eq: (column, value) => ({
          select: (columns) => ({
            single: () => ({ data: null, error: null }),
            data: [],
            error: null
          }),
          data: [],
          error: null
        }),
        data: [],
        error: null
      }),
      delete: () => ({
        eq: (column, value) => ({ data: [], error: null }),
        data: [],
        error: null
      }),
      eq: (column, value) => ({
        single: () => ({ data: null, error: null }),
        data: [],
        error: null
      }),
      or: (query) => ({ data: [], error: null }),
      order: (column, options) => ({ data: [], error: null }),
      range: (from, to) => ({ data: [], error: null }),
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
  // Use SERVICE_KEY for backend operations to bypass RLS and rate limits
  const supabaseKey = config.supabase.serviceKey || config.supabase.anonKey;
  
  supabase = createClient(
    config.supabase.url,
    supabaseKey,
    {
      auth: {
        autoRefreshToken: true,
        persistSession: false,
        detectSessionInUrl: false
      },
      db: {
        schema: 'public'
      },
      global: {
        headers: {
          'apikey': supabaseKey
        }
      }
    }
  );
  logger.info('✅ Supabase client initialized with service key');
}

export { supabase };
