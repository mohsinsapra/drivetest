# Version & Changelog Management Guide

This document explains how to manage versions and changelogs for the DriveTest app.

## Quick Start

### Before Each Release

1. **Update the "Unreleased" section in CHANGELOG.md**:
   ```markdown
   ## [Unreleased]

   ### Added
   - New Firebase Analytics integration
   - Purchase tracking events

   ### Changed
   - Updated payment flow UI

   ### Fixed
   - Fixed AD_ID permission issue
   ```

2. **Run Fastlane Deploy**:
   ```bash
   # For Android
   cd android
   fastlane beta

   # For iOS
   cd ios
   fastlane beta
   ```

3. **What Happens Automatically**:
   - ✅ Version in `pubspec.yaml` auto-increments (build number +1)
   - ✅ CHANGELOG.md gets a new version entry with today's date
   - ✅ Git tag is created (e.g., `v1.0.0-2`)
   - ✅ Changelog is uploaded to Google Play / TestFlight

## Manual Version Management

### Using the Version Script

If you want to manually bump the version before deploying:

```bash
cd scripts

# Bump patch version (1.0.0 -> 1.0.1)
ruby update_version.rb patch

# Bump minor version (1.0.0 -> 1.1.0)
ruby update_version.rb minor

# Bump major version (1.0.0 -> 2.0.0)
ruby update_version.rb major

# Bump only build number (1.0.0+1 -> 1.0.0+2)
ruby update_version.rb build
```

### What the Script Does

1. Reads current version from `pubspec.yaml`
2. Increments version based on bump type
3. Updates `pubspec.yaml` with new version
4. Moves "Unreleased" content to a new version entry in `CHANGELOG.md`
5. Adds today's date to the changelog

## Workflow Examples

### Example 1: Quick Bug Fix Release

```bash
# 1. Fix the bug
# 2. Update CHANGELOG.md
## [Unreleased]

### Fixed
- Fixed payment dialog crash on Android 12

# 3. Deploy
cd android
fastlane beta
```

**Result**: Version `1.0.0+1` → `1.0.0+2` (build number incremented)

---

### Example 2: New Feature Release

```bash
# 1. Develop the feature
# 2. Update CHANGELOG.md
## [Unreleased]

### Added
- Added dark mode support
- Added biometric authentication

### Changed
- Improved loading performance

# 3. Manually bump minor version (optional)
cd scripts
ruby update_version.rb minor

# 4. Deploy
cd ../android
fastlane beta
```

**Result**: Version `1.0.0+2` → `1.1.0+3`

---

### Example 3: Major Version Release

```bash
# 1. Complete major changes
# 2. Update CHANGELOG.md extensively
## [Unreleased]

### Added
- Complete UI redesign
- New subscription tiers
- Offline mode support

### Changed
- Migrated to new API v2
- Redesigned payment flow

### Removed
- Deprecated old test format

# 3. Bump major version
cd scripts
ruby update_version.rb major

# 4. Deploy to production
cd ../android
fastlane production
```

**Result**: Version `1.9.0+15` → `2.0.0+16`

## CHANGELOG.md Format

Follow this structure for consistency:

```markdown
## [Unreleased]

### Added
- New features you've added

### Changed
- Changes to existing functionality

### Deprecated
- Features that will be removed soon

### Removed
- Features that were removed

### Fixed
- Bug fixes

### Security
- Security improvements

---

## [1.0.1+2] - 2025-01-10

### Fixed
- Fixed crash on older Android devices
```

## Best Practices

### 1. **Update Changelog Before Deploy**
Always update the `[Unreleased]` section before running `fastlane beta` or `fastlane production`.

### 2. **Use Semantic Versioning**
- **Major** (X.0.0): Breaking changes, complete redesigns
- **Minor** (1.X.0): New features, backwards-compatible changes
- **Patch** (1.0.X): Bug fixes, small improvements
- **Build** (1.0.0+X): Always auto-increments with each deploy

### 3. **Write Clear Changelog Entries**
```markdown
✅ Good:
- Added Firebase Analytics for purchase tracking
- Fixed crash when selecting payment method on Android 12

❌ Bad:
- Updates
- Bug fixes
- Improvements
```

### 4. **Keep Unreleased Section Clean**
After each deploy, the Unreleased section should be empty (ready for next changes).

### 5. **Review Before Deploy**
Double-check:
- [ ] Changelog has meaningful entries
- [ ] Version bump type is correct
- [ ] All changes are committed to git

## Fastlane Integration

### What Fastlane Does Automatically

When you run `fastlane beta` or `fastlane production`:

1. **Reads** the current version from `pubspec.yaml`
2. **Increments** the build number
3. **Extracts** changelog from CHANGELOG.md
4. **Updates** Google Play / TestFlight with the changelog
5. **Creates** a git tag for the release
6. **Builds** and uploads the app

### Customization

You can modify the Fastlane behavior in:
- `android/fastlane/Fastfile`
- `ios/fastlane/Fastfile`

## Troubleshooting

### Issue: Version didn't increment
**Solution**: Ensure you have write permissions to `pubspec.yaml`

### Issue: Changelog not updating on Play Store
**Solution**: Check that CHANGELOG.md has the correct format and the latest entry is properly formatted

### Issue: Git tag already exists
**Solution**: Delete the tag locally and remotely:
```bash
git tag -d v1.0.0-2
git push origin :refs/tags/v1.0.0-2
```

### Issue: Want to skip auto-increment
**Solution**: Comment out the `update_flutter_version` line in Fastfile temporarily

## Commit Message Convention

When committing version changes, use this format:

```bash
git commit -m "chore: bump version to 1.0.1+2"
```

Or with changelog:

```bash
git commit -m "chore: release v1.0.1+2

- Added Firebase Analytics
- Fixed AD_ID permission issue
- Improved payment flow
"
```

## Summary

**Simple Deploy Process**:
1. ✍️ Update `CHANGELOG.md` → Unreleased section
2. 🚀 Run `fastlane beta`
3. ✅ Everything else is automatic!

**Version Format**: `MAJOR.MINOR.PATCH+BUILD`
- Example: `1.2.3+45` = Version 1.2.3, Build 45
