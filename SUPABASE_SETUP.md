# 🗄️ SUPABASE SETUP - COMPLETE GUIDE

## ✅ WHAT IS SUPABASE?

Supabase is a FREE PostgreSQL database with authentication built-in!
- ✅ 500MB database (FREE forever)
- ✅ 50,000 monthly active users (FREE)
- ✅ Built-in authentication
- ✅ Real-time subscriptions
- ✅ No credit card required!

## 🚀 SETUP IN 5 MINUTES

### Step 1: Create Account (1 minute)
1. Go to: https://supabase.com
2. Click "Start your project"
3. Sign up with GitHub (easiest)
4. ✅ Account created!

### Step 2: Create Project (2 minutes)
1. Click "New Project"
2. Fill in:
   - **Name**: realtime-translator
   - **Database Password**: (create a strong password - SAVE IT!)
   - **Region**: Choose closest to you
   - **Pricing Plan**: FREE
3. Click "Create new project"
4. ⏳ Wait 2 minutes while it provisions
5. ✅ Project ready!

### Step 3: Run Database Schema (1 minute)
1. In Supabase dashboard, click "SQL Editor" (left sidebar)
2. Click "New query"
3. Copy ENTIRE contents of `database/schema.sql` file
4. Paste into SQL editor
5. Click "Run" (or press Ctrl+Enter)
6. ✅ You should see "Success. No rows returned"
7. Click "Table Editor" to verify tables were created
8. ✅ Database ready!

### Step 4: Get API Keys (1 minute)
1. Click "Settings" (gear icon, bottom left)
2. Click "API"
3. Copy these values:

```
Project URL: https://xxxxx.supabase.co
anon/public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
service_role key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

4. ✅ Keys copied!

### Step 5: Update .env File
Open `.env` file and update:

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Step 6: Restart Backend
```bash
# Stop current backend (Ctrl+C)
# Start again
npm start
```

✅ **DONE! Supabase is connected!**

## 🔐 ENABLE SOCIAL LOGIN (Optional - 5 minutes)

### Google OAuth
1. In Supabase dashboard: Authentication → Providers
2. Enable "Google"
3. Go to: https://console.cloud.google.com
4. Create OAuth credentials
5. Copy Client ID and Secret to Supabase
6. ✅ Google login enabled!

### Apple OAuth
1. In Supabase dashboard: Authentication → Providers
2. Enable "Sign in with Apple"
3. Go to: https://developer.apple.com
4. Create Service ID
5. Copy credentials to Supabase
6. ✅ Apple login enabled!

### Facebook OAuth
1. In Supabase dashboard: Authentication → Providers
2. Enable "Facebook"
3. Go to: https://developers.facebook.com
4. Create app and get credentials
5. Copy to Supabase
6. ✅ Facebook login enabled!

## 🧪 TEST YOUR DATABASE

```bash
# Test with curl
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","username":"testuser"}'

# Should return user data with JWT token!
```

## 📊 VERIFY IN SUPABASE

1. Go to Supabase dashboard
2. Click "Table Editor"
3. Click "users" table
4. You should see your test user!
5. ✅ Database working!

## 🎯 WHAT YOU GET

With Supabase FREE tier:
- ✅ 500MB database storage
- ✅ 50,000 monthly active users
- ✅ 2GB bandwidth
- ✅ 500MB file storage
- ✅ Unlimited API requests
- ✅ Social OAuth providers
- ✅ Row Level Security
- ✅ Real-time subscriptions
- ✅ Automatic backups

## 🚨 TROUBLESHOOTING

### "Project not found"
- Wait 2-3 minutes after creating project
- Refresh the page

### "Schema error"
- Make sure you copied ENTIRE schema.sql file
- Check for any syntax errors
- Try running in smaller chunks

### "Connection refused"
- Check your SUPABASE_URL is correct
- Check your SUPABASE_ANON_KEY is correct
- Restart backend server

## 💡 PRO TIPS

1. **Save your database password!** You'll need it
2. **Use environment variables** - Never commit keys to Git
3. **Enable Row Level Security** - Already done in schema!
4. **Monitor usage** - Check Supabase dashboard
5. **Backup data** - Supabase does this automatically

## 🎉 YOU'RE DONE!

Your database is now:
- ✅ Created
- ✅ Schema loaded
- ✅ Connected to backend
- ✅ Ready for production!

**Total time: 5 minutes**
**Total cost: $0**

---

**Now your app has a REAL database! 🎉**
