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
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
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

	// Translations
	String get home => 'Home';
	String get tests => 'Tests';
	String get profile => 'Profile';
	String get welcome_message => 'Welcome to TaxiQuiz';
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
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'home': return 'Home';
			case 'tests': return 'Tests';
			case 'profile': return 'Profile';
			case 'welcome_message': return 'Welcome to TaxiQuiz';
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
			default: return null;
		}
	}
}
