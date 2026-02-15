#!/bin/bash

# Quick Start Script for Real-Time Translation System
# This script sets up everything you need to get started

set -e

echo "🚀 Real-Time Translation System - Quick Start"
echo "=============================================="
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."

command -v docker >/dev/null 2>&1 || { echo "❌ Docker not found. Please install Docker first."; exit 1; }
command -v node >/dev/null 2>&1 || { echo "❌ Node.js not found. Please install Node.js 18+."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Python not found. Please install Python 3.10+."; exit 1; }

echo "✅ All prerequisites found!"
echo ""

# Setup environment
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "⚠️  Please edit .env file with your Supabase and Upstash credentials"
    echo "   - SUPABASE_URL"
    echo "   - SUPABASE_ANON_KEY"
    echo "   - UPSTASH_REDIS_URL"
    echo "   - UPSTASH_REDIS_TOKEN"
    echo ""
    read -p "Press Enter after you've updated .env file..."
else
    echo "✅ .env file already exists"
fi

# Install backend dependencies
echo ""
echo "📦 Installing backend dependencies..."
cd backend
npm install
cd ..
echo "✅ Backend dependencies installed"

# Start services with Docker
echo ""
echo "🐳 Starting services with Docker..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

# Check health
echo ""
echo "🏥 Checking service health..."
curl -s http://localhost:3000/health || echo "⚠️  Backend not responding yet"
curl -s http://localhost:5000/health || echo "⚠️  STT service not responding yet (optional)"
curl -s http://localhost:5001/health || echo "⚠️  Translation service not responding yet (optional)"
curl -s http://localhost:5002/health || echo "⚠️  TTS service not responding yet (optional)"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📚 Next steps:"
echo "1. Setup Supabase database:"
echo "   - Go to https://supabase.com"
echo "   - Create a project"
echo "   - Run SQL from database/schema.sql"
echo ""
echo "2. Test the API:"
echo "   curl http://localhost:3000/health"
echo ""
echo "3. View logs:"
echo "   docker-compose logs -f"
echo ""
echo "4. Stop services:"
echo "   docker-compose down"
echo ""
echo "📖 Read the documentation:"
echo "   - README.md - Project overview"
echo "   - SETUP_GUIDE.md - Detailed setup"
echo "   - DEPLOYMENT.md - Deploy to production"
echo ""
echo "🎉 Happy coding!"
