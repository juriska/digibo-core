#!/bin/bash

# DigiBo Core API - Quick Start Script

set -e

echo "=========================================="
echo "   DigiBo Core API - Quick Start"
echo "=========================================="
echo ""

# Check if node is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

echo "✅ Node.js found: $(node --version)"
echo ""

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

echo "✅ npm found: $(npm --version)"
echo ""

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
    echo ""
fi

# Show menu
echo "Please select your development mode:"
echo ""
echo "1) Mock Mode (No database required) - Recommended for quick start"
echo "2) Local Oracle DB (Requires Docker)"
echo "3) Custom .env file"
echo ""
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        echo ""
        echo "🚀 Starting in MOCK MODE..."
        echo "   No database connection required"
        echo "   API will run on http://localhost:3000"
        echo ""
        cp .env.mock .env
        npm run dev
        ;;
    2)
        echo ""
        if ! command -v docker &> /dev/null; then
            echo "❌ Docker is not installed. Please install Docker first."
            exit 1
        fi

        echo "🐳 Starting Oracle DB and API..."
        echo "   This may take a few minutes on first run"
        echo "   API will run on http://localhost:3000"
        echo "   Oracle will run on localhost:1521"
        echo ""
        npm run docker:db
        ;;
    3)
        echo ""
        if [ -f ".env" ]; then
            echo "✅ Using existing .env file"
        else
            echo "⚠️  No .env file found. Please create one first."
            echo "   You can copy from:"
            echo "   - .env.mock (for mock mode)"
            echo "   - .env.local-db (for local database)"
            echo "   - .env.example (template)"
            exit 1
        fi
        echo ""
        echo "🚀 Starting with custom .env..."
        npm run dev
        ;;
    *)
        echo ""
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac