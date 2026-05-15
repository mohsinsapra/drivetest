import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/config/stripe_config.dart';

void main() {
  group('defaultStripePublishableKeyForMode', () {
    test('returns test key for debug builds', () {
      expect(
        defaultStripePublishableKeyForMode(isReleaseMode: false),
        startsWith('pk_test_'),
      );
    });

    test('returns live key for release builds', () {
      expect(
        defaultStripePublishableKeyForMode(isReleaseMode: true),
        startsWith('pk_live_'),
      );
    });
  });

  group('resolveStripePublishableKey', () {
    test('prefers dart-define over dotenv and fallback', () {
      final key = resolveStripePublishableKey(
        defineValue: 'pk_define',
        dotenvValue: 'pk_env',
        fallbackValue: 'pk_fallback',
      );

      expect(key, 'pk_define');
    });

    test('falls back to dotenv when dart-define is empty', () {
      final key = resolveStripePublishableKey(
        defineValue: '   ',
        dotenvValue: 'pk_env',
        fallbackValue: 'pk_fallback',
      );

      expect(key, 'pk_env');
    });

    test('falls back to provided default when other sources are empty', () {
      final key = resolveStripePublishableKey(
        defineValue: '',
        dotenvValue: ' ',
        fallbackValue: 'pk_fallback',
      );

      expect(key, 'pk_fallback');
    });
  });

  group('initializeStripe', () {
    test('assigns the resolved key and applies settings', () async {
      String? assignedKey;
      var applyCalls = 0;

      final configured = await initializeStripe(
        defineValue: '',
        dotenvValue: 'pk_env',
        isReleaseMode: true,
        assignPublishableKey: (key) => assignedKey = key,
        applySettings: () async {
          applyCalls += 1;
        },
      );

      expect(configured, isTrue);
      expect(assignedKey, 'pk_env');
      expect(applyCalls, 1);
    });

    test('can skip applying settings during bootstrap on native platforms',
        () async {
      String? assignedKey;
      var applyCalls = 0;

      final configured = await initializeStripe(
        defineValue: '',
        dotenvValue: 'pk_env',
        isReleaseMode: true,
        assignPublishableKey: (key) => assignedKey = key,
        applySettings: () async {
          applyCalls += 1;
        },
        shouldApplySettings: false,
      );

      expect(configured, isTrue);
      expect(assignedKey, 'pk_env');
      expect(applyCalls, 0);
    });

    test('uses mode-based test fallback when no key source is available',
        () async {
      String? assignedKey;

      await initializeStripe(
        defineValue: '',
        dotenvValue: null,
        isReleaseMode: false,
        assignPublishableKey: (key) => assignedKey = key,
        applySettings: () async {},
      );

      expect(assignedKey, startsWith('pk_test_'));
    });
  });

  group('readStripePublishableKeySafely', () {
    test('returns env value when available', () {
      final value = readStripePublishableKeySafely(
        () => {'STRIPE_PUBLISHABLE_KEY': 'pk_env'},
      );

      expect(value, 'pk_env');
    });

    test('returns null when env access throws', () {
      final value = readStripePublishableKeySafely(
        () => throw StateError('not initialized'),
      );

      expect(value, isNull);
    });
  });
}
