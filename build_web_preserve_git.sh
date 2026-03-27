#!/bin/bash

# Script to build Flutter web while preserving .git folder in build/web

echo "Building Flutter web with .git folder preservation..."

GIT_BACKUP_EXISTS=false

if [ -d "build/web/.git" ]; then
    echo "Backing up .git folder..."
    mv build/web/.git /tmp/build_web_git_backup
    GIT_BACKUP_EXISTS=true
else
    echo "No .git folder found in build/web, skipping backup"
fi

# Run Flutter build
echo "Running flutter build web..."
flutter build web
BUILD_EXIT=$?

# Restore .git folder if it existed
if [ "$GIT_BACKUP_EXISTS" = true ]; then
    echo "Restoring .git folder..."
    mv /tmp/build_web_git_backup build/web/.git
    echo "✓ .git folder restored successfully"
fi

if [ $BUILD_EXIT -eq 0 ]; then
    echo "✓ Build complete!"
else
    echo "✗ Build failed with exit code $BUILD_EXIT"
    exit $BUILD_EXIT
fi
