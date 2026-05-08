# Graph Report - taxi_exam_app  (2026-05-08)

## Corpus Check
- 146 files · ~127,913 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1470 nodes · 1878 edges · 44 communities detected
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 22 edges (avg confidence: 0.86)
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

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 80 edges
2. `package:taxi_exam_app/core/localization/strings.g.dart` - 35 edges
3. `package:flutter/foundation.dart` - 30 edges
4. `package:shared_preferences/shared_preferences.dart` - 26 edges
5. `package:taxi_exam_app/core/utils/app_page_route.dart` - 23 edges
6. `package:taxi_exam_app/core/api/api_service.dart` - 22 edges
7. `package:taxi_exam_app/core/widgets/snackbar.dart` - 21 edges
8. `package:lucide_icons/lucide_icons.dart` - 15 edges
9. `package:taxi_exam_app/core/models/test_attempt.dart` - 14 edges
10. `package:flutter/services.dart` - 13 edges

## Surprising Connections (you probably didn't know these)
- `Category Detail Screen - Säkerhet (Safety)` --brand_identity_of--> `TaxiQuiz App Icon - D Letter Road Motif`  [INFERRED]
  flutter_01.png → assets/icon/icon.png
- `Web Favicon (PNG)` --belongs_to--> `PWA Web Assets Group`  [INFERRED]
  web/favicon.png → web/icons/Icon-192.png
- `Google Pay Payment Icon` --conceptually_related_to--> `Apple Pay Payment Icon`  [INFERRED]
  assets/icon/google_pay.png → assets/icon/apple_pay.png
- `Web Favicon (PNG)` --depicts--> `Brand D-Letter Logo (Dark Grey and Gold)`  [EXTRACTED]
  web/favicon.png → web/icons/Icon-512.png
- `PWA Standard Icon 192x192` --variant_of--> `PWA Maskable Icon 192x192`  [INFERRED]
  web/icons/Icon-192.png → web/icons/Icon-maskable-192.png

## Communities

### Community 0 - "Community 0"
Cohesion: 0.02
Nodes (78): package:flutter_tts/flutter_tts.dart, package:no_screenshot/no_screenshot.dart, package:taxi_exam_app/core/constants/language_options.dart, package:taxi_exam_app/core/models/image_viewer.dart, package:taxi_exam_app/core/services/tts_service.dart, package:taxi_exam_app/core/widgets/explanation_widget.dart, package:taxi_exam_app/core/widgets/navigation_controls.dart, package:taxi_exam_app/core/widgets/option_tile.dart (+70 more)

### Community 1 - "Community 1"
Cohesion: 0.03
Nodes (64): package:fl_chart/fl_chart.dart, package:flutter/material.dart, package:taxi_exam_app/features/auth/reset_password_screen.dart, tts_button.dart, NavigationService, AppPageRoute, buildWebLottie, AttemptGroupCard (+56 more)

### Community 2 - "Community 2"
Cohesion: 0.03
Nodes (66): core/models/test_attempt.dart, dashboard_repository.dart, package:clarity_flutter/clarity_flutter.dart, package:clarity_web/clarity_web.dart, package:firebase_core/firebase_core.dart, package:firebase_messaging/firebase_messaging.dart, package:hive_flutter/hive_flutter.dart, package:sentry_flutter/sentry_flutter.dart (+58 more)

### Community 3 - "Community 3"
Cohesion: 0.03
Nodes (68): ../../features/tests/result_screen.dart, package:taxi_exam_app/core/models/question.dart, package:taxi_exam_app/core/services/saved_questions_service.dart, package:taxi_exam_app/core/utils/app_page_route.dart, package:taxi_exam_app/features/bcd/providers/bcd_provider.dart, package:taxi_exam_app/features/tests/test_screen.dart, TestAttempt, showDialog (+60 more)

### Community 4 - "Community 4"
Cohesion: 0.03
Nodes (65): dart:io, package:auto_size_text/auto_size_text.dart, package:dio/io.dart, package:flutter_dotenv/flutter_dotenv.dart, package:flutter/services.dart, package:flutter_stripe/flutter_stripe.dart, package:flutter_stripe_web/flutter_stripe_web.dart, package:google_sign_in/google_sign_in.dart (+57 more)

