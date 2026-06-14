# Smart Learning Subscription Paywall Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface subscription lock status in the Smart Learning list and gate every practice-start action for unsubscribed paid content behind a single-product paywall.

**Architecture:** Subscription state is a top-level BCD category concept (`is_subscribed`, `subscription_product`) sourced from `BcdCache`. We thread that state plus per-test `is_free` onto `SmartExamEntry`, derive an `isLocked` getter, show a lock badge in the list, and gate the four start actions in `SmartExamScreen` behind a reusable `showSingleProductPaywall` helper (extracted from the existing `BCDCategoryHubScreen` logic).

**Tech Stack:** Flutter/Dart, slang i18n (EN + SV JSON → generated `.g.dart`), `PaymentCoordinator` (Stripe + iOS IAP), Hive, Firebase Analytics.

---

### Task 1: Analytics — `logPaywallShown`

**Files:**
- Modify: `lib/core/services/analytics_service.dart` (near the engagement section, ~line 216)

- [ ] **Step 1: Add the analytics method**

Find the block starting at `Future<void> logSmartLearningStarted()` and add this method directly after `logSmartLearningCompleted()`:

```dart
  Future<void> logPaywallShown({required String source, int? productId}) =>
      _log('paywall_shown', {
        'source': source,
        'product_id': productId,
      });
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/core/services/analytics_service.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/analytics_service.dart
git commit -m "main: add paywall_shown analytics event"
```

---

### Task 2: i18n — `smart_locked` label

**Files:**
- Modify: `lib/core/localization/strings.i18n.json` (EN source)
- Modify: `lib/core/localization/strings_sv.i18n.json` (SV source)
- Regenerates: `lib/core/localization/strings_en.g.dart`, `strings_sv.g.dart`

- [ ] **Step 1: Add EN key**

In `lib/core/localization/strings.i18n.json`, find the line `"bcd_free_label": "FREE",` and add immediately after it:

```json
  "smart_locked": "Locked",
```

- [ ] **Step 2: Add SV key**

In `lib/core/localization/strings_sv.i18n.json`, find the line `"bcd_free_label": "GRATIS",` and add immediately after it:

```json
  "smart_locked": "Låst",
```

- [ ] **Step 3: Regenerate slang bindings**

Run: `dart run slang`
Expected: "Translations generated successfully" (regenerates `strings_en.g.dart` / `strings_sv.g.dart` with a `String get smart_locked` getter).

- [ ] **Step 4: Verify the getter exists**

Run: `grep -n "smart_locked" lib/core/localization/strings_en.g.dart lib/core/localization/strings_sv.g.dart`
Expected: a `String get smart_locked => 'Locked';` line in EN and `=> 'Låst';` in SV.

- [ ] **Step 5: Commit**

```bash
git add lib/core/localization/strings.i18n.json lib/core/localization/strings_sv.i18n.json lib/core/localization/strings_en.g.dart lib/core/localization/strings_sv.g.dart
git commit -m "main: add smart_locked translation string"
```

---

### Task 3: `SmartExamEntry` — subscription fields + `isLocked` (TDD)

**Files:**
- Modify: `lib/features/smart_learning/screens/smart_learning_screen.dart:16-38` (the `SmartExamEntry` class)
- Test: `test/features/smart_learning/smart_exam_entry_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/features/smart_learning/smart_exam_entry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';

SmartExamEntry _entry({
  required bool isTestFree,
  required bool categorySubscribed,
  Map<String, dynamic>? subscriptionProduct,
}) {
  return SmartExamEntry(
    testBcdId: 1,
    testName: 'Test',
    categoryName: 'Cat',
    parentCategoryBcdId: 1,
    subcategoryName: '',
    questionCount: 10,
    passScore: 7,
    timeLimit: 0,
    chunkSizes: const [5, 5],
    isTestFree: isTestFree,
    categorySubscribed: categorySubscribed,
    subscriptionProduct: subscriptionProduct,
  );
}

void main() {
  group('SmartExamEntry.isLocked', () {
    test('free category (null product) is never locked', () {
      expect(
        _entry(isTestFree: false, categorySubscribed: false).isLocked,
        isFalse,
      );
    });

    test('paid + subscribed is not locked', () {
      expect(
        _entry(
          isTestFree: false,
          categorySubscribed: true,
          subscriptionProduct: const {'id': 5},
        ).isLocked,
        isFalse,
      );
    });

    test('paid + unsubscribed + paid test is locked', () {
      expect(
        _entry(
          isTestFree: false,
          categorySubscribed: false,
          subscriptionProduct: const {'id': 5},
        ).isLocked,
        isTrue,
      );
    });

    test('paid + unsubscribed but free test is not locked', () {
      expect(
        _entry(
          isTestFree: true,
          categorySubscribed: false,
          subscriptionProduct: const {'id': 5},
        ).isLocked,
        isFalse,
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/smart_learning/smart_exam_entry_test.dart`
Expected: FAIL to compile — `SmartExamEntry` has no `isTestFree` / `categorySubscribed` / `subscriptionProduct` / `isLocked`.

