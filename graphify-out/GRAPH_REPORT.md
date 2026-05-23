# Graph Report - taxi_exam_app  (2026-05-23)

## Corpus Check
- 198 files · ~177,284 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1899 nodes · 2572 edges · 45 communities detected
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 34 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 114 edges
2. `package:taxi_exam_app/core/localization/strings.g.dart` - 65 edges
3. `package:flutter/foundation.dart` - 40 edges
4. `package:shared_preferences/shared_preferences.dart` - 30 edges
5. `package:taxi_exam_app/core/utils/app_page_route.dart` - 27 edges
6. `package:taxi_exam_app/core/api/api_service.dart` - 26 edges
7. `package:taxi_exam_app/core/widgets/app_button.dart` - 23 edges
8. `package:google_fonts/google_fonts.dart` - 23 edges
9. `package:flutter_test/flutter_test.dart` - 22 edges
10. `package:taxi_exam_app/core/models/test_attempt.dart` - 21 edges

## Surprising Connections (you probably didn't know these)
- `Category Detail Screen - Säkerhet (Safety)` --brand_identity_of--> `TaxiQuiz App Icon - D Letter Road Motif`  [INFERRED]
  flutter_01.png → assets/icon/icon.png
- `main()` --calls--> `Path`  [INFERRED]
  scripts/generate_missing_bcd_images_with_gemini_cli.py → lib/features/tests/licences_screen.dart
- `main()` --calls--> `Path`  [INFERRED]
  scripts/extract_missing_bcd_images.py → lib/features/tests/licences_screen.dart
- `Web Favicon (PNG)` --belongs_to--> `PWA Web Assets Group`  [INFERRED]
  web/favicon.png → web/icons/Icon-192.png
- `Google Pay Payment Icon` --conceptually_related_to--> `Apple Pay Payment Icon`  [INFERRED]
  assets/icon/google_pay.png → assets/icon/apple_pay.png

## Communities

### Community 0 - "Community 0"
Cohesion: 0.02
Nodes (106): app_lottie_web.dart, dart:io, package:auto_size_text/auto_size_text.dart, package:dio/io.dart, package:flutter/cupertino.dart, package:flutter_dotenv/flutter_dotenv.dart, package:flutter/foundation.dart, package:flutter/gestures.dart (+98 more)

### Community 1 - "Community 1"
Cohesion: 0.02
Nodes (108): core/models/test_attempt.dart, dashboard_repository.dart, package:clarity_flutter/clarity_flutter.dart, package:clarity_web/clarity_web.dart, package:hive_flutter/hive_flutter.dart, package:provider/provider.dart, package:taxi_exam_app/core/api/dio_client.dart, package:taxi_exam_app/core/config/stripe_config.dart (+100 more)

### Community 2 - "Community 2"
Cohesion: 0.02
Nodes (96): all_attempts_sheet.dart, batch_attempt_history.dart, batch_row.dart, exam_nav_helpers.dart, ../helpers/dashboard_helpers.dart, ../models/dashboard_stats.dart, package:taxi_exam_app/core/localization/strings.g.dart, package:taxi_exam_app/features/bcd/bcd_test_screen.dart (+88 more)

### Community 3 - "Community 3"
Cohesion: 0.02
Nodes (78): dart:js_interop, dart:ui_web, package:flutter/material.dart, package:photo_view/photo_view.dart, package:web/web.dart, tts_button.dart, BoxDecoration, build (+70 more)

### Community 4 - "Community 4"
Cohesion: 0.02
Nodes (87): bcd_document_viewer_screen.dart, bcd_licences_screen.dart, bcd_subscriptions_screen.dart, bcd_test_screen.dart, bcd_traffic_signs_screen.dart, package:lucide_icons/lucide_icons.dart, package:taxi_exam_app/core/constants/app_text_styles.dart, package:taxi_exam_app/core/services/tts_service.dart (+79 more)

### Community 5 - "Community 5"
Cohesion: 0.02
Nodes (84): package:firebase_core/firebase_core.dart, package:firebase_messaging/firebase_messaging.dart, package:syncfusion_flutter_pdfviewer/pdfviewer.dart, package:taxi_exam_app/core/utils/web_redirect.dart, package:taxi_exam_app/core/widgets/app_back_button.dart, package:taxi_exam_app/core/widgets/app_button.dart, package:taxi_exam_app/core/widgets/app_loading_indicator.dart, package:taxi_exam_app/core/widgets/snackbar.dart (+76 more)