### Community 5 - "Community 5"
Cohesion: 0.03
Nodes (63): exam_node.dart, package:hive/hive.dart, package:taxi_exam_app/core/utils/calculate_stats.dart, package:taxi_exam_app/core/widgets/attempt_spark_widget.dart, package:taxi_exam_app/core/widgets/category_pie_chart_widget.dart, package:taxi_exam_app/features/home/attempt_detail_screen.dart, subscribed_exam.dart, LocalNotification (+55 more)

### Community 6 - "Community 6"
Cohesion: 0.03
Nodes (58): package:introduction_screen/introduction_screen.dart, package:provider/provider.dart, package:shared_preferences/shared_preferences.dart, package:taxi_exam_app/core/services/streak_notification_service.dart, package:taxi_exam_app/core/widgets/app_lottie.dart, package:taxi_exam_app/features/streak/streak_settings_provider.dart, package:taxi_exam_app/features/streak/streak_settings_screen.dart, FontProvider (+50 more)

### Community 7 - "Community 7"
Cohesion: 0.03
Nodes (58): ../../helpers/dashboard_helpers.dart, ../models/dashboard_stats.dart, package:taxi_exam_app/core/localization/strings.g.dart, BatchProgressCard, build, Container, GestureDetector, _MiniStat (+50 more)

### Community 8 - "Community 8"
Cohesion: 0.04
Nodes (57): bcd_category_hub_screen.dart, bcd_sub_category_screen.dart, package:lucide_icons/lucide_icons.dart, package:shimmer/shimmer.dart, package:taxi_exam_app/core/services/payment_coordinator.dart, package:taxi_exam_app/core/utils/category_sort_utils.dart, build, CategoryCard (+49 more)

### Community 9 - "Community 9"
Cohesion: 0.03
Nodes (55): bcd_text_utils.dart, dart:async, ../models/question.dart, package:expandable/expandable.dart, package:in_app_purchase/in_app_purchase.dart, package:taxi_exam_app/core/api/api_service.dart, package:taxi_exam_app/core/services/session_validation_service.dart, _applyDashboard (+47 more)

### Community 10 - "Community 10"
Cohesion: 0.04
Nodes (53): app_lottie_web.dart, package:flutter/foundation.dart, package:flutter/gestures.dart, package:google_fonts/google_fonts.dart, package:lottie/lottie.dart, package:sign_in_with_apple/sign_in_with_apple.dart, package:url_launcher/url_launcher.dart, AppleSignInHelper (+45 more)

### Community 11 - "Community 11"
Cohesion: 0.04
Nodes (52): package:font_awesome_flutter/font_awesome_flutter.dart, package:taxi_exam_app/core/auth/apple_sign_in_helper.dart, package:taxi_exam_app/core/auth/google_sign_in_helper.dart, package:taxi_exam_app/features/auth/forgot_password_screen.dart, _AuthSheet, _AuthSheetState, build, Column (+44 more)

### Community 12 - "Community 12"
Cohesion: 0.04
Nodes (44): package:flutter_test/flutter_test.dart, package:taxi_exam_app/core/services/navigation_feedback.dart, package:taxi_exam_app/core/services/notification_service.dart, package:taxi_exam_app/core/services/stripe_payment_service.dart, package:taxi_exam_app/features/bcd/bcd_document_viewer_screen.dart, package:taxi_exam_app/features/bcd/bcd_screen.dart, package:taxi_exam_app/features/dashboard/screens/exam_dashboard_screen.dart, package:taxi_exam_app/features/home/home_screen.dart (+36 more)

### Community 13 - "Community 13"
Cohesion: 0.04
Nodes (44): ../models/exam_node.dart, ../models/subscribed_exam.dart, package:taxi_exam_app/core/services/bcd_cache.dart, ../repository/dashboard_repository.dart, ../repository/exam_sync_service.dart, BatchStats, CategoryStats, computeBatchStats (+36 more)