- [ ] **Step 3: Add fields and getter to `SmartExamEntry`**

In `lib/features/smart_learning/screens/smart_learning_screen.dart`, replace the `SmartExamEntry` class body (the fields + constructor, lines ~17-37) so it includes the three new fields and the getter. The full updated class:

```dart
class SmartExamEntry {
  final int testBcdId;
  final String testName;
  final String categoryName;
  final int parentCategoryBcdId;
  final String subcategoryName;
  final int questionCount;
  final int passScore;
  final int timeLimit;
  final List<int> chunkSizes;
  final bool isTestFree;
  final bool categorySubscribed;
  final Map<String, dynamic>? subscriptionProduct;

  const SmartExamEntry({
    required this.testBcdId,
    required this.testName,
    required this.categoryName,
    required this.parentCategoryBcdId,
    required this.subcategoryName,
    required this.questionCount,
    required this.passScore,
    required this.timeLimit,
    required this.chunkSizes,
    this.isTestFree = false,
    this.categorySubscribed = false,
    this.subscriptionProduct,
  });

  /// True when this test requires a subscription the user does not have.
  /// Free categories (null product) and free tests are never locked.
  bool get isLocked =>
      subscriptionProduct != null && !categorySubscribed && !isTestFree;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/smart_learning/smart_exam_entry_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/smart_learning/screens/smart_learning_screen.dart test/features/smart_learning/smart_exam_entry_test.dart
git commit -m "main: add subscription lock fields to SmartExamEntry"
```

---

### Task 4: Thread category subscription data into entries

**Files:**
- Modify: `lib/features/smart_learning/screens/smart_learning_screen.dart:123-178` (`_buildEntries` + `_entryFromTest`)

- [ ] **Step 1: Pass category subscription data when building entries**

In `_buildEntries`, the loop has `final catName = ...; final hasSubs = ...;`. Add two locals right after `catName` is computed, and pass them into both `_entryFromTest` calls. Replace the `for (final cat in allCats) { ... }` body with:

```dart
    for (final cat in allCats) {
      final catId = cat['bcd_id'] as int;
      final catName = stripAppSuffix(cat['name']?.toString() ?? '');
      final hasSubs = cat['has_children'] == true;
      final catSubscribed = cat['is_subscribed'] == true;
      final catProduct = cat['subscription_product'] as Map<String, dynamic>?;

      if (hasSubs) {
        for (final sub in cache.subcategoriesOf(catId)) {
          final subId = sub['bcd_id'] as int;
          final subName = stripAppSuffix(sub['name']?.toString() ?? '');
          for (final test in cache.testsOf(subId)) {
            final entry = _entryFromTest(
              test,
              catName,
              subId,
              subcategoryName: subName,
              categorySubscribed: catSubscribed,
              subscriptionProduct: catProduct,
            );
            if (entry != null) entries.add(entry);
          }
        }
      } else {
        for (final test in cache.testsOf(catId)) {
          final entry = _entryFromTest(
            test,
            catName,
            catId,
            categorySubscribed: catSubscribed,
            subscriptionProduct: catProduct,
          );
          if (entry != null) entries.add(entry);
        }
      }
    }
```

- [ ] **Step 2: Populate the new fields in `_entryFromTest`**

Replace `_entryFromTest` (lines ~161-178) with:

