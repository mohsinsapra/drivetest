# Web Build Guide - Firebase Configuration

This guide explains how to build and deploy the web version of DriveTest app with Firebase configuration passed at build time.

## Overview

For web builds, Firebase configuration is **NOT** loaded from `.env` file. Instead, it's passed as build-time constants using `--dart-define` flags. This ensures:

✅ No `.env` file needs to be deployed to web
✅ Configuration is compiled into the app
✅ More secure for production deployments
✅ Can use different configs for different environments

---

## Quick Start

### Development (Local Testing)

```bash
# Option 1: Use the helper script (recommended)
./scripts/run_web.sh

# Option 2: Manual command
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY="your_key" \
  --dart-define=FIREBASE_AUTH_DOMAIN="your_domain" \
  # ... other vars
```

### Production Build

```bash
# Option 1: Use the helper script (recommended)
./scripts/build_web.sh

# Option 2: Manual command (see below)
```

---

## Build Scripts

### 1. `scripts/run_web.sh` - Development

Runs the web app in development mode with hot reload.

**Usage:**
```bash
./scripts/run_web.sh
```

**What it does:**
- Loads Firebase config from `.env`
- Passes config as `--dart-define` flags
- Runs `flutter run -d chrome`
- Enables hot reload for development

---

### 2. `scripts/build_web.sh` - Production

Builds the web app for production deployment.

**Usage:**
```bash
./scripts/build_web.sh
```

**What it does:**
- Loads Firebase config from `.env`
- Passes config as `--dart-define` flags
- Runs `flutter build web --release`
- Outputs to `build/web/`

---

## Manual Build Commands

### Development Run

```bash
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY="AIzaSyCNHfjgw5mcgg5d7NayRluVTXwHPlpoGWM" \
  --dart-define=FIREBASE_AUTH_DOMAIN="drive-test-a4f94.firebaseapp.com" \
  --dart-define=FIREBASE_PROJECT_ID="drive-test-a4f94" \
  --dart-define=FIREBASE_STORAGE_BUCKET="drive-test-a4f94.firebasestorage.app" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="640394192831" \
  --dart-define=FIREBASE_APP_ID="1:640394192831:web:2f7c45b3bae1a15f1a630a" \
  --dart-define=FIREBASE_MEASUREMENT_ID="G-2Y166BG2F3" \
  --dart-define=STRIPE_PUBLISHABLE_KEY="pk_test_on1dP7jlAmwx5V1vG02ktjF200G4XQHemE"
```

### Production Build

```bash
flutter build web --release \
  --dart-define=FIREBASE_API_KEY="AIzaSyCNHfjgw5mcgg5d7NayRluVTXwHPlpoGWM" \
  --dart-define=FIREBASE_AUTH_DOMAIN="drive-test-a4f94.firebaseapp.com" \
  --dart-define=FIREBASE_PROJECT_ID="drive-test-a4f94" \
  --dart-define=FIREBASE_STORAGE_BUCKET="drive-test-a4f94.firebasestorage.app" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="640394192831" \
  --dart-define=FIREBASE_APP_ID="1:640394192831:web:2f7c45b3bae1a15f1a630a" \
  --dart-define=FIREBASE_MEASUREMENT_ID="G-2Y166BG2F3" \
  --dart-define=STRIPE_PUBLISHABLE_KEY="pk_live_your_production_key"
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build Web

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'

      - name: Build Web
        run: |
          flutter build web --release \
            --dart-define=FIREBASE_API_KEY="${{ secrets.FIREBASE_API_KEY }}" \
            --dart-define=FIREBASE_AUTH_DOMAIN="${{ secrets.FIREBASE_AUTH_DOMAIN }}" \
            --dart-define=FIREBASE_PROJECT_ID="${{ secrets.FIREBASE_PROJECT_ID }}" \
            --dart-define=FIREBASE_STORAGE_BUCKET="${{ secrets.FIREBASE_STORAGE_BUCKET }}" \
            --dart-define=FIREBASE_MESSAGING_SENDER_ID="${{ secrets.FIREBASE_MESSAGING_SENDER_ID }}" \
            --dart-define=FIREBASE_APP_ID="${{ secrets.FIREBASE_APP_ID }}" \
            --dart-define=FIREBASE_MEASUREMENT_ID="${{ secrets.FIREBASE_MEASUREMENT_ID }}" \
            --dart-define=STRIPE_PUBLISHABLE_KEY="${{ secrets.STRIPE_PUBLISHABLE_KEY }}"

      - name: Deploy to Firebase Hosting
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: drive-test-a4f94
```

