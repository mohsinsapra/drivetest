# DriveTest App - Makefile
# Usage: make [target]

.PHONY: help fmt lint check web-build web-deploy web-run web-tunnel tunnel restart-flutter restart-backend clean version-build version-patch version-minor version-major android-beta android-deploy ios-beta release-all deploy-all deploy-web-android _commit-and-push _deploy-to-web-repo _write-web-version-file _web-deploy-core _android-deploy-core _android-beta-core _ios-beta-core _bump-version _cloudflare-purge _web-build-docker _android-build-docker

# Bump type for deploy commands: fix | patch | minor | major (default: patch)
# Usage: make deploy-all BUMP=minor
BUMP ?= patch

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

# Public config defaults — safe to hardcode (not secrets).
# If .env provides them they take precedence via the include above.
# Without these defaults, an absent .env would pass empty --dart-define values
# which override the defaultValue in main.dart and silently break things.

# Firebase web config
FIREBASE_API_KEY              ?= AIzaSyCNHfjgw5mcgg5d7NayRluVTXwHPlpoGWM
FIREBASE_AUTH_DOMAIN          ?= drive-test-a4f94.firebaseapp.com
FIREBASE_PROJECT_ID           ?= drive-test-a4f94
FIREBASE_STORAGE_BUCKET       ?= drive-test-a4f94.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID  ?= 640394192831
FIREBASE_APP_ID               ?= 1:640394192831:web:2f7c45b3bae1a15f1a630a
FIREBASE_MEASUREMENT_ID       ?= G-2Y166BG2F3

# Google OAuth client IDs (no defaultValue in code — must always be passed)
GOOGLE_CLIENT_ID              ?= 678561448025-n2jia0bm2q47ojt4dmba4o7bg2opu18t.apps.googleusercontent.com
GOOGLE_SERVER_CLIENT_ID       ?= 640394192831-e6hi0ho85923epa77ir6402ggl8pgrff.apps.googleusercontent.com

# Sentry DSN (has a hardcoded default in main.dart, but .env value should win)
SENTRY_DSN                    ?= https://32d4a7e8f8033e788074ecf90ad55f2a@o4511088769564672.ingest.de.sentry.io/4511202750038096

# Set default base href if not provided in .env
WEB_BASE_HREF ?= /

# Docker image for isolated Flutter builds (includes Android SDK)
FLUTTER_DOCKER_IMAGE ?= ghcr.io/cirruslabs/flutter:stable

## help: Show this help message
help:
	@echo "$(COLOR_BOLD)DriveTest App - Available Commands$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_GREEN)Web Commands:$(COLOR_RESET)"
	@echo "  make web-run          - Run web app in development mode"
	@echo "  make web-tunnel       - Run web app + Cloudflare tunnel (accessible from anywhere)"
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
	@echo "  make deploy-all       - Deploy web + Android production + iOS TestFlight"
	@echo "  make ios-beta         - Deploy iOS to TestFlight"
	@echo ""
	@echo "$(COLOR_YELLOW)BUMP parameter (applies to all deploy commands):$(COLOR_RESET)"
	@echo "  BUMP=fix    - Bug fix release:   1.0.3 → 1.0.4  (default)"
	@echo "  BUMP=patch  - Same as fix:       1.0.3 → 1.0.4"
	@echo "  BUMP=minor  - New features:      1.0.3 → 1.1.0"
	@echo "  BUMP=major  - Breaking changes:  1.0.3 → 2.0.0"
	@echo "  Example: make deploy-all BUMP=minor"
	@echo ""
	@echo "$(COLOR_GREEN)Utility Commands:$(COLOR_RESET)"
	@echo "  make fmt              - Format all Dart files"
	@echo "  make lint             - Run flutter analyze"
	@echo "  make check            - Format then lint before deploy"
	@echo "  make clean            - Clean build artifacts"
	@echo "  make help             - Show this help message"
	@echo ""

## fmt: Format all Dart files
fmt:
	@echo "$(COLOR_BLUE)Formatting Dart files...$(COLOR_RESET)"
	@dart format .
	@echo "$(COLOR_GREEN)✅ Formatting complete!$(COLOR_RESET)"

