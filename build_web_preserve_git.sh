#!/bin/bash

# Script to build Flutter web while preserving .git folder in build/web

echo "Building Flutter web with .git folder preservation..."

# Check if build/web/.git exists
if [ -d "build/web/.git" ]; then
    echo "Backing up .git folder..."
    cp -R build/web/.git /tmp/build_web_git_backup
    GIT_BACKUP_EXISTS=true
else
    echo "No .git folder found in build/web, skipping backup"
    GIT_BACKUP_EXISTS=false
fi

# Run Flutter build
echo "Running flutter build web..."
flutter build web

# Restore .git folder if it existed
if [ "$GIT_BACKUP_EXISTS" = true ]; then
    echo "Restoring .git folder..."
    cp -R /tmp/build_web_git_backup build/web/.git
    rm -rf /tmp/build_web_git_backup
    echo "✓ .git folder restored successfully"
fi

echo "✓ Build complete!"
