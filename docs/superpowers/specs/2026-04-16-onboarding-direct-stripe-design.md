# Onboarding Direct Stripe Design

## Goal

Replace the current category-driven onboarding purchase flow with a product-driven flow so the user selects a subscription plan once, completes onboarding, authenticates if needed, and is taken directly into Stripe without seeing a second plan-selection sheet.

## Current Behavior

- Step 0 of onboarding fetches BCD categories with `ApiService().fetchBCDAllCategories()`.
- The last onboarding screen lists recommended categories.
- Tapping subscribe while logged out opens `showAuthBottomSheet(context)`.
- After login succeeds, onboarding opens `showCategorySubscribeSheet(...)`.
- That paywall sheet fetches subscription products again and makes the user choose a plan a second time before Stripe opens.

## Desired Behavior

- Step 0 fetches subscription products with `ApiService().fetchBCDSubscriptionProducts()`.
- The first onboarding screen allows the user to choose a single subscription product.
- The selected product remains in onboarding state for the rest of the flow.
- The last onboarding screen summarizes the chosen plan and provides the purchase CTA.
- If the user is unauthenticated when they tap the CTA, onboarding shows the auth bottom sheet.
- When auth succeeds, onboarding immediately starts Stripe payment for the already-selected product.
- The onboarding purchase path does not open `showCategorySubscribeSheet(...)`.

## Scope

### In scope

- Change onboarding data source from categories to subscription products.
- Change onboarding selection state from category indices to a selected product.
- Rework the final onboarding screen to operate on the selected product.
- Reuse existing Stripe payment and success overlay behavior.
- Preserve the auth bottom sheet, but change the post-auth handoff to Stripe directly.

### Out of scope

- Removing `showCategorySubscribeSheet(...)` from non-onboarding flows.
- Redesigning auth UI.
- Changing backend API contracts.
- Adding multi-plan selection inside onboarding.

## Data Flow

1. `OnboardingScreen.initState()` fetches subscription products.
2. Step 0 renders available products and stores one selected product map in widget state.
3. User completes exam date and practice-day steps.
4. Final onboarding screen renders the chosen plan summary and purchase CTA.
5. CTA handler checks `DioClient().accessToken`.
6. If unauthenticated, show `showAuthBottomSheet(context)` and stop on dismiss/failure.
7. Save onboarding preferences.
8. Call `processStripePayment(...)` directly with `ApiService().createBCDPaymentIntent(selectedProductId)`.
9. On success, show the existing subscription success overlay.

## UI Design

### Step 0

- Replace the category grid with a subscription-product selection list/grid.
- Each product card should show the plan name and core pricing information already available in the product payload.
- Selection must be visually obvious and exclusive; only one plan can be active at a time.
- The continue button is disabled until a plan is selected.

### Final step

- Replace the recommendation list with a confirmation-style screen for the chosen plan.
- Show the selected plan name and any lightweight supporting details already available in the product data.
- Primary CTA starts purchase for the selected plan.
- Secondary action remains the existing “get started” exit path only if the current product/UX still requires a non-purchase path.

## Implementation Shape

### `lib/features/onboarding/onboarding_screen.dart`

- Replace `_categories`, `_loadingCategories`, `_selectedIndices`, and `_recommendedCategories` with product-based state.
- Add a background loader for subscription products.
- Replace `_handleSubscribeTap(Map<String, dynamic> category)` with a product-based purchase handler.
- In the purchase handler, call Stripe directly instead of `showCategorySubscribeSheet(...)`.
- Update step-0 and final-step widgets to receive product-centric props.

### `lib/features/payment/subscribe_paywall_sheet.dart`

- No behavior changes required for this task.
- The onboarding path simply stops calling into this sheet.

## Error Handling

- If product loading fails, show the existing empty/fallback state pattern already used in onboarding.
- If auth is dismissed, remain on onboarding with no navigation.
- If Stripe throws a cancellation exception, fail silently as current payment flows do.
- If Stripe or intent creation fails, show the existing BCD payment failure snackbar.

## Testing Strategy

- Add or update widget tests for onboarding so step 0 requires a product selection before continuing.
- Add a test for unauthenticated purchase flow:
  - select product
  - finish onboarding steps
  - auth returns success
  - direct Stripe handler is invoked
  - paywall sheet is not invoked
- Add a test for authenticated purchase flow that verifies direct Stripe handoff without auth sheet.
- Keep tests focused on onboarding orchestration rather than Stripe internals by injecting or wrapping external calls where needed.

## Risks

- `onboarding_screen.dart` is already large and currently dirty in the worktree, so edits must be minimal and carefully merged.
- The current implementation uses direct service calls, which may make widget testing hard; small seams may be needed for dependency injection without broad refactoring.
- Product payload shape is not yet documented in the UI layer, so card rendering should use only fields already proven in existing paywall code (`id`, `name`, `price`, `currency`, `duration_days` when present).
