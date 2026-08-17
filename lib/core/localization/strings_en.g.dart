///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element

class Translations implements BaseTranslations<AppLocale, Translations> {
  /// Returns the current translations of the given [context].
  ///
  /// Usage:
  /// final t = Translations.of(context);
  static Translations of(BuildContext context) =>
      InheritedLocaleData.of<AppLocale, Translations>(context).translations;

  /// You can call this constructor and build your own translation instance of this locale.
  /// Constructing via the enum [AppLocale.build] is preferred.
  Translations(
      {Map<String, Node>? overrides,
      PluralResolver? cardinalResolver,
      PluralResolver? ordinalResolver,
      TranslationMetadata<AppLocale, Translations>? meta})
      : assert(overrides == null,
            'Set "translation_overrides: true" in order to enable this feature.'),
        $meta = meta ??
            TranslationMetadata(
              locale: AppLocale.en,
              overrides: overrides ?? {},
              cardinalResolver: cardinalResolver,
              ordinalResolver: ordinalResolver,
            ) {
    $meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <en>.
  @override
  final TranslationMetadata<AppLocale, Translations> $meta;

  /// Access flat map
  dynamic operator [](String key) => $meta.getTranslation(key);

  late final Translations _root = this; // ignore: unused_field

  Translations $copyWith(
          {TranslationMetadata<AppLocale, Translations>? meta}) =>
      Translations(meta: meta ?? this.$meta);

  // Translations
  String get home => 'Home';
  String get tests => 'Tests';
  String get profile => 'Profile';
  String get welcome_message => 'Welcome to Drive Test';
  String get save => 'Save';
  String get cancel => 'Cancel';
  String get delete => 'Delete';
  String get logout => 'Logout';
  String get loading => 'Loading...';
  String get settings_title => 'Settings';
  String get settings_appearance => 'Appearance';
  String get settings_test_prefs => 'Test Preferences';
  String get settings_timed_test => 'Timed Test';
  String get settings_timed_test_sub => 'Enable a time limit for the test';
  String get settings_instant_marking => 'Instant Marking';
  String get settings_instant_marking_sub =>
      'Show correct answer after each question';
  String get settings_num_questions => 'Number of Questions';
  String get settings_enter_num => 'Enter number of questions:';
  String get settings_include_saved => 'Include Saved Questions';
  String get settings_include_saved_sub =>
      'Include questions you previously saved';
  String get settings_notifications => 'Notifications';
  String get settings_notifications_toggle => 'Push Notifications';
  String get settings_notifications_on_sub =>
      'You will receive exam reminders and updates';
  String get settings_notifications_off_sub => 'Notifications are turned off';
  String get settings_notifications_denied =>
      'Permission denied — tap below to open Settings';
  String get settings_notifications_open_settings => 'Open Settings';
  String get settings_dark_mode => 'Dark Mode';
  String get settings_dark_mode_sub => 'Switch between light and dark theme';
  String get settings_language => 'Language';
  String get settings_language_sub => 'Choose your preferred language';
  String get settings_version => 'Version Information';
  String get settings_app_version => 'App Version';
  String get settings_commit => 'Commit';
  String get settings_branch => 'Branch';
  String get settings_last_update => 'Last Update';
  String get settings_date => 'Date';
  String get settings_saved => 'Settings saved successfully';
  String get profile_student => 'STUDENT';
  String get profile_view_profile => 'View Profile';
  String get profile_edit => 'Edit profile';
  String get profile_section_preferences => 'Preferences';
  String get profile_section_resources => 'Resources';
  String get profile_stats => 'My stats';
  String get profile_statistics => 'Statistics';
  String get stats_no_tests_yet => 'No completed tests yet';
  String get stats_attempt_history => 'ATTEMPT HISTORY';
  String get stats_avg_time => 'Avg time';
  String get stats_attempt_one => 'attempt';
  String get stats_attempt_many => 'attempts';
  String get stats_avg_label => 'Avg';
  String get stats_unknown => 'Unknown';
  String get stats_best => 'Best';
  String get stats_average => 'Average';
  String get stats_completed_tests => 'Completed tests';
  String get stats_pass_rate => 'Pass rate';
  String get stats_best_score => 'Best score';
  String get stats_average_score => 'Average score';
  String get stats_total_study_time => 'Total study time';
  String get stats_latest_result => 'Latest result';
  String get stats_per_test_breakdown => 'Per-test breakdown';
  String get stats_all_attempts => 'All attempts';
  String get home_attempt_details => 'Attempt Details';
  String get home_saved_questions_title => 'Saved Questions';
  String get profile_settings => 'Settings';
  String get profile_invite => 'Invite a friend';
  String get profile_help => 'Help';
  String get profile_manage_subscription => 'Manage Subscription';
  String get profile_purchase_history => 'Purchase History';
  String get profile_receipt_title => 'Receipt';
  String get profile_receipt_copy_number => 'Copy receipt number';
  String get profile_receipt_number_copied => 'Receipt number copied';
  String get profile_no_purchases => 'No purchases yet.';
  String get profile_receipt_payment_receipt => 'Payment Receipt';
  String get profile_receipt_no => 'Receipt no.';
  String get profile_receipt_product => 'Product';
  String get profile_receipt_duration => 'Duration';
  String get profile_receipt_amount_paid => 'Amount paid';
  String get profile_receipt_payment_via => 'Payment via';
  String get profile_receipt_via_iap => 'Apple App Store';
  String get profile_receipt_via_card => 'Card (Stripe)';
  String get profile_receipt_transaction_id => 'Transaction ID';
  String get profile_receipt_payment_intent => 'Payment intent';
  String get profile_receipt_reference_no => 'Reference no.';
  String get profile_receipt_footer =>
      'Keep this receipt for your records. Contact support with your receipt number if you have questions about this purchase.';
  String get profile_revisit_setup => 'Revisit Setup';
  String get profile_send_feedback => 'Send Feedback';
  String get profile_logout_confirm => 'Are you sure you want to log out?';
  String get profile_yes_logout => 'Yes, Logout';
  String get home_dashboard => 'Dashboard';
  String get home_my_progress => 'My Progress';
  String get home_overall_score => 'Overall Score';
  String get home_passed => 'Passed';
  String get home_failed => 'Failed';
  String get home_total => 'Total';
  String get home_in_progress => 'In Progress';
  String get home_recent_activity => 'Recent Activity';
  String get home_by_category => 'By Category';
  String get home_this_week => 'This Week';
  String get home_this_month => 'This Month';
  String get home_no_attempts => 'No attempts yet!';
  String get home_no_attempts_sub =>
      'Once you complete a quiz, your results will show up here.';
  String get home_take_quiz => 'Take Your First Quiz';
  String get home_paused => 'Paused';
  String get home_started => 'Started';
  String get home_resume => 'Resume';
  String get home_attempts => 'attempts';
  String get home_active => 'active';
  String get home_tests => 'tests';
  String get home_quick_access => 'Quick Access';
  String get home_qa_start_test => 'Practice Test';
  String get home_qa_custom_test => 'Custom Test';
  String get home_qa_saved_questions => 'Saved Questions';
  String get home_qa_settings => 'Settings';
  String get intro_slide1_body =>
      'Learn and practice for your license with ease.';
  String get intro_slide2_title => 'Interactive Tests';
  String get intro_slide2_body =>
      'Practice tests with real-time feedback and explanations.';
  String get intro_slide3_title => 'Get Certified';
  String get intro_slide3_body =>
      'Ace your exams and become a certified driver.';
  String get intro_skip => 'Skip';
  String get intro_get_started => 'Get Started';
  String get auth_welcome_title => 'Welcome to Drive Test!';
  String get auth_welcome_subtitle => 'Practice. Pass with confidence.';
  String get auth_login_btn => 'LOGIN';
  String get auth_signup_btn => 'SIGNUP';
  String get auth_skip_demo => 'SKIP FOR NOW (TRY DEMO)';
  String get auth_demo_error =>
      'Failed to login with demo account. Please try again.';
  String get auth_or => 'OR';
  String get auth_login_title => 'Login';
  String get auth_contact_support => 'Contact support';
  String get auth_username => 'Username or Email';
  String get auth_email => 'Email';
  String get auth_password => 'Password';
  String get auth_remember_me => 'Remember me';
  String get auth_forgot_password => 'Forgot Password?';
  String get auth_invalid_credentials => 'Invalid username or password';
  String get auth_no_account => 'Don\'t have an account? ';
  String get auth_sign_up_link => 'Sign up';
  String get auth_skip_demo_short => 'Skip for now (Try Demo)';
  String get auth_google_continue => 'Continue with Google';
  String get auth_feedback_type => 'Type';
  String get auth_feedback_email_optional => 'Email (optional)';
  String get auth_feedback_subject_optional => 'Subject (optional)';
  String get auth_feedback_message => 'Message';
  String get auth_feedback_sent => 'Thanks! Your feedback was sent.';
  String get auth_feedback_error =>
      'Could not send feedback. Please try again.';
  String get auth_submit => 'Submit';
  String get auth_feedback_login_issue => 'Login issue';
  String get auth_feedback_signup_issue => 'Signup issue';
  String get auth_feedback_app_issue => 'App issue';
  String get auth_feedback_feature_request => 'Feature request';
  String get auth_feedback_payment_issue => 'Payment issue';
  String get auth_feedback_other => 'Other';
  String get auth_create_account => 'Create Account';
  String get auth_sign_up_btn => 'Sign Up';
  String get auth_val_username_required =>
      'Please enter your username or email';
  String get auth_val_username_length =>
      'Username must be at least 4 characters';
  String get auth_val_email_required => 'Please enter an email';
  String get auth_val_email_invalid => 'Please enter a valid email';
  String get auth_val_password_required => 'Please enter a password';
  String get auth_val_password_length =>
      'Password must be at least 6 characters';
  String get auth_signup_success => 'Signup successful! Please login.';
  String get auth_welcome_first_login => 'Welcome. Enjoy exam prep.';
  String get auth_welcome_returning => 'Welcome back again.';
  String get auth_deleted_account_welcome_back => 'Always welcome back.';
  String get auth_signup_failed => 'Signup failed. Please correct the errors.';
  String get auth_generic_error => 'An error occurred. Please try again.';
  String get auth_express_google => 'Continue with Google';
  String get auth_or_continue_with => 'or continue with';
  String get auth_google_label => 'Google';
  String get auth_express_apple => 'Continue with Apple';
  String get auth_more_options => 'More options';
  String get auth_apple_label => 'Apple';
  String get auth_signing_in => 'Signing in...';
  String get auth_tab_login => 'Log in';
  String get auth_tab_signup => 'Sign up';
  String get auth_show_password => 'Show';
  String get auth_hide_password => 'Hide';
  String get auth_forgot_title => 'Forgot Password';
  String get auth_forgot_heading => 'Reset Your Password';
  String get auth_forgot_subtitle =>
      'Enter your email address and we\'ll send you instructions to reset your password.';
  String get auth_forgot_email_label => 'Email Address';
  String get auth_forgot_send_btn => 'Send Reset Instructions';
  String get auth_forgot_back_login => 'Back to Login';
  String get auth_forgot_success =>
      'Password reset instructions have been sent to your email.';
  String get auth_forgot_error =>
      'Failed to send reset email. Please try again.';
  String get auth_verify_title => 'Verify Code';
  String get auth_verify_heading => 'Check Your Email';
  String get auth_verify_subtitle => 'We sent a reset code to\n{email}';
  String get auth_verify_code_label => 'Reset Code';
  String get auth_verify_code_hint => 'Enter the code from your email';
  String get auth_verify_code_empty =>
      'Please enter the reset code from your email.';
  String get auth_verify_resend => 'Resend Code';
  String get auth_reset_title => 'Reset Password';
  String get auth_reset_heading => 'Set New Password';
  String get auth_reset_subtitle => 'Please enter your new password';
  String get auth_reset_new_password_label => 'New Password';
  String get auth_reset_confirm_password_label => 'Confirm Password';
  String get auth_reset_empty => 'Please enter a new password.';
  String get auth_reset_mismatch => 'Passwords do not match.';
  String get auth_reset_invalid_code =>
      'Invalid or expired reset code. Please try requesting a new reset link.';
  String get auth_reset_success_title => 'Success!';
  String get auth_reset_success_body =>
      'Your password has been reset successfully. You can now log in with your new password.';
  String get auth_reset_go_to_login => 'Go to Login';
  String get auth_google_connecting => 'Connecting to Google...';
  String get auth_apple_connecting => 'Connecting to Apple...';
  String get auth_google_verifying => 'Verifying account...';
  String get auth_google_signing_in => 'Signing you in...';
  String get auth_google_creating => 'Creating your account...';
  String get auth_google_loading => 'Loading your profile...';
  String get auth_landing_subtitle =>
      'Your journey to excellence starts with a single tap.';
  String get auth_landing_new_here => 'New here?';
  String get auth_create_account_link => 'Create an account';
  String get auth_login_heading => 'Welcome\nBack';
  String get auth_login_subtitle => 'Continue your kinetic journey.';
  String get auth_username_hint => 'username or email';
  String get auth_signup_heading_plain => 'Join the';
  String get auth_signup_heading_italic => 'Movement.';
  String get auth_signup_subtitle => 'Accelerate your learning journey today.';
  String get auth_signup_username_hint => 'Erik Andersson';
  String get auth_signup_email_hint => 'erik@example.se';
  String get auth_have_account => 'Already have an account?';
  String get auth_reset_onboarding_tooltip => 'Reset Onboarding';
  String get auth_language_english => 'English';
  String get auth_language_swedish => 'Swedish';
  String get brand_drive => 'DRIVE ';
  String get brand_test => 'TEST';
  String get purchase_success_title => 'Your Purchase has\nbeen confirmed';
  String get purchase_success_start_tests => 'Start Tests';
  String get purchase_success_back_home => 'Back to home';
  String get bcd_drive_test => 'Drive Test';
  String get bcd_exams => 'Exams';
  String get bcd_exams_sub => 'Licences, categories & tests';
  String get bcd_traffic_signs => 'Traffic Signs';
  String get bcd_traffic_signs_sub => 'Browse all traffic signs';
  String get bcd_subscriptions => 'Subscriptions';
  String get bcd_subscriptions_sub => 'View plans & manage access';
  String get bcd_hub_practice => 'Practice';
  String get bcd_hub_tests => 'Tests';
  String get bcd_hub_theory_docs => 'Theory\nDocuments';
  String get bcd_hub_traffic_signs => 'Traffic Signs';
  String get bcd_hub_checklist => 'Checklist';
  String get checklist_language_subtitle =>
      'Translate checklist to your language';
  String get bcd_hub_statistics => 'Statistics';
  String get bcd_hub_saved_questions => 'Saved\nQuestions';
  String get bcd_no_free_practice =>
      'No free practice test available for this category.';
  String get bcd_failed_practice => 'Failed to load practice test.';
  String get bcd_no_saved_questions =>
      'No saved questions in this category yet.';
  String get bcd_no_saved_questions_found =>
      'No saved questions found in this category.';
  String get bcd_failed_saved => 'Failed to load saved questions.';
  String get bcd_no_subscription =>
      'You don\'t have an active subscription for this category';
  String get bcd_free_content_desc =>
      'Practice, Traffic Signs, Documents and Checklists are free. Subscribe to unlock Tests.';
  String get bcd_buy_subscription => 'Buy subscription';
  String get bcd_buy_subscription_arrow => 'Buy subscription →';
  String get bcd_not_subscribed => 'You\'re not subscribed to this category';
  String get bcd_only_free_tests =>
      'Only free practice tests are available. Subscribe to unlock all tests.';
  String get bcd_no_free_practice_tests => 'No free practice tests available.';
  String get bcd_no_tests => 'No tests available.';
  String get bcd_no_documents => 'No documents available.';
  String get bcd_no_checklists => 'No checklists available.';
  String get bcd_failed_tests => 'Failed to load tests';
  String get bcd_subscription_required => 'Subscription Required';
  String get bcd_subscribe_access =>
      'Subscribe to access "{name}" and all its content.';
  String get bcd_not_now => 'Not now';
  String get legal_terms_of_use => 'Terms of Use';
  String get legal_privacy_policy => 'Privacy Policy';
  String get bcd_buy => 'Buy';
  String get bcd_payment_failed => 'Payment failed. Please try again.';
  String get iap_owned_by_other_title => 'Subscription Already Linked';
  String get iap_owned_by_other_body =>
      'This subscription is associated with a different account. Please log in with the account you originally purchased it on.';
  String get iap_owned_by_other_ok => 'OK';
  String get bcd_feedback_unavailable =>
      'Feedback is unavailable for this question.';
  String get bcd_feedback_submitted => 'Thanks! Your feedback was submitted.';
  String get bcd_feedback_failed =>
      'Could not submit feedback. Please try again.';
  String get bcd_categories => 'Categories';
  String get bcd_search_categories => 'Search categories…';
  String get bcd_no_categories => 'No categories available.';
  String get bcd_no_match_search => 'No matches found.';
  String get bcd_subscribed => 'Subscribed';
  String get bcd_tap_to_subscribe => 'Tap to subscribe';
  String get bcd_failed_categories => 'Failed to load categories';
  String get bcd_plans_tab => 'Plans';
  String get bcd_my_subscriptions_tab => 'My Subscriptions';
  String get bcd_no_plans => 'No plans available';
  String get bcd_active_label => 'Active';
  String get bcd_expired_label => 'Expired';
  String get bcd_sub_expires_days => 'Expires in {days} days · {date}';
  String get bcd_subscribe_btn => 'Subscribe';
  String get bcd_start_practice => 'Start Practice';
  String get bcd_no_active_subscriptions => 'No active subscriptions';
  String get bcd_browse_plans => 'Browse plans to get started';
  String get bcd_expires => 'Expires';
  String get bcd_failed_plans => 'Failed to load plans';
  String get bcd_no_categories_linked =>
      'No categories linked to this subscription';
  String get bcd_failed_category => 'Failed to load category';
  String get bcd_search_signs => 'Search sign groups…';
  String get bcd_no_signs => 'No signs found';
  String get bcd_no_image => 'No image';
  String get bcd_tap_to_zoom => 'Tap to zoom';
  String get bcd_signs_count_label => 'traffic signs';
  String get bcd_view => 'View';
  String get bcd_previous => 'Previous';
  String get bcd_next => 'Next';
  String get smart_check => 'Check';
  String get notif_subtitle => 'DriveTest';
  String get notif_morning_title => '☀️ Morning study reminder';
  String notif_morning_title_exam({required Object examTitle}) =>
      '☀️ Time to study ${examTitle}';
  String get notif_morning_body =>
      'Start your practice session — build that streak!';
  String get notif_evening_title => '🌙 Evening streak check-in';
  String notif_evening_title_exam({required Object examTitle}) =>
      '🌙 ${examTitle} is waiting for you';
  String get notif_evening_body =>
      'Don\'t let today slip by — keep your streak alive!';
  String notif_activity_0({required Object examTitle}) =>
      'You were working on ${examTitle} — one more session and it clicks.';
  String notif_activity_1({required Object examTitle}) =>
      '${examTitle} is waiting. Your last session built real momentum — don\'t lose it.';
  String notif_activity_2({required Object examTitle}) =>
      'Small daily sessions beat cramming. Jump back into ${examTitle} now.';
  String notif_activity_3({required Object examTitle}) =>
      'You\'re closer than you think on ${examTitle}. Keep the streak alive!';
  String notif_activity_4({required Object examTitle}) =>
      'One focused session on ${examTitle} today makes the exam day easier.';
  String get bcd_failed_traffic_signs => 'Failed to load traffic signs';
  String get bcd_search_hint => 'Search…';
  String get bcd_no_subcategories => 'No sub-categories available.';
  String get bcd_failed_subcategories => 'Failed to load sub-categories';
  String get bcd_no_questions => 'No questions found for this test.';
  String get bcd_failed_test_questions => 'Failed to load test questions.';
  String get bcd_questions_label => 'questions';
  String get bcd_pass_label => 'Pass';
  String get bcd_free_label => 'FREE';
  String get smart_locked => 'Locked';
  String get settings_theme_label => 'Theme';
  String get settings_theme_sub => 'Light, dark or follow system';
  String get settings_theme_system => 'System';
  String get settings_theme_light => 'Light';
  String get settings_theme_dark => 'Dark';
  String get help_title => 'Help & Support';
  String get help_need_help => 'Need Help?';
  String get help_subtitle =>
      'Tell us about your issue and we\'ll get back to you soon.';
  String get help_your_information => 'Your Information';
  String get help_username => 'Username';
  String get help_email => 'Email';
  String get help_user_id => 'User ID';
  String get help_subject => 'Subject';
  String get help_subject_hint =>
      'e.g., Login issue, Bug report, Feature request';
  String get help_subject_required => 'Please enter a subject';
  String get help_description => 'Description';
  String get help_description_hint => 'Please describe your issue in detail...';
  String get help_description_required => 'Please describe your issue';
  String get help_description_too_short =>
      'Please provide more details (at least 10 characters)';
  String get help_submit => 'Submit Report';
  String get help_or_email => 'Or email us directly at support@drivetest.se';
  String get help_opening_email => 'Opening email app...';
  String get help_email_error =>
      'Could not open email app. Please email support@drivetest.se directly.';
  String get help_generic_error => 'Error opening email app. Please try again.';
  String get notifications_title => 'Notifications';
  String get notifications_mark_all_read => 'Mark all read';
  String get notifications_clear => 'Clear';
  String get notifications_clear_confirm_title => 'Clear all notifications?';
  String get notifications_clear_confirm_body =>
      'This will remove all notifications. This action cannot be undone.';
  String get notifications_empty_title => 'No notifications';
  String get notifications_empty_subtitle =>
      'You\'re all caught up! We\'ll let you know when something new arrives.';
  String get notifications_just_now => 'Just now';
  String get notifications_minutes_ago => '{n} min ago';
  String get notifications_hours_ago => '{n}h ago';
  String get notifications_days_ago => '{n}d ago';
  String get notifications_permission_off_title => 'Notifications are off';
  String get notifications_permission_denied_body =>
      'You have denied notification permission. Open Settings to enable them.';
  String get notifications_permission_not_determined_body =>
      'Allow notifications to stay updated on your exam progress and reminders.';
  String get notifications_permission_open_settings => 'Open Settings';
  String get notifications_permission_enable => 'Enable Notifications';
  String get notifications_permission_web_dialog_title => 'Enable in browser';
  String get notifications_permission_web_dialog_body =>
      'To enable notifications, click the lock icon (🔒) in your browser\'s address bar, find "Notifications", and set it to "Allow". Then refresh the page.';
  String get notifications_permission_web_dialog_ok => 'Got it';
  String get image_viewer_swipe_to_close => 'Swipe down to close';
  String get image_viewer_load_error => 'Could not load image';
  String get dash_my_progress => 'My Progress';
  String get dash_sync_from_server => 'Sync from server';
  String get dash_unknown_error => 'Something went wrong. Please try again.';
  String get dash_network_error =>
      'No internet connection. Check your connection and try again.';
  String get dash_server_error => 'Server error. Please try again later.';
  String get dash_retry => 'Retry';
  String get dash_my_exams => 'My Exams';
  String get dash_tap_to_dive => 'Tap an exam to dive in';
  String get dash_overview => 'Overview';
  String get dash_categories_header => 'Categories';
  String get dash_batches_header => 'Batches';
  String get dash_expand_categories => 'Expand each category to see batches';
  String get dash_weekly_streak => 'Weekly Streak';
  String get dash_consistency_builds => 'Consistency builds mastery';
  String get dash_smart_insights => 'Smart Insights';
  String get dash_based_on_attempts => 'Based on your attempts';
  String get dash_continue_label => 'Continue: {name}';
  String get dash_total_attempts => 'Total Attempts';
  String get dash_batches_done => 'Batches Done';
  String get dash_avg_time => 'Avg Time';
  String get dash_chunks_mastered => 'Chunks Mastered';
  String get dash_weak_questions => 'Weak Questions';
  String get dash_weakest_label => 'Weakest: {name} ({score}%)';
  String get dash_batches_completed_label => '{done}/{total} batches completed';
  String get dash_weakness_low_score => 'Low score';
  String get dash_weakness_over_time => 'Over time';
  String get dash_weakness_needs_work => 'Needs work';
  String get dash_weakness_on_track => 'On track';
  String get dash_not_started => 'Not started';
  String get dash_attempt_one => '1 attempt';
  String get dash_attempt_many => '{n} attempts';
  String get dash_avg_duration => 'Avg {duration}';
  String get dash_over_time_pct => '+{pct}% time';
  String get dash_on_time => 'On time';
  String get dash_insight_strongest => 'Strongest area';
  String get dash_insight_weakest => 'Weakest area';
  String get dash_insight_focus => 'Focus recommendation';
  String get dash_insight_continue_learning => 'Continue learning';
  String get dash_insight_area_detail => '{name} — {score}% avg';
  String get dash_insight_focus_detail =>
      'Work on {name} next to keep progressing';
  String get dash_insight_start =>
      'Start with {name} — pick any batch to begin.';
  String get dash_insight_all_done =>
      'All batches completed! Revisit low-scoring batches to master them.';
  String get dash_insight_progress =>
      '{done}/{total} batches passed. Keep going — you\'re {pct}% there!';
  String get dash_streak_current => 'Current\nStreak';
  String get dash_streak_best => 'Best\nStreak';
  String get dash_streak_weekly_goal => 'Weekly goal';
  String get dash_day_mon => 'M';
  String get dash_day_tue => 'T';
  String get dash_day_wed => 'W';
  String get dash_day_thu => 'T';
  String get dash_day_fri => 'F';
  String get dash_day_sat => 'S';
  String get dash_day_sun => 'S';
  String get dash_streak_msg_none =>
      'Start a session today to begin your streak!';
  String get dash_streak_msg_amazing =>
      'Amazing! {n} days in a row — keep it up!';
  String get dash_streak_msg_goal => 'Weekly goal reached! You\'re on fire 🔥';
  String get dash_streak_msg_progress_one =>
      '{n} day streak! 1 more session to hit your weekly goal.';
  String get dash_streak_msg_progress_other =>
      '{n} day streak! {left} more sessions to hit your weekly goal.';
  String get dash_completed => 'Completed!';
  String get dash_tap_to_explore => 'Tap to explore';
  String get onb_which_exams => 'Which exams are you preparing for?';
  String get onb_select_all_apply => 'Select all that apply';
  String get onb_exam_date_title => 'When is your exam?';
  String get onb_exam_date_subtitle => 'Set a target date to stay on track';
  String get onb_practice_days_title =>
      'How many days a week will you practice?';
  String get onb_practice_days_subtitle => 'Be realistic — consistency is key';
  String get onb_recommendations_title => 'Recommended for you';
  String get onb_recommendations_subtitle =>
      'Subscribe to unlock full access to these exams';
  String get onb_continue => 'Continue';
  String get onb_weekday_mon_short => 'M';
  String get onb_weekday_tue_short => 'T';
  String get onb_weekday_wed_short => 'W';
  String get onb_weekday_thu_short => 'T';
  String get onb_weekday_fri_short => 'F';
  String get onb_weekday_sat_short => 'S';
  String get onb_weekday_sun_short => 'S';
  String get onb_get_started => 'Get Started';
  String get onb_1_week => '1 week';
  String get onb_2_weeks => '2 weeks';
  String get onb_3_weeks => '3 weeks';
  String get onb_1_month => '1 month';
  String get onb_2_months => '2 months';
  String get onb_3_months => '3 months';
  String get onb_custom_date => 'Custom date';
  String get onb_subscribe => 'Subscribe';
  String get onb_sign_in_to_subscribe => 'Sign in to subscribe';
  String get onb_sign_in_subtitle =>
      'Create a free account or log in to unlock full exam access';
  String get onb_no_exams => 'No exams available right now';
  String get onb_days_week_label => '{n} days/week';
  String get onb_step_of => 'Step {current} of {total}';
  String get onb_weekly_goal_title => 'Weekly Study Goal';
  String get onb_weekly_goal_sub =>
      'Select the days you\'ll commit to studying.';
  String get dash_exam_deadline => 'Exam Deadline';
  String get dash_days_remaining => '{n} days left';
  String get dash_deadline_today => 'Today!';
  String get dash_deadline_passed => 'Deadline passed';
  String get dash_no_deadline => 'No deadline set';
  String get dash_set_deadline => 'Set deadline';
  String get dash_change_deadline => 'Change deadline';
  String get dash_practice_days => '{n} days/week';
  String get dash_hero_sub_start => 'Start your learning journey!';
  String get dash_hero_sub_progress => 'Keep going, you\'re doing great!';
  String get dash_hero_sub_almost => 'Almost ready for the exam!';
  String get dash_hero_sub_done => 'All done — great work!';
  String get dash_performance_overview => 'Performance Overview';
  String get dash_focus_areas => 'Focus Areas';
  String get dash_recently_practiced => 'Recent';
  String get dash_exam_progress => 'Exam Progress';
  String get dash_cat_complete => 'Complete';
  String get dash_cat_not_started => 'Not started';
  String get dash_cat_almost_done => '{n} left to finish!';
  String get dash_cat_needs_practice => 'Needs practice';
  String get dash_cat_in_progress => '{done}/{total} done';
  String get dash_progress_all_done => 'All topics complete!';
  String get dash_progress_topics_done => '{done} of {total} topics done';
  String get dash_progress_avg_hint => '{score}% overall avg';
  String get dash_progress_no_attempts => 'No attempts yet';
  String get dash_smart_new => 'New';
  String get dash_quick_access => 'Quick Access';
  String get dash_item_one => '1 item';
  String get dash_item_many => '{n} items';
  String get dash_shortcuts_count => '{n} shortcuts';
  String get dash_loading_batch => 'Batch {n}';
  String get dash_loading_category => 'Category {n}';
  String get dash_no_exams_found => 'No exams found.';
  String get dash_card_active => 'ACTIVE';
  String get dash_card_inactive => 'INACTIVE';
  String get dash_card_expired => 'Expired {date}';
  String get dash_card_expires_today => 'Expires today';
  String get dash_card_expires_tomorrow => 'Expires tomorrow';
  String get dash_card_expires_days => 'Expires in {days} days';
  String get dash_card_expires_on => 'Expires {date}';
  String get dash_stat_completed => 'Done';
  String get dash_stat_none_yet => 'None yet';
  String get dash_stat_of_n => 'of {total}';
  String get dash_stat_to_train => 'to train';
  String get dash_stat_per_session => 'Per session';
  String get dash_perf_title1 => 'Performance';
  String get dash_perf_title2 => 'Overview';
  String get dash_period_today => 'Today';
  String get dash_period_7days => '7 Days';
  String get dash_period_all => 'All Time';
  String get dash_perf_subtitle => 'Track your progress. Reach your goals.';
  String get dash_perf_attempts_desc => 'All your attempts in this period';
  String get dash_perf_batches_desc => 'Progress this period';
  String get dash_avg_time_per_session => 'Avg. Time / Session';
  String get dash_perf_time_desc => 'Average time taken per session';
  String get dash_keep_it_up => 'Keep it up!';
  String get dash_consistency_today => 'Consistency today, success tomorrow.';
  String get dash_exam_type_taxi => 'TAXI';
  String get dash_exam_type_test => 'TEST';
  String get dash_streak_title => '{n} day streak!';
  String get dash_streak_days => '{n} days';
  String get dash_batches_count => '{n} batches';
  String get dash_avg_score_label => '{score}% avg';
  String get dash_new_test => '+ New Test';
  String get dash_no_attempts_yet => 'No attempts yet';
  String get dash_previous_attempts => 'Previous attempts';
  String get dash_see_all => 'See all';
  String get dash_all_attempts => 'All Attempts';
  String get tut_step1_title => 'Step 1 of 2 — Translate';
  String get tut_step1_body =>
      'Tap the language button to open the list, then select English (or any other language).';
  String get tut_step1b_title => 'Step 1 of 2 — Choose a language';
  String get tut_step1b_body =>
      'Tap \'Question Language\' in the menu, then select a language from the list.';
  String get tut_step1_grid_hint =>
      'Select a different language below, for example English.';
  String get tut_step2a_title => 'Step 2 of 2 — Peek original';
  String get tut_step2a_body =>
      'Press and hold anywhere on the question (not the options) to temporarily see the original Swedish text.';
  String get tut_step2b_title => 'Step 2 of 2 — Now release';
  String get tut_step2b_body =>
      'Release your finger to go back to the translated text.';
  String get tut_complete_title => 'You\'re all set!';
  String get tut_complete_body =>
      'Great job! You now know how to translate questions and peek at the original text.';
  String get tut_complete_subtitle =>
      'You\'re ready to prepare for your taxi exam!';
  String get tut_start_practicing => 'Start practicing!';
  String get sg_title => 'Study Goals';
  String get sg_section_exam_date => 'EXAM DATE';
  String get sg_section_practice_days => 'PRACTICE DAYS';
  String get sg_practice_days_sub =>
      'Pick the days you commit to practising each week.';
  String get sg_days_per_week => '{n} day(s) / week';
  String get sg_save => 'Save Settings';
  String get sg_settings_saved => 'Settings saved!';
  String get sg_months => 'MONTHS';
  String get sg_custom_date => 'Custom date';
  String get sg_deadline_passed => 'Exam date passed';
  String get sg_days_remaining => '{n} days remaining';
  String get sg_notif_note =>
      'You\'ll get two reminders on each practice day — one in the morning and one in the evening — at randomised times to help you build a habit.';
  String get sg_profile_menu_label => 'Study Goals';
  String get splash_tagline => 'HELLO SWEDEN';
  String get splash_loading => 'Preparing your success...';
  String get splash_footer => 'ACADEMIC EXCELLENCE THROUGH KINETIC LEARNING';
  String get onb_top_bar_title => 'GET STARTED';
  String get onb_months => 'MONTHS';
  String get onb_step1_plain => 'What are you studying ';
  String get onb_step1_italic => 'for?';
  String get onb_step2_plain => 'When is your ';
  String get onb_step2_italic => 'exam?';
  String get onb_step3_plain => 'Set your weekly ';
  String get onb_step3_italic => 'goal.';
  String get onb_step4_plain => 'Your Path to ';
  String get onb_step4_italic => 'Mastery.';
  String get onb_step4_subtitle =>
      'Accelerate your learning with personalised study tools.';
  String get onb_no_plan_selected => 'No plan selected.';
  String get onb_buy_bundle => 'Buy bundle — {price}';
  String get onb_signin_to_purchase_title => 'Sign In to Subscribe';
  String get onb_signin_to_purchase_subtitle =>
      'Create a free account or sign in to start your subscription. Your progress and subscription will sync across all your devices.';
  String get onb_create_account_title => 'Create Your Free Account';
  String get onb_create_account_subtitle =>
      'Save your study plan and track your progress across all your devices.';
  String get onb_start_practicing => 'Start Practicing';
  String get onb_your_plan_badge => 'YOUR PLAN';
  String get onb_days_per_week => 'days/week';
  String get onb_most_popular => 'MOST POPULAR';
  String get onb_feature_mock_exams => 'Full mock exam library';
  String get onb_feature_progress_tracking => 'Smart progress tracking';
  String get onb_feature_explanations => 'Detailed answer explanations';
  String get onb_feature_ai_tutor => 'Personal AI study coach';
  String get onb_get_best_deal => 'Get Best Deal';
  String get onb_best_value => 'BEST VALUE';
  String get onb_choose_plan => 'Choose Plan';
  String get onb_bundle_discount_title => 'You\'re getting 20% off';
  String get onb_bundle_saving => 'Saving {amount}';
  String get onb_price_unavailable => 'Price unavailable';
  String get onb_duration_year_access => '{n} year access';
  String get onb_duration_months_access => '{n} months access';
  String get onb_duration_one_day => '1 day';
  String get onb_duration_days => '{n} days';
  String get onb_free_trial => '7-DAY FREE TRIAL INCLUDED. CANCEL ANYTIME.';
  String get onb_start_free => 'Continue as Guest';
  String get onb_skip_for_now => 'Skip for now';
  String get onb_pre_purchase_title => 'One quick step';
  String get onb_pre_purchase_subtitle =>
      'Create a free account to access your subscription on all your devices, or continue as a guest — you can always create one later.';
  String get onb_pre_purchase_sign_in => 'Sign In / Create Account';
  String get onb_pre_purchase_guest => 'Continue as Guest';
  String get auth_continue_as_guest => 'Continue as Guest';
  String get auth_guest_session_error =>
      'Could not restore your session. Please try again.';
  String get free_trial_banner_badge => 'FREE';
  String get free_trial_banner_title =>
      'Try road signs — no subscription needed';
  String get free_trial_banner_subtitle =>
      'Vägmärkestest is completely free. Practise at your own pace and get a feel for the app before subscribing.';
  String get free_trial_banner_cta => 'Start Practising';
  String get guest_banner_title => 'You\'re browsing as a guest';
  String get guest_banner_subtitle =>
      'Create a free account to save your progress and sync across all your devices.';
  String get guest_banner_cta => 'Create Account';
  String get guest_convert_title => 'Save Your Progress';
  String get guest_convert_subtitle =>
      'Create a free account to keep everything you\'ve practised.';
  String get guest_username_hint => 'Choose a username';
  String get guest_email_hint => 'Email address';
  String get guest_password_hint => 'Password (min. 8 characters)';
  String get guest_convert_cta => 'Create Account';
  String get dash_free_hub_title => 'Full Exam Practice — Free Content';
  String get dash_free_hub_subtitle =>
      'Practice questions, theory documents, checklists and statistics — no subscription needed.';
  String get dash_free_hub_badge => 'FREE';
  String get btn_save_changes => 'Save Changes';
  String get btn_set_password => 'Set Password';
  String get btn_delete_account => 'Delete My Account';
  String get delete_account_confirm_body =>
      'This action is permanent and cannot be undone. All your progress and data will be removed.';
  String get btn_deleting => 'Deleting...';
  String get btn_keep_going => 'Keep Going';
  String get btn_exit => 'Exit';
  String get btn_save_and_exit => 'Save & Exit';
  String get btn_submit => 'Submit';
  String get btn_start_saved_test => 'Start Saved Questions Test';
  String get btn_buy_now => 'Buy Now';
  String get btn_pay_now => 'Pay Now';
  String get home_all_tests_deleted => 'All tests have been deleted.';
  String get home_delete_progress_title => 'Delete Progress';
  String get home_delete_progress_body =>
      'Are you sure you want to delete this saved test?';
  String get home_delete_all_tests_title => 'Delete All Tests';
  String get home_delete_all_tests_body =>
      'Are you sure you want to delete all test attempts?';
  String get test_time_up_submitting => 'Time is up! Submitting your test.';
  String get test_first_question => 'This is the first question!';
  String get test_exit_title => 'Exit Test';
  String get test_exit_save_prompt => 'Would you like to save your progress?';
  String get test_save_backend_failed =>
      'Progress was saved on this device, but sync to your account failed. Please try again.';
  String get test_feedback_unavailable =>
      'Feedback is unavailable for this question.';
  String get test_feedback_title => 'Feedback';
  String get test_feedback_type => 'Type';
  String get test_feedback_question_issue => 'Question issue';
  String get test_feedback_wrong_answer => 'Wrong answer';
  String get test_feedback_typo => 'Typo/text issue';
  String get test_feedback_image_issue => 'Image issue';
  String get test_feedback_other => 'Other';
  String get test_feedback_hint =>
      'Tell us what is wrong with this question...';
  String get test_feedback_submitted => 'Thanks! Your feedback was submitted.';
  String get test_feedback_failed =>
      'Could not submit feedback. Please try again.';
  String get test_translation_failed => 'Translation failed. Please try again.';
  String get test_language_english => 'English';
  String get test_language_swedish => 'Svenska';
  String get test_question_language_title => 'Question Language';
  String get test_question_language_subtitle =>
      'Translate questions to your language';
  String get test_question_language_menu => 'Question Language';
  String get test_turn_off_timer => 'Turn off timer';
  String get test_turn_on_timer => 'Turn on timer';
  String get test_turn_off_instant_marking => 'Turn off instant marking';
  String get test_turn_on_instant_marking => 'Turn on instant marking';
  String get test_question_saved => 'Question saved';
  String get test_question_removed => 'Question removed from saved';
  String get test_saved => 'Saved';
  String get test_save_question => 'Save question';
  String get test_questions_title => 'Questions';
  String get test_question_progress => '{current} of {total}';
  String get test_question_label => 'Question {n}';
  String get test_answered => 'Answered';
  String get test_not_answered => 'Not answered';
  String get test_finish_title => 'Finish Test';
  String get test_finish_unanswered_prompt =>
      'You have {count} unanswered question(s). Do you still want to finish the test?';
  String get test_finish_prompt => 'Do you want to finish the test?';
  String get test_finish_no => 'No';
  String get test_finish_yes => 'Yes';
  String get test_result_congratulations => 'Congratulations!';
  String get test_result_not_quite_there => 'Not Quite There';
  String get test_result_passed_badge => 'PASSED';
  String get test_result_failed_badge => 'FAILED';
  String get test_result_pass_message => 'You have passed the test. Well done!';
  String get test_result_fail_message =>
      'Keep practicing and try again. You can do it!';
  String get test_result_go_back => 'Go Back';
  String get test_result_see_results => 'See Results';
  String get test_result_screen_passed_title => 'Test Passed';
  String get test_result_screen_failed_title => 'Test Failed';
  String get test_result_question_review => 'Question Review';
  String get test_result_score_label => 'Score';
  String get test_result_passed_message => 'Great job! You passed the test.';
  String get test_result_need_to_pass =>
      'Keep practicing. You need {score}% to pass.';
  String get test_result_correct => 'Correct';
  String get test_result_wrong => 'Wrong';
  String get test_result_skipped => 'Skipped';
  String get test_result_above_pass_mark => '{gap}% above pass mark';
  String get test_result_below_pass_mark => '{gap}% below pass mark';
  String get test_result_your_results => 'Your Results';
  String get test_result_your_score => 'Your score';
  String get test_result_pass_mark => 'Pass mark';
  String get test_result_correct_answers => 'Correct answers';
  String get test_result_wrong_answers => 'Wrong answers';
  String get test_result_question_row => 'Q{n}: {text}';
  String get test_result_your_answer => 'Your answer: {answer}';
  String get error_too_many_requests =>
      'Too many attempts. Please try again in {wait}.';
  String get error_service_unavailable =>
      'Service temporarily unavailable. Please try again in a moment.';
  String get error_connection_timeout =>
      'Connection timed out. Check your internet and try again.';
  String get error_session_expired =>
      'Your session has expired. Please log in again.';
  String get error_logged_out_other_device =>
      'You were logged out because your account was used on another device.';
  String get app_download_title => 'Better on the app';
  String get app_download_subtitle_android =>
      'Download the Drive Test app on Google Play for a faster, smoother experience.';
  String get app_download_subtitle_ios =>
      'Download the Drive Test app on the App Store for a faster, smoother experience.';
  String get app_download_cta_android => 'Download on Google Play';
  String get app_download_cta_ios => 'Download on the App Store';
  String get app_download_learn_more => 'Learn more at drivetest.se';
  String get app_download_dismiss => 'Continue in browser';
  String get journey_title => 'Learning Journey';
  String get journey_start => 'Start';
  String get journey_continue => 'Continue';
  String get journey_start_subtitle => 'Start your guided learning journey';
  String get journey_complete => 'Journey complete!';
  String get journey_overall_progress => 'Overall Progress';
  String get journey_stages => 'Stages';
  String get journey_stage_n => 'Stage {n}';
  String get journey_stage_locked => 'Complete previous stage to unlock';
  String get journey_stages_to_unlock_review => 'Complete all stages to unlock';
  String get journey_review_mode => 'Review Mode';
  String get journey_review_locked => 'Complete Review Mode to unlock';
  String get journey_mastered_count => '{done} / {total} mastered';
  String get journey_review_count => '{count} questions to review';
  String get journey_all_mastered => 'All questions mastered!';
  String get journey_full_test_n => 'Full {n}-Question Test';
  String get journey_test_all => 'Test all questions from this group';
  String get node_group_prefix => 'Group';
  String get journey_passed_score => 'Passed! Score: {score}%';
  String get journey_stage_complete_title => 'Stage {n} Complete!';
  String get journey_review_complete_title => 'Review Complete!';
  String get journey_full_test_unlocked => 'Full test ready';
  String get journey_review_ready => 'Review mode ready';
  String get journey_all_groups_done => 'All groups done — Mega Review';
  String get journey_group_stage_progress =>
      'Group {group} — Stage {done} / {total}';
  String get journey_group_full_test_ready => 'Group {group} — Full test ready';
  String get journey_group_review_ready => 'Group {group} — Review mode ready';
  String get journey_loading_questions => 'Loading questions…';
  String get journey_group_unlocked => 'Group {n} unlocked!';
  String get journey_all_groups_complete => 'All groups done!';
  String get journey_group_complete => 'Group {n} complete!';
  String get journey_state_mastered => 'Mastered';
  String get journey_state_review => 'Review';
  String get journey_state_repeat => 'Repeat soon';
  String get journey_state_correct => 'Correct';
  String get journey_state_practiced => 'Practiced';
  String get journey_correct_toward_mastery =>
      'Correct! ({count}/3 toward mastery)';
  String get journey_try_again => 'Try again — progress reset';
  String get journey_failed_load => 'Failed to load journey';
  String get journey_retry => 'Retry';
  String get journey_questions_not_ready =>
      'Questions not loaded yet. Please wait.';
  String get journey_mastered_label => 'Mastered';
  String get journey_needs_review_label => 'Needs Review';
  String get journey_total_label => 'Total';
  String get journey_review_unlocked_msg =>
      'All questions mastered. The Full Test is now unlocked!';
  String get journey_back_to_group => 'Back to Group';
  String get journey_no_review_questions => 'No questions to review!';
  String get question_tab_label => 'Tab';
  String get bcd_min_label => 'min';
  String get ai_assistant => 'AI Assistant';
  String get ai_greeting =>
      'Hi! What would you like to know about this question?';
  String get ai_initializing => 'Initializing AI...';
  String get ai_input_hint => 'Ask a question...';
  String get ai_error => 'Something went wrong. Please try again.';
  String get ai_tooltip => 'AI Assistant';
  String get ai_hint_button => 'Give me a hint';
  String get ai_understand_button => 'Help me understand this';
  String get ai_continue_button => 'Continue chat';
  String get ai_greeting_full =>
      'Need help with this question? Pick one of the options below, or ask your own question.';
  String get ai_read_aloud => 'Read aloud';
  String get option_image_unavailable => 'Image not available';
  String get ai_close => 'Close';
  String get smart_learning_title => 'Smart Learning';
  String get smart_learning_subtitle =>
      'Train chunk by chunk, master your weak spots';
  String smart_chunk_n({required Object n}) => 'Part ${n}';
  String get smart_chunk_passed => 'Passed';
  String get smart_chunk_locked => 'Locked';
  String get smart_chunk_active => 'Start';
  String get smart_chunk_retry => 'Retry';
  String get smart_review_n => 'Review';
  String smart_review_subtitle({required Object count}) =>
      '${count} questions · All previous parts';
  String get smart_full_exam => 'Full Exam';
  String get smart_full_exam_locked => 'Complete all parts to unlock';
  String get smart_full_exam_ready => 'Full exam ready';
  String get smart_hearts_guide_title => 'Playing with lives';
  String get smart_hearts_guide_body =>
      'Each wrong answer costs a heart ❤️. Lose all 3 and you\'ll be taken back — complete the earlier parts to unlock the full exam.';
  String get smart_hearts_guide_got_it => 'Got it';
  String get smart_hearts_game_over_title => 'Sorry, practice more!';
  String get smart_hearts_game_over_body =>
      'You made 3 mistakes. Keep practising the parts before trying the full exam again.';
  String get smart_hearts_keep_practising => 'Keep Practising';
  String get smart_hearts_3_left => '3 left';
  String get smart_hearts_2_left => '2 left';
  String get smart_hearts_1_left => '1 left';
  String get smart_hearts_0_left => '0 left';
  String smart_full_exam_q_of(
          {required Object current, required Object total}) =>
      '${current} / ${total}';
  String smart_train_mistakes({required Object count}) =>
      'Train Mistakes (${count})';
  String get smart_practice_mode => 'Practice';
  String get smart_timed_mode => 'Timed Exam';
  String get smart_attempt_final_exam => 'Attempt Final Exam';
  String smart_questions_count({required Object count}) => '${count} questions';
  String get smart_part_pass_requirement => 'Pass this part with 70%';
  String get smart_not_started => 'Not started';
  String smart_chunks_done({required Object done, required Object total}) =>
      '${done} of ${total} parts done';
  String get smart_result_passed => 'Part passed!';
  String get smart_result_failed => 'Not quite — try again';
  String smart_result_weak_updated({required Object count}) =>
      '${count} weak questions updated';
  String get smart_result_continue => 'Continue';
  String get smart_no_exams => 'No exams available for Smart Learning yet';
  String get smart_mistakes_title => 'Practice Mistakes';
  String get smart_mistakes_none_category =>
      'No mistakes to practice in this category.';
  String get smart_mistakes_load_failed => 'Could not load mistake questions.';
  String smart_mistakes_to_review({required Object count}) =>
      '${count} mistake to review';
  String get smart_progress_title => 'Your Progress';
  String get smart_progress_ready_full_exam => 'Ready for full exam!';
  String get smart_progress_required_to_pass => '70% required to pass';
  String get smart_full_exam_early_attempt =>
      'You can attempt the final timed exam now, even before completing all parts.';
  String get smart_full_exam_early_rules =>
      'You will get 3 lives and instant marking until you complete every part.';
  String get smart_full_exam_completed_parts => 'You completed the parts.';
  String get smart_full_exam_completed_rules =>
      'Your answers will be checked at the end.';
  String smart_category_completed(
          {required Object count, required Object examLabel}) =>
      '${count} ${examLabel} • Completed';
  String smart_category_not_started(
          {required Object count, required Object examLabel}) =>
      '${count} ${examLabel} • Not started';
  String smart_category_parts_done(
          {required Object count,
          required Object examLabel,
          required Object done,
          required Object total}) =>
      '${count} ${examLabel} • ${done}/${total} parts done';
  String get smart_category_exam => 'exam';
  String get smart_category_exams => 'exams';
  String smart_category_mistakes_subtitle(
          {required Object count, required Object questionLabel}) =>
      '${count} ${questionLabel} to review across this category';
  String get smart_category_question => 'question';
  String get smart_category_questions => 'questions';
  String smart_result_unlock_needed({required Object count}) =>
      'Master ${count} questions to unlock the full exam.';
  String smart_result_unlock_remaining(
          {required Object count, required Object questionLabel}) =>
      '${count} more ${questionLabel} to master and you\'ll unlock the full exam.';
  String get smart_result_part_passed_caps => 'PART PASSED';
  String get smart_result_try_again_caps => 'TRY AGAIN';
  String get smart_result_overall_mastery => 'Overall Mastery';
  String get smart_result_threshold => '70% to pass';
  String smart_mastered_of({required Object mastered, required Object total}) =>
      '${mastered} / ${total} mastered';
  String smart_in_a_row({required Object n}) => '${n} in a row';
  String get smart_exit_title => 'Leave Smart Learning?';
  String get smart_exit_body => 'Your current session progress will be lost.';
  String get smart_feedback_correct => 'Correct!';
  String get smart_feedback_incorrect => 'Incorrect';
  String get smart_feedback_correct_answer => 'Correct Answer:';
  String get edit_profile_load_failed => 'Failed to load profile data.';
  String get edit_profile_username_required => 'Username is required.';
  String get edit_profile_updated => 'Profile updated.';
  String get edit_profile_password_set => 'Password set successfully.';
  String get edit_profile_demo_warning =>
      'Demo accounts cannot change username or email.';
  String get edit_profile_google_info =>
      'You are signed in with Google. Password changes are managed through your Google account.';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on Translations {
  dynamic _flatMapFunction(String path) {
    switch (path) {
      case 'home':
        return 'Home';
      case 'tests':
        return 'Tests';
      case 'profile':
        return 'Profile';
      case 'welcome_message':
        return 'Welcome to Drive Test';
      case 'save':
        return 'Save';
      case 'cancel':
        return 'Cancel';
      case 'delete':
        return 'Delete';
      case 'logout':
        return 'Logout';
      case 'loading':
        return 'Loading...';
      case 'settings_title':
        return 'Settings';
      case 'settings_appearance':
        return 'Appearance';
      case 'settings_test_prefs':
        return 'Test Preferences';
      case 'settings_timed_test':
        return 'Timed Test';
      case 'settings_timed_test_sub':
        return 'Enable a time limit for the test';
      case 'settings_instant_marking':
        return 'Instant Marking';
      case 'settings_instant_marking_sub':
        return 'Show correct answer after each question';
      case 'settings_num_questions':
        return 'Number of Questions';
      case 'settings_enter_num':
        return 'Enter number of questions:';
      case 'settings_include_saved':
        return 'Include Saved Questions';
      case 'settings_include_saved_sub':
        return 'Include questions you previously saved';
      case 'settings_notifications':
        return 'Notifications';
      case 'settings_notifications_toggle':
        return 'Push Notifications';
      case 'settings_notifications_on_sub':
        return 'You will receive exam reminders and updates';
      case 'settings_notifications_off_sub':
        return 'Notifications are turned off';
      case 'settings_notifications_denied':
        return 'Permission denied — tap below to open Settings';
      case 'settings_notifications_open_settings':
        return 'Open Settings';
      case 'settings_dark_mode':
        return 'Dark Mode';
      case 'settings_dark_mode_sub':
        return 'Switch between light and dark theme';
      case 'settings_language':
        return 'Language';
      case 'settings_language_sub':
        return 'Choose your preferred language';
      case 'settings_version':
        return 'Version Information';
      case 'settings_app_version':
        return 'App Version';
      case 'settings_commit':
        return 'Commit';
      case 'settings_branch':
        return 'Branch';
      case 'settings_last_update':
        return 'Last Update';
      case 'settings_date':
        return 'Date';
      case 'settings_saved':
        return 'Settings saved successfully';
      case 'profile_student':
        return 'STUDENT';
      case 'profile_view_profile':
        return 'View Profile';
      case 'profile_edit':
        return 'Edit profile';
      case 'profile_section_preferences':
        return 'Preferences';
      case 'profile_section_resources':
        return 'Resources';
      case 'profile_stats':
        return 'My stats';
      case 'profile_statistics':
        return 'Statistics';
      case 'stats_no_tests_yet':
        return 'No completed tests yet';
      case 'stats_attempt_history':
        return 'ATTEMPT HISTORY';
      case 'stats_avg_time':
        return 'Avg time';
      case 'stats_attempt_one':
        return 'attempt';
      case 'stats_attempt_many':
        return 'attempts';
      case 'stats_avg_label':
        return 'Avg';
      case 'stats_unknown':
        return 'Unknown';
      case 'stats_best':
        return 'Best';
      case 'stats_average':
        return 'Average';
      case 'stats_completed_tests':
        return 'Completed tests';
      case 'stats_pass_rate':
        return 'Pass rate';
      case 'stats_best_score':
        return 'Best score';
      case 'stats_average_score':
        return 'Average score';
      case 'stats_total_study_time':
        return 'Total study time';
      case 'stats_latest_result':
        return 'Latest result';
      case 'stats_per_test_breakdown':
        return 'Per-test breakdown';
      case 'stats_all_attempts':
        return 'All attempts';
      case 'home_attempt_details':
        return 'Attempt Details';
      case 'home_saved_questions_title':
        return 'Saved Questions';
      case 'profile_settings':
        return 'Settings';
      case 'profile_invite':
        return 'Invite a friend';
      case 'profile_help':
        return 'Help';
      case 'profile_manage_subscription':
        return 'Manage Subscription';
      case 'profile_purchase_history':
        return 'Purchase History';
      case 'profile_receipt_title':
        return 'Receipt';
      case 'profile_receipt_copy_number':
        return 'Copy receipt number';
      case 'profile_receipt_number_copied':
        return 'Receipt number copied';
      case 'profile_no_purchases':
        return 'No purchases yet.';
      case 'profile_receipt_payment_receipt':
        return 'Payment Receipt';
      case 'profile_receipt_no':
        return 'Receipt no.';
      case 'profile_receipt_product':
        return 'Product';
      case 'profile_receipt_duration':
        return 'Duration';
      case 'profile_receipt_amount_paid':
        return 'Amount paid';
      case 'profile_receipt_payment_via':
        return 'Payment via';
      case 'profile_receipt_via_iap':
        return 'Apple App Store';
      case 'profile_receipt_via_card':
        return 'Card (Stripe)';
      case 'profile_receipt_transaction_id':
        return 'Transaction ID';
      case 'profile_receipt_payment_intent':
        return 'Payment intent';
      case 'profile_receipt_reference_no':
        return 'Reference no.';
      case 'profile_receipt_footer':
        return 'Keep this receipt for your records. Contact support with your receipt number if you have questions about this purchase.';
      case 'profile_revisit_setup':
        return 'Revisit Setup';
      case 'profile_send_feedback':
        return 'Send Feedback';
      case 'profile_logout_confirm':
        return 'Are you sure you want to log out?';
      case 'profile_yes_logout':
        return 'Yes, Logout';
      case 'home_dashboard':
        return 'Dashboard';
      case 'home_my_progress':
        return 'My Progress';
      case 'home_overall_score':
        return 'Overall Score';
      case 'home_passed':
        return 'Passed';
      case 'home_failed':
        return 'Failed';
      case 'home_total':
        return 'Total';
      case 'home_in_progress':
        return 'In Progress';
      case 'home_recent_activity':
        return 'Recent Activity';
      case 'home_by_category':
        return 'By Category';
      case 'home_this_week':
        return 'This Week';
      case 'home_this_month':
        return 'This Month';
      case 'home_no_attempts':
        return 'No attempts yet!';
      case 'home_no_attempts_sub':
        return 'Once you complete a quiz, your results will show up here.';
      case 'home_take_quiz':
        return 'Take Your First Quiz';
      case 'home_paused':
        return 'Paused';
      case 'home_started':
        return 'Started';
      case 'home_resume':
        return 'Resume';
      case 'home_attempts':
        return 'attempts';
      case 'home_active':
        return 'active';
      case 'home_tests':
        return 'tests';
      case 'home_quick_access':
        return 'Quick Access';
      case 'home_qa_start_test':
        return 'Practice Test';
      case 'home_qa_custom_test':
        return 'Custom Test';
      case 'home_qa_saved_questions':
        return 'Saved Questions';
      case 'home_qa_settings':
        return 'Settings';
      case 'intro_slide1_body':
        return 'Learn and practice for your license with ease.';
      case 'intro_slide2_title':
        return 'Interactive Tests';
      case 'intro_slide2_body':
        return 'Practice tests with real-time feedback and explanations.';
      case 'intro_slide3_title':
        return 'Get Certified';
      case 'intro_slide3_body':
        return 'Ace your exams and become a certified driver.';
      case 'intro_skip':
        return 'Skip';
      case 'intro_get_started':
        return 'Get Started';
      case 'auth_welcome_title':
        return 'Welcome to Drive Test!';
      case 'auth_welcome_subtitle':
        return 'Practice. Pass with confidence.';
      case 'auth_login_btn':
        return 'LOGIN';
      case 'auth_signup_btn':
        return 'SIGNUP';
      case 'auth_skip_demo':
        return 'SKIP FOR NOW (TRY DEMO)';
      case 'auth_demo_error':
        return 'Failed to login with demo account. Please try again.';
      case 'auth_or':
        return 'OR';
      case 'auth_login_title':
        return 'Login';
      case 'auth_contact_support':
        return 'Contact support';
      case 'auth_username':
        return 'Username or Email';
      case 'auth_email':
        return 'Email';
      case 'auth_password':
        return 'Password';
      case 'auth_remember_me':
        return 'Remember me';
      case 'auth_forgot_password':
        return 'Forgot Password?';
      case 'auth_invalid_credentials':
        return 'Invalid username or password';
      case 'auth_no_account':
        return 'Don\'t have an account? ';
      case 'auth_sign_up_link':
        return 'Sign up';
      case 'auth_skip_demo_short':
        return 'Skip for now (Try Demo)';
      case 'auth_google_continue':
        return 'Continue with Google';
      case 'auth_feedback_type':
        return 'Type';
      case 'auth_feedback_email_optional':
        return 'Email (optional)';
      case 'auth_feedback_subject_optional':
        return 'Subject (optional)';
      case 'auth_feedback_message':
        return 'Message';
      case 'auth_feedback_sent':
        return 'Thanks! Your feedback was sent.';
      case 'auth_feedback_error':
        return 'Could not send feedback. Please try again.';
      case 'auth_submit':
        return 'Submit';
      case 'auth_feedback_login_issue':
        return 'Login issue';
      case 'auth_feedback_signup_issue':
        return 'Signup issue';
      case 'auth_feedback_app_issue':
        return 'App issue';
      case 'auth_feedback_feature_request':
        return 'Feature request';
      case 'auth_feedback_payment_issue':
        return 'Payment issue';
      case 'auth_feedback_other':
        return 'Other';
      case 'auth_create_account':
        return 'Create Account';
      case 'auth_sign_up_btn':
        return 'Sign Up';
      case 'auth_val_username_required':
        return 'Please enter your username or email';
      case 'auth_val_username_length':
        return 'Username must be at least 4 characters';
      case 'auth_val_email_required':
        return 'Please enter an email';
      case 'auth_val_email_invalid':
        return 'Please enter a valid email';
      case 'auth_val_password_required':
        return 'Please enter a password';
      case 'auth_val_password_length':
        return 'Password must be at least 6 characters';
      case 'auth_signup_success':
        return 'Signup successful! Please login.';
      case 'auth_welcome_first_login':
        return 'Welcome. Enjoy exam prep.';
      case 'auth_welcome_returning':
        return 'Welcome back again.';
      case 'auth_deleted_account_welcome_back':
        return 'Always welcome back.';
      case 'auth_signup_failed':
        return 'Signup failed. Please correct the errors.';
      case 'auth_generic_error':
        return 'An error occurred. Please try again.';
      case 'auth_express_google':
        return 'Continue with Google';
      case 'auth_or_continue_with':
        return 'or continue with';
      case 'auth_google_label':
        return 'Google';
      case 'auth_express_apple':
        return 'Continue with Apple';
      case 'auth_more_options':
        return 'More options';
      case 'auth_apple_label':
        return 'Apple';
      case 'auth_signing_in':
        return 'Signing in...';
      case 'auth_tab_login':
        return 'Log in';
      case 'auth_tab_signup':
        return 'Sign up';
      case 'auth_show_password':
        return 'Show';
      case 'auth_hide_password':
        return 'Hide';
      case 'auth_forgot_title':
        return 'Forgot Password';
      case 'auth_forgot_heading':
        return 'Reset Your Password';
      case 'auth_forgot_subtitle':
        return 'Enter your email address and we\'ll send you instructions to reset your password.';
      case 'auth_forgot_email_label':
        return 'Email Address';
      case 'auth_forgot_send_btn':
        return 'Send Reset Instructions';
      case 'auth_forgot_back_login':
        return 'Back to Login';
      case 'auth_forgot_success':
        return 'Password reset instructions have been sent to your email.';
      case 'auth_forgot_error':
        return 'Failed to send reset email. Please try again.';
      case 'auth_verify_title':
        return 'Verify Code';
      case 'auth_verify_heading':
        return 'Check Your Email';
      case 'auth_verify_subtitle':
        return 'We sent a reset code to\n{email}';
      case 'auth_verify_code_label':
        return 'Reset Code';
      case 'auth_verify_code_hint':
        return 'Enter the code from your email';
      case 'auth_verify_code_empty':
        return 'Please enter the reset code from your email.';
      case 'auth_verify_resend':
        return 'Resend Code';
      case 'auth_reset_title':
        return 'Reset Password';
      case 'auth_reset_heading':
        return 'Set New Password';
      case 'auth_reset_subtitle':
        return 'Please enter your new password';
      case 'auth_reset_new_password_label':
        return 'New Password';
      case 'auth_reset_confirm_password_label':
        return 'Confirm Password';
      case 'auth_reset_empty':
        return 'Please enter a new password.';
      case 'auth_reset_mismatch':
        return 'Passwords do not match.';
      case 'auth_reset_invalid_code':
        return 'Invalid or expired reset code. Please try requesting a new reset link.';
      case 'auth_reset_success_title':
        return 'Success!';
      case 'auth_reset_success_body':
        return 'Your password has been reset successfully. You can now log in with your new password.';
      case 'auth_reset_go_to_login':
        return 'Go to Login';
      case 'auth_google_connecting':
        return 'Connecting to Google...';
      case 'auth_apple_connecting':
        return 'Connecting to Apple...';
      case 'auth_google_verifying':
        return 'Verifying account...';
      case 'auth_google_signing_in':
        return 'Signing you in...';
      case 'auth_google_creating':
        return 'Creating your account...';
      case 'auth_google_loading':
        return 'Loading your profile...';
      case 'auth_landing_subtitle':
        return 'Your journey to excellence starts with a single tap.';
      case 'auth_landing_new_here':
        return 'New here?';
      case 'auth_create_account_link':
        return 'Create an account';
      case 'auth_login_heading':
        return 'Welcome\nBack';
      case 'auth_login_subtitle':
        return 'Continue your kinetic journey.';
      case 'auth_username_hint':
        return 'username or email';
      case 'auth_signup_heading_plain':
        return 'Join the';
      case 'auth_signup_heading_italic':
        return 'Movement.';
      case 'auth_signup_subtitle':
        return 'Accelerate your learning journey today.';
      case 'auth_signup_username_hint':
        return 'Erik Andersson';
      case 'auth_signup_email_hint':
        return 'erik@example.se';
      case 'auth_have_account':
        return 'Already have an account?';
      case 'auth_reset_onboarding_tooltip':
        return 'Reset Onboarding';
      case 'auth_language_english':
        return 'English';
      case 'auth_language_swedish':
        return 'Swedish';
      case 'brand_drive':
        return 'DRIVE ';
      case 'brand_test':
        return 'TEST';
      case 'purchase_success_title':
        return 'Your Purchase has\nbeen confirmed';
      case 'purchase_success_start_tests':
        return 'Start Tests';
      case 'purchase_success_back_home':
        return 'Back to home';
      case 'bcd_drive_test':
        return 'Drive Test';
      case 'bcd_exams':
        return 'Exams';
      case 'bcd_exams_sub':
        return 'Licences, categories & tests';
      case 'bcd_traffic_signs':
        return 'Traffic Signs';
      case 'bcd_traffic_signs_sub':
        return 'Browse all traffic signs';
      case 'bcd_subscriptions':
        return 'Subscriptions';
      case 'bcd_subscriptions_sub':
        return 'View plans & manage access';
      case 'bcd_hub_practice':
        return 'Practice';
      case 'bcd_hub_tests':
        return 'Tests';
      case 'bcd_hub_theory_docs':
        return 'Theory\nDocuments';
      case 'bcd_hub_traffic_signs':
        return 'Traffic Signs';
      case 'bcd_hub_checklist':
        return 'Checklist';
      case 'checklist_language_subtitle':
        return 'Translate checklist to your language';
      case 'bcd_hub_statistics':
        return 'Statistics';
      case 'bcd_hub_saved_questions':
        return 'Saved\nQuestions';
      case 'bcd_no_free_practice':
        return 'No free practice test available for this category.';
      case 'bcd_failed_practice':
        return 'Failed to load practice test.';
      case 'bcd_no_saved_questions':
        return 'No saved questions in this category yet.';
      case 'bcd_no_saved_questions_found':
        return 'No saved questions found in this category.';
      case 'bcd_failed_saved':
        return 'Failed to load saved questions.';
      case 'bcd_no_subscription':
        return 'You don\'t have an active subscription for this category';
      case 'bcd_free_content_desc':
        return 'Practice, Traffic Signs, Documents and Checklists are free. Subscribe to unlock Tests.';
      case 'bcd_buy_subscription':
        return 'Buy subscription';
      case 'bcd_buy_subscription_arrow':
        return 'Buy subscription →';
      case 'bcd_not_subscribed':
        return 'You\'re not subscribed to this category';
      case 'bcd_only_free_tests':
        return 'Only free practice tests are available. Subscribe to unlock all tests.';
      case 'bcd_no_free_practice_tests':
        return 'No free practice tests available.';
      case 'bcd_no_tests':
        return 'No tests available.';
      case 'bcd_no_documents':
        return 'No documents available.';
      case 'bcd_no_checklists':
        return 'No checklists available.';
      case 'bcd_failed_tests':
        return 'Failed to load tests';
      case 'bcd_subscription_required':
        return 'Subscription Required';
      case 'bcd_subscribe_access':
        return 'Subscribe to access "{name}" and all its content.';
      case 'bcd_not_now':
        return 'Not now';
      case 'legal_terms_of_use':
        return 'Terms of Use';
      case 'legal_privacy_policy':
        return 'Privacy Policy';
      case 'bcd_buy':
        return 'Buy';
      case 'bcd_payment_failed':
        return 'Payment failed. Please try again.';
      case 'iap_owned_by_other_title':
        return 'Subscription Already Linked';
      case 'iap_owned_by_other_body':
        return 'This subscription is associated with a different account. Please log in with the account you originally purchased it on.';
      case 'iap_owned_by_other_ok':
        return 'OK';
      case 'bcd_feedback_unavailable':
        return 'Feedback is unavailable for this question.';
      case 'bcd_feedback_submitted':
        return 'Thanks! Your feedback was submitted.';
      case 'bcd_feedback_failed':
        return 'Could not submit feedback. Please try again.';
      case 'bcd_categories':
        return 'Categories';
      case 'bcd_search_categories':
        return 'Search categories…';
      case 'bcd_no_categories':
        return 'No categories available.';
      case 'bcd_no_match_search':
        return 'No matches found.';
      case 'bcd_subscribed':
        return 'Subscribed';
      case 'bcd_tap_to_subscribe':
        return 'Tap to subscribe';
      case 'bcd_failed_categories':
        return 'Failed to load categories';
      case 'bcd_plans_tab':
        return 'Plans';
      case 'bcd_my_subscriptions_tab':
        return 'My Subscriptions';
      case 'bcd_no_plans':
        return 'No plans available';
      case 'bcd_active_label':
        return 'Active';
      case 'bcd_expired_label':
        return 'Expired';
      case 'bcd_sub_expires_days':
        return 'Expires in {days} days · {date}';
      case 'bcd_subscribe_btn':
        return 'Subscribe';
      case 'bcd_start_practice':
        return 'Start Practice';
      case 'bcd_no_active_subscriptions':
        return 'No active subscriptions';
      case 'bcd_browse_plans':
        return 'Browse plans to get started';
      case 'bcd_expires':
        return 'Expires';
      case 'bcd_failed_plans':
        return 'Failed to load plans';
      case 'bcd_no_categories_linked':
        return 'No categories linked to this subscription';
      case 'bcd_failed_category':
        return 'Failed to load category';
      case 'bcd_search_signs':
        return 'Search sign groups…';
      case 'bcd_no_signs':
        return 'No signs found';
      case 'bcd_no_image':
        return 'No image';
      case 'bcd_tap_to_zoom':
        return 'Tap to zoom';
      case 'bcd_signs_count_label':
        return 'traffic signs';
      case 'bcd_view':
        return 'View';
      case 'bcd_previous':
        return 'Previous';
      case 'bcd_next':
        return 'Next';
      case 'smart_check':
        return 'Check';
      case 'notif_subtitle':
        return 'DriveTest';
      case 'notif_morning_title':
        return '☀️ Morning study reminder';
      case 'notif_morning_title_exam':
        return ({required Object examTitle}) => '☀️ Time to study ${examTitle}';
      case 'notif_morning_body':
        return 'Start your practice session — build that streak!';
      case 'notif_evening_title':
        return '🌙 Evening streak check-in';
      case 'notif_evening_title_exam':
        return ({required Object examTitle}) =>
            '🌙 ${examTitle} is waiting for you';
      case 'notif_evening_body':
        return 'Don\'t let today slip by — keep your streak alive!';
      case 'notif_activity_0':
        return ({required Object examTitle}) =>
            'You were working on ${examTitle} — one more session and it clicks.';
      case 'notif_activity_1':
        return ({required Object examTitle}) =>
            '${examTitle} is waiting. Your last session built real momentum — don\'t lose it.';
      case 'notif_activity_2':
        return ({required Object examTitle}) =>
            'Small daily sessions beat cramming. Jump back into ${examTitle} now.';
      case 'notif_activity_3':
        return ({required Object examTitle}) =>
            'You\'re closer than you think on ${examTitle}. Keep the streak alive!';
      case 'notif_activity_4':
        return ({required Object examTitle}) =>
            'One focused session on ${examTitle} today makes the exam day easier.';
      case 'bcd_failed_traffic_signs':
        return 'Failed to load traffic signs';
      case 'bcd_search_hint':
        return 'Search…';
      case 'bcd_no_subcategories':
        return 'No sub-categories available.';
      case 'bcd_failed_subcategories':
        return 'Failed to load sub-categories';
      case 'bcd_no_questions':
        return 'No questions found for this test.';
      case 'bcd_failed_test_questions':
        return 'Failed to load test questions.';
      case 'bcd_questions_label':
        return 'questions';
      case 'bcd_pass_label':
        return 'Pass';
      case 'bcd_free_label':
        return 'FREE';
      case 'smart_locked':
        return 'Locked';
      case 'settings_theme_label':
        return 'Theme';
      case 'settings_theme_sub':
        return 'Light, dark or follow system';
      case 'settings_theme_system':
        return 'System';
      case 'settings_theme_light':
        return 'Light';
      case 'settings_theme_dark':
        return 'Dark';
      case 'help_title':
        return 'Help & Support';
      case 'help_need_help':
        return 'Need Help?';
      case 'help_subtitle':
        return 'Tell us about your issue and we\'ll get back to you soon.';
      case 'help_your_information':
        return 'Your Information';
      case 'help_username':
        return 'Username';
      case 'help_email':
        return 'Email';
      case 'help_user_id':
        return 'User ID';
      case 'help_subject':
        return 'Subject';
      case 'help_subject_hint':
        return 'e.g., Login issue, Bug report, Feature request';
      case 'help_subject_required':
        return 'Please enter a subject';
      case 'help_description':
        return 'Description';
      case 'help_description_hint':
        return 'Please describe your issue in detail...';
      case 'help_description_required':
        return 'Please describe your issue';
      case 'help_description_too_short':
        return 'Please provide more details (at least 10 characters)';
      case 'help_submit':
        return 'Submit Report';
      case 'help_or_email':
        return 'Or email us directly at support@drivetest.se';
      case 'help_opening_email':
        return 'Opening email app...';
      case 'help_email_error':
        return 'Could not open email app. Please email support@drivetest.se directly.';
      case 'help_generic_error':
        return 'Error opening email app. Please try again.';
      case 'notifications_title':
        return 'Notifications';
      case 'notifications_mark_all_read':
        return 'Mark all read';
      case 'notifications_clear':
        return 'Clear';
      case 'notifications_clear_confirm_title':
        return 'Clear all notifications?';
      case 'notifications_clear_confirm_body':
        return 'This will remove all notifications. This action cannot be undone.';
      case 'notifications_empty_title':
        return 'No notifications';
      case 'notifications_empty_subtitle':
        return 'You\'re all caught up! We\'ll let you know when something new arrives.';
      case 'notifications_just_now':
        return 'Just now';
      case 'notifications_minutes_ago':
        return '{n} min ago';
      case 'notifications_hours_ago':
        return '{n}h ago';
      case 'notifications_days_ago':
        return '{n}d ago';
      case 'notifications_permission_off_title':
        return 'Notifications are off';
      case 'notifications_permission_denied_body':
        return 'You have denied notification permission. Open Settings to enable them.';
      case 'notifications_permission_not_determined_body':
        return 'Allow notifications to stay updated on your exam progress and reminders.';
      case 'notifications_permission_open_settings':
        return 'Open Settings';
      case 'notifications_permission_enable':
        return 'Enable Notifications';
      case 'notifications_permission_web_dialog_title':
        return 'Enable in browser';
      case 'notifications_permission_web_dialog_body':
        return 'To enable notifications, click the lock icon (🔒) in your browser\'s address bar, find "Notifications", and set it to "Allow". Then refresh the page.';
      case 'notifications_permission_web_dialog_ok':
        return 'Got it';
      case 'image_viewer_swipe_to_close':
        return 'Swipe down to close';
      case 'image_viewer_load_error':
        return 'Could not load image';
      case 'dash_my_progress':
        return 'My Progress';
      case 'dash_sync_from_server':
        return 'Sync from server';
      case 'dash_unknown_error':
        return 'Something went wrong. Please try again.';
      case 'dash_network_error':
        return 'No internet connection. Check your connection and try again.';
      case 'dash_server_error':
        return 'Server error. Please try again later.';
      case 'dash_retry':
        return 'Retry';
      case 'dash_my_exams':
        return 'My Exams';
      case 'dash_tap_to_dive':
        return 'Tap an exam to dive in';
      case 'dash_overview':
        return 'Overview';
      case 'dash_categories_header':
        return 'Categories';
      case 'dash_batches_header':
        return 'Batches';
      case 'dash_expand_categories':
        return 'Expand each category to see batches';
      case 'dash_weekly_streak':
        return 'Weekly Streak';
      case 'dash_consistency_builds':
        return 'Consistency builds mastery';
      case 'dash_smart_insights':
        return 'Smart Insights';
      case 'dash_based_on_attempts':
        return 'Based on your attempts';
      case 'dash_continue_label':
        return 'Continue: {name}';
      case 'dash_total_attempts':
        return 'Total Attempts';
      case 'dash_batches_done':
        return 'Batches Done';
      case 'dash_avg_time':
        return 'Avg Time';
      case 'dash_chunks_mastered':
        return 'Chunks Mastered';
      case 'dash_weak_questions':
        return 'Weak Questions';
      case 'dash_weakest_label':
        return 'Weakest: {name} ({score}%)';
      case 'dash_batches_completed_label':
        return '{done}/{total} batches completed';
      case 'dash_weakness_low_score':
        return 'Low score';
      case 'dash_weakness_over_time':
        return 'Over time';
      case 'dash_weakness_needs_work':
        return 'Needs work';
      case 'dash_weakness_on_track':
        return 'On track';
      case 'dash_not_started':
        return 'Not started';
      case 'dash_attempt_one':
        return '1 attempt';
      case 'dash_attempt_many':
        return '{n} attempts';
      case 'dash_avg_duration':
        return 'Avg {duration}';
      case 'dash_over_time_pct':
        return '+{pct}% time';
      case 'dash_on_time':
        return 'On time';
      case 'dash_insight_strongest':
        return 'Strongest area';
      case 'dash_insight_weakest':
        return 'Weakest area';
      case 'dash_insight_focus':
        return 'Focus recommendation';
      case 'dash_insight_continue_learning':
        return 'Continue learning';
      case 'dash_insight_area_detail':
        return '{name} — {score}% avg';
      case 'dash_insight_focus_detail':
        return 'Work on {name} next to keep progressing';
      case 'dash_insight_start':
        return 'Start with {name} — pick any batch to begin.';
      case 'dash_insight_all_done':
        return 'All batches completed! Revisit low-scoring batches to master them.';
      case 'dash_insight_progress':
        return '{done}/{total} batches passed. Keep going — you\'re {pct}% there!';
      case 'dash_streak_current':
        return 'Current\nStreak';
      case 'dash_streak_best':
        return 'Best\nStreak';
      case 'dash_streak_weekly_goal':
        return 'Weekly goal';
      case 'dash_day_mon':
        return 'M';
      case 'dash_day_tue':
        return 'T';
      case 'dash_day_wed':
        return 'W';
      case 'dash_day_thu':
        return 'T';
      case 'dash_day_fri':
        return 'F';
      case 'dash_day_sat':
        return 'S';
      case 'dash_day_sun':
        return 'S';
      case 'dash_streak_msg_none':
        return 'Start a session today to begin your streak!';
      case 'dash_streak_msg_amazing':
        return 'Amazing! {n} days in a row — keep it up!';
      case 'dash_streak_msg_goal':
        return 'Weekly goal reached! You\'re on fire 🔥';
      case 'dash_streak_msg_progress_one':
        return '{n} day streak! 1 more session to hit your weekly goal.';
      case 'dash_streak_msg_progress_other':
        return '{n} day streak! {left} more sessions to hit your weekly goal.';
      case 'dash_completed':
        return 'Completed!';
      case 'dash_tap_to_explore':
        return 'Tap to explore';
      case 'onb_which_exams':
        return 'Which exams are you preparing for?';
      case 'onb_select_all_apply':
        return 'Select all that apply';
      case 'onb_exam_date_title':
        return 'When is your exam?';
      case 'onb_exam_date_subtitle':
        return 'Set a target date to stay on track';
      case 'onb_practice_days_title':
        return 'How many days a week will you practice?';
      case 'onb_practice_days_subtitle':
        return 'Be realistic — consistency is key';
      case 'onb_recommendations_title':
        return 'Recommended for you';
      case 'onb_recommendations_subtitle':
        return 'Subscribe to unlock full access to these exams';
      case 'onb_continue':
        return 'Continue';
      case 'onb_weekday_mon_short':
        return 'M';
      case 'onb_weekday_tue_short':
        return 'T';
      case 'onb_weekday_wed_short':
        return 'W';
      case 'onb_weekday_thu_short':
        return 'T';
      case 'onb_weekday_fri_short':
        return 'F';
      case 'onb_weekday_sat_short':
        return 'S';
      case 'onb_weekday_sun_short':
        return 'S';
      case 'onb_get_started':
        return 'Get Started';
      case 'onb_1_week':
        return '1 week';
      case 'onb_2_weeks':
        return '2 weeks';
      case 'onb_3_weeks':
        return '3 weeks';
      case 'onb_1_month':
        return '1 month';
      case 'onb_2_months':
        return '2 months';
      case 'onb_3_months':
        return '3 months';
      case 'onb_custom_date':
        return 'Custom date';
      case 'onb_subscribe':
        return 'Subscribe';
      case 'onb_sign_in_to_subscribe':
        return 'Sign in to subscribe';
      case 'onb_sign_in_subtitle':
        return 'Create a free account or log in to unlock full exam access';
      case 'onb_no_exams':
        return 'No exams available right now';
      case 'onb_days_week_label':
        return '{n} days/week';
      case 'onb_step_of':
        return 'Step {current} of {total}';
      case 'onb_weekly_goal_title':
        return 'Weekly Study Goal';
      case 'onb_weekly_goal_sub':
        return 'Select the days you\'ll commit to studying.';
      case 'dash_exam_deadline':
        return 'Exam Deadline';
      case 'dash_days_remaining':
        return '{n} days left';
      case 'dash_deadline_today':
        return 'Today!';
      case 'dash_deadline_passed':
        return 'Deadline passed';
      case 'dash_no_deadline':
        return 'No deadline set';
      case 'dash_set_deadline':
        return 'Set deadline';
      case 'dash_change_deadline':
        return 'Change deadline';
      case 'dash_practice_days':
        return '{n} days/week';
      case 'dash_hero_sub_start':
        return 'Start your learning journey!';
      case 'dash_hero_sub_progress':
        return 'Keep going, you\'re doing great!';
      case 'dash_hero_sub_almost':
        return 'Almost ready for the exam!';
      case 'dash_hero_sub_done':
        return 'All done — great work!';
      case 'dash_performance_overview':
        return 'Performance Overview';
      case 'dash_focus_areas':
        return 'Focus Areas';
      case 'dash_recently_practiced':
        return 'Recent';
      case 'dash_exam_progress':
        return 'Exam Progress';
      case 'dash_cat_complete':
        return 'Complete';
      case 'dash_cat_not_started':
        return 'Not started';
      case 'dash_cat_almost_done':
        return '{n} left to finish!';
      case 'dash_cat_needs_practice':
        return 'Needs practice';
      case 'dash_cat_in_progress':
        return '{done}/{total} done';
      case 'dash_progress_all_done':
        return 'All topics complete!';
      case 'dash_progress_topics_done':
        return '{done} of {total} topics done';
      case 'dash_progress_avg_hint':
        return '{score}% overall avg';
      case 'dash_progress_no_attempts':
        return 'No attempts yet';
      case 'dash_smart_new':
        return 'New';
      case 'dash_quick_access':
        return 'Quick Access';
      case 'dash_item_one':
        return '1 item';
      case 'dash_item_many':
        return '{n} items';
      case 'dash_shortcuts_count':
        return '{n} shortcuts';
      case 'dash_loading_batch':
        return 'Batch {n}';
      case 'dash_loading_category':
        return 'Category {n}';
      case 'dash_no_exams_found':
        return 'No exams found.';
      case 'dash_card_active':
        return 'ACTIVE';
      case 'dash_card_inactive':
        return 'INACTIVE';
      case 'dash_card_expired':
        return 'Expired {date}';
      case 'dash_card_expires_today':
        return 'Expires today';
      case 'dash_card_expires_tomorrow':
        return 'Expires tomorrow';
      case 'dash_card_expires_days':
        return 'Expires in {days} days';
      case 'dash_card_expires_on':
        return 'Expires {date}';
      case 'dash_stat_completed':
        return 'Done';
      case 'dash_stat_none_yet':
        return 'None yet';
      case 'dash_stat_of_n':
        return 'of {total}';
      case 'dash_stat_to_train':
        return 'to train';
      case 'dash_stat_per_session':
        return 'Per session';
      case 'dash_perf_title1':
        return 'Performance';
      case 'dash_perf_title2':
        return 'Overview';
      case 'dash_period_today':
        return 'Today';
      case 'dash_period_7days':
        return '7 Days';
      case 'dash_period_all':
        return 'All Time';
      case 'dash_perf_subtitle':
        return 'Track your progress. Reach your goals.';
      case 'dash_perf_attempts_desc':
        return 'All your attempts in this period';
      case 'dash_perf_batches_desc':
        return 'Progress this period';
      case 'dash_avg_time_per_session':
        return 'Avg. Time / Session';
      case 'dash_perf_time_desc':
        return 'Average time taken per session';
      case 'dash_keep_it_up':
        return 'Keep it up!';
      case 'dash_consistency_today':
        return 'Consistency today, success tomorrow.';
      case 'dash_exam_type_taxi':
        return 'TAXI';
      case 'dash_exam_type_test':
        return 'TEST';
      case 'dash_streak_title':
        return '{n} day streak!';
      case 'dash_streak_days':
        return '{n} days';
      case 'dash_batches_count':
        return '{n} batches';
      case 'dash_avg_score_label':
        return '{score}% avg';
      case 'dash_new_test':
        return '+ New Test';
      case 'dash_no_attempts_yet':
        return 'No attempts yet';
      case 'dash_previous_attempts':
        return 'Previous attempts';
      case 'dash_see_all':
        return 'See all';
      case 'dash_all_attempts':
        return 'All Attempts';
      case 'tut_step1_title':
        return 'Step 1 of 2 — Translate';
      case 'tut_step1_body':
        return 'Tap the language button to open the list, then select English (or any other language).';
      case 'tut_step1b_title':
        return 'Step 1 of 2 — Choose a language';
      case 'tut_step1b_body':
        return 'Tap \'Question Language\' in the menu, then select a language from the list.';
      case 'tut_step1_grid_hint':
        return 'Select a different language below, for example English.';
      case 'tut_step2a_title':
        return 'Step 2 of 2 — Peek original';
      case 'tut_step2a_body':
        return 'Press and hold anywhere on the question (not the options) to temporarily see the original Swedish text.';
      case 'tut_step2b_title':
        return 'Step 2 of 2 — Now release';
      case 'tut_step2b_body':
        return 'Release your finger to go back to the translated text.';
      case 'tut_complete_title':
        return 'You\'re all set!';
      case 'tut_complete_body':
        return 'Great job! You now know how to translate questions and peek at the original text.';
      case 'tut_complete_subtitle':
        return 'You\'re ready to prepare for your taxi exam!';
      case 'tut_start_practicing':
        return 'Start practicing!';
      case 'sg_title':
        return 'Study Goals';
      case 'sg_section_exam_date':
        return 'EXAM DATE';
      case 'sg_section_practice_days':
        return 'PRACTICE DAYS';
      case 'sg_practice_days_sub':
        return 'Pick the days you commit to practising each week.';
      case 'sg_days_per_week':
        return '{n} day(s) / week';
      case 'sg_save':
        return 'Save Settings';
      case 'sg_settings_saved':
        return 'Settings saved!';
      case 'sg_months':
        return 'MONTHS';
      case 'sg_custom_date':
        return 'Custom date';
      case 'sg_deadline_passed':
        return 'Exam date passed';
      case 'sg_days_remaining':
        return '{n} days remaining';
      case 'sg_notif_note':
        return 'You\'ll get two reminders on each practice day — one in the morning and one in the evening — at randomised times to help you build a habit.';
      case 'sg_profile_menu_label':
        return 'Study Goals';
      case 'splash_tagline':
        return 'HELLO SWEDEN';
      case 'splash_loading':
        return 'Preparing your success...';
      case 'splash_footer':
        return 'ACADEMIC EXCELLENCE THROUGH KINETIC LEARNING';
      case 'onb_top_bar_title':
        return 'GET STARTED';
      case 'onb_months':
        return 'MONTHS';
      case 'onb_step1_plain':
        return 'What are you studying ';
      case 'onb_step1_italic':
        return 'for?';
      case 'onb_step2_plain':
        return 'When is your ';
      case 'onb_step2_italic':
        return 'exam?';
      case 'onb_step3_plain':
        return 'Set your weekly ';
      case 'onb_step3_italic':
        return 'goal.';
      case 'onb_step4_plain':
        return 'Your Path to ';
      case 'onb_step4_italic':
        return 'Mastery.';
      case 'onb_step4_subtitle':
        return 'Accelerate your learning with personalised study tools.';
      case 'onb_no_plan_selected':
        return 'No plan selected.';
      case 'onb_buy_bundle':
        return 'Buy bundle — {price}';
      case 'onb_signin_to_purchase_title':
        return 'Sign In to Subscribe';
      case 'onb_signin_to_purchase_subtitle':
        return 'Create a free account or sign in to start your subscription. Your progress and subscription will sync across all your devices.';
      case 'onb_create_account_title':
        return 'Create Your Free Account';
      case 'onb_create_account_subtitle':
        return 'Save your study plan and track your progress across all your devices.';
      case 'onb_start_practicing':
        return 'Start Practicing';
      case 'onb_your_plan_badge':
        return 'YOUR PLAN';
      case 'onb_days_per_week':
        return 'days/week';
      case 'onb_most_popular':
        return 'MOST POPULAR';
      case 'onb_feature_mock_exams':
        return 'Full mock exam library';
      case 'onb_feature_progress_tracking':
        return 'Smart progress tracking';
      case 'onb_feature_explanations':
        return 'Detailed answer explanations';
      case 'onb_feature_ai_tutor':
        return 'Personal AI study coach';
      case 'onb_get_best_deal':
        return 'Get Best Deal';
      case 'onb_best_value':
        return 'BEST VALUE';
      case 'onb_choose_plan':
        return 'Choose Plan';
      case 'onb_bundle_discount_title':
        return 'You\'re getting 20% off';
      case 'onb_bundle_saving':
        return 'Saving {amount}';
      case 'onb_price_unavailable':
        return 'Price unavailable';
      case 'onb_duration_year_access':
        return '{n} year access';
      case 'onb_duration_months_access':
        return '{n} months access';
      case 'onb_duration_one_day':
        return '1 day';
      case 'onb_duration_days':
        return '{n} days';
      case 'onb_free_trial':
        return '7-DAY FREE TRIAL INCLUDED. CANCEL ANYTIME.';
      case 'onb_start_free':
        return 'Continue as Guest';
      case 'onb_skip_for_now':
        return 'Skip for now';
      case 'onb_pre_purchase_title':
        return 'One quick step';
      case 'onb_pre_purchase_subtitle':
        return 'Create a free account to access your subscription on all your devices, or continue as a guest — you can always create one later.';
      case 'onb_pre_purchase_sign_in':
        return 'Sign In / Create Account';
      case 'onb_pre_purchase_guest':
        return 'Continue as Guest';
      case 'auth_continue_as_guest':
        return 'Continue as Guest';
      case 'auth_guest_session_error':
        return 'Could not restore your session. Please try again.';
      case 'free_trial_banner_badge':
        return 'FREE';
      case 'free_trial_banner_title':
        return 'Try road signs — no subscription needed';
      case 'free_trial_banner_subtitle':
        return 'Vägmärkestest is completely free. Practise at your own pace and get a feel for the app before subscribing.';
      case 'free_trial_banner_cta':
        return 'Start Practising';
      case 'guest_banner_title':
        return 'You\'re browsing as a guest';
      case 'guest_banner_subtitle':
        return 'Create a free account to save your progress and sync across all your devices.';
      case 'guest_banner_cta':
        return 'Create Account';
      case 'guest_convert_title':
        return 'Save Your Progress';
      case 'guest_convert_subtitle':
        return 'Create a free account to keep everything you\'ve practised.';
      case 'guest_username_hint':
        return 'Choose a username';
      case 'guest_email_hint':
        return 'Email address';
      case 'guest_password_hint':
        return 'Password (min. 8 characters)';
      case 'guest_convert_cta':
        return 'Create Account';
      case 'dash_free_hub_title':
        return 'Full Exam Practice — Free Content';
      case 'dash_free_hub_subtitle':
        return 'Practice questions, theory documents, checklists and statistics — no subscription needed.';
      case 'dash_free_hub_badge':
        return 'FREE';
      case 'btn_save_changes':
        return 'Save Changes';
      case 'btn_set_password':
        return 'Set Password';
      case 'btn_delete_account':
        return 'Delete My Account';
      case 'delete_account_confirm_body':
        return 'This action is permanent and cannot be undone. All your progress and data will be removed.';
      case 'btn_deleting':
        return 'Deleting...';
      case 'btn_keep_going':
        return 'Keep Going';
      case 'btn_exit':
        return 'Exit';
      case 'btn_save_and_exit':
        return 'Save & Exit';
      case 'btn_submit':
        return 'Submit';
      case 'btn_start_saved_test':
        return 'Start Saved Questions Test';
      case 'btn_buy_now':
        return 'Buy Now';
      case 'btn_pay_now':
        return 'Pay Now';
      case 'home_all_tests_deleted':
        return 'All tests have been deleted.';
      case 'home_delete_progress_title':
        return 'Delete Progress';
      case 'home_delete_progress_body':
        return 'Are you sure you want to delete this saved test?';
      case 'home_delete_all_tests_title':
        return 'Delete All Tests';
      case 'home_delete_all_tests_body':
        return 'Are you sure you want to delete all test attempts?';
      case 'test_time_up_submitting':
        return 'Time is up! Submitting your test.';
      case 'test_first_question':
        return 'This is the first question!';
      case 'test_exit_title':
        return 'Exit Test';
      case 'test_exit_save_prompt':
        return 'Would you like to save your progress?';
      case 'test_save_backend_failed':
        return 'Progress was saved on this device, but sync to your account failed. Please try again.';
      case 'test_feedback_unavailable':
        return 'Feedback is unavailable for this question.';
      case 'test_feedback_title':
        return 'Feedback';
      case 'test_feedback_type':
        return 'Type';
      case 'test_feedback_question_issue':
        return 'Question issue';
      case 'test_feedback_wrong_answer':
        return 'Wrong answer';
      case 'test_feedback_typo':
        return 'Typo/text issue';
      case 'test_feedback_image_issue':
        return 'Image issue';
      case 'test_feedback_other':
        return 'Other';
      case 'test_feedback_hint':
        return 'Tell us what is wrong with this question...';
      case 'test_feedback_submitted':
        return 'Thanks! Your feedback was submitted.';
      case 'test_feedback_failed':
        return 'Could not submit feedback. Please try again.';
      case 'test_translation_failed':
        return 'Translation failed. Please try again.';
      case 'test_language_english':
        return 'English';
      case 'test_language_swedish':
        return 'Svenska';
      case 'test_question_language_title':
        return 'Question Language';
      case 'test_question_language_subtitle':
        return 'Translate questions to your language';
      case 'test_question_language_menu':
        return 'Question Language';
      case 'test_turn_off_timer':
        return 'Turn off timer';
      case 'test_turn_on_timer':
        return 'Turn on timer';
      case 'test_turn_off_instant_marking':
        return 'Turn off instant marking';
      case 'test_turn_on_instant_marking':
        return 'Turn on instant marking';
      case 'test_question_saved':
        return 'Question saved';
      case 'test_question_removed':
        return 'Question removed from saved';
      case 'test_saved':
        return 'Saved';
      case 'test_save_question':
        return 'Save question';
      case 'test_questions_title':
        return 'Questions';
      case 'test_question_progress':
        return '{current} of {total}';
      case 'test_question_label':
        return 'Question {n}';
      case 'test_answered':
        return 'Answered';
      case 'test_not_answered':
        return 'Not answered';
      case 'test_finish_title':
        return 'Finish Test';
      case 'test_finish_unanswered_prompt':
        return 'You have {count} unanswered question(s). Do you still want to finish the test?';
      case 'test_finish_prompt':
        return 'Do you want to finish the test?';
      case 'test_finish_no':
        return 'No';
      case 'test_finish_yes':
        return 'Yes';
      case 'test_result_congratulations':
        return 'Congratulations!';
      case 'test_result_not_quite_there':
        return 'Not Quite There';
      case 'test_result_passed_badge':
        return 'PASSED';
      case 'test_result_failed_badge':
        return 'FAILED';
      case 'test_result_pass_message':
        return 'You have passed the test. Well done!';
      case 'test_result_fail_message':
        return 'Keep practicing and try again. You can do it!';
      case 'test_result_go_back':
        return 'Go Back';
      case 'test_result_see_results':
        return 'See Results';
      case 'test_result_screen_passed_title':
        return 'Test Passed';
      case 'test_result_screen_failed_title':
        return 'Test Failed';
      case 'test_result_question_review':
        return 'Question Review';
      case 'test_result_score_label':
        return 'Score';
      case 'test_result_passed_message':
        return 'Great job! You passed the test.';
      case 'test_result_need_to_pass':
        return 'Keep practicing. You need {score}% to pass.';
      case 'test_result_correct':
        return 'Correct';
      case 'test_result_wrong':
        return 'Wrong';
      case 'test_result_skipped':
        return 'Skipped';
      case 'test_result_above_pass_mark':
        return '{gap}% above pass mark';
      case 'test_result_below_pass_mark':
        return '{gap}% below pass mark';
      case 'test_result_your_results':
        return 'Your Results';
      case 'test_result_your_score':
        return 'Your score';
      case 'test_result_pass_mark':
        return 'Pass mark';
      case 'test_result_correct_answers':
        return 'Correct answers';
      case 'test_result_wrong_answers':
        return 'Wrong answers';
      case 'test_result_question_row':
        return 'Q{n}: {text}';
      case 'test_result_your_answer':
        return 'Your answer: {answer}';
      case 'error_too_many_requests':
        return 'Too many attempts. Please try again in {wait}.';
      case 'error_service_unavailable':
        return 'Service temporarily unavailable. Please try again in a moment.';
      case 'error_connection_timeout':
        return 'Connection timed out. Check your internet and try again.';
      case 'error_session_expired':
        return 'Your session has expired. Please log in again.';
      case 'error_logged_out_other_device':
        return 'You were logged out because your account was used on another device.';
      case 'app_download_title':
        return 'Better on the app';
      case 'app_download_subtitle_android':
        return 'Download the Drive Test app on Google Play for a faster, smoother experience.';
      case 'app_download_subtitle_ios':
        return 'Download the Drive Test app on the App Store for a faster, smoother experience.';
      case 'app_download_cta_android':
        return 'Download on Google Play';
      case 'app_download_cta_ios':
        return 'Download on the App Store';
      case 'app_download_learn_more':
        return 'Learn more at drivetest.se';
      case 'app_download_dismiss':
        return 'Continue in browser';
      case 'journey_title':
        return 'Learning Journey';
      case 'journey_start':
        return 'Start';
      case 'journey_continue':
        return 'Continue';
      case 'journey_start_subtitle':
        return 'Start your guided learning journey';
      case 'journey_complete':
        return 'Journey complete!';
      case 'journey_overall_progress':
        return 'Overall Progress';
      case 'journey_stages':
        return 'Stages';
      case 'journey_stage_n':
        return 'Stage {n}';
      case 'journey_stage_locked':
        return 'Complete previous stage to unlock';
      case 'journey_stages_to_unlock_review':
        return 'Complete all stages to unlock';
      case 'journey_review_mode':
        return 'Review Mode';
      case 'journey_review_locked':
        return 'Complete Review Mode to unlock';
      case 'journey_mastered_count':
        return '{done} / {total} mastered';
      case 'journey_review_count':
        return '{count} questions to review';
      case 'journey_all_mastered':
        return 'All questions mastered!';
      case 'journey_full_test_n':
        return 'Full {n}-Question Test';
      case 'journey_test_all':
        return 'Test all questions from this group';
      case 'node_group_prefix':
        return 'Group';
      case 'journey_passed_score':
        return 'Passed! Score: {score}%';
      case 'journey_stage_complete_title':
        return 'Stage {n} Complete!';
      case 'journey_review_complete_title':
        return 'Review Complete!';
      case 'journey_full_test_unlocked':
        return 'Full test ready';
      case 'journey_review_ready':
        return 'Review mode ready';
      case 'journey_all_groups_done':
        return 'All groups done — Mega Review';
      case 'journey_group_stage_progress':
        return 'Group {group} — Stage {done} / {total}';
      case 'journey_group_full_test_ready':
        return 'Group {group} — Full test ready';
      case 'journey_group_review_ready':
        return 'Group {group} — Review mode ready';
      case 'journey_loading_questions':
        return 'Loading questions…';
      case 'journey_group_unlocked':
        return 'Group {n} unlocked!';
      case 'journey_all_groups_complete':
        return 'All groups done!';
      case 'journey_group_complete':
        return 'Group {n} complete!';
      case 'journey_state_mastered':
        return 'Mastered';
      case 'journey_state_review':
        return 'Review';
      case 'journey_state_repeat':
        return 'Repeat soon';
      case 'journey_state_correct':
        return 'Correct';
      case 'journey_state_practiced':
        return 'Practiced';
      case 'journey_correct_toward_mastery':
        return 'Correct! ({count}/3 toward mastery)';
      case 'journey_try_again':
        return 'Try again — progress reset';
      case 'journey_failed_load':
        return 'Failed to load journey';
      case 'journey_retry':
        return 'Retry';
      case 'journey_questions_not_ready':
        return 'Questions not loaded yet. Please wait.';
      case 'journey_mastered_label':
        return 'Mastered';
      case 'journey_needs_review_label':
        return 'Needs Review';
      case 'journey_total_label':
        return 'Total';
      case 'journey_review_unlocked_msg':
        return 'All questions mastered. The Full Test is now unlocked!';
      case 'journey_back_to_group':
        return 'Back to Group';
      case 'journey_no_review_questions':
        return 'No questions to review!';
      case 'question_tab_label':
        return 'Tab';
      case 'bcd_min_label':
        return 'min';
      case 'ai_assistant':
        return 'AI Assistant';
      case 'ai_greeting':
        return 'Hi! What would you like to know about this question?';
      case 'ai_initializing':
        return 'Initializing AI...';
      case 'ai_input_hint':
        return 'Ask a question...';
      case 'ai_error':
        return 'Something went wrong. Please try again.';
      case 'ai_tooltip':
        return 'AI Assistant';
      case 'ai_hint_button':
        return 'Give me a hint';
      case 'ai_understand_button':
        return 'Help me understand this';
      case 'ai_continue_button':
        return 'Continue chat';
      case 'ai_greeting_full':
        return 'Need help with this question? Pick one of the options below, or ask your own question.';
      case 'ai_read_aloud':
        return 'Read aloud';
      case 'option_image_unavailable':
        return 'Image not available';
      case 'ai_close':
        return 'Close';
      case 'smart_learning_title':
        return 'Smart Learning';
      case 'smart_learning_subtitle':
        return 'Train chunk by chunk, master your weak spots';
      case 'smart_chunk_n':
        return ({required Object n}) => 'Part ${n}';
      case 'smart_chunk_passed':
        return 'Passed';
      case 'smart_chunk_locked':
        return 'Locked';
      case 'smart_chunk_active':
        return 'Start';
      case 'smart_chunk_retry':
        return 'Retry';
      case 'smart_review_n':
        return 'Review';
      case 'smart_review_subtitle':
        return ({required Object count}) =>
            '${count} questions · All previous parts';
      case 'smart_full_exam':
        return 'Full Exam';
      case 'smart_full_exam_locked':
        return 'Complete all parts to unlock';
      case 'smart_full_exam_ready':
        return 'Full exam ready';
      case 'smart_hearts_guide_title':
        return 'Playing with lives';
      case 'smart_hearts_guide_body':
        return 'Each wrong answer costs a heart ❤️. Lose all 3 and you\'ll be taken back — complete the earlier parts to unlock the full exam.';
      case 'smart_hearts_guide_got_it':
        return 'Got it';
      case 'smart_hearts_game_over_title':
        return 'Sorry, practice more!';
      case 'smart_hearts_game_over_body':
        return 'You made 3 mistakes. Keep practising the parts before trying the full exam again.';
      case 'smart_hearts_keep_practising':
        return 'Keep Practising';
      case 'smart_hearts_3_left':
        return '3 left';
      case 'smart_hearts_2_left':
        return '2 left';
      case 'smart_hearts_1_left':
        return '1 left';
      case 'smart_hearts_0_left':
        return '0 left';
      case 'smart_full_exam_q_of':
        return ({required Object current, required Object total}) =>
            '${current} / ${total}';
      case 'smart_train_mistakes':
        return ({required Object count}) => 'Train Mistakes (${count})';
      case 'smart_practice_mode':
        return 'Practice';
      case 'smart_timed_mode':
        return 'Timed Exam';
      case 'smart_attempt_final_exam':
        return 'Attempt Final Exam';
      case 'smart_questions_count':
        return ({required Object count}) => '${count} questions';
      case 'smart_part_pass_requirement':
        return 'Pass this part with 70%';
      case 'smart_not_started':
        return 'Not started';
      case 'smart_chunks_done':
        return ({required Object done, required Object total}) =>
            '${done} of ${total} parts done';
      case 'smart_result_passed':
        return 'Part passed!';
      case 'smart_result_failed':
        return 'Not quite — try again';
      case 'smart_result_weak_updated':
        return ({required Object count}) => '${count} weak questions updated';
      case 'smart_result_continue':
        return 'Continue';
      case 'smart_no_exams':
        return 'No exams available for Smart Learning yet';
      case 'smart_mistakes_title':
        return 'Practice Mistakes';
      case 'smart_mistakes_none_category':
        return 'No mistakes to practice in this category.';
      case 'smart_mistakes_load_failed':
        return 'Could not load mistake questions.';
      case 'smart_mistakes_to_review':
        return ({required Object count}) => '${count} mistake to review';
      case 'smart_progress_title':
        return 'Your Progress';
      case 'smart_progress_ready_full_exam':
        return 'Ready for full exam!';
      case 'smart_progress_required_to_pass':
        return '70% required to pass';
      case 'smart_full_exam_early_attempt':
        return 'You can attempt the final timed exam now, even before completing all parts.';
      case 'smart_full_exam_early_rules':
        return 'You will get 3 lives and instant marking until you complete every part.';
      case 'smart_full_exam_completed_parts':
        return 'You completed the parts.';
      case 'smart_full_exam_completed_rules':
        return 'Your answers will be checked at the end.';
      case 'smart_category_completed':
        return ({required Object count, required Object examLabel}) =>
            '${count} ${examLabel} • Completed';
      case 'smart_category_not_started':
        return ({required Object count, required Object examLabel}) =>
            '${count} ${examLabel} • Not started';
      case 'smart_category_parts_done':
        return (
                {required Object count,
                required Object examLabel,
                required Object done,
                required Object total}) =>
            '${count} ${examLabel} • ${done}/${total} parts done';
      case 'smart_category_exam':
        return 'exam';
      case 'smart_category_exams':
        return 'exams';
      case 'smart_category_mistakes_subtitle':
        return ({required Object count, required Object questionLabel}) =>
            '${count} ${questionLabel} to review across this category';
      case 'smart_category_question':
        return 'question';
      case 'smart_category_questions':
        return 'questions';
      case 'smart_result_unlock_needed':
        return ({required Object count}) =>
            'Master ${count} questions to unlock the full exam.';
      case 'smart_result_unlock_remaining':
        return ({required Object count, required Object questionLabel}) =>
            '${count} more ${questionLabel} to master and you\'ll unlock the full exam.';
      case 'smart_result_part_passed_caps':
        return 'PART PASSED';
      case 'smart_result_try_again_caps':
        return 'TRY AGAIN';
      case 'smart_result_overall_mastery':
        return 'Overall Mastery';
      case 'smart_result_threshold':
        return '70% to pass';
      case 'smart_mastered_of':
        return ({required Object mastered, required Object total}) =>
            '${mastered} / ${total} mastered';
      case 'smart_in_a_row':
        return ({required Object n}) => '${n} in a row';
      case 'smart_exit_title':
        return 'Leave Smart Learning?';
      case 'smart_exit_body':
        return 'Your current session progress will be lost.';
      case 'smart_feedback_correct':
        return 'Correct!';
      case 'smart_feedback_incorrect':
        return 'Incorrect';
      case 'smart_feedback_correct_answer':
        return 'Correct Answer:';
      case 'edit_profile_load_failed':
        return 'Failed to load profile data.';
      case 'edit_profile_username_required':
        return 'Username is required.';
      case 'edit_profile_updated':
        return 'Profile updated.';
      case 'edit_profile_password_set':
        return 'Password set successfully.';
      case 'edit_profile_demo_warning':
        return 'Demo accounts cannot change username or email.';
      case 'edit_profile_google_info':
        return 'You are signed in with Google. Password changes are managed through your Google account.';
      default:
        return null;
    }
  }
}
