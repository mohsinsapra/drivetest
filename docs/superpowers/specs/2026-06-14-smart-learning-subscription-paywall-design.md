# Smart Learning — Subscription Awareness & Per-Exam Paywall

**Date:** 2026-06-14
**Status:** Approved (design)

## Problem

The Exams page (`BCDSubscriptionsScreen`) shows prices, Free/Active badges, and a
Subscribe vs Start-practice CTA per product. The Smart Learning tab does not surface
subscription status, and — more importantly — it currently provides **no gating**:
tapping any exam navigates to `SmartExamScreen` and practice starts immediately, even
for paid content the user has not subscribed to.

## Goals

1. Surface subscription status in the Smart Learning list (lock indicator for paid,
   unsubscribed content).
2. Gate practice so an unsubscribed user hits a paywall when they try to *start* a
   session on paid content.
3. The paywall shows **only the one product** relevant to that exam's category
   (not the full plan list).

## Decisions (locked)

- **Gating point:** *Both* — allow previewing the parts/full-exam layout, but gate
  every start action (parts, reviews, mistakes, full exam).
- **Free tests:** *Respect per-test `is_free`* — a free test inside a paid,
  unsubscribed category stays open; only non-free tests are gated.
- **Status UI:** *Lock indicator only* — keep the existing Free badge; add a lock
  glyph for paid, unsubscribed content. No "Active" badge.

## Data model

Subscription state is a **top-level category** concept (`is_subscribed`,
`subscription_product`). Subcategory tests inherit the parent category's state.
Source: `BcdCache` (seeded from `/self` → `bcd_dashboard`).

### `SmartExamEntry` — new fields

- `bool isTestFree` ← `test['is_free'] == true`
- `bool categorySubscribed` ← top-level category `is_subscribed == true`
- `Map<String, dynamic>? subscriptionProduct` ← top-level category
  `subscription_product` (lightweight map containing `id`; `null` = free category)

Derived:

```dart
bool get isLocked =>
    subscriptionProduct != null && !categorySubscribed && !isTestFree;
```

`_buildEntries` already iterates `allCats` with full `cat` data, so `_entryFromTest`
receives `categorySubscribed` + `subscriptionProduct` from the parent category for
both leaf-category tests and subcategory tests.

## UI — `smart_learning_screen.dart`

- **`_CategoryRow` / subcategory rows:** keep Free badge. Add a lock glyph when the
  group is paid & unsubscribed: `catEntries.any((e) => e.subscriptionProduct != null
  && !e.categorySubscribed)`. Rows remain tappable (preview allowed).
- **`_ExamRow`:** show a lock glyph when `entry.isLocked` (per-test accurate — a free
  test inside a paid category shows no lock). Remains tappable → opens
  `SmartExamScreen` for preview.
- **Glyph:** `Icons.lock_outline_rounded`, muted `cs.onSurface`, in the badge slot.

## Gating — `smart_exam_screen.dart`

- Mutable state: `bool _subscribed = widget.entry.categorySubscribed;`
- `bool get _locked => widget.entry.subscriptionProduct != null && !_subscribed &&
  !widget.entry.isTestFree;`
- Guard wrapping the four start actions (`_startChunk`, `_startReview`,
  `_startMistakes`, `_launchFullExam`):

```dart
Future<void> _gate(Future<void> Function() start) async {
  if (!_locked) return start();
  final purchased = await showSingleProductPaywall(
    context,
    subscriptionProduct: widget.entry.subscriptionProduct,
    title: widget.entry.categoryName,
  );
  if (purchased && mounted) {
    setState(() => _subscribed = true);
    await start();
  }
}
```

On successful purchase the originally requested action auto-continues.

## Shared paywall helper — `lib/features/payment/single_product_paywall.dart` (new)

Extract the existing logic from `BCDCategoryHubScreen._showPaywall()`:

```dart
Future<bool> showSingleProductPaywall(
  BuildContext context, {
  required Map<String, dynamic>? subscriptionProduct,
  required String title,
});
```

Behaviour (unchanged from the hub version):
1. Fetch full products via `ApiService.fetchBCDSubscriptionProducts()` (the embedded
   `subscription_product` omits `iap_product_id`, needed for iOS IAP).
2. Match the single product by `id`; fall back to embedded product, then full list.
3. `PaymentCoordinator.show(products: [...], title: title, createStripeIntent / 
   onStripePaymentConfirmed / onIAPPurchaseConfirmed)`.
4. On success: `DioClient().clearCache()`, `BcdCache.invalidate()` + `ensureLoaded()`.
5. Return `true` if purchased, else `false`.

Repoint `BCDCategoryHubScreen._showPaywall()` to this helper to remove the
duplication (related cleanup — a second caller now exists).

## Translations & polish

- If a text label is needed alongside the lock glyph, add `smart_locked` to **all**
  locale files. Icon-only is acceptable per the "lock indicator only" decision.
- Paywall title = category name, so the sheet shows only that one exam's product.
- Optional: log a `paywall_shown` analytics event (source `smart_learning`) if a
  matching `AnalyticsService` method exists.

## Files touched

- `lib/features/smart_learning/screens/smart_learning_screen.dart` — entry fields,
  row lock indicators
- `lib/features/smart_learning/screens/smart_exam_screen.dart` — gate guard + paywall
- `lib/features/payment/single_product_paywall.dart` — **new** shared helper
- `lib/features/bcd/bcd_category_hub_screen.dart` — repoint to shared helper
- locale files — `smart_locked` (only if a text label is added)

## Out of scope

- Changes to the Exams page itself.
- New badge styles beyond the lock glyph (no "Active" badge).
- Subscription/pricing backend changes.
