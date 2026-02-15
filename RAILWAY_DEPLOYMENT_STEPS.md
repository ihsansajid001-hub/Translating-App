# Railway Deployment Steps

## After Railway Loads:

### Step 1: Select Your Repository
- Look for "Deploy from GitHub repo" or similar option
- Select: **ihsansajid001-hub/Translating-App**
- Railway will auto-detect it's a Node.js project

### Step 2: Configure Build Settings
Railway should auto-detect:
- Build Command: `cd backend && npm install`
- Start Command: `cd backend && npm start`
- Root Directory: `/`

### Step 3: Add Environment Variables
Click "Variables" and add these from your `.env` file:

```
NODE_ENV=production
PORT=3000
SUPABASE_URL=https://blqqqxsijgvydczjaayy.supabase.co
SUPABASE_ANON_KEY=sb_publishable_XAckfjJTsJ0PrlwvThq8ng_o8tvThfose
SUPABASE_SERVICE_KEY=sb_secret_UqLinlJDodUqyR_ae_UvMw_mYAizibdi
JWT_SECRET=super-secret-jwt-key-change-in-production-habibi
AI_MODE=local
CORS_ORIGIN=*
```

### Step 4: Deploy
- Click "Deploy"
- Wait 2-3 minutes for build
- Railway will give you a URL like: `https://your-app.railway.app`

### Step 5: Test Your Live API
```bash
curl https://your-app.railway.app/health
```

## That's It! 🎉

Your backend will be live and accessible from anywhere!
