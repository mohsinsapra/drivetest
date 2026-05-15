const defaultLiveStripePublishableKey =
    'pk_live_51QSEQxLdbibfvPzFVwe3hE5seqcH1wQigVXOW60o9KWurHg8ewRFtpekd0c4R16UaiAa51mDZ3MDJFCmIzIRX56i00rZyQBtdD';
const defaultTestStripePublishableKey =
    'pk_test_51QSEQxLdbibfvPzFsFCUaB7Lbx9FEHNaACw6AfAVV7XW7I4b5bsOPUbFWi82S9rTwgvBMHr6cCYp0GlSW6mKSLaK00Q36N90tZ';

String defaultStripePublishableKeyForMode({required bool isReleaseMode}) {
  return isReleaseMode
      ? defaultLiveStripePublishableKey
      : defaultTestStripePublishableKey;
}

String? readStripePublishableKeySafely(Map<String, String> Function() readEnv) {
  try {
    return readEnv()['STRIPE_PUBLISHABLE_KEY'];
  } catch (_) {
    return null;
  }
}

String resolveStripePublishableKey({
  required String defineValue,
  String? dotenvValue,
  String fallbackValue = defaultLiveStripePublishableKey,
}) {
  final normalizedDefine = defineValue.trim();
  if (normalizedDefine.isNotEmpty) return normalizedDefine;

  final normalizedEnv = (dotenvValue ?? '').trim();
  if (normalizedEnv.isNotEmpty) return normalizedEnv;

  return fallbackValue.trim();
}

Future<bool> initializeStripe({
  required String defineValue,
  String? dotenvValue,
  required bool isReleaseMode,
  String? fallbackValue,
  required void Function(String key) assignPublishableKey,
  required Future<void> Function() applySettings,
  bool shouldApplySettings = true,
  void Function(String message)? log,
}) async {
  final key = resolveStripePublishableKey(
    defineValue: defineValue,
    dotenvValue: dotenvValue,
    fallbackValue: fallbackValue ??
        defaultStripePublishableKeyForMode(isReleaseMode: isReleaseMode),
  );

  if (key.isEmpty) {
    log?.call('Stripe publishable key is missing; payment setup skipped.');
    return false;
  }

  assignPublishableKey(key);
  if (shouldApplySettings) {
    await applySettings();
  }
  return true;
}
