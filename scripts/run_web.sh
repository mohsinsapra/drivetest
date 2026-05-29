#!/bin/bash

# Run Web App in Development with Firebase Configuration
# Usage: ./scripts/run_web.sh

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please create a .env file with your Firebase configuration."
    exit 1
fi

# Load environment variables from .env
export $(cat .env | grep -v '^#' | xargs)

echo -e "${GREEN}Starting web app in development mode...${NC}"
echo -e "${YELLOW}Using Firebase Project: ${FIREBASE_PROJECT_ID}${NC}"
echo ""

# Run command with Firebase configuration
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY="${FIREBASE_API_KEY}" \
  --dart-define=FIREBASE_AUTH_DOMAIN="${FIREBASE_AUTH_DOMAIN}" \
  --dart-define=FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID}" \
  --dart-define=FIREBASE_STORAGE_BUCKET="${FIREBASE_STORAGE_BUCKET}" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="${FIREBASE_MESSAGING_SENDER_ID}" \
  --dart-define=FIREBASE_APP_ID="${FIREBASE_APP_ID}" \
  --dart-define=FIREBASE_MEASUREMENT_ID="${FIREBASE_MEASUREMENT_ID}" \
  --dart-define=STRIPE_PUBLISHABLE_KEY="${STRIPE_PUBLISHABLE_KEY}" \
  --dart-define=GEMINI_API_KEY="${GEMINI_API_KEY}"