### Community 6 - "Community 6"
Cohesion: 0.03
Nodes (71): certificate_pinning_stub.dart, dart:convert, dio_client.dart, package:dio_cache_interceptor/dio_cache_interceptor.dart, package:dio/dio.dart, package:encrypt/encrypt.dart, package:flutter_secure_storage/flutter_secure_storage.dart, package:sentry_dio/sentry_dio.dart (+63 more)

### Community 7 - "Community 7"
Cohesion: 0.03
Nodes (71): package:flutter_test/flutter_test.dart, package:taxi_exam_app/core/services/navigation_feedback.dart, package:taxi_exam_app/core/services/notification_service.dart, package:taxi_exam_app/core/utils/platform_detector.dart, package:taxi_exam_app/core/widgets/app_download_sheet.dart, package:taxi_exam_app/features/bcd/bcd_document_viewer_screen.dart, package:taxi_exam_app/features/bcd/bcd_screen.dart, package:taxi_exam_app/features/consent/gdpr_consent_sheet.dart (+63 more)

### Community 8 - "Community 8"
Cohesion: 0.03
Nodes (68): package:shared_preferences/shared_preferences.dart, package:taxi_exam_app/core/providers/font_provider.dart, package:taxi_exam_app/core/providers/theme_provider.dart, package:taxi_exam_app/core/services/streak_notification_service.dart, package:taxi_exam_app/core/services/version_service.dart, package:taxi_exam_app/features/streak/streak_settings_provider.dart, FontProvider, _resolve (+60 more)

### Community 9 - "Community 9"
Cohesion: 0.03
Nodes (72): package:flutter_tts/flutter_tts.dart, package:no_screenshot/no_screenshot.dart, package:taxi_exam_app/core/constants/language_options.dart, package:taxi_exam_app/core/models/image_viewer.dart, package:taxi_exam_app/core/widgets/explanation_widget.dart, package:taxi_exam_app/core/widgets/navigation_controls.dart, package:taxi_exam_app/core/widgets/option_tile.dart, package:taxi_exam_app/core/widgets/question_progress_header.dart (+64 more)

### Community 10 - "Community 10"
Cohesion: 0.03
Nodes (70): bcd_category_hub_screen.dart, bcd_sub_category_screen.dart, mini_bar_chart.dart, package:shimmer/shimmer.dart, package:taxi_exam_app/core/utils/category_sort_utils.dart, package:taxi_exam_app/core/widgets/adaptive_refresh_indicator.dart, _AccessBadge, ApiService (+62 more)

### Community 11 - "Community 11"
Cohesion: 0.03
Nodes (68): package:font_awesome_flutter/font_awesome_flutter.dart, package:taxi_exam_app/core/auth/apple_sign_in_helper.dart, package:taxi_exam_app/core/auth/google_sign_in_helper.dart, package:taxi_exam_app/features/auth/debug_credentials.dart, package:taxi_exam_app/features/auth/forgot_password_screen.dart, AppButton, AppDangerButton, AppFilledButton (+60 more)

### Community 12 - "Community 12"
Cohesion: 0.03
Nodes (63): exam_node.dart, package:hive/hive.dart, package:taxi_exam_app/core/utils/calculate_stats.dart, package:taxi_exam_app/core/widgets/attempt_spark_widget.dart, package:taxi_exam_app/core/widgets/category_pie_chart_widget.dart, package:taxi_exam_app/features/home/attempt_detail_screen.dart, subscribed_exam.dart, LocalNotification (+55 more)

### Community 13 - "Community 13"
Cohesion: 0.03
Nodes (62): package:confetti/confetti.dart, package:taxi_exam_app/core/models/test_attempt.dart, package:taxi_exam_app/core/services/analytics_service.dart, package:taxi_exam_app/core/widgets/category_card_widget.dart, package:taxi_exam_app/core/widgets/licence_type_card_widget.dart, package:taxi_exam_app/core/widgets/test_option_card_widget.dart, package:taxi_exam_app/features/tests/custom_test_screen.dart, package:taxi_exam_app/features/tests/saved_questions_preview_screen.dart (+54 more)

### Community 14 - "Community 14"
Cohesion: 0.03
Nodes (65): package:collection/collection.dart, package:taxi_exam_app/features/auth/auth_bottom_sheet.dart, package:taxi_exam_app/features/bcd/bcd_category_hub_screen.dart, package:taxi_exam_app/features/bcd/bcd_licences_screen.dart, package:taxi_exam_app/features/bcd/bcd_sub_category_screen.dart, package:taxi_exam_app/features/payment/subscription_plan_card.dart, build, Color (+57 more)

