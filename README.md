# DriveTest — Flutter App

Swedish taxi exam prep app for iOS, Android, and Web.

- **Production web**: https://drivetest.se
- **Dev tunnel**: https://dev-app.drivetest.se
- **Backend dev tunnel**: https://dev-dashboard.drivetest.se

---

## Prerequisites

- Flutter 3.x (`brew install --cask flutter`)
- Xcode (for iOS builds)
- Android Studio (for Android builds)
- Ruby + Bundler (`gem install bundler`) — for Fastlane deployments
- cloudflared (`brew install cloudflared`) — for tunnel commands

---

## First-time setup

```bash
# 1. Clone
git clone git@github.com:mohsinsapra/taxiexam_app.git
cd taxiexam_app

# 2. Install Flutter dependencies
flutter pub get

# 3. Copy environment file
cp .env.example .env   # or copy from 1Password
# Edit .env with your local keys
```

---

## Running the app

### Mobile (iOS / Android)

```bash
flutter run                  # Run on connected device or simulator
flutter run -d <device-id>   # Target a specific device
```

### Web (local browser)

```bash
make web-run                 # Opens Chrome on http://localhost:5005
```

### Web + Cloudflare tunnel (test from any device / remotely)

```bash
make tunnel                  # Start both backend + Flutter tunnels together (recommended)
make web-tunnel              # Start Flutter tunnel only
```

Once running, open **https://dev-app.drivetest.se** on any device anywhere.

> The backend dev tunnel must also be running for API calls to work.
> `make tunnel` starts both together.

**Restart controls (without stopping the other tunnel):**

```bash
make restart-flutter         # Restart Flutter only
make restart-backend         # Restart backend only
```

---

## Building

```bash
make web-build               # Production web build → build/web/
make web-deploy              # Bump version + build + push to web repo + purge Cloudflare CDN
```

---

## Deployment

```bash
make android-beta            # Deploy Android to Google Play alpha
make android-deploy          # Deploy Android to alpha + promote to production
make ios-beta                # Deploy iOS to TestFlight
make deploy-all              # Web + Android + iOS in one command
```

Bump type can be controlled with `BUMP=`:

```bash
make deploy-all BUMP=minor   # 1.0.x → 1.1.0
make deploy-all BUMP=major   # 1.x.x → 2.0.0
make deploy-all              # default: patch (1.0.3 → 1.0.4)
```

---

## All make commands

```bash
make web-run                 # Run web in Chrome (local dev)
make web-tunnel              # Run web + Cloudflare tunnel
make tunnel                  # Start both backend + Flutter tunnels

make restart-flutter         # Restart Flutter tunnel only
make restart-backend         # Restart backend tunnel only

make web-build               # Production build
make web-deploy              # Build + deploy to web repo

make android-beta            # Deploy to Google Play alpha
make android-deploy          # Deploy to Google Play production
make ios-beta                # Deploy to TestFlight
make deploy-all              # Deploy everywhere

make fmt                     # Format Dart files
make lint                    # Run flutter analyze
make check                   # Format + lint
make clean                   # Clean build artifacts

make version-patch           # Bump patch version
make version-minor           # Bump minor version
make version-major           # Bump major version
```

---

## Environment variables (`.env`)

| Variable | Description |
|---|---|
| `STRIPE_PUBLISHABLE_KEY` | Stripe publishable key |
| `GOOGLE_CLIENT_ID` | Google OAuth web client ID |
| `GOOGLE_SERVER_CLIENT_ID` | Google Android client ID |
| `FIREBASE_API_KEY` | Firebase web API key |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `SENTRY_DSN` | Sentry error tracking DSN |
| `CLOUDFLARE_ZONE_ID` | Cloudflare zone ID for cache purge |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token for cache purge |

---

## Project structure

```
taxi_exam_app/
├── lib/
│   ├── core/
│   │   ├── api/            # Dio HTTP client + API service
│   │   ├── localization/   # Slang i18n (strings.i18n.json)
│   │   ├── models/         # Data models
│   │   └── services/       # IAP, payment, cache, navigation
│   └── features/
│       ├── auth/           # Login, signup, Google/Apple Sign-In
│       ├── bcd/            # Exam categories and questions
│       ├── onboarding/     # Purchase flow
│       ├── profile/        # User profile and settings
│       └── payment/        # Stripe + Apple IAP
├── ios/                    # iOS project + Fastlane
├── android/                # Android project + Fastlane
├── scripts/                # Version bumping scripts
├── Makefile
└── .env                    # Local secrets (gitignored)
```

---

## Localization

Translations live in `lib/core/localization/`:

- `strings.i18n.json` — English (base)
- `strings_sv.i18n.json` — Swedish

After editing translation files, regenerate with:

```bash
dart run slang
```
