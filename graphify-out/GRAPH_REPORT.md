# Graph Report - .  (2026-04-29)

## Corpus Check
- 154 files · ~189,909 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1318 nodes · 1660 edges · 45 communities detected
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 22 edges (avg confidence: 0.86)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_BCD Content Hub|BCD Content Hub]]
- [[_COMMUNITY_Web Platform Layer|Web Platform Layer]]
- [[_COMMUNITY_Firebase & Analytics|Firebase & Analytics]]
- [[_COMMUNITY_Core Foundation|Core Foundation]]
- [[_COMMUNITY_Exam & Stats Engine|Exam & Stats Engine]]
- [[_COMMUNITY_Dashboard UI|Dashboard UI]]
- [[_COMMUNITY_Networking Layer|Networking Layer]]
- [[_COMMUNITY_Dashboard Repository|Dashboard Repository]]
- [[_COMMUNITY_Auth & Social Login|Auth & Social Login]]
- [[_COMMUNITY_Notifications & API|Notifications & API]]
- [[_COMMUNITY_Test Screen Features|Test Screen Features]]
- [[_COMMUNITY_BCD Content Browser|BCD Content Browser]]
- [[_COMMUNITY_Dashboard Screens|Dashboard Screens]]
- [[_COMMUNITY_Data Models|Data Models]]
- [[_COMMUNITY_BCD Testing|BCD Testing]]
- [[_COMMUNITY_Document Viewer|Document Viewer]]
- [[_COMMUNITY_Licences & Subscriptions|Licences & Subscriptions]]
- [[_COMMUNITY_Cryptography & Archive|Cryptography & Archive]]
- [[_COMMUNITY_Onboarding & Preferences|Onboarding & Preferences]]
- [[_COMMUNITY_Main Screen|Main Screen]]
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
1. `package:flutter/material.dart` - 76 edges
2. `package:taxi_exam_app/core/localization/strings.g.dart` - 30 edges
3. `package:taxi_exam_app/core/utils/app_page_route.dart` - 23 edges
4. `package:taxi_exam_app/core/api/api_service.dart` - 22 edges
5. `package:taxi_exam_app/core/widgets/snackbar.dart` - 21 edges
6. `package:flutter/foundation.dart` - 20 edges
7. `package:shared_preferences/shared_preferences.dart` - 19 edges
8. `package:lucide_icons/lucide_icons.dart` - 15 edges
9. `package:taxi_exam_app/core/models/test_attempt.dart` - 13 edges
10. `package:hive/hive.dart` - 11 edges

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

### Community 0 - "BCD Content Hub"
Cohesion: 0.02
Nodes (85): bcd_category_hub_screen.dart, bcd_sub_category_screen.dart, package:flutter_stripe/flutter_stripe.dart, package:flutter_stripe_web/flutter_stripe_web.dart, package:lucide_icons/lucide_icons.dart, package:shimmer/shimmer.dart, package:taxi_exam_app/core/services/stripe_payment_service.dart, package:taxi_exam_app/core/services/tts_service.dart (+77 more)

### Community 1 - "Web Platform Layer"
Cohesion: 0.02
Nodes (71): app_lottie_web.dart, dart:js_interop, dart:ui_web, package:auto_size_text/auto_size_text.dart, package:fl_chart/fl_chart.dart, package:flutter/material.dart, package:lottie/lottie.dart, package:web/web.dart (+63 more)

### Community 2 - "Firebase & Analytics"
Cohesion: 0.03
Nodes (70): core/models/test_attempt.dart, package:clarity_flutter/clarity_flutter.dart, package:clarity_web/clarity_web.dart, package:firebase_core/firebase_core.dart, package:flutter_dotenv/flutter_dotenv.dart, package:flutter_test/flutter_test.dart, package:provider/provider.dart, package:sentry_flutter/sentry_flutter.dart (+62 more)

### Community 3 - "Core Foundation"
Cohesion: 0.03
Nodes (69): dart:io, package:confetti/confetti.dart, package:flutter/foundation.dart, package:flutter/services.dart, package:google_sign_in/google_sign_in.dart, package:package_info_plus/package_info_plus.dart, package:taxi_exam_app/core/services/analytics_service.dart, package:taxi_exam_app/core/widgets/category_card_widget.dart (+61 more)

