# DriveTest App - Makefile
# Usage: make [target]

.PHONY: help web-build web-deploy web-run clean version-build version-patch version-minor version-major android-beta android-deploy ios-beta release-all deploy-all

# Colors for output
COLOR_RESET = \033[0m
COLOR_BOLD = \033[1m
COLOR_GREEN = \033[32m
COLOR_YELLOW = \033[33m
COLOR_BLUE = \033[34m

# Configuration
WEB_BUILD_DIR = build/web
WEB_REPO_REMOTE ?= origin
WEB_REPO_BRANCH ?= master
APP_VERSION = $(shell sed -nE 's/^version:[[:space:]]*([^+]+)\+(.+)$$/\1/p' pubspec.yaml | head -1)
APP_BUILD_NUMBER = $(shell sed -nE 's/^version:[[:space:]]*([^+]+)\+(.+)$$/\2/p' pubspec.yaml | head -1)
GIT_COMMIT_HASH = $(shell git rev-parse HEAD 2>/dev/null)
GIT_SHORT_HASH = $(shell git rev-parse --short HEAD 2>/dev/null)
GIT_BRANCH = $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null)
GIT_COMMIT_DATE = $(shell git log -1 --date=iso-strict --pretty=%cd 2>/dev/null)

# Load environment variables
# .env.local overrides .env for local development (test keys, etc.)
ifneq (,$(wildcard ./.env))
    include .env
    export
endif
# Capture live keys from .env before .env.local can override them
LIVE_STRIPE_PUBLISHABLE_KEY := $(STRIPE_PUBLISHABLE_KEY)
ifneq (,$(wildcard ./.env.local))
    include .env.local
    export
endif

# Set default base href if not provided in .env
WEB_BASE_HREF ?= /

## help: Show this help message
help:
	@echo "$(COLOR_BOLD)DriveTest App - Available Commands$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_GREEN)Web Commands:$(COLOR_RESET)"
	@echo "  make web-run          - Run web app in development mode"
	@echo "  make web-build        - Build web app for production"
	@echo "  make web-deploy       - Build and deploy to web repository"
	@echo ""
	@echo "$(COLOR_GREEN)Version Commands:$(COLOR_RESET)"
	@echo "  make version-build    - Bump build number only (1.0.0+1 -> 1.0.0+2)"
	@echo "  make version-patch    - Bump patch version (1.0.0 -> 1.0.1)"
	@echo "  make version-minor    - Bump minor version (1.0.0 -> 1.1.0)"
	@echo "  make version-major    - Bump major version (1.0.0 -> 2.0.0)"
	@echo ""
	@echo "$(COLOR_GREEN)Mobile Deployment:$(COLOR_RESET)"
	@echo "  make android-beta     - Deploy Android to Google Play alpha"
	@echo "  make android-deploy   - Deploy Android to alpha, then promote to production"
	@echo "  make deploy-all       - Deploy web, then deploy Android to alpha and production"
	@echo "  make ios-beta         - Deploy iOS to TestFlight"
	@echo ""
	@echo "$(COLOR_GREEN)Utility Commands:$(COLOR_RESET)"
	@echo "  make clean            - Clean build artifacts"
	@echo "  make help             - Show this help message"
	@echo ""

## web-run: Run web app in development mode
web-run:
	@echo "$(COLOR_GREEN)Starting web app in development mode...$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Web version: v$(APP_VERSION) ($(APP_BUILD_NUMBER))$(COLOR_RESET)"
	@flutter run -d chrome \
		--dart-define=FIREBASE_API_KEY="$(FIREBASE_API_KEY)" \
		--dart-define=FIREBASE_AUTH_DOMAIN="$(FIREBASE_AUTH_DOMAIN)" \
		--dart-define=FIREBASE_PROJECT_ID="$(FIREBASE_PROJECT_ID)" \
		--dart-define=FIREBASE_STORAGE_BUCKET="$(FIREBASE_STORAGE_BUCKET)" \
		--dart-define=FIREBASE_MESSAGING_SENDER_ID="$(FIREBASE_MESSAGING_SENDER_ID)" \
		--dart-define=FIREBASE_APP_ID="$(FIREBASE_APP_ID)" \
		--dart-define=FIREBASE_MEASUREMENT_ID="$(FIREBASE_MEASUREMENT_ID)" \
		--dart-define=STRIPE_PUBLISHABLE_KEY="$(STRIPE_PUBLISHABLE_KEY)" \
		--dart-define=GOOGLE_WEB_CLIENT_ID="$(GOOGLE_CLIENT_ID)" \
		--dart-define=GOOGLE_SERVER_CLIENT_ID="$(GOOGLE_SERVER_CLIENT_ID)" \
		--dart-define=APP_VERSION="$(APP_VERSION)" \
		--dart-define=BUILD_NUMBER="$(APP_BUILD_NUMBER)" \
		--dart-define=GIT_COMMIT_HASH="$(GIT_COMMIT_HASH)" \
		--dart-define=GIT_SHORT_HASH="$(GIT_SHORT_HASH)" \
		--dart-define=GIT_BRANCH="$(GIT_BRANCH)" \
		--dart-define=GIT_COMMIT_DATE="$(GIT_COMMIT_DATE)"

## web-build: Build web app for production
web-build:
	@echo "$(COLOR_GREEN)Building web app for production...$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Base URL: $(WEB_BASE_HREF)$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Web version: v$(APP_VERSION) ($(APP_BUILD_NUMBER))$(COLOR_RESET)"
	@if [ -d "$(WEB_BUILD_DIR)/.git" ]; then \
		echo "$(COLOR_YELLOW)Backing up .git folder...$(COLOR_RESET)"; \
		rm -rf /tmp/build_web_git_backup; \
		mv $(WEB_BUILD_DIR)/.git /tmp/build_web_git_backup; \
	fi
	@flutter build web --release \
		--base-href=$(WEB_BASE_HREF) \
		--dart-define=FIREBASE_API_KEY="$(FIREBASE_API_KEY)" \
		--dart-define=FIREBASE_AUTH_DOMAIN="$(FIREBASE_AUTH_DOMAIN)" \
		--dart-define=FIREBASE_PROJECT_ID="$(FIREBASE_PROJECT_ID)" \
		--dart-define=FIREBASE_STORAGE_BUCKET="$(FIREBASE_STORAGE_BUCKET)" \
		--dart-define=FIREBASE_MESSAGING_SENDER_ID="$(FIREBASE_MESSAGING_SENDER_ID)" \
		--dart-define=FIREBASE_APP_ID="$(FIREBASE_APP_ID)" \
		--dart-define=FIREBASE_MEASUREMENT_ID="$(FIREBASE_MEASUREMENT_ID)" \
		--dart-define=STRIPE_PUBLISHABLE_KEY="$(LIVE_STRIPE_PUBLISHABLE_KEY)" \
		--dart-define=GOOGLE_WEB_CLIENT_ID="$(GOOGLE_CLIENT_ID)" \
		--dart-define=GOOGLE_SERVER_CLIENT_ID="$(GOOGLE_SERVER_CLIENT_ID)" \
		--dart-define=APP_VERSION="$(APP_VERSION)" \
		--dart-define=BUILD_NUMBER="$(APP_BUILD_NUMBER)" \
		--dart-define=GIT_COMMIT_HASH="$(GIT_COMMIT_HASH)" \
		--dart-define=GIT_SHORT_HASH="$(GIT_SHORT_HASH)" \
		--dart-define=GIT_BRANCH="$(GIT_BRANCH)" \
		--dart-define=GIT_COMMIT_DATE="$(GIT_COMMIT_DATE)"
	@$(MAKE) -s _write-web-version-file
	@if [ -d "/tmp/build_web_git_backup" ]; then \
		echo "$(COLOR_YELLOW)Restoring .git folder...$(COLOR_RESET)"; \
		mv /tmp/build_web_git_backup $(WEB_BUILD_DIR)/.git; \
		echo "$(COLOR_GREEN)✅ .git folder restored!$(COLOR_RESET)"; \
	fi
	@echo "$(COLOR_GREEN)✅ Build completed! Output: $(WEB_BUILD_DIR)$(COLOR_RESET)"

## _write-web-version-file: Write deploy metadata for the built web app
_write-web-version-file:
	@mkdir -p $(WEB_BUILD_DIR)
	@printf '%s\n' '{' \
		'  "appVersion": "$(APP_VERSION)",' \
		'  "buildNumber": "$(APP_BUILD_NUMBER)",' \
		'  "shortHash": "$(GIT_SHORT_HASH)",' \
		'  "branch": "$(GIT_BRANCH)",' \
		'  "commitDate": "$(GIT_COMMIT_DATE)"' \
		'}' > $(WEB_BUILD_DIR)/version.json
	@echo "$(COLOR_GREEN)✅ Wrote $(WEB_BUILD_DIR)/version.json$(COLOR_RESET)"

## web-deploy: Bump build number, build and deploy web app to repository
web-deploy: version-build web-build
	@echo "$(COLOR_BLUE)Deploying web app to repository...$(COLOR_RESET)"
	@$(MAKE) -s _deploy-to-web-repo
	@echo "$(COLOR_BLUE)Committing version bump to main repository...$(COLOR_RESET)"
	@git add pubspec.yaml CHANGELOG.md
	@git diff --cached --quiet || git commit -m "chore: bump version to $(APP_VERSION)+$(APP_BUILD_NUMBER)"
	@git push
	@echo "$(COLOR_GREEN)✅ Version commit pushed!$(COLOR_RESET)"

WEB_REPO_URL ?= https://github.com/mohsinsapra/drivetest

## _deploy-to-web-repo: Internal target for deploying to web repo
_deploy-to-web-repo:
	@echo "$(COLOR_YELLOW)Checking if build/web is a git repository...$(COLOR_RESET)"
	@if [ ! -d "$(WEB_BUILD_DIR)/.git" ]; then \
		echo "$(COLOR_YELLOW)Initializing git repository in $(WEB_BUILD_DIR)...$(COLOR_RESET)"; \
		cd $(WEB_BUILD_DIR) && git init; \
	fi
	@if ! git -C $(WEB_BUILD_DIR) remote get-url $(WEB_REPO_REMOTE) > /dev/null 2>&1; then \
		echo "$(COLOR_YELLOW)Adding remote origin: $(WEB_REPO_URL)$(COLOR_RESET)"; \
		git -C $(WEB_BUILD_DIR) remote add $(WEB_REPO_REMOTE) $(WEB_REPO_URL); \
	fi
	@echo "$(COLOR_GREEN)Getting last commit message from main repository...$(COLOR_RESET)"
	@LAST_COMMIT=$$(git log -1 --pretty=%B); \
	echo "$(COLOR_BLUE)Commit message: $$LAST_COMMIT$(COLOR_RESET)"; \
	cd $(WEB_BUILD_DIR) && \
	git add . && \
	git commit -m "$$LAST_COMMIT" || echo "$(COLOR_YELLOW)No changes to commit$(COLOR_RESET)"; \
	git push $(WEB_REPO_REMOTE) $(WEB_REPO_BRANCH) --force && \
	echo "$(COLOR_GREEN)✅ Successfully deployed to web repository!$(COLOR_RESET)" || \
	echo "$(COLOR_YELLOW)⚠️  Push failed. Check your remote configuration.$(COLOR_RESET)"

## version-build: Bump build number only
version-build:
	@echo "$(COLOR_GREEN)Bumping build number...$(COLOR_RESET)"
	@cd scripts && ruby update_version.rb build

## version-patch: Bump patch version
version-patch:
	@echo "$(COLOR_GREEN)Bumping patch version...$(COLOR_RESET)"
	@cd scripts && ruby update_version.rb patch

## version-minor: Bump minor version
version-minor:
	@echo "$(COLOR_GREEN)Bumping minor version...$(COLOR_RESET)"
	@cd scripts && ruby update_version.rb minor

## version-major: Bump major version
version-major:
	@echo "$(COLOR_GREEN)Bumping major version...$(COLOR_RESET)"
	@cd scripts && ruby update_version.rb major

web-android-deploy: web-build android-beta 
## android-beta: Deploy Android to Google Play alpha
android-beta:
	@echo "$(COLOR_GREEN)Deploying Android to Google Play alpha track...$(COLOR_RESET)"
	@cd android && bundle exec fastlane android beta

## android-deploy: Deploy Android to alpha and promote to production
android-deploy:
	@echo "$(COLOR_GREEN)Deploying Android to alpha and promoting to production...$(COLOR_RESET)"
	@cd android && bundle exec fastlane android deploy

## release-all: Deploy web and Android production release
release-all: web-deploy android-deploy

## deploy-all: Deploy web and Android production release
deploy-all: web-deploy android-deploy

## ios-beta: Deploy iOS to TestFlight
ios-beta:
	@echo "$(COLOR_GREEN)Deploying iOS to TestFlight...$(COLOR_RESET)"
	@cd ios && fastlane beta

## clean: Clean build artifacts
clean:
	@echo "$(COLOR_YELLOW)Cleaning build artifacts...$(COLOR_RESET)"
	@flutter clean
	@rm -rf build/
	@echo "$(COLOR_GREEN)✅ Clean completed!$(COLOR_RESET)"

# Default target
.DEFAULT_GOAL := help
