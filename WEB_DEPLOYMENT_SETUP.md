# Web Deployment Setup Guide

This guide shows you how to set up automatic deployment of your web build to a separate Git repository.

## Overview

When you run `make web-deploy`, it will:
1. ✅ Build your web app with Firebase configuration
2. ✅ Copy the last commit message from your main repo
3. ✅ Commit to `build/web` with that message
4. ✅ Push to your web deployment repository

---

## Quick Setup (First Time)

### Step 1: Create a Web Deployment Repository

Create a new repository on GitHub (or your Git provider):

```bash
# Example: https://github.com/yourusername/drivetest-web
```

### Step 2: Initialize Git in build/web

```bash
# First, build the web app
make web-build

# Then set up git in build/web
cd build/web
git init
git branch -M main  # or gh-pages
```

### Step 3: Add Remote

```bash
# Still in build/web directory
git remote add origin https://github.com/yourusername/drivetest-web.git

# Or if using SSH
git remote add origin git@github.com:yourusername/drivetest-web.git
```

### Step 4: First Commit and Push

```bash
git add .
git commit -m "Initial web deployment"
git push -u origin main  # or gh-pages
```

### Step 5: Go Back to Project Root

```bash
cd ../..  # Back to project root
```

---

## Usage

### Deploy Web App

```bash
# Build and deploy in one command
make web-deploy
```

This will:
- Build the web app
- Use the latest commit message from main repo
- Commit to build/web
- Push to your web repository

### Example Workflow

```bash
# 1. Make changes to your app
# 2. Update CHANGELOG.md
vim CHANGELOG.md

# 3. Commit your changes
git add .
git commit -m "feat: added new analytics features"

# 4. Build and deploy web
make web-deploy
```

The web repository will get a commit with the message: "feat: added new analytics features"

---

## Configuration

### Custom Remote/Branch

By default, it uses:
- Remote: `origin`
- Branch: `gh-pages`

To customize:

```bash
# Deploy to different remote
make web-deploy WEB_REPO_REMOTE=production

# Deploy to different branch
make web-deploy WEB_REPO_BRANCH=main

# Both
make web-deploy WEB_REPO_REMOTE=production WEB_REPO_BRANCH=main
```

### Make it Permanent

Edit `Makefile` and change these lines:

```makefile
WEB_REPO_REMOTE ?= origin
WEB_REPO_BRANCH ?= gh-pages
```

---

## GitHub Pages Setup

### Option 1: Using gh-pages Branch (Recommended)

1. In your web repository on GitHub, go to **Settings** → **Pages**
2. Set source to: **Deploy from a branch**
3. Select branch: **gh-pages** and folder: **/ (root)**
4. Click **Save**

Your site will be available at: `https://yourusername.github.io/drivetest-web`

### Option 2: Using main Branch

If you used `main` branch instead of `gh-pages`:
- Follow the same steps but select **main** branch

---

## Deployment to Other Platforms

### Firebase Hosting

After running `make web-build`:

```bash
# Deploy to Firebase
firebase deploy --only hosting
```

### Netlify

```bash
# Deploy to Netlify
cd build/web
netlify deploy --prod
```

### Vercel

```bash
# Deploy to Vercel
cd build/web
vercel --prod
```

---

## Common Workflows

### Workflow 1: Feature Development

```bash
# Develop feature
# ... make changes ...

# Update changelog
vim CHANGELOG.md

# Commit
git add .
git commit -m "feat: added dark mode"

# Deploy web
make web-deploy
```

### Workflow 2: Bug Fix

```bash
# Fix bug
# ... make changes ...

# Update changelog
vim CHANGELOG.md

# Commit
git add .
git commit -m "fix: resolved payment dialog crash"

# Deploy web
make web-deploy
```

### Workflow 3: Release

```bash
# Update version
make version-minor

# Update changelog (if needed)
vim CHANGELOG.md

# Commit
git add .
git commit -m "chore: release v1.1.0"

# Deploy all platforms
make web-deploy
make android-beta
make ios-beta
```

---

## Troubleshooting

### Error: "not a git repository"

**Solution:**
```bash
cd build/web
git init
git remote add origin <your-repo-url>
cd ../..
```

### Error: "failed to push"

**Causes:**
1. Remote not configured
2. Authentication issue
3. Branch protection

**Solutions:**

**Check remote:**
```bash
cd build/web
git remote -v
```

**Re-add remote:**
```bash
cd build/web
git remote remove origin
git remote add origin <your-repo-url>
```

**Check authentication:**
```bash
# For SSH
ssh -T git@github.com

# For HTTPS, you may need a personal access token
```

### Error: "No changes to commit"

This is normal if you haven't made any changes since last deploy.

### Build/web has uncommitted changes

**Solution:**
```bash
cd build/web
git status
git add .
git commit -m "manual commit"
```

---

## Advanced: Automated CI/CD

### GitHub Actions Workflow

Create `.github/workflows/deploy-web.yml`:

```yaml
name: Deploy Web

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2

      - name: Create .env file
        run: |
          echo "FIREBASE_API_KEY=${{ secrets.FIREBASE_API_KEY }}" >> .env
          echo "FIREBASE_AUTH_DOMAIN=${{ secrets.FIREBASE_AUTH_DOMAIN }}" >> .env
          # ... add all other env vars

      - name: Build Web
        run: make web-build

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
          commit_message: ${{ github.event.head_commit.message }}
```

---

## Directory Structure

```
taxi_exam_app/
├── build/
│   └── web/              # Web build output (separate git repo)
│       ├── .git/         # Git repository for web deployment
│       ├── index.html
│       └── ...
├── Makefile              # Build and deployment commands
└── ...
```

---

## Best Practices

### 1. Keep Separate Repositories
- Main repo: Source code
- Web repo: Built files only

### 2. Use Meaningful Commit Messages
The web repo will use your main repo's commit messages, so make them descriptive:

```bash
✅ Good: "feat: added Firebase Analytics to track purchases"
❌ Bad: "updates"
```

### 3. Don't Commit build/web to Main Repo
Make sure `build/` is in your main repo's `.gitignore`:

```bash
# In main repo .gitignore
build/
```

### 4. Automated Deployments
Consider setting up CI/CD to deploy automatically on push to main.

---

## Summary

**Initial Setup:**
```bash
make web-build
cd build/web
git init
git remote add origin <your-web-repo-url>
git push -u origin gh-pages
cd ../..
```

**Regular Usage:**
```bash
# After making changes
git commit -m "your message"
make web-deploy
```

**That's it!** Your web app is automatically deployed with the same commit message! 🚀