### Community 4 - "Exam & Stats Engine"
Cohesion: 0.03
Nodes (66): package:taxi_exam_app/core/models/question.dart, package:taxi_exam_app/core/utils/calculate_stats.dart, package:taxi_exam_app/core/widgets/attempt_spark_widget.dart, package:taxi_exam_app/core/widgets/category_pie_chart_widget.dart, package:taxi_exam_app/features/home/attempt_detail_screen.dart, package:taxi_exam_app/features/tests/test_screen.dart, TestAttempt, build (+58 more)

### Community 5 - "Dashboard UI"
Cohesion: 0.03
Nodes (58): ../../helpers/dashboard_helpers.dart, ../models/dashboard_stats.dart, package:taxi_exam_app/core/localization/strings.g.dart, BatchProgressCard, build, Container, GestureDetector, _MiniStat (+50 more)

### Community 6 - "Networking Layer"
Cohesion: 0.04
Nodes (51): dart:convert, dio_client.dart, package:dio_cache_interceptor/dio_cache_interceptor.dart, package:dio/dio.dart, package:flutter_secure_storage/flutter_secure_storage.dart, package:google_fonts/google_fonts.dart, package:taxi_exam_app/core/models/option.dart, package:taxi_exam_app/core/services/navigation_service.dart (+43 more)

### Community 7 - "Dashboard Repository"
Cohesion: 0.04
Nodes (47): dashboard_repository.dart, ../models/exam_node.dart, ../models/subscribed_exam.dart, package:hive_flutter/hive_flutter.dart, package:taxi_exam_app/core/services/bcd_cache.dart, package:taxi_exam_app/core/storage/app_storage.dart, ../repository/dashboard_repository.dart, ../repository/exam_sync_service.dart (+39 more)

### Community 8 - "Auth & Social Login"
Cohesion: 0.04
Nodes (51): package:font_awesome_flutter/font_awesome_flutter.dart, package:taxi_exam_app/core/auth/google_sign_in_helper.dart, package:taxi_exam_app/features/auth/forgot_password_screen.dart, _AuthSheet, _AuthSheetState, build, Column, Container (+43 more)

### Community 9 - "Notifications & API"
Cohesion: 0.04
Nodes (47): dart:async, package:firebase_messaging/firebase_messaging.dart, package:taxi_exam_app/core/api/api_service.dart, package:taxi_exam_app/core/providers/notification_provider.dart, package:taxi_exam_app/core/providers/theme_provider.dart, package:taxi_exam_app/core/services/session_validation_service.dart, package:taxi_exam_app/core/services/version_service.dart, package:taxi_exam_app/core/widgets/snackbar.dart (+39 more)

### Community 10 - "Test Screen Features"
Cohesion: 0.04
Nodes (49): package:flutter_tts/flutter_tts.dart, package:no_screenshot/no_screenshot.dart, package:taxi_exam_app/core/constants/language_options.dart, package:taxi_exam_app/core/models/image_viewer.dart, package:taxi_exam_app/core/widgets/explanation_widget.dart, package:taxi_exam_app/core/widgets/navigation_controls.dart, package:taxi_exam_app/core/widgets/option_tile.dart, package:taxi_exam_app/core/widgets/question_progress_header.dart (+41 more)

### Community 11 - "BCD Content Browser"
Cohesion: 0.04
Nodes (49): package:collection/collection.dart, package:taxi_exam_app/features/auth/auth_bottom_sheet.dart, package:taxi_exam_app/features/bcd/bcd_category_hub_screen.dart, package:taxi_exam_app/features/bcd/bcd_sub_category_screen.dart, AnimatedContainer, build, _BundleRow, _CategoryCard (+41 more)

### Community 12 - "Dashboard Screens"
Cohesion: 0.05
Nodes (41): package:taxi_exam_app/features/bcd/bcd_test_screen.dart, package:taxi_exam_app/features/notifications/notifications_screen.dart, ../providers/dashboard_provider.dart, AnimatedContainer, _BatchAttemptHistory, _BatchRow, _BatchRowState, build (+33 more)

### Community 13 - "Data Models"
Cohesion: 0.05
Nodes (33): exam_node.dart, package:hive/hive.dart, subscribed_exam.dart, LocalNotification, copyWith, Option, BatchStats, CategoryStats (+25 more)

### Community 14 - "BCD Testing"
Cohesion: 0.05
Nodes (36): bcd_text_utils.dart, package:flutter/gestures.dart, package:taxi_exam_app/features/bcd/providers/bcd_provider.dart, BCDTestScreen, _BCDTestScreenState, build, dispose, initState (+28 more)