```dart
  SmartExamEntry? _entryFromTest(
    Map<String, dynamic> test,
    String catName,
    int catId, {
    String subcategoryName = '',
    bool categorySubscribed = false,
    Map<String, dynamic>? subscriptionProduct,
  }) {
    final qc = test['question_count'] as int? ?? 0;
    if (qc == 0) return null;
    final sizes = SmartUtils.computeSmartSizes(qc);
    return SmartExamEntry(
      testBcdId: test['bcd_id'] as int,
      testName: stripAppSuffix(test['name']?.toString() ?? ''),
      categoryName: catName,
      parentCategoryBcdId: catId,
      subcategoryName: subcategoryName,
      questionCount: qc,
      passScore: test['pass_score'] as int? ?? 0,
      timeLimit: test['time_limit'] as int? ?? 0,
      chunkSizes: sizes,
      isTestFree: test['is_free'] == true,
      categorySubscribed: categorySubscribed,
      subscriptionProduct: subscriptionProduct,
    );
  }
```

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze lib/features/smart_learning/screens/smart_learning_screen.dart`
Expected: "No issues found!"

- [ ] **Step 4: Commit**

```bash
git add lib/features/smart_learning/screens/smart_learning_screen.dart
git commit -m "main: thread category subscription state into smart entries"
```

---

### Task 5: Shared `showSingleProductPaywall` helper

**Files:**
- Create: `lib/features/payment/single_product_paywall.dart`

- [ ] **Step 1: Create the helper**

Create `lib/features/payment/single_product_paywall.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import 'package:taxi_exam_app/core/services/payment_coordinator.dart';

/// Shows a paywall scoped to a single BCD subscription product and returns
/// `true` if the user completed a purchase.
///
/// [subscriptionProduct] is the lightweight `subscription_product` map embedded
/// in the bcd_dashboard (it omits `iap_product_id`, so we always fetch the full
/// product list and match by `id` for iOS IAP support). [title] is shown as the
/// paywall heading — pass the category/exam name so the user sees only the one
/// product relevant to what they tapped.
Future<bool> showSingleProductPaywall(
  BuildContext context, {
  required Map<String, dynamic>? subscriptionProduct,
  required String title,
}) async {
  final api = ApiService();
  List<dynamic> products;
  try {
    final all = await api.fetchBCDSubscriptionProducts();
    if (subscriptionProduct != null) {
      final productId = subscriptionProduct['id'];
      final matched = all.where((p) => p['id'] == productId).toList();
      products = matched.isNotEmpty ? matched : all;
    } else {
      products = all;
    }
  } catch (_) {
    products = subscriptionProduct != null ? [subscriptionProduct] : const [];
  }

  if (!context.mounted || products.isEmpty) return false;

  final result = await PaymentCoordinator.show(
    context,
    products: products,
    title: title,
    createStripeIntent: (p) => api.createBCDPaymentIntent(p['id'] as int),
    onStripePaymentConfirmed: api.confirmBCDPayment,
    onIAPPurchaseConfirmed: (p, transactionId) => api.confirmBCDIAPPurchase(
      (p['id'] as num).toInt(),
      transactionId: transactionId,
    ),
  );

  if (result == null) return false;
  await DioClient().clearCache();
  BcdCache.instance.invalidate();
  await BcdCache.instance.ensureLoaded();
  return true;
}
```

- [ ] **Step 2: Verify it compiles**

Run: `flutter analyze lib/features/payment/single_product_paywall.dart`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add lib/features/payment/single_product_paywall.dart
git commit -m "main: extract reusable single-product paywall helper"
```

---

### Task 6: Repoint `BCDCategoryHubScreen` to the shared helper

**Files:**
- Modify: `lib/features/bcd/bcd_category_hub_screen.dart:33-99`

- [ ] **Step 1: Add the import**

In `lib/features/bcd/bcd_category_hub_screen.dart`, add to the import block:

```dart
import 'package:taxi_exam_app/features/payment/single_product_paywall.dart';
```

- [ ] **Step 2: Replace `_showPaywall` body**

Replace the entire `_showPaywall()` method (lines ~55-99) with:

```dart
  Future<void> _showPaywall() async {
    if (_subscribed) return;
    final purchased = await showSingleProductPaywall(
      context,
      subscriptionProduct:
          widget.category['subscription_product'] as Map<String, dynamic>?,
      title: _categoryName,
    );
    if (!purchased || !mounted) return;
    setState(() => widget.category['is_subscribed'] = true);
    _subscribedNotifier.value = true;
  }
```

- [ ] **Step 3: Remove the now-unused `_products` field**

The `_products` field (line ~34, `List<dynamic> _products = [];`) is no longer referenced. Delete that line. If `flutter analyze` reports the `_api` field is now unused, leave it — it is used elsewhere in the file (`_startPractice` calls `BcdCache`, but confirm via analyze; only remove fields analyze flags as unused).

- [ ] **Step 4: Verify it compiles with no warnings**

Run: `flutter analyze lib/features/bcd/bcd_category_hub_screen.dart`
Expected: "No issues found!" (no unused-field warnings).