### Community 14 - "Community 14"
Cohesion: 0.04
Nodes (46): package:collection/collection.dart, package:taxi_exam_app/features/auth/auth_bottom_sheet.dart, package:taxi_exam_app/features/bcd/bcd_category_hub_screen.dart, package:taxi_exam_app/features/bcd/bcd_sub_category_screen.dart, AnimatedContainer, build, _BundleRow, _CategoryCard (+38 more)

### Community 15 - "Community 15"
Cohesion: 0.05
Nodes (38): certificate_pinning_stub.dart, dart:convert, dio_client.dart, package:dio_cache_interceptor/dio_cache_interceptor.dart, package:dio/dio.dart, package:flutter_secure_storage/flutter_secure_storage.dart, package:sentry_dio/sentry_dio.dart, package:taxi_exam_app/core/models/option.dart (+30 more)

### Community 16 - "Community 16"
Cohesion: 0.05
Nodes (41): bcd_document_viewer_screen.dart, bcd_licences_screen.dart, bcd_subscriptions_screen.dart, bcd_test_screen.dart, bcd_traffic_signs_screen.dart, ../tests/saved_questions_preview_screen.dart, BCDCategoryHubScreen, _BCDCategoryHubScreenState (+33 more)

### Community 17 - "Community 17"
Cohesion: 0.05
Nodes (41): package:taxi_exam_app/features/bcd/bcd_test_screen.dart, package:taxi_exam_app/features/notifications/notifications_screen.dart, ../providers/dashboard_provider.dart, AnimatedContainer, _BatchAttemptHistory, _BatchRow, _BatchRowState, build (+33 more)

### Community 18 - "Community 18"
Cohesion: 0.05
Nodes (38): dart:math, dart:typed_data, package:archive/archive.dart, package:flutter_local_notifications/flutter_local_notifications.dart, package:flutter_timezone/flutter_timezone.dart, package:pointycastle/export.dart, package:timezone/data/latest_all.dart, package:timezone/timezone.dart (+30 more)

### Community 19 - "Community 19"
Cohesion: 0.05
Nodes (35): package:flutter/widgets.dart, package:intl/intl.dart, package:package_info_plus/package_info_plus.dart, package:slang_flutter/slang_flutter.dart, package:slang/generated.dart, strings.g.dart, strings_sv.g.dart, AppLocale (+27 more)

### Community 20 - "Community 20"
Cohesion: 0.05
Nodes (36): package:confetti/confetti.dart, package:taxi_exam_app/core/services/analytics_service.dart, package:taxi_exam_app/core/widgets/category_card_widget.dart, package:taxi_exam_app/core/widgets/licence_type_card_widget.dart, package:taxi_exam_app/core/widgets/test_option_card_widget.dart, package:taxi_exam_app/features/tests/custom_test_screen.dart, package:taxi_exam_app/features/tests/saved_questions_preview_screen.dart, package:youtube_player_flutter/youtube_player_flutter.dart (+28 more)

### Community 21 - "Community 21"
Cohesion: 0.06
Nodes (33): package:taxi_exam_app/core/widgets/snackbar.dart, package:taxi_exam_app/features/profile/edit_profile_screen.dart, package:taxi_exam_app/features/profile/providers/profile_provider.dart, package:taxi_exam_app/features/profile/stats_screen.dart, package:taxi_exam_app/features/support/help_screen.dart, package:taxi_exam_app/settings/settings.dart, build, dispose (+25 more)

### Community 22 - "Community 22"
Cohesion: 0.06
Nodes (32): package:syncfusion_flutter_pdfviewer/pdfviewer.dart, package:taxi_exam_app/core/api/dio_client.dart, package:taxi_exam_app/features/consent/gdpr_consent_sheet.dart, package:taxi_exam_app/features/onboarding/onboarding_screen.dart, BCDDocumentViewerScreen, _BCDDocumentViewerScreenState, build, Center (+24 more)

### Community 23 - "Community 23"
Cohesion: 0.06
Nodes (28): package:taxi_exam_app/core/models/test_attempt.dart, AttemptEntryCard, build, Container, SizedBox, build, Container, ProgressCard (+20 more)

### Community 24 - "Community 24"
Cohesion: 0.08
Nodes (23): package:taxi_exam_app/core/providers/font_provider.dart, package:taxi_exam_app/core/providers/theme_provider.dart, package:taxi_exam_app/core/services/version_service.dart, build, Center, DateFormat, didChangeAppLifecycleState, dispose (+15 more)

