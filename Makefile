# DriveTest App - Makefile
# Usage: make [target]

.PHONY: help web-build web-deploy web-run clean version-patch version-minor version-major

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

# Load environment variables
ifneq (,$(wildcard ./.env))
    include .env
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
	@echo "  make version-patch    - Bump patch version (1.0.0 -> 1.0.1)"
	@echo "  make version-minor    - Bump minor version (1.0.0 -> 1.1.0)"
	@echo "  make version-major    - Bump major version (1.0.0 -> 2.0.0)"
	@echo ""
	@echo "$(COLOR_GREEN)Mobile Deployment:$(COLOR_RESET)"
	@echo "  make android-beta     - Deploy Android to Google Play alpha"
	@echo "  make ios-beta         - Deploy iOS to TestFlight"
	@echo ""
	@echo "$(COLOR_GREEN)Utility Commands:$(COLOR_RESET)"
	@echo "  make clean            - Clean build artifacts"
	@echo "  make help             - Show this help message"
	@echo ""

## web-run: Run web app in development mode
web-run:
	@echo "$(COLOR_GREEN)Starting web app in development mode...$(COLOR_RESET)"
	@flutter run -d chrome \
		--dart-define=FIREBASE_API_KEY="$(FIREBASE_API_KEY)" \
		--dart-define=FIREBASE_AUTH_DOMAIN="$(FIREBASE_AUTH_DOMAIN)" \
		--dart-define=FIREBASE_PROJECT_ID="$(FIREBASE_PROJECT_ID)" \
		--dart-define=FIREBASE_STORAGE_BUCKET="$(FIREBASE_STORAGE_BUCKET)" \
		--dart-define=FIREBASE_MESSAGING_SENDER_ID="$(FIREBASE_MESSAGING_SENDER_ID)" \
		--dart-define=FIREBASE_APP_ID="$(FIREBASE_APP_ID)" \
		--dart-define=FIREBASE_MEASUREMENT_ID="$(FIREBASE_MEASUREMENT_ID)" \
		--dart-define=STRIPE_PUBLISHABLE_KEY="$(STRIPE_PUBLISHABLE_KEY)"

## web-build: Build web app for production
web-build:
	@echo "$(COLOR_GREEN)Building web app for production...$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Base URL: $(WEB_BASE_HREF)$(COLOR_RESET)"
	@flutter build web --release \
		--base-href=$(WEB_BASE_HREF) \
		--dart-define=FIREBASE_API_KEY="$(FIREBASE_API_KEY)" \
		--dart-define=FIREBASE_AUTH_DOMAIN="$(FIREBASE_AUTH_DOMAIN)" \
		--dart-define=FIREBASE_PROJECT_ID="$(FIREBASE_PROJECT_ID)" \
		--dart-define=FIREBASE_STORAGE_BUCKET="$(FIREBASE_STORAGE_BUCKET)" \
		--dart-define=FIREBASE_MESSAGING_SENDER_ID="$(FIREBASE_MESSAGING_SENDER_ID)" \
		--dart-define=FIREBASE_APP_ID="$(FIREBASE_APP_ID)" \
		--dart-define=FIREBASE_MEASUREMENT_ID="$(FIREBASE_MEASUREMENT_ID)" \
		--dart-define=STRIPE_PUBLISHABLE_KEY="$(STRIPE_PUBLISHABLE_KEY)"
	@echo "$(COLOR_GREEN)✅ Build completed! Output: $(WEB_BUILD_DIR)$(COLOR_RESET)"

## web-deploy: Build and deploy web app to repository
web-deploy: web-build
	@echo "$(COLOR_BLUE)Deploying web app to repository...$(COLOR_RESET)"
	@$(MAKE) -s _deploy-to-web-repo

## _deploy-to-web-repo: Internal target for deploying to web repo
_deploy-to-web-repo:
	@echo "$(COLOR_YELLOW)Checking if build/web is a git repository...$(COLOR_RESET)"
	@if [ ! -d "$(WEB_BUILD_DIR)/.git" ]; then \
		echo "$(COLOR_YELLOW)Initializing git repository in $(WEB_BUILD_DIR)...$(COLOR_RESET)"; \
		cd $(WEB_BUILD_DIR) && git init; \
		echo "$(COLOR_YELLOW)Please add your remote repository:$(COLOR_RESET)"; \
		echo "  cd $(WEB_BUILD_DIR) && git remote add origin https://github.com/mohsinsapra/drivetest"; \
		exit 1; \
	fi
	@echo "$(COLOR_GREEN)Getting last commit message from main repository...$(COLOR_RESET)"
	@LAST_COMMIT=$$(git log -1 --pretty=%B); \
	echo "$(COLOR_BLUE)Commit message: $$LAST_COMMIT$(COLOR_RESET)"; \
	cd $(WEB_BUILD_DIR) && \
	git add . && \
	git commit -m "$$LAST_COMMIT" || echo "$(COLOR_YELLOW)No changes to commit$(COLOR_RESET)"; \
	git push $(WEB_REPO_REMOTE) $(WEB_REPO_BRANCH) && \
	echo "$(COLOR_GREEN)✅ Successfully deployed to web repository!$(COLOR_RESET)" || \
	echo "$(COLOR_YELLOW)⚠️  Push failed. Check your remote configuration.$(COLOR_RESET)"

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
	@cd android && fastlane beta

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
