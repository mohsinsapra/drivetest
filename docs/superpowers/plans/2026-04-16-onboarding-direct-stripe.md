# Onboarding Direct Stripe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Change onboarding from category-driven recommendations to a single product-driven purchase flow that authenticates if needed and then opens Stripe directly without showing the paywall sheet again.

**Architecture:** Keep the change localized to `OnboardingScreen` by replacing category state with product state and routing the final CTA through a direct payment handler. Add narrow injectable callbacks for product loading, auth, payment, and success display so widget tests can verify orchestration without mocking Stripe internals or refactoring the rest of the payment stack.

**Tech Stack:** Flutter, Dart, `flutter_test`, existing `ApiService`, existing auth bottom sheet, existing Stripe payment service, existing subscription success overlay

---

## File Structure

- Modify: `lib/features/onboarding/onboarding_screen.dart`
  Responsibility: convert onboarding from category selection to subscription-product selection, preserve date/practice steps, and orchestrate auth -> Stripe payment directly.
- Test: `test/features/onboarding/onboarding_screen_test.dart`
  Responsibility: verify plan selection gating and final CTA orchestration for authenticated and unauthenticated users.
- Reference only: `lib/features/auth/auth_bottom_sheet.dart`
  Responsibility: existing auth modal entrypoint reused via injected callback default.
- Reference only: `lib/core/services/stripe_payment_service.dart`
  Responsibility: existing Stripe entrypoint reused via injected callback default.
- Reference only: `lib/features/payment/subscription_success_overlay.dart`
  Responsibility: existing success overlay reused after payment success.

### Task 1: Add Testable Onboarding Seams

**Files:**
- Modify: `lib/features/onboarding/onboarding_screen.dart`
- Test: `test/features/onboarding/onboarding_screen_test.dart`

- [ ] **Step 1: Write the failing test for plan-selection gating**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('continue stays disabled until a subscription product is selected',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          loadProducts: () async => [
            {
              'id': 7,
              'name': '30 Days',
              'price': '199',
              'currency': 'SEK',
              'duration_days': 30,
            },
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    final continueButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull);

    await tester.tap(find.text('30 Days'));
    await tester.pumpAndSettle();

    final enabledButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Continue'),
    );
    expect(enabledButton.onPressed, isNotNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/onboarding/onboarding_screen_test.dart --plain-name "continue stays disabled until a subscription product is selected"`

Expected: FAIL with a constructor error because `OnboardingScreen` does not yet accept `loadProducts`, or FAIL because the continue button is still enabled before selection.

- [ ] **Step 3: Write minimal implementation for injectable dependencies**

```dart
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.loadProducts = _defaultLoadProducts,
    this.showAuthSheet = _defaultShowAuthSheet,
    this.processPayment = _defaultProcessPayment,
    this.showSuccessOverlay = _defaultShowSuccessOverlay,
  });

  final Future<List<Map<String, dynamic>>> Function() loadProducts;
  final Future<bool> Function(BuildContext context) showAuthSheet;
  final Future<void> Function(
    BuildContext context,
    Map<String, dynamic> product,
  ) processPayment;
  final Future<void> Function(
    BuildContext context,
    Map<String, dynamic> product,
  ) showSuccessOverlay;

  static Future<List<Map<String, dynamic>>> _defaultLoadProducts() async {
    final raw = await ApiService().fetchBCDSubscriptionProducts();
    return raw.whereType<Map<String, dynamic>>().toList();
  }
}
```

- [ ] **Step 4: Wire the state class to use the injected loader**

```dart
List<Map<String, dynamic>> _products = [];
bool _loadingProducts = true;
Map<String, dynamic>? _selectedProduct;

@override
void initState() {
  super.initState();
  _fetchProductsInBackground();
}

