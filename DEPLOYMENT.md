# 🚀 Deployment Guide - FREE Hosting

## Railway.app Deployment (RECOMMENDED - Easiest)

### Step 1: Prepare Repository
```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-github-repo>
git push -u origin main
```

### Step 2: Deploy to Railway
1. Go to [railway.app](https://railway.app)
2. Sign up with GitHub (FREE)
3. Click "New Project" → "Deploy from GitHub repo"
4. Select your repository
5. Railway auto-detects and deploys!

### Step 3: Add Environment Variables
In Railway dashboard:
- Add all variables from `.env.example`
- Set `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- Set `UPSTASH_REDIS_URL`, `UPSTASH_REDIS_TOKEN`

### Step 4: Get Your URL
Railway provides: `https://your-app.railway.app`

---

## Render.com Deployment (Alternative)

### Step 1: Create Web Service
1. Go to [render.com](https://render.com)
2. New → Web Service
3. Connect GitHub repo
4. Build Command: `cd backend && npm install`
5. Start Command: `cd backend && npm start`

### Step 2: Add Environment Variables
Same as Railway

### Step 3: Deploy
Render auto-deploys on git push

---

## Fly.io Deployment (Advanced)

```bash
# Install flyctl
curl -L https://fly.io/install.sh | sh

# Login
fly auth login

# Launch app
fly launch

# Deploy
fly deploy
```

---

## Free Tier Limits

| Platform | Hours/Month | Memory | Storage |
|----------|-------------|--------|---------|
| Railway  | 500 hrs     | 512MB  | 1GB     |
| Render   | 750 hrs     | 512MB  | Free    |
| Fly.io   | 3 VMs       | 256MB  | 3GB     |

---

## Production Checklist

- [ ] Environment variables set
- [ ] Database schema deployed
- [ ] Redis connected
- [ ] AI services configured
- [ ] CORS origins updated
- [ ] SSL enabled (auto on Railway/Render)
- [ ] Monitoring setup
- [ ] Error tracking enabled

---

## Scaling Strategy

Start FREE → Upgrade when needed:
1. **0-100 users**: Free tier
2. **100-1000 users**: Railway Pro ($20/mo)
3. **1000+ users**: Dedicated hosting ($50-100/mo)
