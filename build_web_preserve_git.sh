#!/bin/bash

# Script to build Flutter web while preserving .git folder in build/web

# Load .env from project root if present
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

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

# Purge Cloudflare CDN cache so users get fresh files immediately.
# Requires CLOUDFLARE_ZONE_ID and CLOUDFLARE_API_TOKEN env vars.
if [ -n "$CLOUDFLARE_ZONE_ID" ] && [ -n "$CLOUDFLARE_API_TOKEN" ]; then
    echo "Purging Cloudflare cache..."
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data '{"purge_everything":true}')
    if [ "$RESPONSE" = "200" ]; then
        echo "✓ Cloudflare cache purged"
    else
        echo "⚠ Cloudflare purge returned HTTP $RESPONSE (check token/zone)"
    fi
else
    echo "⚠ Skipping Cloudflare purge — set CLOUDFLARE_ZONE_ID and CLOUDFLARE_API_TOKEN to enable"
fi
