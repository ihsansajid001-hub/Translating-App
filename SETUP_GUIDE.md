# 🚀 Complete Setup Guide - $0 Budget Real-Time Translation System

## Prerequisites

- Computer with 8GB+ RAM
- Internet connection
- Git installed
- Docker & Docker Compose installed
- Node.js 18+ (for backend)
- Python 3.10+ (for AI services)
- Flutter SDK (for mobile/desktop apps)

## Quick Start (5 Minutes)

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd realtime-translator
```

### 2. Setup Environment
```bash
cp .env.example .env
# Edit .env with your configuration
```

### 3. Start Services
```bash
docker-compose up -d
```

### 4. Setup Database
Follow instructions in `database/README.md`

### 5. Run Flutter App
```bash
cd apps/flutter_app
flutter pub get
flutter run
```

## Detailed Setup Instructions

See individual README files:
- Backend: `backend/README.md`
- AI Services: `ai-local/README.md`
- Database: `database/README.md`
- Flutter App: `apps/flutter_app/README.md`

## Free Services Setup

### Supabase (Database + Auth)
1. Create account at supabase.com
2. Create new project
3. Run schema from `database/schema.sql`
4. Copy API keys to `.env`

### Upstash (Redis)
1. Create account at upstash.com
2. Create Redis database
3. Copy connection URL to `.env`

### Hugging Face (AI API - Optional)
1. Create account at huggingface.co
2. Generate API token
3. Add to `.env`

## Deployment Options

### Option 1: Railway.app (Recommended)
```bash
railway login
railway init
railway up
```

### Option 2: Render.com
Connect GitHub repo and deploy

### Option 3: Fly.io
```bash
fly launch
fly deploy
```

## Troubleshooting

See individual service README files for specific issues.

## Support

Open an issue on GitHub or check documentation.
