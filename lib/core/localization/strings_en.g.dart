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
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

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
	String get settings_instant_marking_sub => 'Show correct answer after each question';
	String get settings_num_questions => 'Number of Questions';
	String get settings_enter_num => 'Enter number of questions:';
	String get settings_include_saved => 'Include Saved Questions';
	String get settings_include_saved_sub => 'Include questions you previously saved';
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
	String get profile_edit => 'Edit profile';
	String get profile_stats => 'My stats';
	String get profile_settings => 'Settings';
	String get profile_invite => 'Invite a friend';
	String get profile_help => 'Help';
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
	String get home_no_attempts_sub => 'Once you complete a quiz, your results will show up here.';
	String get home_take_quiz => 'Take Your First Quiz';
	String get home_paused => 'Paused';
	String get home_resume => 'Resume';
	String get home_attempts => 'attempts';
	String get home_active => 'active';
	String get home_tests => 'tests';
	String get intro_slide1_body => 'Learn and practice for your license with ease.';
	String get intro_slide2_title => 'Interactive Tests';
	String get intro_slide2_body => 'Practice tests with real-time feedback and explanations.';
	String get intro_slide3_title => 'Get Certified';
	String get intro_slide3_body => 'Ace your exams and become a certified driver.';
	String get intro_skip => 'Skip';
	String get intro_get_started => 'Get Started';
	String get auth_welcome_title => 'Welcome to Drive Test!';
	String get auth_welcome_subtitle => 'Practice. Pass with confidence.';
	String get auth_login_btn => 'LOGIN';
	String get auth_signup_btn => 'SIGNUP';
	String get auth_skip_demo => 'SKIP FOR NOW (TRY DEMO)';
	String get auth_demo_error => 'Failed to login with demo account. Please try again.';
	String get auth_or => 'OR';
	String get auth_login_title => 'Login';
	String get auth_contact_support => 'Contact support';
	String get auth_username => 'Username';
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
	String get auth_feedback_error => 'Could not send feedback. Please try again.';
	String get auth_submit => 'Submit';
	String get auth_feedback_login_issue => 'Login issue';
	String get auth_feedback_signup_issue => 'Signup issue';
	String get auth_feedback_app_issue => 'App issue';
	String get auth_feedback_feature_request => 'Feature request';
	String get auth_feedback_other => 'Other';
	String get auth_create_account => 'Create Account';
	String get auth_sign_up_btn => 'Sign Up';
	String get auth_val_username_required => 'Please enter a username';
	String get auth_val_username_length => 'Username must be at least 4 characters';
	String get auth_val_email_required => 'Please enter an email';
	String get auth_val_email_invalid => 'Please enter a valid email';
	String get auth_val_password_required => 'Please enter a password';
	String get auth_val_password_length => 'Password must be at least 6 characters';
	String get auth_signup_success => 'Signup successful! Please login.';
	String get auth_welcome_first_login => 'Welcome. Enjoy exam prep.';
	String get auth_welcome_returning => 'Welcome back again.';
	String get auth_deleted_account_welcome_back => 'Always welcome back.';
	String get auth_signup_failed => 'Signup failed. Please correct the errors.';
	String get auth_generic_error => 'An error occurred. Please try again.';
	String get auth_express_google => 'Express login via Google';
	String get auth_google_label => 'Google';
	String get auth_tab_login => 'Log in';
	String get auth_tab_signup => 'Sign up';
	String get auth_show_password => 'Show';
	String get auth_hide_password => 'Hide';
	String get auth_forgot_title => 'Forgot Password';
	String get auth_forgot_heading => 'Reset Your Password';
	String get auth_forgot_subtitle => 'Enter your email address and we\'ll send you instructions to reset your password.';
	String get auth_forgot_email_label => 'Email Address';
	String get auth_forgot_send_btn => 'Send Reset Instructions';
	String get auth_forgot_back_login => 'Back to Login';
	String get auth_forgot_success => 'Password reset instructions have been sent to your email.';
	String get auth_forgot_error => 'Failed to send reset email. Please try again.';
	String get purchase_success_title => 'Your Purchase has\nbeen confirmed';
	String get purchase_success_start_tests => 'Start Tests';
	String get purchase_success_back_home => 'Back to home';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'home': return 'Home';
			case 'tests': return 'Tests';
			case 'profile': return 'Profile';
			case 'welcome_message': return 'Welcome to Drive Test';
			case 'save': return 'Save';
			case 'cancel': return 'Cancel';
			case 'delete': return 'Delete';
			case 'logout': return 'Logout';
			case 'loading': return 'Loading...';
			case 'settings_title': return 'Settings';
			case 'settings_appearance': return 'Appearance';
			case 'settings_test_prefs': return 'Test Preferences';
			case 'settings_timed_test': return 'Timed Test';
			case 'settings_timed_test_sub': return 'Enable a time limit for the test';
			case 'settings_instant_marking': return 'Instant Marking';
			case 'settings_instant_marking_sub': return 'Show correct answer after each question';
			case 'settings_num_questions': return 'Number of Questions';
			case 'settings_enter_num': return 'Enter number of questions:';
			case 'settings_include_saved': return 'Include Saved Questions';
			case 'settings_include_saved_sub': return 'Include questions you previously saved';
			case 'settings_dark_mode': return 'Dark Mode';
			case 'settings_dark_mode_sub': return 'Switch between light and dark theme';
			case 'settings_language': return 'Language';
			case 'settings_language_sub': return 'Choose your preferred language';
			case 'settings_version': return 'Version Information';
			case 'settings_app_version': return 'App Version';
			case 'settings_commit': return 'Commit';
			case 'settings_branch': return 'Branch';
			case 'settings_last_update': return 'Last Update';
			case 'settings_date': return 'Date';
			case 'settings_saved': return 'Settings saved successfully';
			case 'profile_student': return 'STUDENT';
			case 'profile_edit': return 'Edit profile';
			case 'profile_stats': return 'My stats';
			case 'profile_settings': return 'Settings';
			case 'profile_invite': return 'Invite a friend';
			case 'profile_help': return 'Help';
			case 'profile_logout_confirm': return 'Are you sure you want to log out?';
			case 'profile_yes_logout': return 'Yes, Logout';
			case 'home_dashboard': return 'Dashboard';
			case 'home_my_progress': return 'My Progress';
			case 'home_overall_score': return 'Overall Score';
			case 'home_passed': return 'Passed';
			case 'home_failed': return 'Failed';
			case 'home_total': return 'Total';
			case 'home_in_progress': return 'In Progress';
			case 'home_recent_activity': return 'Recent Activity';
			case 'home_by_category': return 'By Category';
			case 'home_this_week': return 'This Week';
			case 'home_this_month': return 'This Month';
			case 'home_no_attempts': return 'No attempts yet!';
			case 'home_no_attempts_sub': return 'Once you complete a quiz, your results will show up here.';
			case 'home_take_quiz': return 'Take Your First Quiz';
			case 'home_paused': return 'Paused';
			case 'home_resume': return 'Resume';
			case 'home_attempts': return 'attempts';
			case 'home_active': return 'active';
			case 'home_tests': return 'tests';
			case 'intro_slide1_body': return 'Learn and practice for your license with ease.';
			case 'intro_slide2_title': return 'Interactive Tests';
			case 'intro_slide2_body': return 'Practice tests with real-time feedback and explanations.';
			case 'intro_slide3_title': return 'Get Certified';
			case 'intro_slide3_body': return 'Ace your exams and become a certified driver.';
			case 'intro_skip': return 'Skip';
			case 'intro_get_started': return 'Get Started';
			case 'auth_welcome_title': return 'Welcome to Drive Test!';
			case 'auth_welcome_subtitle': return 'Practice. Pass with confidence.';
			case 'auth_login_btn': return 'LOGIN';
			case 'auth_signup_btn': return 'SIGNUP';
			case 'auth_skip_demo': return 'SKIP FOR NOW (TRY DEMO)';
			case 'auth_demo_error': return 'Failed to login with demo account. Please try again.';
			case 'auth_or': return 'OR';
			case 'auth_login_title': return 'Login';
			case 'auth_contact_support': return 'Contact support';
			case 'auth_username': return 'Username';
			case 'auth_email': return 'Email';
			case 'auth_password': return 'Password';
			case 'auth_remember_me': return 'Remember me';
			case 'auth_forgot_password': return 'Forgot Password?';
			case 'auth_invalid_credentials': return 'Invalid username or password';
			case 'auth_no_account': return 'Don\'t have an account? ';
			case 'auth_sign_up_link': return 'Sign up';
			case 'auth_skip_demo_short': return 'Skip for now (Try Demo)';
			case 'auth_google_continue': return 'Continue with Google';
			case 'auth_feedback_type': return 'Type';
			case 'auth_feedback_email_optional': return 'Email (optional)';
			case 'auth_feedback_subject_optional': return 'Subject (optional)';
			case 'auth_feedback_message': return 'Message';
			case 'auth_feedback_sent': return 'Thanks! Your feedback was sent.';
			case 'auth_feedback_error': return 'Could not send feedback. Please try again.';
			case 'auth_submit': return 'Submit';
			case 'auth_feedback_login_issue': return 'Login issue';
			case 'auth_feedback_signup_issue': return 'Signup issue';
			case 'auth_feedback_app_issue': return 'App issue';
			case 'auth_feedback_feature_request': return 'Feature request';
			case 'auth_feedback_other': return 'Other';
			case 'auth_create_account': return 'Create Account';
			case 'auth_sign_up_btn': return 'Sign Up';
			case 'auth_val_username_required': return 'Please enter a username';
			case 'auth_val_username_length': return 'Username must be at least 4 characters';
			case 'auth_val_email_required': return 'Please enter an email';
			case 'auth_val_email_invalid': return 'Please enter a valid email';
			case 'auth_val_password_required': return 'Please enter a password';
			case 'auth_val_password_length': return 'Password must be at least 6 characters';
			case 'auth_signup_success': return 'Signup successful! Please login.';
			case 'auth_welcome_first_login': return 'Welcome. Enjoy exam prep.';
			case 'auth_welcome_returning': return 'Welcome back again.';
			case 'auth_deleted_account_welcome_back': return 'Always welcome back.';
			case 'auth_signup_failed': return 'Signup failed. Please correct the errors.';
			case 'auth_generic_error': return 'An error occurred. Please try again.';
			case 'auth_express_google': return 'Express login via Google';
			case 'auth_google_label': return 'Google';
			case 'auth_tab_login': return 'Log in';
			case 'auth_tab_signup': return 'Sign up';
			case 'auth_show_password': return 'Show';
			case 'auth_hide_password': return 'Hide';
			case 'auth_forgot_title': return 'Forgot Password';
			case 'auth_forgot_heading': return 'Reset Your Password';
			case 'auth_forgot_subtitle': return 'Enter your email address and we\'ll send you instructions to reset your password.';
			case 'auth_forgot_email_label': return 'Email Address';
			case 'auth_forgot_send_btn': return 'Send Reset Instructions';
			case 'auth_forgot_back_login': return 'Back to Login';
			case 'auth_forgot_success': return 'Password reset instructions have been sent to your email.';
			case 'auth_forgot_error': return 'Failed to send reset email. Please try again.';
			case 'purchase_success_title': return 'Your Purchase has\nbeen confirmed';
			case 'purchase_success_start_tests': return 'Start Tests';
			case 'purchase_success_back_home': return 'Back to home';
			default: return null;
		}
	}
}