**Setting Secrets:**
1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Add each Firebase variable as a secret:
   - `FIREBASE_API_KEY`
   - `FIREBASE_AUTH_DOMAIN`
   - `FIREBASE_PROJECT_ID`
   - etc.

---

## Deployment Options

### Option 1: Firebase Hosting (Recommended)

```bash
# 1. Build the web app
./scripts/build_web.sh

# 2. Initialize Firebase Hosting (first time only)
firebase init hosting

# 3. Deploy
firebase deploy --only hosting
```

### Option 2: Netlify

```bash
# 1. Build the web app
./scripts/build_web.sh

# 2. Deploy
netlify deploy --prod --dir=build/web
```

### Option 3: Vercel

```bash
# 1. Build the web app
./scripts/build_web.sh

# 2. Deploy
vercel --prod build/web
```

### Option 4: Custom Server

```bash
# 1. Build the web app
./scripts/build_web.sh

# 2. Copy build/web to your server
scp -r build/web/* user@server:/var/www/html/

# 3. Configure web server (Nginx example)
server {
    listen 80;
    server_name your-domain.com;
    root /var/www/html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

---

## Environment-Specific Builds

### Development

```bash
./scripts/build_web.sh development
```

Uses:
- Test Firebase project
- Test Stripe keys
- Debug analytics

### Production

```bash
./scripts/build_web.sh production
```

Should use:
- Production Firebase project
- Live Stripe keys (`pk_live_xxx`)
- Production analytics

---

## Troubleshooting

### Error: "FirebaseOptions cannot be null"

**Cause:** Missing `--dart-define` flags
**Solution:** Use the provided build scripts or ensure all flags are passed

### Error: ".env file not found"

**Cause:** Running build script from wrong directory
**Solution:** Run from project root:
```bash
cd /path/to/taxi_exam_app
./scripts/build_web.sh
```

### Build works locally but not in CI/CD

**Cause:** Environment variables not set in CI
**Solution:** Add all Firebase variables as secrets in your CI platform

### Firebase Analytics not working on web

**Cause:**
1. Domain not allowed in Firebase Console
2. Wrong Firebase config

**Solution:**
1. Go to Firebase Console → Authentication → Settings
2. Add your domain to authorized domains
3. Verify `FIREBASE_API_KEY` is correct

---

## Testing Locally

After building, test the production build locally:

```bash
# 1. Build
./scripts/build_web.sh

# 2. Serve locally
cd build/web
python3 -m http.server 8000

# 3. Open browser
open http://localhost:8000
```

---

## Security Notes

### Safe to Expose (Public)
✅ `FIREBASE_API_KEY` - Public, restricted by domain
✅ `FIREBASE_AUTH_DOMAIN` - Public identifier
✅ `FIREBASE_PROJECT_ID` - Public identifier
✅ `FIREBASE_STORAGE_BUCKET` - Public identifier
✅ `FIREBASE_MESSAGING_SENDER_ID` - Public identifier
✅ `FIREBASE_APP_ID` - Public identifier
✅ `FIREBASE_MEASUREMENT_ID` - Public identifier
✅ `STRIPE_PUBLISHABLE_KEY` - Designed to be public

### Must Keep Private
🔴 Stripe Secret Key - Never expose
🔴 Firebase Service Account Keys - Never expose
🔴 Encryption Passphrase - Never expose

---

## Platform Comparison

| Platform | Config Source | Notes |
|----------|--------------|-------|
| **Web** | `--dart-define` flags | This guide |
| **Android** | `google-services.json` | Auto-loaded |
| **iOS** | `GoogleService-Info.plist` | Auto-loaded |

---

## Summary

**Development:**
```bash
./scripts/run_web.sh
```

**Production Build:**
```bash
./scripts/build_web.sh
```

**Deploy:**
```bash
firebase deploy --only hosting
```

Your web app will load Firebase configuration from build-time constants, not from any deployed files! 🎉