Future<void> _fetchProductsInBackground() async {
  try {
    final products = await widget.loadProducts();
    if (!mounted) return;
    setState(() {
      _products = products;
      _loadingProducts = false;
    });
  } catch (_) {
    if (mounted) setState(() => _loadingProducts = false);
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/onboarding/onboarding_screen_test.dart --plain-name "continue stays disabled until a subscription product is selected"`

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/onboarding/onboarding_screen.dart test/features/onboarding/onboarding_screen_test.dart
git commit -m "test: add onboarding product selection seam"
```

### Task 2: Replace Step 0 Category UI With Product Selection

**Files:**
- Modify: `lib/features/onboarding/onboarding_screen.dart`
- Test: `test/features/onboarding/onboarding_screen_test.dart`

- [ ] **Step 1: Write the failing test for selected plan summary**

```dart
testWidgets('selected product appears on the final onboarding step',
    (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: OnboardingScreen(
        loadProducts: () async => [
          {
            'id': 21,
            'name': '90 Days',
            'price': '399',
            'currency': 'SEK',
            'duration_days': 90,
          },
        ],
      ),
    ),
  );

  await tester.pumpAndSettle();
  await tester.tap(find.text('90 Days'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
  await tester.pumpAndSettle();

  expect(find.text('90 Days'), findsWidgets);
  expect(find.text('399 SEK'), findsOneWidget);
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/onboarding/onboarding_screen_test.dart --plain-name "selected product appears on the final onboarding step"`

Expected: FAIL because onboarding still renders categories/recommendations instead of product confirmation UI.

- [ ] **Step 3: Replace product selection and final-step widgets with minimal implementation**

```dart
_ProductSelectionPage(
  products: _products,
  loading: _loadingProducts,
  selectedProductId: _selectedProduct?['id'] as int?,
  onSelect: (product) => setState(() => _selectedProduct = product),
  onNext: _selectedProduct != null ? _goNext : null,
),
...
_SelectedPlanPage(
  product: _selectedProduct,
  onPurchase: _selectedProduct == null ? null : _handlePurchaseTap,
  onGetStarted: _saveAndExit,
),
```

- [ ] **Step 4: Implement the plan-card UI using existing product fields only**

```dart
class _ProductPlanCard extends StatelessWidget {
  const _ProductPlanCard({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final Map<String, dynamic> product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? 'Subscription';
    final price = product['price']?.toString() ?? '';
    final currency = product['currency']?.toString() ?? 'SEK';

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name),
          if (price.isNotEmpty) Text('$price $currency'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Run tests to verify both onboarding UI tests pass**

Run: `flutter test test/features/onboarding/onboarding_screen_test.dart`

Expected: PASS with both selection and final-step summary tests green.

- [ ] **Step 6: Commit**

```bash
git add lib/features/onboarding/onboarding_screen.dart test/features/onboarding/onboarding_screen_test.dart
git commit -m "feat: switch onboarding to product selection"
```

### Task 3: Add Failing Tests For Direct Stripe Handoff

**Files:**
- Modify: `lib/features/onboarding/onboarding_screen.dart`
- Test: `test/features/onboarding/onboarding_screen_test.dart`

- [ ] **Step 1: Write the failing test for unauthenticated direct purchase**

```dart
testWidgets('unauthenticated purchase authenticates then pays selected product',
    (tester) async {
  var authCalls = 0;
  var paymentProductId = -1;

  await tester.pumpWidget(
    MaterialApp(
      home: OnboardingScreen(
        loadProducts: () async => [
          {
            'id': 55,
            'name': 'Annual',
            'price': '999',
            'currency': 'SEK',
          },
        ],
        isLoggedIn: () => false,
        showAuthSheet: (_) async {
          authCalls++;
          return true;
        },
        processPayment: (_, product) async {
          paymentProductId = product['id'] as int;
        },
        showSuccessOverlay: (_, __) async {},
      ),
    ),
  );

  await tester.pumpAndSettle();
  await tester.tap(find.text('Annual'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(OutlinedButton, 'Subscribe'));
  await tester.pumpAndSettle();

  expect(authCalls, 1);
  expect(paymentProductId, 55);
})
```

- [ ] **Step 2: Write the failing test for authenticated direct purchase**

```dart
testWidgets('authenticated purchase skips auth and pays selected product',
    (tester) async {
  var authCalls = 0;
  var paymentCalls = 0;

  await tester.pumpWidget(
    MaterialApp(
      home: OnboardingScreen(
        loadProducts: () async => [
          {'id': 77, 'name': 'Quarterly', 'price': '299', 'currency': 'SEK'},
        ],
        isLoggedIn: () => true,
        showAuthSheet: (_) async {
          authCalls++;
          return true;
        },
        processPayment: (_, __) async {
          paymentCalls++;
        },
        showSuccessOverlay: (_, __) async {},
      ),
    ),
  );

  await tester.pumpAndSettle();
  await tester.tap(find.text('Quarterly'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(OutlinedButton, 'Subscribe'));
  await tester.pumpAndSettle();

  expect(authCalls, 0);
  expect(paymentCalls, 1);
})
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `flutter test test/features/onboarding/onboarding_screen_test.dart --plain-name "purchase"`

Expected: FAIL because the current onboarding path still routes through the category paywall flow and does not expose `isLoggedIn` or direct payment injection.

- [ ] **Step 4: Add injectable auth/session/payment defaults to the screen**

```dart
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.loadProducts = _defaultLoadProducts,
    this.isLoggedIn = _defaultIsLoggedIn,
    this.showAuthSheet = _defaultShowAuthSheet,
    this.processPayment = _defaultProcessPayment,
    this.showSuccessOverlay = _defaultShowSuccessOverlay,
  });

  final bool Function() isLoggedIn;

  static bool _defaultIsLoggedIn() => DioClient().accessToken != null;

  static Future<bool> _defaultShowAuthSheet(BuildContext context) {
    return showAuthBottomSheet(context);
  }
}
```

- [ ] **Step 5: Run tests to verify they still fail for the right reason**

Run: `flutter test test/features/onboarding/onboarding_screen_test.dart --plain-name "purchase"`

Expected: FAIL because `_handlePurchaseTap` has not yet been updated to call the injected direct payment path.

- [ ] **Step 6: Commit**

```bash
git add lib/features/onboarding/onboarding_screen.dart test/features/onboarding/onboarding_screen_test.dart
git commit -m "test: cover onboarding direct purchase flow"
```

### Task 4: Implement Direct Auth -> Stripe Purchase Flow

**Files:**
- Modify: `lib/features/onboarding/onboarding_screen.dart`
- Test: `test/features/onboarding/onboarding_screen_test.dart`

- [ ] **Step 1: Implement the direct purchase handler with existing services**

```dart
Future<void> _handlePurchaseTap() async {
  final product = _selectedProduct;
  if (product == null || !mounted) return;

  if (!widget.isLoggedIn()) {
    final authed = await widget.showAuthSheet(context);
    if (!authed || !mounted) return;
  }

  await _savePrefs();
  if (!mounted) return;

  try {
    await widget.processPayment(context, product);
    if (!mounted) return;
    await widget.showSuccessOverlay(context, product);
  } on stripe.StripeException catch (e) {
    final msg = e.error.localizedMessage ?? '';
    if (!msg.toLowerCase().contains('cancel')) {
      showAppSnackBar(msg, type: SnackBarType.error);
    }
  } catch (_) {
    if (!mounted) return;
    showAppSnackBar(
      Translations.of(context).bcd_payment_failed,
      type: SnackBarType.error,
    );
  }
}
```

- [ ] **Step 2: Implement the default payment and success callbacks**

```dart
static Future<void> _defaultProcessPayment(
  BuildContext context,
  Map<String, dynamic> product,
) async {
  final api = ApiService();
  final productId = product['id'] as int;
  final price = product['price']?.toString() ?? '';
  final currency = product['currency']?.toString() ?? 'SEK';
  final name = product['name']?.toString() ?? 'Subscription';

  await processStripePayment(
    context,
    createIntent: () => api.createBCDPaymentIntent(productId),
    merchantName: 'Drive Test',
    subtitle: name,
    displayAmount: price,
    currency: currency,
  );
}

static Future<void> _defaultShowSuccessOverlay(
  BuildContext context,
  Map<String, dynamic> product,
) async {
  final price = product['price']?.toString() ?? '';
  final currency = product['currency']?.toString() ?? 'SEK';
  final name = product['name']?.toString() ?? 'Subscription';
  final days = product['duration_days'] as int?;
  final duration = days == null
      ? null
      : days >= 365
          ? '${(days / 365).round()} year'
          : days >= 30
              ? '${(days / 30).round()} months'
              : '$days days';

  await showSubscriptionSuccess(
    context,
    productName: name,
    duration: duration,
    amount: price,
    currency: currency,
  );
}
```

- [ ] **Step 3: Replace the old category/paywall call sites**

```dart
children: [
  _ProductSelectionPage(...),
  _ExamDatePage(...),
  _PracticeDaysPage(...),
  _SelectedPlanPage(
    product: _selectedProduct,
    onPurchase: _selectedProduct == null ? null : _handlePurchaseTap,
    onGetStarted: _saveAndExit,
  ),
],
```

- [ ] **Step 4: Run the onboarding tests to verify they pass**

Run: `flutter test test/features/onboarding/onboarding_screen_test.dart`

Expected: PASS with selection, final-step summary, authenticated purchase, and unauthenticated purchase tests green.

- [ ] **Step 5: Run static analysis on the modified onboarding file**

Run: `flutter analyze lib/features/onboarding/onboarding_screen.dart`

Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/features/onboarding/onboarding_screen.dart test/features/onboarding/onboarding_screen_test.dart
git commit -m "feat: send onboarding purchases directly to stripe"
```

### Task 5: Final Verification

**Files:**
- Modify: none
- Test: `test/features/onboarding/onboarding_screen_test.dart`

- [ ] **Step 1: Run the focused onboarding test suite**

Run: `flutter test test/features/onboarding/onboarding_screen_test.dart`

Expected: PASS

- [ ] **Step 2: Run a broader regression check for Flutter analysis**

Run: `flutter analyze`

Expected: PASS or only pre-existing unrelated issues clearly identified.

- [ ] **Step 3: Manually verify the user-facing flow**

Run:

```bash
flutter run
```

Expected:
- Step 0 shows subscription products, not categories.
- Continue stays disabled until a plan is selected.
- Final step shows the chosen plan.
- Logged-out purchase shows auth once and then opens Stripe directly.
- Logged-in purchase opens Stripe directly with no extra plan sheet.

- [ ] **Step 4: Commit final verification notes if code changed during cleanup**

```bash
git status --short
```

Expected: clean worktree or only intentional unrelated changes.
