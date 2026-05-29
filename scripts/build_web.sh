#!/bin/bash

# Build Web App with Firebase Configuration
# Usage: ./scripts/build_web.sh [development|production]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please create a .env file with your Firebase configuration."
    exit 1
fi

# Load environment variables from .env
export $(cat .env | grep -v '^#' | xargs)

# Determine environment (default to development)
ENVIRONMENT=${1:-development}

# Set default base href if not in .env
WEB_BASE_HREF=${WEB_BASE_HREF:-/}

echo -e "${GREEN}Building web app for ${ENVIRONMENT} environment...${NC}"
echo -e "${YELLOW}Base URL: ${WEB_BASE_HREF}${NC}"
echo ""

# Build command with Firebase configuration
flutter build web \
  --base-href=${WEB_BASE_HREF} \
  --dart-define=FIREBASE_API_KEY="${FIREBASE_API_KEY}" \
  --dart-define=FIREBASE_AUTH_DOMAIN="${FIREBASE_AUTH_DOMAIN}" \
  --dart-define=FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID}" \
  --dart-define=FIREBASE_STORAGE_BUCKET="${FIREBASE_STORAGE_BUCKET}" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="${FIREBASE_MESSAGING_SENDER_ID}" \
  --dart-define=FIREBASE_APP_ID="${FIREBASE_APP_ID}" \
  --dart-define=FIREBASE_MEASUREMENT_ID="${FIREBASE_MEASUREMENT_ID}" \
  --dart-define=STRIPE_PUBLISHABLE_KEY="${STRIPE_PUBLISHABLE_KEY}" \
  --dart-define=GEMINI_API_KEY="${GEMINI_API_KEY}" \
  --release

echo ""
echo -e "${GREEN}✅ Web build completed successfully!${NC}"
echo -e "${YELLOW}Output directory: build/web/${NC}"
echo ""
echo "To test locally, run:"
echo "  cd build/web && python3 -m http.server 8000"
echo ""
