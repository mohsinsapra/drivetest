import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:clarity_web/clarity_web.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Single entry point for all product analytics.
///
/// Events are sent to **Firebase Analytics (GA4)** — funnels, retention and
/// feature-adoption reports live in the GA4 console, with free BigQuery export
/// for deeper analysis. User identity is fanned out to Firebase, Clarity
/// (session replay) and Sentry (errors) via [identifyUser] so a single user can
/// be traced across the whole pipeline. See callers for the event taxonomy.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // `late` so constructing the singleton never touches Firebase: on web,
  // DioClient.init() runs in parallel with Firebase.initializeApp() and can
  // construct this service first — FirebaseAnalytics.instance would then throw
  // outside any try/catch. A throwing `late` initializer re-runs on next read.
  late final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Waits (max ~10s) for Firebase.initializeApp() to complete, for callers
  /// that can fire during app bootstrap before Firebase is ready.
  Future<bool> _firebaseReady() async {
    for (var i = 0; i < 40; i++) {
      try {
        if (Firebase.apps.isNotEmpty) return true;
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return false;
  }

  FirebaseAnalytics get analytics => _analytics;
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ───────────────────────────── core dispatch ─────────────────────────────

  /// Strips nulls and stamps an ISO timestamp. Firebase accepts
  /// `Map<String, Object>` (String / num / bool values).
  Map<String, Object> _props([Map<String, Object?> extra = const {}]) {
    final out = <String, Object>{
      'timestamp': DateTime.now().toIso8601String(),
    };
    extra.forEach((k, v) {
      if (v != null) out[k] = v;
    });
    return out;
  }

  /// Sends one event to Firebase. Never throws — analytics must never break
  /// the app.
  Future<void> _log(String name,
      [Map<String, Object?> params = const {}]) async {
    try {
      await _analytics.logEvent(name: name, parameters: _props(params));
    } catch (e) {
      if (kDebugMode) debugPrint('Firebase logEvent failed ($name): $e');
    }
  }

  // ───────────────────────────── identity glue ─────────────────────────────

  /// Sets the SAME user id across Firebase, Clarity and Sentry so a single user
  /// can be traced across every tool in the analytics pipeline. Call right after
  /// login or session restore.
  Future<void> identifyUser({
    required String userId,
    Map<String, Object>? properties,
  }) async {
    // Firebase — identifyUser is called from DioClient.init() during startup,
    // which races Firebase.initializeApp(); wait for it so the id isn't lost.
    try {
      if (!await _firebaseReady()) {
        throw StateError('Firebase not initialized');
      }
      await _analytics.setUserId(id: userId);
      if (properties != null) {
        for (final entry in properties.entries) {
          await _analytics.setUserProperty(
            name: entry.key,
            value: entry.value.toString(),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Firebase identify failed: $e');
    }

    // Clarity (session replay) — ties replays to this user.
    try {
      if (kIsWeb) {
        ClarityWeb.instance.setCustomUserId(userId);
      } else {
        Clarity.setCustomUserId(userId);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Clarity setCustomUserId failed: $e');
    }

    // Sentry (errors) — attaches user to crash reports.
    try {
      await Sentry.configureScope(
        (scope) => scope.setUser(SentryUser(id: userId)),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Sentry setUser failed: $e');
    }
  }

  /// Clear identity on logout so the next user is not attributed to this one.
  Future<void> clearUser() async {
    try {
      await _analytics.setUserId(id: null);
    } catch (_) {}
    try {
      await Sentry.configureScope((scope) => scope.setUser(null));
    } catch (_) {}
  }

  /// Set a single user property (Firebase).
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (_) {}
  }

  /// Set user ID only (Firebase) — kept for backward compatibility.
  /// Prefer [identifyUser] which fans out to all tools.
  Future<void> setUserId(String userId) => identifyUser(userId: userId);

  // ════════════════════════════ LEARNING LOOP ════════════════════════════
  // The core product loop — previously untracked. Highest-value funnel.

  /// User started an exam/test attempt.
  Future<void> logExamStarted({
    required String licenceId,
    String? licenceName,
    String? categoryId,
    required int questionCount,
    required bool isTimed,
    required bool isInstantMarking,
    bool? includesSaved,
  }) =>
      _log('exam_started', {
        'licence_id': licenceId,
        'licence_name': licenceName,
        'category_id': categoryId,
        'question_count': questionCount,
        'mode': isTimed ? 'timed' : 'practice',
        'instant_marking': isInstantMarking,
        'includes_saved': includesSaved,
      });

  /// A single question was answered. `timeSpentMs` is optional.
  Future<void> logQuestionAnswered({
    required String questionId,
    required bool correct,
    required int questionIndex,
    int? timeSpentMs,
    bool? usedHint,
    bool? usedAi,
  }) =>
      _log('exam_question_answered', {
        'question_id': questionId,
        'correct': correct,
        'question_index': questionIndex,
        'time_spent_ms': timeSpentMs,
        'used_hint': usedHint,
        'used_ai': usedAi,
      });

  /// User finished an exam (submitted or timer expired).
  Future<void> logExamCompleted({
    required String licenceId,
    String? categoryId,
    required double scorePercent,
    required bool passed,
    required int questionsAnswered,
    required int totalQuestions,
    int? durationMs,
    required String trigger, // 'submit' | 'timer_expired' | 'last_question'
  }) =>
      _log('exam_completed', {
        'licence_id': licenceId,
        'category_id': categoryId,
        'score_pct': scorePercent,
        'passed': passed,
        'questions_answered': questionsAnswered,
        'total_questions': totalQuestions,
        'duration_ms': durationMs,
        'trigger': trigger,
      });

  /// User left an exam before completing it — your single most actionable event.
  Future<void> logExamAbandoned({
    required String licenceId,
    String? categoryId,
    required int lastQuestionIndex,
    required int questionsAnswered,
    required int totalQuestions,
  }) =>
      _log('exam_abandoned', {
        'licence_id': licenceId,
        'category_id': categoryId,
        'last_question_index': lastQuestionIndex,
        'questions_answered': questionsAnswered,
        'total_questions': totalQuestions,
      });

  /// Result screen viewed.
  Future<void> logResultViewed({
    required bool passed,
    required double scorePercent,
  }) =>
      _log('result_viewed', {
        'passed': passed,
        'score_pct': scorePercent,
      });

  Future<void> logQuestionSaved(
          {required String questionId, required bool saved}) =>
      _log(saved ? 'question_saved' : 'question_unsaved', {
        'question_id': questionId,
      });

  // ════════════════════════ ENGAGEMENT / RETENTION ═══════════════════════

  Future<void> logSmartJourneyOpened() => _log('smart_journey_opened');

  Future<void> logSmartJourneyNodeCompleted({String? nodeId}) =>
      _log('smart_journey_node_completed', {'node_id': nodeId});

  Future<void> logSmartLearningStarted() =>
      _log('smart_learning_session_started');

  Future<void> logSmartLearningCompleted() =>
      _log('smart_learning_session_completed');

  Future<void> logPaywallShown({required String source, int? productId}) =>
      _log('paywall_shown', {
        'source': source,
        'product_id': productId,
      });

  Future<void> logStreakViewed({int? currentStreak}) =>
      _log('streak_viewed', {'current_streak': currentStreak});

  Future<void> logStreakMilestone({required int days}) =>
      _log('streak_milestone_reached', {'days': days});

  Future<void> logDashboardViewed({bool? hasExamHistory}) =>
      _log('dashboard_viewed', {'has_exam_history': hasExamHistory});

  /// User opened their personal stats screen. `attemptCount` tells whether the
  /// screen had data — a strong signal for whether to invest in user analytics.
  Future<void> logStatsViewed({bool? hasHistory, int? attemptCount}) =>
      _log('stats_viewed', {
        'has_history': hasHistory,
        'attempt_count': attemptCount,
      });

  /// User expanded a per-test breakdown card on the stats screen.
  Future<void> logStatsBreakdownExpanded({String? category}) =>
      _log('stats_breakdown_expanded', {'category': category});

  Future<void> logAiChatOpened({required String context}) =>
      _log('ai_chat_opened', {'context': context});

  Future<void> logAiMessageSent({String? context}) =>
      _log('ai_message_sent', {'context': context});

  // ═══════════════════════════ LIFECYCLE / ACTIVATION ═════════════════════

  Future<void> logOnboardingStepViewed({required int step}) =>
      _log('onboarding_step_viewed', {'step': step});

  Future<void> logOnboardingCompleted() => _log('onboarding_completed');

  Future<void> logSignupCompleted({required String method}) =>
      _log('signup_completed', {'method': method});

  Future<void> logLogin({required String method}) =>
      _log('login', {'method': method});

  Future<void> logNotificationOpened({String? type}) =>
      _log('notification_opened', {'type': type});

  Future<void> logReviewPromptShown() => _log('app_review_prompt_shown');

  // ════════════════════════════ PURCHASE FUNNEL ═══════════════════════════
  // Existing events — now also funnel through _log for consistency.

  Future<void> logPurchaseAttempt({
    required String licenceId,
    required String licenceName,
    required String categoryId,
    required String categoryName,
    required double amount,
    required String currency,
  }) =>
      _log('purchase_attempt', {
        'licence_id': licenceId,
        'licence_name': licenceName,
        'category_id': categoryId,
        'category_name': categoryName,
        'value': amount,
        'currency': currency,
      });

  Future<void> logBuyNowClick({
    required String licenceId,
    required String licenceName,
    required String categoryId,
    required String categoryName,
  }) =>
      _log('buy_now_clicked', {
        'licence_id': licenceId,
        'licence_name': licenceName,
        'category_id': categoryId,
        'category_name': categoryName,
      });

  Future<void> logPaymentMethodSheetOpened({
    required String licenceId,
    required String categoryId,
  }) =>
      _log('payment_method_sheet_opened', {
        'licence_id': licenceId,
        'category_id': categoryId,
      });

  Future<void> logPaymentMethodSelected({
    required String paymentMethod,
    required String licenceId,
    required String categoryId,
  }) =>
      _log('payment_method_selected', {
        'payment_method': paymentMethod,
        'licence_id': licenceId,
        'category_id': categoryId,
      });

  Future<void> logPurchaseSuccess({
    required String licenceId,
    required String licenceName,
    required String categoryId,
    required String categoryName,
    required double amount,
    required String currency,
    required String transactionId,
  }) async {
    // Firebase's standard purchase event for revenue reporting.
    try {
      await _analytics.logPurchase(
        value: amount,
        currency: currency,
        items: [
          AnalyticsEventItem(
            itemId: categoryId,
            itemName: categoryName,
            itemCategory: licenceName,
            price: amount,
            quantity: 1,
          ),
        ],
      );
    } catch (_) {}

    await _log('subscription_purchased', {
      'licence_id': licenceId,
      'licence_name': licenceName,
      'category_id': categoryId,
      'category_name': categoryName,
      'value': amount,
      'currency': currency,
      'transaction_id': transactionId,
    });
  }

  Future<void> logPurchaseFailure({
    required String licenceId,
    required String categoryId,
    required String errorMessage,
  }) =>
      _log('purchase_failed', {
        'licence_id': licenceId,
        'category_id': categoryId,
        'error_message': errorMessage,
      });

  Future<void> logPurchaseCancelled({
    required String licenceId,
    required String categoryId,
  }) =>
      _log('purchase_cancelled', {
        'licence_id': licenceId,
        'category_id': categoryId,
      });

  Future<void> logSubscriptionDialogShown({
    required String licenceId,
    required String categoryId,
    required String categoryName,
  }) =>
      _log('subscription_dialog_shown', {
        'licence_id': licenceId,
        'category_id': categoryId,
        'category_name': categoryName,
      });
}