## lint: Run flutter analyze
lint:
	@echo "$(COLOR_BLUE)Running flutter analyze...$(COLOR_RESET)"
	@flutter analyze
	@echo "$(COLOR_GREEN)✅ Linting passed!$(COLOR_RESET)"

## check: Format and lint before deploy
check: fmt lint
	@echo "$(COLOR_GREEN)✅ Project checks passed!$(COLOR_RESET)"

WEB_PORT ?= 5005

## web-run: Run web app in development mode
web-run:
	@echo "$(COLOR_GREEN)Starting web app in development mode on port $(WEB_PORT)...$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Web version: v$(APP_VERSION) ($(APP_BUILD_NUMBER))$(COLOR_RESET)"
	@flutter run -d chrome --web-port=$(WEB_PORT) \
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
		--dart-define=SENTRY_DSN="$(SENTRY_DSN)" \
		--dart-define=APP_VERSION="$(APP_VERSION)" \
		--dart-define=BUILD_NUMBER="$(APP_BUILD_NUMBER)" \
		--dart-define=GIT_COMMIT_HASH="$(GIT_COMMIT_HASH)" \
		--dart-define=GIT_SHORT_HASH="$(GIT_SHORT_HASH)" \
		--dart-define=GIT_BRANCH="$(GIT_BRANCH)" \
		--dart-define=GIT_COMMIT_DATE="$(GIT_COMMIT_DATE)"

## web-tunnel: Run web app + Cloudflare tunnel with auto hot-reload on file save
web-tunnel:
	@command -v cloudflared >/dev/null 2>&1 || (echo "$(COLOR_YELLOW)Installing cloudflared...$(COLOR_RESET)" && brew install cloudflared)
	@command -v fswatch >/dev/null 2>&1 || (echo "$(COLOR_YELLOW)Installing fswatch...$(COLOR_RESET)" && brew install fswatch)
	@lsof -ti:$(WEB_PORT) | xargs kill -9 2>/dev/null; true
	@rm -f /tmp/flutter_tunnel_pipe; mkfifo /tmp/flutter_tunnel_pipe; \
	cloudflared tunnel --config $(HOME)/.cloudflared/drivetest-flutter.yml run & CF_PID=$$!; \
	flutter run -d web-server --web-port=$(WEB_PORT) \
		--dart-define=API_BASE_URL="https://dev-dashboard.drivetest.se/" \
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
		--dart-define=SENTRY_DSN="$(SENTRY_DSN)" \
		--dart-define=APP_VERSION="$(APP_VERSION)" \
		--dart-define=BUILD_NUMBER="$(APP_BUILD_NUMBER)" \
		--dart-define=GIT_COMMIT_HASH="$(GIT_COMMIT_HASH)" \
		--dart-define=GIT_SHORT_HASH="$(GIT_SHORT_HASH)" \
		--dart-define=GIT_BRANCH="$(GIT_BRANCH)" \
		--dart-define=GIT_COMMIT_DATE="$(GIT_COMMIT_DATE)" \
		< /tmp/flutter_tunnel_pipe & FLUTTER_PID=$$!; \
	exec 3>/tmp/flutter_tunnel_pipe; \
	trap "echo '$(COLOR_YELLOW)Shutting down...$(COLOR_RESET)'; kill $$CF_PID $$FLUTTER_PID 2>/dev/null; exec 3>&-; rm -f /tmp/flutter_tunnel_pipe; exit" INT TERM; \
	echo "$(COLOR_GREEN)Live at: https://dev-app.drivetest.se$(COLOR_RESET)"; \
	echo "$(COLOR_YELLOW)Watching lib/ — hot reload fires automatically on every save$(COLOR_RESET)"; \
	fswatch -o lib/ | while read; do \
		echo "$(COLOR_BLUE)Change detected — hot restarting...$(COLOR_RESET)"; \
		echo R >&3; \
	done

## tunnel: Start backend + Flutter web app tunnels (same as make tunnel in the backend dir)
tunnel:
	@$(MAKE) -C ../taxi_exam_backend tunnel

## restart-flutter: Restart only the Flutter web server + tunnel
restart-flutter:
	@$(MAKE) -C ../taxi_exam_backend restart-flutter

## restart-backend: Restart only Django + its tunnel
restart-backend:
	@$(MAKE) -C ../taxi_exam_backend restart-backend