### Community 15 - "Community 15"
Cohesion: 0.03
Nodes (61): dart:math, dart:typed_data, package:archive/archive.dart, package:flutter_local_notifications/flutter_local_notifications.dart, package:flutter_timezone/flutter_timezone.dart, package:pointycastle/export.dart, package:timezone/data/latest_all.dart, package:timezone/timezone.dart (+53 more)

### Community 16 - "Community 16"
Cohesion: 0.03
Nodes (59): exam_card.dart, free_bcd_hub_card.dart, free_vagmarkes_card.dart, package:google_fonts/google_fonts.dart, package:taxi_exam_app/features/bcd/bcd_traffic_signs_screen.dart, performance_insight_card.dart, performance_metric_card.dart, period_dropdown.dart (+51 more)

### Community 17 - "Community 17"
Cohesion: 0.04
Nodes (50): bcd_text_utils.dart, dart:async, package:in_app_purchase/in_app_purchase.dart, package:taxi_exam_app/core/api/api_service.dart, package:taxi_exam_app/core/services/session_validation_service.dart, _applyDashboard, BcdCache, _fetchAll (+42 more)

### Community 18 - "Community 18"
Cohesion: 0.04
Nodes (47): ../models/exam_node.dart, ../models/subscribed_exam.dart, package:cached_network_image/cached_network_image.dart, package:taxi_exam_app/core/services/bcd_cache.dart, _AttemptsIndex, BatchStats, _batchStatsFromAttempts, _batchStatsIndexed (+39 more)

### Community 19 - "Community 19"
Cohesion: 0.04
Nodes (46): category_list_item.dart, exam_carousel_section.dart, hero_section.dart, package:taxi_exam_app/core/utils/category_icon_mapper.dart, performance_overview_section.dart, AdaptiveRefreshIndicator, build, _buildCategorySlivers (+38 more)

### Community 20 - "Community 20"
Cohesion: 0.05
Nodes (39): package:taxi_exam_app/core/models/purchase_receipt.dart, package:taxi_exam_app/features/payment/receipt_screen.dart, build, Card, Container, _divider, _durationLabel, initState (+31 more)

### Community 21 - "Community 21"
Cohesion: 0.05
Nodes (36): ../../features/tests/result_screen.dart, ../models/question.dart, package:expandable/expandable.dart, package:introduction_screen/introduction_screen.dart, package:taxi_exam_app/core/utils/app_page_route.dart, package:taxi_exam_app/core/widgets/app_lottie.dart, package:taxi_exam_app/features/auth/reset_password_screen.dart, build (+28 more)

### Community 22 - "Community 22"
Cohesion: 0.06
Nodes (30): package:flutter/widgets.dart, package:intl/intl.dart, package:slang_flutter/slang_flutter.dart, package:slang/generated.dart, strings.g.dart, strings_sv.g.dart, AppLocale, AppLocaleUtils (+22 more)

### Community 23 - "Community 23"
Cohesion: 0.11
Nodes (20): build_image_prompt_spec(), build_report(), classify_scene_type(), fix_mojibake(), html_to_text(), infer_shot_guidance(), load_json(), main() (+12 more)

### Community 24 - "Community 24"
Cohesion: 0.08
Nodes (23): package:flutter_stripe/flutter_stripe.dart, package:flutter_stripe_web/flutter_stripe_web.dart, package:taxi_exam_app/core/services/iap_service.dart, package:taxi_exam_app/core/services/stripe_payment_service.dart, package:taxi_exam_app/features/payment/paywall_sheet.dart, package:taxi_exam_app/features/payment/subscription_success_overlay.dart, AlertDialog, Exception (+15 more)

### Community 25 - "Community 25"
Cohesion: 0.1
Nodes (19): ../services/navigation_service.dart, _addToVisible, build, _buildCard, _cleanupOverlay, Container, _dismissItem, dispose (+11 more)

### Community 26 - "Community 26"
Cohesion: 0.11
Nodes (17): package:fl_chart/fl_chart.dart, AttemptCountLineGraph, AxisTitles, build, LineTooltipItem, Padding, SideTitleWidget, TextStyle (+9 more)

### Community 27 - "Community 27"
Cohesion: 0.21
Nodes (5): VersionManager, ExamNode, ExamNodeAdapter, read, write