- [ ] **Step 5: Commit**

```bash
git add lib/features/bcd/bcd_category_hub_screen.dart
git commit -m "main: use shared paywall helper in BCD category hub"
```

---

### Task 7: Lock badge in the Smart Learning list

**Files:**
- Modify: `lib/features/smart_learning/screens/smart_learning_screen.dart` (`_buildCategoryList`, `_buildSubcategoryList`, `_CategoryRow`, `_ExamRow`, and a new `_LockBadge`)

- [ ] **Step 1: Add a `_LockBadge` widget**

In `smart_learning_screen.dart`, directly below the `_FreeBadge` class (ends ~line 719), add:

```dart
// ── Lock badge ─────────────────────────────────────────────────────────────────

class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    final color = cs.onSurface.withValues(alpha: 0.55);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            t.smart_locked,
            style:
                TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Add `locked` param to `_CategoryRow`**

Replace the `_CategoryRow` field list + constructor (lines ~602-617) with:

```dart
class _CategoryRow extends StatelessWidget {
  final String name;
  final bool isFree;
  final bool locked;
  final int testCount;
  final int passedChunks;
  final int totalChunks;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.name,
    required this.isFree,
    this.locked = false,
    required this.testCount,
    required this.passedChunks,
    required this.totalChunks,
    required this.onTap,
  });
```

Then in `_CategoryRow.build`, find the `Row(children: [ if (isFree) ...[ _FreeBadge(...) ... ] ...])` block (lines ~669-681) and add a locked branch. Replace that inner `Row` with:

```dart
                    Row(
                      children: [
                        if (isFree) ...[
                          _FreeBadge(color: cs.primary),
                          const SizedBox(width: 6),
                        ] else if (locked) ...[
                          const _LockBadge(),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(sub,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.5))),
                        ),
                      ],
                    ),