## web-build: Build web app for production
web-build: check
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
		--dart-define=SENTRY_DSN="$(SENTRY_DSN)" \
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

## _cloudflare-purge: Purge Cloudflare CDN cache so users get fresh files immediately
_cloudflare-purge:
	@if [ -n "$(CLOUDFLARE_ZONE_ID)" ] && [ -n "$(CLOUDFLARE_API_TOKEN)" ]; then \
		echo "$(COLOR_BLUE)Purging Cloudflare cache...$(COLOR_RESET)"; \
		HTTP_STATUS=$$(curl -s -o /tmp/cf_purge_response.json -w "%{http_code}" -X POST \
			"https://api.cloudflare.com/client/v4/zones/$(CLOUDFLARE_ZONE_ID)/purge_cache" \
			-H "Authorization: Bearer $(CLOUDFLARE_API_TOKEN)" \
			-H "Content-Type: application/json" \
			--data '{"purge_everything":true}'); \
		if [ "$$HTTP_STATUS" = "200" ]; then \
			echo "$(COLOR_GREEN)✅ Cloudflare cache purged — users will get fresh build$(COLOR_RESET)"; \
		else \
			echo "$(COLOR_YELLOW)⚠️  Cloudflare purge returned HTTP $$HTTP_STATUS$(COLOR_RESET)"; \
			cat /tmp/cf_purge_response.json; \
		fi; \
	else \
		echo "$(COLOR_YELLOW)⚠️  Skipping Cloudflare purge — CLOUDFLARE_ZONE_ID or CLOUDFLARE_API_TOKEN not set$(COLOR_RESET)"; \
	fi

## _web-build-docker: Build web app inside Docker (isolated, parallel-safe)
_web-build-docker:
	@echo "$(COLOR_GREEN)Building web app in Docker...$(COLOR_RESET)"
	@if [ -d "$(WEB_BUILD_DIR)/.git" ]; then \
		rm -rf /tmp/build_web_git_backup; \
		mv $(WEB_BUILD_DIR)/.git /tmp/build_web_git_backup; \
	fi
	@docker run --rm \
		-v $(shell pwd):/app \
		-v /tmp/flutter-web-dart-tool:/app/.dart_tool \
		-w /app \
		$(FLUTTER_DOCKER_IMAGE) \
		sh -c "flutter pub get && flutter build web --release \
			--base-href=$(WEB_BASE_HREF) \
			--dart-define=FIREBASE_API_KEY='$(FIREBASE_API_KEY)' \
			--dart-define=FIREBASE_AUTH_DOMAIN='$(FIREBASE_AUTH_DOMAIN)' \
			--dart-define=FIREBASE_PROJECT_ID='$(FIREBASE_PROJECT_ID)' \
			--dart-define=FIREBASE_STORAGE_BUCKET='$(FIREBASE_STORAGE_BUCKET)' \
			--dart-define=FIREBASE_MESSAGING_SENDER_ID='$(FIREBASE_MESSAGING_SENDER_ID)' \
			--dart-define=FIREBASE_APP_ID='$(FIREBASE_APP_ID)' \
			--dart-define=FIREBASE_MEASUREMENT_ID='$(FIREBASE_MEASUREMENT_ID)' \
			--dart-define=STRIPE_PUBLISHABLE_KEY='$(LIVE_STRIPE_PUBLISHABLE_KEY)' \
			--dart-define=GOOGLE_WEB_CLIENT_ID='$(GOOGLE_CLIENT_ID)' \
			--dart-define=GOOGLE_SERVER_CLIENT_ID='$(GOOGLE_SERVER_CLIENT_ID)' \
			--dart-define=SENTRY_DSN='$(SENTRY_DSN)' \
			--dart-define=APP_VERSION='$(APP_VERSION)' \
			--dart-define=BUILD_NUMBER='$(APP_BUILD_NUMBER)' \
			--dart-define=GIT_COMMIT_HASH='$(GIT_COMMIT_HASH)' \
			--dart-define=GIT_SHORT_HASH='$(GIT_SHORT_HASH)' \
			--dart-define=GIT_BRANCH='$(GIT_BRANCH)' \
			--dart-define=GIT_COMMIT_DATE='$(GIT_COMMIT_DATE)'"
	@$(MAKE) -s _write-web-version-file
	@if [ -d "/tmp/build_web_git_backup" ]; then \
		mv /tmp/build_web_git_backup $(WEB_BUILD_DIR)/.git; \
	fi
	@echo "$(COLOR_GREEN)✅ Web Docker build completed!$(COLOR_RESET)"