### Community 28 - "Community 28"
Cohesion: 0.36
Nodes (9): TaxiQuiz App Icon - D Letter Road Motif, Apple Pay Payment Icon, Create Custom Test Action, Category Detail Screen - Säkerhet (Safety), Google Pay Payment Icon, In-App Payment Feature, Säkerhet (Safety) Exam Category, Saved Questions Action (+1 more)

### Community 29 - "Community 29"
Cohesion: 0.47
Nodes (9): Brand Color: Dark Grey, Brand Color: Gold/Yellow, Brand D-Letter Logo (Dark Grey and Gold), PWA Web Assets Group, PWA Standard Icon 192x192, PWA Standard Icon 512x512, PWA Maskable Icon 192x192, PWA Maskable Icon 512x512 (+1 more)

### Community 30 - "Community 30"
Cohesion: 0.25
Nodes (5): dart:html, platform_detector.dart, detectWebPlatformImpl, detectWebPlatformImpl, performRedirect

### Community 31 - "Community 31"
Cohesion: 0.33
Nodes (5): applySettings, defaultStripePublishableKeyForMode, Function, readEnv, resolveStripePublishableKey

### Community 32 - "Community 32"
Cohesion: 0.4
Nodes (4): LocalNotification, LocalNotificationAdapter, read, write

### Community 33 - "Community 33"
Cohesion: 0.4
Nodes (4): Question, QuestionAdapter, read, write

### Community 34 - "Community 34"
Cohesion: 0.4
Nodes (4): read, TestAttempt, TestAttemptAdapter, write

### Community 35 - "Community 35"
Cohesion: 0.4
Nodes (4): Option, OptionAdapter, read, write

### Community 36 - "Community 36"
Cohesion: 0.4
Nodes (4): read, SubscribedExam, SubscribedExamAdapter, write

### Community 37 - "Community 37"
Cohesion: 0.5
Nodes (3): HomeDataCache, invalidate, markSynced

### Community 38 - "Community 38"
Cohesion: 0.5
Nodes (3): _flatMapFunction, of, Translations

### Community 39 - "Community 39"
Cohesion: 0.67
Nodes (2): redirectToUrl, web_redirect_stub.dart

### Community 40 - "Community 40"
Cohesion: 0.67
Nodes (2): platform_detector_stub.dart, detectWebPlatform

### Community 41 - "Community 41"
Cohesion: 0.67
Nodes (2): package:firebase_analytics/firebase_analytics.dart, AnalyticsService

### Community 42 - "Community 42"
Cohesion: 0.67
Nodes (2): webVibrate, webVibratePattern

### Community 43 - "Community 43"
Cohesion: 1.0
Nodes (1): performRedirect

### Community 44 - "Community 44"
Cohesion: 1.0
Nodes (1): hasResumableProgressChanges

## Knowledge Gaps
- **1531 isolated node(s):** `main`, `main`, `main`, `initializeStripe`, `main` (+1526 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 39`** (3 nodes): `web_redirect.dart`, `redirectToUrl`, `web_redirect_stub.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 40`** (3 nodes): `platform_detector.dart`, `platform_detector_stub.dart`, `detectWebPlatform`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 41`** (3 nodes): `analytics_service.dart`, `package:firebase_analytics/firebase_analytics.dart`, `AnalyticsService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 42`** (3 nodes): `platform_vibrate_native.dart`, `webVibrate`, `webVibratePattern`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 43`** (2 nodes): `web_redirect_stub.dart`, `performRedirect`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 44`** (2 nodes): `test_progress_guard.dart`, `hasResumableProgressChanges`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 3` to `Community 0`, `Community 1`, `Community 2`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 15`, `Community 16`, `Community 17`, `Community 18`, `Community 19`, `Community 20`, `Community 21`, `Community 24`, `Community 25`, `Community 26`?**
  _High betweenness centrality (0.385) - this node is a cross-community bridge._
- **Why does `package:taxi_exam_app/core/localization/strings.g.dart` connect `Community 2` to `Community 0`, `Community 1`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 15`, `Community 16`, `Community 17`, `Community 18`, `Community 19`, `Community 20`, `Community 21`, `Community 24`?**
  _High betweenness centrality (0.152) - this node is a cross-community bridge._
- **Why does `package:flutter/foundation.dart` connect `Community 0` to `Community 1`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 11`, `Community 12`, `Community 14`, `Community 15`, `Community 17`, `Community 24`?**
  _High betweenness centrality (0.064) - this node is a cross-community bridge._
- **What connects `main`, `main`, `main` to the rest of the system?**
  _1531 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._