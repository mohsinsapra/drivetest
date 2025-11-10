# Makefile Quick Reference

## 🚀 Most Used Commands

```bash
# Run web app locally
make web-run

# Build and deploy web (with auto commit message)
make web-deploy

# Bump version and deploy everything
make version-minor
make web-deploy
make android-beta
make ios-beta
```

---

## 📦 Web Commands

| Command | Description |
|---------|-------------|
| `make web-run` | Run web app in Chrome with hot reload |
| `make web-build` | Build production web app |
| `make web-deploy` | Build + commit + push to web repo |

---

## 🔢 Version Commands

| Command | Description | Example |
|---------|-------------|---------|
| `make version-patch` | Bug fixes | 1.0.0 → 1.0.1 |
| `make version-minor` | New features | 1.0.0 → 1.1.0 |
| `make version-major` | Breaking changes | 1.0.0 → 2.0.0 |

---

## 📱 Mobile Deployment

| Command | Description |
|---------|-------------|
| `make android-beta` | Deploy to Google Play alpha |
| `make ios-beta` | Deploy to TestFlight |

---

## 🛠️ Utility Commands

| Command | Description |
|---------|-------------|
| `make clean` | Remove all build artifacts |
| `make help` | Show all available commands |

---

## 💡 Common Workflows

### Daily Development
```bash
# Make changes, then:
make web-run          # Test locally
```

### Deploy Web
```bash
git commit -m "feat: new feature"
make web-deploy       # Auto uses commit message
```

### Release New Version
```bash
make version-minor    # Bump version
git commit -m "chore: release v1.1.0"
make web-deploy      # Deploy web
make android-beta    # Deploy Android
make ios-beta        # Deploy iOS
```

### Clean Start
```bash
make clean
make web-build
```

---

## 🎯 Pro Tips

**Tip 1:** Commit first, then deploy
```bash
git commit -m "your message"
make web-deploy  # Uses your commit message!
```

**Tip 2:** Chain commands
```bash
make version-patch && git add . && git commit -m "release" && make web-deploy
```

**Tip 3:** Custom deploy settings
```bash
make web-deploy WEB_REPO_BRANCH=main
```

---

## 📚 Documentation

- **Setup**: Read [WEB_DEPLOYMENT_SETUP.md](WEB_DEPLOYMENT_SETUP.md)
- **Complete Guide**: Read [WEB_BUILD_GUIDE.md](WEB_BUILD_GUIDE.md)
- **Versions**: Read [VERSION_MANAGEMENT.md](VERSION_MANAGEMENT.md)