```

- [ ] **Step 3: Pass `locked` from the category list**

In `_buildCategoryList`, where `_CategoryRow(...)` is constructed (~line 374), compute lock state from the category's entries and pass it. Replace the `_CategoryRow(` call args up to `onTap:` with:

```dart
                _CategoryRow(
                  name: catName,
                  isFree: isFreeMap[catName] ?? false,
                  locked: catEntries.any((e) =>
                      e.subscriptionProduct != null && !e.categorySubscribed),
                  testCount: catEntries.length,
                  passedChunks: passedChunks,
                  totalChunks: totalChunks,
```

- [ ] **Step 4: Pass `locked` from the subcategory list**

In `_buildSubcategoryList`, the `_CategoryRow(...)` call (~line 461) currently passes `isFree: false`. Replace its leading args (down to `testCount:`) with:

```dart
                _CategoryRow(
                  name: subName,
                  isFree: false,
                  locked: subEntries.any((e) =>
                      e.subscriptionProduct != null && !e.categorySubscribed),
                  testCount: subEntries.length,
```

- [ ] **Step 5: Show lock badge on `_ExamRow`**

In `_ExamRow.build`, find the title `Column` (the `Text(entry.testName ...)` followed by `Text(statusLabel ...)`, lines ~836-848). Replace that `Column`'s `children` with a version that prepends a lock badge row when locked:

```dart
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.testName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    if (entry.isLocked) ...[
                      const _LockBadge(),
                      const SizedBox(height: 4),
                    ],
                    Text(statusLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: allDone
                                ? Colors.green.shade600
                                : cs.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
```

- [ ] **Step 6: Verify it compiles**

Run: `flutter analyze lib/features/smart_learning/screens/smart_learning_screen.dart`
Expected: "No issues found!"

- [ ] **Step 7: Commit**

```bash
git add lib/features/smart_learning/screens/smart_learning_screen.dart
git commit -m "main: show subscription lock badge in smart learning list"
```

---

### Task 8: Gate practice-start actions in `SmartExamScreen`

**Files:**
- Modify: `lib/features/smart_learning/screens/smart_exam_screen.dart` (imports, state, `_startChunk`, `_startReview`, `_startMistakes`, `_launchFullExam`)

- [ ] **Step 1: Add imports**

In `lib/features/smart_learning/screens/smart_exam_screen.dart`, add to the import block:

```dart
import 'package:taxi_exam_app/core/services/analytics_service.dart';
import 'package:taxi_exam_app/features/payment/single_product_paywall.dart';
```

- [ ] **Step 2: Add subscription state + gate helper**

In `_SmartExamScreenState` (after the existing field declarations, ~line 41, before `int get _reviewCount`), add:

```dart
  late bool _subscribed = widget.entry.categorySubscribed;

  bool get _locked =>
      widget.entry.subscriptionProduct != null &&
      !_subscribed &&
      !widget.entry.isTestFree;

  /// Returns true when the action should be blocked (locked and not purchased).
  /// If the user buys during the paywall, unlocks in place and returns false so
  /// the caller proceeds with the originally requested action.
  Future<bool> _gateBlocked() async {
    if (!_locked) return false;
    AnalyticsService().logPaywallShown(
      source: 'smart_learning',
      productId: (widget.entry.subscriptionProduct?['id'] as num?)?.toInt(),
    );
    final purchased = await showSingleProductPaywall(
      context,
      subscriptionProduct: widget.entry.subscriptionProduct,
      title: widget.entry.categoryName,
    );
    if (!mounted) return true;
    if (purchased) {
      setState(() => _subscribed = true);
      return false;
    }
    return true;
  }
```

- [ ] **Step 3: Gate `_startChunk`**

In `_startChunk` (line ~78), insert the gate check after the existing `_loadingKey` guard. The opening becomes:

```dart
  Future<void> _startChunk(int chunkIndex) async {
    if (_loadingKey != null) return;
    if (await _gateBlocked()) return;
    setState(() => _loadingKey = 'chunk-$chunkIndex');
```

- [ ] **Step 4: Gate `_startReview`**

In `_startReview` (line ~137), the opening becomes:

```dart
  Future<void> _startReview(int reviewIndex) async {
    if (_loadingKey != null) return;
    if (await _gateBlocked()) return;
    setState(() => _loadingKey = 'review-$reviewIndex');
```

- [ ] **Step 5: Gate `_startMistakes`**

In `_startMistakes` (line ~196), the opening becomes:

```dart
  Future<void> _startMistakes() async {
    if (_loadingKey != null) return;
    if (await _gateBlocked()) return;
    setState(() => _loadingKey = 'mistakes');
```

- [ ] **Step 6: Gate `_launchFullExam`**

In `_launchFullExam` (line ~381), the opening becomes:

```dart
  Future<void> _launchFullExam() async {
    if (_loadingKey != null) return;
    if (await _gateBlocked()) return;
    setState(() => _loadingKey = 'fullExam');
```

- [ ] **Step 7: Verify it compiles**

Run: `flutter analyze lib/features/smart_learning/screens/smart_exam_screen.dart`
Expected: "No issues found!"

- [ ] **Step 8: Commit**

```bash
git add lib/features/smart_learning/screens/smart_exam_screen.dart
git commit -m "main: gate smart learning practice behind per-exam paywall"
```

---

### Task 9: Full verification

- [ ] **Step 1: Analyze the whole project**

Run: `flutter analyze`
Expected: "No issues found!"

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: All tests pass (including the 4 new `SmartExamEntry.isLocked` tests).

- [ ] **Step 3: Manual smoke test (device/simulator)**

Run the app and verify:
1. Smart Learning list shows a **Locked** badge on paid categories the user has not subscribed to, and the **Free** badge still shows on free categories.
2. A free test inside a paid (unsubscribed) category shows **no** lock badge and practices normally.
3. Tapping a locked exam still opens `SmartExamScreen` (preview allowed).
4. Tapping any start action (a part, a review, train mistakes, or the full exam) on a locked exam opens a paywall titled with the **category name** showing only that one product.
5. Completing a purchase unlocks the exam in place and continues into the action; cancelling returns to the parts list with no session started.
6. An already-subscribed paid exam starts every action with no paywall.

- [ ] **Step 4: Update graphify (per project CLAUDE.md)**

Run: `graphify update .`
Expected: graph updated (AST-only, no API cost).

---

## Notes for the executor

- **Commits:** This project's owner reviews all diffs and does not want auto-commits. **Skip every `git commit` step** in the tasks above and leave changes unstaged for review. The commit messages are retained only as a record of the intended task boundaries.
- The `subscription_product` map is the lightweight bcd_dashboard snapshot (has `id`, lacks `iap_product_id`); the paywall helper deliberately re-fetches full products and matches by `id`. Do not pass the embedded map straight to `PaymentCoordinator`.
- Subscription is a top-level category concept; subcategory tests inherit it because `_entryFromTest` receives the parent category's `categorySubscribed` / `subscriptionProduct` for both leaf and subcategory branches.
