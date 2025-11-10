# Web Base URL Configuration Guide

## Overview

The `WEB_BASE_HREF` environment variable controls the base URL path for your web app deployment.

---

## Configuration

Edit `.env` file:

```env
# Web Build Configuration
WEB_BASE_HREF=/drivetest/
```

---

## Common Scenarios

### 1. GitHub Pages (Repository)
**URL**: `https://yourusername.github.io/repository-name/`

**.env**:
```env
WEB_BASE_HREF=/repository-name/
```

**Example**:
```env
WEB_BASE_HREF=/drivetest/
```
→ App will be at: `https://mohsinsapra.github.io/drivetest/`

---

### 2. GitHub Pages (User/Org Site)
**URL**: `https://yourusername.github.io/`

**.env**:
```env
WEB_BASE_HREF=/
```

**Example**: If repo is named `yourusername.github.io`
```env
WEB_BASE_HREF=/
```
→ App will be at: `https://mohsinsapra.github.io/`

---

### 3. Custom Domain (Root)
**URL**: `https://yourapp.com/`

**.env**:
```env
WEB_BASE_HREF=/
```

**Example**: `https://drivetest.app/`
```env
WEB_BASE_HREF=/
```

---

### 4. Custom Domain (Subdirectory)
**URL**: `https://yourapp.com/path/to/app/`

**.env**:
```env
WEB_BASE_HREF=/path/to/app/
```

**Example**: `https://example.com/apps/drivetest/`
```env
WEB_BASE_HREF=/apps/drivetest/
```

---

### 5. Subdomain
**URL**: `https://app.yoursite.com/`

**.env**:
```env
WEB_BASE_HREF=/
```

---

## Important Rules

### ✅ DO:
- Always start with `/`
- Always end with `/`
- Use lowercase
- No spaces

### ❌ DON'T:
- `WEB_BASE_HREF=drivetest/` ❌ (missing leading /)
- `WEB_BASE_HREF=/drivetest` ❌ (missing trailing /)
- `WEB_BASE_HREF=/Drive Test/` ❌ (has spaces)

---

## Testing Different Configurations

### Test Locally

After changing `WEB_BASE_HREF` in `.env`:

```bash
# Rebuild with new base href
make web-build

# Test locally
cd build/web
python3 -m http.server 8000

# Open browser to: http://localhost:8000/drivetest/
# (Note: Local testing might not perfectly replicate production)
```

---

## Changing Base URL

### Example: Moving from GitHub Pages to Custom Domain

**Current** (GitHub Pages):
```env
WEB_BASE_HREF=/drivetest/
```
→ `https://mohsinsapra.github.io/drivetest/`

**Change to** (Custom Domain):
```env
WEB_BASE_HREF=/
```
→ `https://yourapp.com/`

**Steps**:
1. Edit `.env` and change `WEB_BASE_HREF=/`
2. Rebuild: `make web-build`
3. Deploy to your custom domain

---

## Verification

Check what base href will be used:

```bash
# Show the value
make -n web-build | grep "base-href"

# Or check directly
grep WEB_BASE_HREF .env
```

---

## Override at Build Time

You can override the .env value temporarily:

```bash
# Build with custom base href
make web-build WEB_BASE_HREF=/custom/path/

# Or using the script
WEB_BASE_HREF=/custom/path/ ./scripts/build_web.sh
```

---

## Troubleshooting

### Issue: App loads but assets (CSS/JS) are missing

**Cause**: Wrong `WEB_BASE_HREF`

**Solution**:
1. Check your actual deployment URL
2. Ensure `WEB_BASE_HREF` matches your URL path
3. Rebuild and redeploy

**Example**:
- App deployed to: `https://mohsinsapra.github.io/drivetest/`
- WEB_BASE_HREF must be: `/drivetest/`

---

### Issue: App shows 404 on refresh

**Cause**: Server not configured for SPA routing

**Solution**:
- For GitHub Pages: It should work automatically
- For custom servers: Configure to serve `index.html` for all routes

**Nginx example**:
```nginx
location /drivetest/ {
    try_files $uri $uri/ /drivetest/index.html;
}
```

---

## Quick Reference

| Deployment Type | WEB_BASE_HREF | Example URL |
|----------------|---------------|-------------|
| GitHub Pages (repo) | `/repo-name/` | `username.github.io/repo-name/` |
| GitHub Pages (user) | `/` | `username.github.io/` |
| Custom domain (root) | `/` | `yourapp.com/` |
| Custom domain (subdir) | `/path/` | `yourapp.com/path/` |
| Subdomain | `/` | `app.yoursite.com/` |

---

## Current Configuration

Your current setup:

```env
WEB_BASE_HREF=/drivetest/
```

**Deployed to**: `https://mohsinsapra.github.io/drivetest/`

**To change**, edit `.env` and rebuild!