### Community 15 - "Document Viewer"
Cohesion: 0.05
Nodes (37): bcd_document_viewer_screen.dart, bcd_test_screen.dart, ../tests/saved_questions_preview_screen.dart, BCDCategoryHubScreen, _BCDCategoryHubScreenState, _BCDChecklistsScreen, _BCDChecklistsScreenState, _BCDDocumentsScreen (+29 more)

### Community 16 - "Licences & Subscriptions"
Cohesion: 0.05
Nodes (33): bcd_licences_screen.dart, bcd_subscriptions_screen.dart, bcd_traffic_signs_screen.dart, ../../features/tests/result_screen.dart, ../models/question.dart, package:expandable/expandable.dart, package:taxi_exam_app/core/utils/app_page_route.dart, package:taxi_exam_app/features/auth/reset_password_screen.dart (+25 more)

### Community 17 - "Cryptography & Archive"
Cohesion: 0.05
Nodes (34): dart:math, dart:typed_data, package:archive/archive.dart, package:pointycastle/export.dart, package:taxi_exam_app/features/bcd/bcd_text_utils.dart, CryptoService, decrypt, decryptCompressed (+26 more)

### Community 18 - "Onboarding & Preferences"
Cohesion: 0.06
Nodes (31): package:introduction_screen/introduction_screen.dart, package:shared_preferences/shared_preferences.dart, package:taxi_exam_app/core/widgets/app_lottie.dart, FontProvider, setMode, ThemeProvider, clearMemoryCache, getSavedIdsScoped (+23 more)

### Community 19 - "Main Screen"
Cohesion: 0.06
Nodes (34): _applyFlagsFromMap, build, createState, dispose, _flag, _FloatingFab, _FloatingFabState, _FloatingNavArea (+26 more)

### Community 20 - "Community 20"
Cohesion: 0.06
Nodes (32): build, _buildMenuTile, dispose, initState, ListTile, _LogoutSheet, _LogoutSheetState, _onProfileChanged (+24 more)

### Community 21 - "Community 21"
Cohesion: 0.06
Nodes (30): package:flutter/widgets.dart, package:intl/intl.dart, package:slang_flutter/slang_flutter.dart, package:slang/generated.dart, strings.g.dart, strings_sv.g.dart, AppLocale, AppLocaleUtils (+22 more)

### Community 22 - "Community 22"
Cohesion: 0.07
Nodes (27): package:syncfusion_flutter_pdfviewer/pdfviewer.dart, package:taxi_exam_app/core/api/dio_client.dart, package:url_launcher/url_launcher.dart, BCDDocumentViewerScreen, _BCDDocumentViewerScreenState, build, Center, Exception (+19 more)

### Community 23 - "Community 23"
Cohesion: 0.08
Nodes (21): package:taxi_exam_app/core/models/test_attempt.dart, AttemptEntryCard, build, Container, SizedBox, build, Container, ProgressCard (+13 more)

### Community 24 - "Community 24"
Cohesion: 0.21
Nodes (5): VersionManager, ExamNode, ExamNodeAdapter, read, write

### Community 25 - "Community 25"
Cohesion: 0.14
Nodes (13): package:photo_view/photo_view.dart, BoxDecoration, build, dispose, Icon, _ImageViewerPage, _ImageViewerPageState, initState (+5 more)

### Community 26 - "Community 26"
Cohesion: 0.15
Nodes (12): dash_avg_score_label, dash_batches_count, dash_days_remaining, dash_practice_days, dash_stat_of_n, dash_streak_days, dash_streak_title, _flatMapFunction (+4 more)

### Community 27 - "Community 27"
Cohesion: 0.36
Nodes (9): TaxiQuiz App Icon - D Letter Road Motif, Apple Pay Payment Icon, Create Custom Test Action, Category Detail Screen - Säkerhet (Safety), Google Pay Payment Icon, In-App Payment Feature, Säkerhet (Safety) Exam Category, Saved Questions Action (+1 more)

### Community 28 - "Community 28"
Cohesion: 0.47
Nodes (9): Brand Color: Dark Grey, Brand Color: Gold/Yellow, Brand D-Letter Logo (Dark Grey and Gold), PWA Web Assets Group, PWA Standard Icon 192x192, PWA Standard Icon 512x512, PWA Maskable Icon 192x192, PWA Maskable Icon 512x512 (+1 more)

