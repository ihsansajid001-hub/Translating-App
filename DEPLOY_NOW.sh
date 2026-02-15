#!/bin/bash

echo "🚀 DEPLOYING REAL-TIME TRANSLATOR TO PRODUCTION"
echo "=============================================="
echo ""

# Check if git is initialized
if [ ! -d .git ]; then
    echo "📦 Initializing Git repository..."
    git init
    git add .
    git commit -m "Initial commit - Real-Time Translator App"
    echo "✅ Git initialized"
else
    echo "✅ Git already initialized"
fi

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found"
    echo "📥 Installing Railway CLI..."
    
    # Install Railway CLI
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install railway
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -fsSL https://railway.app/install.sh | sh
    else
        # Windows
        echo "Please install Railway CLI manually:"
        echo "npm install -g @railway/cli"
        exit 1
    fi
fi

echo ""
echo "🔐 Logging into Railway..."
railway login

echo ""
echo "🚀 Creating Railway project..."
railway init

echo ""
echo "⚙️  Setting environment variables..."
echo "Please set these in Railway dashboard:"
echo "  - SUPABASE_URL (get from supabase.com)"
echo "  - SUPABASE_ANON_KEY"
echo "  - UPSTASH_REDIS_URL (get from upstash.com)"
echo "  - UPSTASH_REDIS_TOKEN"
echo "  - JWT_SECRET (random string)"
echo ""
read -p "Press Enter after setting environment variables in Railway dashboard..."

echo ""
echo "🚀 Deploying to Railway..."
railway up

echo ""
echo "✅ DEPLOYMENT COMPLETE!"
echo ""
echo "📝 Next steps:"
echo "1. Get your Railway URL from dashboard"
echo "2. Update Flutter app .env with production URL"
echo "3. Build Flutter apps: flutter build apk --release"
echo "4. Test the production deployment"
echo ""
echo "🎉 YOUR APP IS LIVE!"
