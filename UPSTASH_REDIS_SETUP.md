# ⚡ UPSTASH REDIS SETUP - 2 MINUTES

## 🚀 SETUP STEPS

### Step 1: Create Account (30 seconds)
1. Go to: https://upstash.com
2. Click "Get Started"
3. Sign up with GitHub
4. ✅ Account created!

### Step 2: Create Redis Database (1 minute)
1. Click "Create Database"
2. Fill in:
   - **Name**: translator-cache
   - **Type**: Regional
   - **Region**: Choose closest to you
   - **Plan**: FREE
3. Click "Create"
4. ✅ Database created instantly!

### Step 3: Get Connection Details (30 seconds)
1. Click on your database
2. Scroll to "REST API" section
3. Copy:
   - **UPSTASH_REDIS_REST_URL**
   - **UPSTASH_REDIS_REST_TOKEN**

### Step 4: Update .env
```env
UPSTASH_REDIS_URL=https://xxxxx.upstash.io
UPSTASH_REDIS_TOKEN=your-token-here
```

### Step 5: Restart Backend
```bash
npm start
```

✅ **DONE! Redis connected!**

## 🎯 WHAT YOU GET (FREE)

- ✅ 10,000 commands per day
- ✅ 256MB storage
- ✅ Global replication
- ✅ TLS encryption
- ✅ REST API
- ✅ No credit card required

**Total time: 2 minutes**
**Total cost: $0**