### Community 29 - "Community 29"
Cohesion: 0.4
Nodes (4): LocalNotification, LocalNotificationAdapter, read, write

### Community 30 - "Community 30"
Cohesion: 0.4
Nodes (4): Question, QuestionAdapter, read, write

### Community 31 - "Community 31"
Cohesion: 0.4
Nodes (4): read, TestAttempt, TestAttemptAdapter, write

### Community 32 - "Community 32"
Cohesion: 0.4
Nodes (4): Option, OptionAdapter, read, write

### Community 33 - "Community 33"
Cohesion: 0.4
Nodes (4): read, SubscribedExam, SubscribedExamAdapter, write

### Community 34 - "Community 34"
Cohesion: 0.5
Nodes (3): HomeDataCache, invalidate, markSynced

### Community 35 - "Community 35"
Cohesion: 0.67
Nodes (2): dart:html, performRedirect

### Community 36 - "Community 36"
Cohesion: 0.67
Nodes (2): redirectToUrl, web_redirect_stub.dart

### Community 37 - "Community 37"
Cohesion: 0.67
Nodes (2): package:firebase_analytics/firebase_analytics.dart, AnalyticsService

### Community 38 - "Community 38"
Cohesion: 1.0
Nodes (1): performRedirect

### Community 39 - "Community 39"
Cohesion: 1.0
Nodes (0): 

### Community 40 - "Community 40"
Cohesion: 1.0
Nodes (0): 

### Community 41 - "Community 41"
Cohesion: 1.0
Nodes (0): 

### Community 42 - "Community 42"
Cohesion: 1.0
Nodes (0): 

### Community 43 - "Community 43"
Cohesion: 1.0
Nodes (0): 

### Community 44 - "Community 44"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **1086 isolated node(s):** `main`, `main`, `main`, `main`, `package:taxi_exam_app/features/bcd/bcd_document_viewer_screen.dart` (+1081 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 38`** (2 nodes): `web_redirect_stub.dart`, `performRedirect`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 39`** (1 nodes): `widget_test.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 40`** (1 nodes): `firebase-messaging-sw.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 41`** (1 nodes): `language_options.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 42`** (1 nodes): `category_sort_utils.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 43`** (1 nodes): `navigation_feedback.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 44`** (1 nodes): `localization_helper.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Web Platform Layer` to `BCD Content Hub`, `Firebase & Analytics`, `Core Foundation`, `Exam & Stats Engine`, `Dashboard UI`, `Networking Layer`, `Auth & Social Login`, `Notifications & API`, `Test Screen Features`, `BCD Content Browser`, `Dashboard Screens`, `Data Models`, `BCD Testing`, `Document Viewer`, `Licences & Subscriptions`, `Cryptography & Archive`, `Onboarding & Preferences`, `Main Screen`, `Community 20`, `Community 22`, `Community 23`, `Community 25`?**
  _High betweenness centrality (0.457) - this node is a cross-community bridge._
- **Why does `package:taxi_exam_app/core/localization/strings.g.dart` connect `Dashboard UI` to `BCD Content Hub`, `Firebase & Analytics`, `Exam & Stats Engine`, `Auth & Social Login`, `Notifications & API`, `BCD Content Browser`, `Dashboard Screens`, `BCD Testing`, `Document Viewer`, `Licences & Subscriptions`, `Cryptography & Archive`, `Onboarding & Preferences`, `Community 20`, `Community 22`, `Community 25`?**
  _High betweenness centrality (0.074) - this node is a cross-community bridge._
- **Why does `package:taxi_exam_app/core/api/api_service.dart` connect `Notifications & API` to `BCD Content Hub`, `Firebase & Analytics`, `Core Foundation`, `Exam & Stats Engine`, `Networking Layer`, `Dashboard Repository`, `Auth & Social Login`, `Test Screen Features`, `BCD Content Browser`, `BCD Testing`, `Document Viewer`, `Licences & Subscriptions`, `Cryptography & Archive`, `Onboarding & Preferences`, `Main Screen`?**
  _High betweenness centrality (0.066) - this node is a cross-community bridge._
- **What connects `main`, `main`, `main` to the rest of the system?**
  _1086 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `BCD Content Hub` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `Web Platform Layer` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `Firebase & Analytics` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._