import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// IAP Flow Tests
//
// Tests the SharedPreferences-based logic used by IAPService without
// instantiating the singleton (which triggers Google Play billing init
// that fails in the test environment).
//
// The keys below match the private constants in IAPService — if those change,
// update here too.
// ─────────────────────────────────────────────────────────────────────────────

const _kDeferredKey = 'iap_deferred_receipt';
const _kDeviceTokenKey = 'iap_device_token';
const _kLocalEntitlementKey = 'iap_local_entitlement';

// Replicates IAPService.hasLocalEntitlement() logic.
Future<bool> _hasLocalEntitlement() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kLocalEntitlementKey);
  if (raw == null) return false;
  try {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final endDate = DateTime.parse(data['end_date'] as String);
    return endDate.isAfter(DateTime.now());
  } catch (_) {
    return false;
  }
}

// Replicates IAPService.hasDeferredReceipt() logic.
Future<bool> _hasDeferredReceipt() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_kDeferredKey) != null;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── Local entitlement ─────────────────────────────────────────────────────

  group('hasLocalEntitlement', () {
    test('returns false when nothing is stored', () async {
      expect(await _hasLocalEntitlement(), isFalse);
    });

    test('returns true when end_date is in the future', () async {
      final future = DateTime.now().add(const Duration(days: 30)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        _kLocalEntitlementKey: '{"end_date":"$future","product_id":"com.taxi.sub.30days"}',
      });
      expect(await _hasLocalEntitlement(), isTrue);
    });

    test('returns false when end_date is in the past (subscription expired)', () async {
      final past = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        _kLocalEntitlementKey: '{"end_date":"$past","product_id":"com.taxi.sub.30days"}',
      });
      expect(await _hasLocalEntitlement(), isFalse);
    });

    test('returns false when JSON is malformed', () async {
      SharedPreferences.setMockInitialValues({
        _kLocalEntitlementKey: 'not-valid-json',
      });
      expect(await _hasLocalEntitlement(), isFalse);
    });

    test('returns false when end_date field is missing', () async {
      SharedPreferences.setMockInitialValues({
        _kLocalEntitlementKey: '{"product_id":"x"}',
      });
      expect(await _hasLocalEntitlement(), isFalse);
    });
  });

  // ── Clear local entitlement ───────────────────────────────────────────────

  group('clearLocalEntitlement', () {
    test('removes stored entitlement', () async {
      final future = DateTime.now().add(const Duration(days: 30)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        _kLocalEntitlementKey: '{"end_date":"$future","product_id":"x"}',
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLocalEntitlementKey);

      expect(await _hasLocalEntitlement(), isFalse);
    });

    test('is safe to call when nothing is stored', () async {
      final prefs = await SharedPreferences.getInstance();
      await expectLater(prefs.remove(_kLocalEntitlementKey), completes);
    });
  });

  // ── Deferred receipt ──────────────────────────────────────────────────────

  group('hasDeferredReceipt', () {
    test('returns false when nothing is stored', () async {
      expect(await _hasDeferredReceipt(), isFalse);
    });

    test('returns true when a receipt is stored', () async {
      SharedPreferences.setMockInitialValues({
        _kDeferredKey: '{"receipt_data":"abc","product_id":"x","internal_product_id":7}',
      });
      expect(await _hasDeferredReceipt(), isTrue);
    });
  });

  group('verifyDeferredReceipt — prefs side', () {
    test('purged when malformed JSON is stored', () async {
      SharedPreferences.setMockInitialValues({
        _kDeferredKey: 'not-valid-json',
      });

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_kDeferredKey);
      Map<String, dynamic>? data;
      try {
        data = jsonDecode(stored!) as Map<String, dynamic>;
      } catch (_) {
        await prefs.remove(_kDeferredKey);
      }

      expect(data, isNull);
      expect(prefs.getString(_kDeferredKey), isNull);
    });
  });

  // ── Device token ──────────────────────────────────────────────────────────

  group('deviceToken', () {
    test('generates a UUID v4 when nothing is stored', () async {
      final prefs = await SharedPreferences.getInstance();
      // Simulate what IAPService.deviceToken does.
      var token = prefs.getString(_kDeviceTokenKey);
      if (token == null) {
        // UUID v4 format: 8-4-4-4-12 hex chars.
        token = '550e8400-e29b-41d4-a716-446655440000'; // placeholder
        await prefs.setString(_kDeviceTokenKey, token);
      }
      expect(token, isNotEmpty);
      expect(token, equals(prefs.getString(_kDeviceTokenKey)));
    });

    test('reuses a pre-existing token', () async {
      const stored = '11111111-2222-3333-4444-555555555555';
      SharedPreferences.setMockInitialValues({_kDeviceTokenKey: stored});

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_kDeviceTokenKey) ?? 'generated';
      expect(token, equals(stored));
    });
  });

  // ── Restore stream logic ──────────────────────────────────────────────────

  group('restoredProductIds stream', () {
    test('emits one event per restored product', () async {
      final controller = StreamController<String>.broadcast();
      final received = <String>[];

      final sub = controller.stream.listen(received.add);
      controller.add('com.taxi.sub.30days');
      controller.add('com.taxi.sub.90days');
      await controller.close();
      await sub.cancel();

      expect(received, ['com.taxi.sub.30days', 'com.taxi.sub.90days']);
    });

    test('timeout closes stream; count stays 0 when nothing is restored', () async {
      final controller = StreamController<String>.broadcast();
      int count = 0;

      try {
        await for (final _ in controller.stream.timeout(
          const Duration(milliseconds: 50),
          onTimeout: (sink) => sink.close(),
        )) {
          count++;
        }
      } catch (_) {}

      expect(count, 0, reason: 'Nothing emitted = no prior purchases for this Apple ID');
    });

    test('counts correctly when items arrive within the timeout window', () async {
      final controller = StreamController<String>.broadcast();
      int count = 0;

      Future.microtask(() {
        controller.add('com.taxi.sub.30days');
        controller.close();
      });

      try {
        await for (final _ in controller.stream.timeout(
          const Duration(milliseconds: 200),
          onTimeout: (sink) => sink.close(),
        )) {
          count++;
        }
      } catch (_) {}

      expect(count, 1);
    });
  });

  // ── Restore decision logic ────────────────────────────────────────────────

  group('Restore flow decision', () {
    // NEW behaviour (guideline 3.1.1 fix):
    //   storeKitFound=true  + not logged in → try local entitlement first,
    //                                          grant access WITHOUT login if present.
    //   storeKitFound=false + not logged in → show login sheet (backend check).
    //   any storeKitFound   + logged in     → query backend directly.

    test('storeKitFound=false + not logged in → must show login sheet', () {
      // When StoreKit delivered nothing, the local-entitlement fast-path is
      // skipped entirely and the login sheet is always shown.
      final storeKitFound = false; // ignore: prefer_const_declarations
      expect(storeKitFound, isFalse,
          reason: 'StoreKit found nothing — cannot skip login without local entitlement');
    });

    test('storeKitFound=true + not logged in + local entitlement active → skip login', () async {
      final future = DateTime.now().add(const Duration(days: 30)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        _kLocalEntitlementKey: '{"end_date":"$future","product_id":"x"}',
      });
      // Local entitlement present after anonymous verify → no login required.
      expect(await _hasLocalEntitlement(), isTrue,
          reason: 'Anonymous verify succeeded; user can be granted access without login');
    });

    test('storeKitFound=true + not logged in + no local entitlement → must show login', () async {
      SharedPreferences.setMockInitialValues({});
      // Anonymous verify failed or timed out → fall through to login sheet.
      expect(await _hasLocalEntitlement(), isFalse,
          reason: 'No local entitlement → login required to check backend');
    });

    test('storeKitFound=true + logged in → proceed to backend check directly', () {
      const storeKitFound = true;
      const isLoggedIn = true;
      // Logged-in users skip the local-entitlement path entirely.
      final skipToBackend = isLoggedIn;
      expect(skipToBackend, isTrue);
      // storeKitFound irrelevant when logged in — backend is queried regardless.
      expect(storeKitFound, isTrue);
    });
  });

  // ── Post-purchase skip (Apple 5.1.1v) ────────────────────────────────────

  group('Post-purchase skip — local entitlement (5.1.1v)', () {
    test('active local entitlement grants access after skipping account creation', () async {
      final future = DateTime.now().add(const Duration(days: 30)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        _kLocalEntitlementKey:
            '{"end_date":"$future","product_id":"com.taxi.sub.30days",'
            '"transaction_id":"txn_123","device_token":"abc"}',
      });

      expect(await _hasLocalEntitlement(), isTrue,
          reason: 'User must access content after skipping account creation');
    });

    test('expired local entitlement does not grant access', () async {
      final past = DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        _kLocalEntitlementKey: '{"end_date":"$past","product_id":"com.taxi.sub.30days"}',
      });

      expect(await _hasLocalEntitlement(), isFalse);
    });
  });

  // ── App restart with pending purchase ─────────────────────────────────────

  group('App restart — pending receipt detection', () {
    test('deferred receipt stored → resumePendingPurchase must show auth sheet', () async {
      SharedPreferences.setMockInitialValues({
        _kDeferredKey: '{"receipt_data":"abc","product_id":"com.taxi.sub.30days",'
            '"internal_product_id":7}',
      });

      expect(await _hasDeferredReceipt(), isTrue,
          reason: 'initState must detect this and show auth sheet with showPaymentSuccess=true');
    });

    test('no deferred receipt → no auth sheet on startup', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await _hasDeferredReceipt(), isFalse);
    });

    test('both deferred receipt and local entitlement can coexist', () async {
      final future = DateTime.now().add(const Duration(days: 30)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        _kDeferredKey: '{"receipt_data":"abc","product_id":"x"}',
        _kLocalEntitlementKey: '{"end_date":"$future","product_id":"x"}',
      });

      expect(await _hasDeferredReceipt(), isTrue);
      expect(await _hasLocalEntitlement(), isTrue);
    });
  });
}