### Community 25 - "Community 25"
Cohesion: 0.11
Nodes (16): package:taxi_exam_app/features/bcd/bcd_text_utils.dart, BcdProvider, mediaUrl, Option, Question, _toQuestion, build, Container (+8 more)

### Community 26 - "Community 26"
Cohesion: 0.21
Nodes (5): VersionManager, ExamNode, ExamNodeAdapter, read, write

### Community 27 - "Community 27"
Cohesion: 0.14
Nodes (13): package:photo_view/photo_view.dart, BoxDecoration, build, dispose, Icon, _ImageViewerPage, _ImageViewerPageState, initState (+5 more)

### Community 28 - "Community 28"
Cohesion: 0.22
Nodes (7): dart:js_interop, dart:ui_web, package:web/web.dart, webVibrate, webVibratePattern, buildWebLottie, SizedBox

### Community 29 - "Community 29"
Cohesion: 0.36
Nodes (9): TaxiQuiz App Icon - D Letter Road Motif, Apple Pay Payment Icon, Create Custom Test Action, Category Detail Screen - Säkerhet (Safety), Google Pay Payment Icon, In-App Payment Feature, Säkerhet (Safety) Exam Category, Saved Questions Action (+1 more)

### Community 30 - "Community 30"
Cohesion: 0.47
Nodes (9): Brand Color: Dark Grey, Brand Color: Gold/Yellow, Brand D-Letter Logo (Dark Grey and Gold), PWA Web Assets Group, PWA Standard Icon 192x192, PWA Standard Icon 512x512, PWA Maskable Icon 192x192, PWA Maskable Icon 512x512 (+1 more)

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
Nodes (2): dart:html, performRedirect

### Community 40 - "Community 40"
Cohesion: 0.67
Nodes (2): redirectToUrl, web_redirect_stub.dart

### Community 41 - "Community 41"
Cohesion: 0.67
Nodes (2): package:firebase_analytics/firebase_analytics.dart, AnalyticsService

### Community 42 - "Community 42"
Cohesion: 0.67
Nodes (2): webVibrate, webVibratePattern

### Community 43 - "Community 43"
Cohesion: 1.0
Nodes (1): performRedirect

## Knowledge Gaps
- **1208 isolated node(s):** `main`, `main`, `initializeStripe`, `main`, `main` (+1203 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 39`** (3 nodes): `dart:html`, `web_redirect_html.dart`, `performRedirect`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 40`** (3 nodes): `web_redirect.dart`, `redirectToUrl`, `web_redirect_stub.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 41`** (3 nodes): `analytics_service.dart`, `package:firebase_analytics/firebase_analytics.dart`, `AnalyticsService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 42`** (3 nodes): `platform_vibrate_native.dart`, `webVibrate`, `webVibratePattern`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 43`** (2 nodes): `web_redirect_stub.dart`, `performRedirect`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 1` to `Community 0`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 14`, `Community 15`, `Community 16`, `Community 17`, `Community 18`, `Community 20`, `Community 21`, `Community 22`, `Community 23`, `Community 24`, `Community 25`, `Community 27`, `Community 28`?**
  _High betweenness centrality (0.420) - this node is a cross-community bridge._
- **Why does `package:taxi_exam_app/core/localization/strings.g.dart` connect `Community 7` to `Community 0`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 14`, `Community 16`, `Community 17`, `Community 18`, `Community 21`, `Community 22`, `Community 24`, `Community 25`, `Community 27`?**
  _High betweenness centrality (0.100) - this node is a cross-community bridge._
- **Why does `package:taxi_exam_app/core/api/api_service.dart` connect `Community 9` to `Community 0`, `Community 2`, `Community 3`, `Community 5`, `Community 6`, `Community 8`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 15`, `Community 16`, `Community 20`, `Community 22`, `Community 24`, `Community 25`?**
  _High betweenness centrality (0.067) - this node is a cross-community bridge._
- **What connects `main`, `main`, `initializeStripe` to the rest of the system?**
  _1208 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._