# Database Setup Guide

## Supabase Setup (FREE)

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Click "Start your project"
3. Create a new project (FREE tier)
4. Wait for database to be provisioned (~2 minutes)

### 2. Run Database Schema

1. Go to SQL Editor in Supabase Dashboard
2. Copy contents of `schema.sql`
3. Paste and click "Run"
4. Verify tables are created in Table Editor

### 3. Get API Keys

1. Go to Project Settings → API
2. Copy these values to your `.env` file:
   - `SUPABASE_URL`: Your project URL
   - `SUPABASE_ANON_KEY`: Your anon/public key
   - `SUPABASE_SERVICE_KEY`: Your service_role key (keep secret!)

### 4. Configure Authentication

1. Go to Authentication → Providers
2. Enable Email provider (default)
3. Enable Social Providers (optional):
   - **Google**: Add OAuth credentials
   - **Apple**: Add OAuth credentials  
   - **Facebook**: Add OAuth credentials

#### Google OAuth Setup:
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create new project
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Add authorized redirect URI: `https://your-project.supabase.co/auth/v1/callback`
6. Copy Client ID and Secret to Supabase

#### Apple OAuth Setup:
1. Go to [Apple Developer](https://developer.apple.com)
2. Create App ID and Service ID
3. Configure Sign in with Apple
4. Add redirect URI
5. Copy credentials to Supabase

#### Facebook OAuth Setup:
1. Go to [Facebook Developers](https://developers.facebook.com)
2. Create new app
3. Add Facebook Login product
4. Configure OAuth redirect URIs
5. Copy App ID and Secret to Supabase

### 5. Configure Row Level Security (RLS)

RLS is already configured in `schema.sql`. It ensures:
- Users can only access their own data
- Users can only see sessions they're part of
- Translation logs are private to session participants

### 6. Test Database Connection

```bash
# From backend directory
cd backend
npm install
node -e "
  import { supabase } from './src/services/supabase.js';
  const { data, error } = await supabase.from('supported_languages').select('*');
  console.log(data || error);
"
```

## Database Maintenance

### Clean Old Data (Free Tier Optimization)

Run this monthly to stay within 500MB limit:

```sql
SELECT cleanup_old_data();
```

Or set up a cron job:

```bash
# Add to crontab (runs monthly)
0 0 1 * * psql $DATABASE_URL -c "SELECT cleanup_old_data();"
```

### Monitor Database Size

```sql
SELECT 
    pg_size_pretty(pg_database_size(current_database())) as database_size,
    pg_size_pretty(pg_total_relation_size('translation_logs')) as translation_logs_size,
    pg_size_pretty(pg_total_relation_size('sessions')) as sessions_size;
```

### Backup Database

Supabase FREE tier includes:
- Automatic daily backups (7 days retention)
- Point-in-time recovery

Manual backup:
```bash
# Export to SQL file
pg_dump $DATABASE_URL > backup.sql

# Restore from backup
psql $DATABASE_URL < backup.sql
```

## Useful Queries

### Get Active Sessions
```sql
SELECT * FROM active_sessions_view;
```

### Get User Statistics
```sql
SELECT * FROM user_stats_view WHERE id = 'user-uuid';
```

### Get Popular Language Pairs
```sql
SELECT * FROM language_pair_stats LIMIT 10;
```

### Get Average Latency by Language
```sql
SELECT 
    source_language,
    target_language,
    AVG(total_latency)::INTEGER as avg_latency_ms,
    COUNT(*) as translation_count
FROM translation_logs
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY source_language, target_language
ORDER BY translation_count DESC;
```

### Find Slow Translations
```sql
SELECT 
    id,
    original_text,
    total_latency,
    source_language,
    target_language,
    created_at
FROM translation_logs
WHERE total_latency > 2000  -- More than 2 seconds
ORDER BY total_latency DESC
LIMIT 20;
```

## Troubleshooting

### Connection Issues
- Verify `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `.env`
- Check if Supabase project is active
- Verify network connectivity

### RLS Errors
- Make sure user is authenticated
- Check RLS policies in Supabase Dashboard
- Verify JWT token is valid

### Performance Issues
- Add indexes for frequently queried columns
- Run `VACUUM ANALYZE` periodically
- Monitor query performance in Supabase Dashboard

## Free Tier Limits

Supabase FREE tier includes:
- ✅ 500MB database space
- ✅ 50,000 monthly active users
- ✅ 2GB bandwidth
- ✅ 500MB file storage
- ✅ Unlimited API requests
- ✅ Social OAuth providers
- ✅ Row Level Security
- ✅ Realtime subscriptions

**Tips to stay within limits:**
1. Clean old data regularly
2. Don't store audio files (only text)
3. Use Redis for caching
4. Compress large text fields
5. Archive old sessions
