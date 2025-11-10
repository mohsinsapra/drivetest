# Build Scripts

Quick reference for building and running the DriveTest app.

## Web Development

### Run in Development Mode
```bash
./scripts/run_web.sh
```
- Hot reload enabled
- Uses `.env` configuration
- Opens in Chrome

### Build for Production
```bash
./scripts/build_web.sh
```
- Release mode
- Optimized build
- Output: `build/web/`

## Version Management

### Bump Version
```bash
cd scripts

# Increment patch (1.0.0 -> 1.0.1)
ruby update_version.rb patch

# Increment minor (1.0.0 -> 1.1.0)
ruby update_version.rb minor

# Increment major (1.0.0 -> 2.0.0)
ruby update_version.rb major

# Increment build only (1.0.0+1 -> 1.0.0+2)
ruby update_version.rb build
```

## Deployment

### Android Beta
```bash
cd android
fastlane beta
```
Auto-increments version, updates changelog, deploys to Google Play alpha track.

### iOS Beta
```bash
cd ios
fastlane beta
```
Auto-increments version, updates changelog, uploads to TestFlight.

## Requirements

- Ruby (for version script)
- Flutter SDK
- Fastlane (for deployment)
- `.env` file with configuration

## Documentation

- [WEB_BUILD_GUIDE.md](../WEB_BUILD_GUIDE.md) - Complete web build guide
- [VERSION_MANAGEMENT.md](../VERSION_MANAGEMENT.md) - Version & changelog guide