## _android-build-docker: Build Android app bundle inside Docker (isolated, parallel-safe)
_android-build-docker:
	@echo "$(COLOR_GREEN)Building Android app bundle in Docker...$(COLOR_RESET)"
	@printf 'org.gradle.jvmargs=-Xmx2g -Dorg.gradle.daemon=false -Djdk.lang.Process.launchMechanism=posix_spawn\nandroid.useAndroidX=true\nandroid.enableJetifier=true\n' > /tmp/docker-gradle.properties
	@docker run --rm \
		-v $(shell pwd):/app \
		-v /tmp/flutter-android-dart-tool:/app/.dart_tool \
		-v /tmp/docker-gradle.properties:/app/android/gradle.properties:ro \
		-w /app \
		$(FLUTTER_DOCKER_IMAGE) \
		sh -c "flutter pub get && flutter build appbundle --release \
			--dart-define=FIREBASE_API_KEY='$(FIREBASE_API_KEY)' \
			--dart-define=FIREBASE_AUTH_DOMAIN='$(FIREBASE_AUTH_DOMAIN)' \
			--dart-define=FIREBASE_PROJECT_ID='$(FIREBASE_PROJECT_ID)' \
			--dart-define=FIREBASE_STORAGE_BUCKET='$(FIREBASE_STORAGE_BUCKET)' \
			--dart-define=FIREBASE_MESSAGING_SENDER_ID='$(FIREBASE_MESSAGING_SENDER_ID)' \
			--dart-define=FIREBASE_APP_ID='$(FIREBASE_APP_ID)' \
			--dart-define=FIREBASE_MEASUREMENT_ID='$(FIREBASE_MEASUREMENT_ID)' \
			--dart-define=STRIPE_PUBLISHABLE_KEY='$(LIVE_STRIPE_PUBLISHABLE_KEY)' \
			--dart-define=GOOGLE_WEB_CLIENT_ID='$(GOOGLE_CLIENT_ID)' \
			--dart-define=GOOGLE_SERVER_CLIENT_ID='$(GOOGLE_SERVER_CLIENT_ID)' \
			--dart-define=SENTRY_DSN='$(SENTRY_DSN)' \
			--dart-define=APP_VERSION='$(APP_VERSION)' \
			--dart-define=BUILD_NUMBER='$(APP_BUILD_NUMBER)' \
			--dart-define=GIT_COMMIT_HASH='$(GIT_COMMIT_HASH)' \
			--dart-define=GIT_SHORT_HASH='$(GIT_SHORT_HASH)' \
			--dart-define=GIT_BRANCH='$(GIT_BRANCH)' \
			--dart-define=GIT_COMMIT_DATE='$(GIT_COMMIT_DATE)'"
	@echo "$(COLOR_GREEN)✅ Android Docker build completed!$(COLOR_RESET)"

## _web-deploy-core: Build web and push to web repo (no version bump, no git commit)
_web-deploy-core: web-build
	@echo "$(COLOR_BLUE)Deploying web app to repository...$(COLOR_RESET)"
	@$(MAKE) -s _deploy-to-web-repo
	@$(MAKE) -s _cloudflare-purge

## web-deploy: Bump patch, deploy web and commit to main repo
web-deploy: check
	@$(MAKE) -s _bump-version BUMP=$(BUMP)
	@$(MAKE) -s _web-deploy-core
	@$(MAKE) -s _commit-and-push

## _android-beta-core: Deploy Android to alpha (no git commit)
_android-beta-core:
	@echo "$(COLOR_GREEN)Deploying Android to Google Play alpha track...$(COLOR_RESET)"
	@cd android && bundle exec fastlane android beta

## _android-deploy-core: Deploy Android to alpha and production (no git commit)
_android-deploy-core:
	@echo "$(COLOR_GREEN)Deploying Android to alpha and promoting to production...$(COLOR_RESET)"
	@cd android && bundle exec fastlane android deploy

## _commit-and-push: Stage pubspec + changelog + fastlane reports and push to main repo
_commit-and-push:
	@echo "$(COLOR_BLUE)Committing changes to main repository...$(COLOR_RESET)"
	@git add pubspec.yaml CHANGELOG.md
	@git add android/fastlane/report.xml 2>/dev/null || true
	@git add android/fastlane/metadata/ 2>/dev/null || true
	@CURRENT_VER=$$(sed -nE 's/^version:[[:space:]]*(.+)$$/\1/p' pubspec.yaml | head -1); \
	git diff --cached --quiet || git commit -m "chore: bump version to $$CURRENT_VER [deploy]"
	@git push
	@echo "$(COLOR_GREEN)✅ Commit pushed!$(COLOR_RESET)"

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

## _bump-version: Bump version using BUMP= (fix|patch|minor|major). Defaults to patch.
_bump-version:
	$(eval BUMP_TYPE := $(if $(filter fix,$(BUMP)),patch,$(BUMP)))
	@echo "$(COLOR_GREEN)Bumping $(BUMP_TYPE) version...$(COLOR_RESET)"
	@cd scripts && ruby update_version.rb $(BUMP_TYPE)

web-android-deploy: check web-build android-beta

## android-beta: Bump patch, deploy Android to alpha and commit to main repo
android-beta: check
	@$(MAKE) -s _bump-version BUMP=$(BUMP)
	@$(MAKE) -s _android-beta-core
	@$(MAKE) -s _commit-and-push

## android-deploy: Bump patch, deploy Android to alpha + production and commit to main repo
android-deploy: check
	@$(MAKE) -s _bump-version BUMP=$(BUMP)
	@$(MAKE) -s _android-deploy-core
	@$(MAKE) -s _commit-and-push

## release-all: Bump patch, deploy web + Android production, single commit at the end
release-all: check
	@$(MAKE) -s _bump-version BUMP=$(BUMP)
	@$(MAKE) -s _web-deploy-core
	@$(MAKE) -s _android-deploy-core
	@$(MAKE) -s _commit-and-push

## deploy-web-android: Bump patch, deploy web + Android natively in parallel, single commit
deploy-web-android: check
	@$(MAKE) -s _bump-version BUMP=$(BUMP)
	@$(MAKE) -s _web-deploy-core & WEB_PID=$$!; \
	$(MAKE) -s _android-deploy-core & AND_PID=$$!; \
	wait $$WEB_PID; WEB_EXIT=$$?; \
	wait $$AND_PID; AND_EXIT=$$?; \
	[ $$WEB_EXIT -eq 0 ] && [ $$AND_EXIT -eq 0 ]
	@$(MAKE) -s _commit-and-push

## deploy-all: Bump patch, deploy web + Android + iOS all in parallel, single commit at the end
deploy-all: check
	@$(MAKE) -s _bump-version BUMP=$(BUMP)
	@$(MAKE) -s _web-deploy-core & WEB_PID=$$!; \
	$(MAKE) -s _android-deploy-core & AND_PID=$$!; \
	$(MAKE) -s _ios-beta-core & IOS_PID=$$!; \
	wait $$WEB_PID; WEB_EXIT=$$?; \
	wait $$AND_PID; AND_EXIT=$$?; \
	wait $$IOS_PID; IOS_EXIT=$$?; \
	[ $$WEB_EXIT -eq 0 ] && [ $$AND_EXIT -eq 0 ] && [ $$IOS_EXIT -eq 0 ]
	@$(MAKE) -s _commit-and-push

## _ios-beta-core: Deploy iOS to TestFlight (no git commit, no version bump)
_ios-beta-core:
	@echo "$(COLOR_GREEN)Deploying iOS to TestFlight...$(COLOR_RESET)"
	@cd ios && bundle exec fastlane beta

## ios-beta: Bump patch, deploy iOS to TestFlight and commit to main repo
ios-beta: check
	@$(MAKE) -s _bump-version BUMP=$(BUMP)
	@$(MAKE) -s _ios-beta-core
	@$(MAKE) -s _commit-and-push

## clean: Clean build artifacts
clean:
	@echo "$(COLOR_YELLOW)Cleaning build artifacts...$(COLOR_RESET)"
	@flutter clean
	@rm -rf build/
	@echo "$(COLOR_GREEN)✅ Clean completed!$(COLOR_RESET)"

# Default target
.DEFAULT_GOAL := help
