///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsSv implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsSv({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.sv,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <sv>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsSv _root = this; // ignore: unused_field

	// Translations
	@override String get home => 'Hem';
	@override String get tests => 'Prov';
	@override String get profile => 'Profil';
	@override String get welcome_message => 'Välkommen till TaxiQuiz';
	@override String get save => 'Spara';
	@override String get cancel => 'Avbryt';
	@override String get delete => 'Ta bort';
	@override String get logout => 'Logga ut';
	@override String get loading => 'Laddar...';
	@override String get settings_title => 'Inställningar';
	@override String get settings_appearance => 'Utseende';
	@override String get settings_test_prefs => 'Provpreferenser';
	@override String get settings_timed_test => 'Tidsbegränsat prov';
	@override String get settings_timed_test_sub => 'Aktivera tidsgräns för provet';
	@override String get settings_instant_marking => 'Omedelbar rättning';
	@override String get settings_instant_marking_sub => 'Visa rätt svar efter varje fråga';
	@override String get settings_num_questions => 'Antal frågor';
	@override String get settings_enter_num => 'Ange antal frågor:';
	@override String get settings_include_saved => 'Inkludera sparade frågor';
	@override String get settings_include_saved_sub => 'Inkludera frågor du tidigare sparat';
	@override String get settings_dark_mode => 'Mörkt läge';
	@override String get settings_dark_mode_sub => 'Växla mellan ljust och mörkt tema';
	@override String get settings_language => 'Språk';
	@override String get settings_language_sub => 'Välj ditt föredragna språk';
	@override String get settings_version => 'Versionsinformation';
	@override String get settings_app_version => 'Appversion';
	@override String get settings_commit => 'Commit';
	@override String get settings_branch => 'Gren';
	@override String get settings_last_update => 'Senaste uppdatering';
	@override String get settings_date => 'Datum';
	@override String get settings_saved => 'Inställningar sparades';
	@override String get profile_student => 'STUDENT';
	@override String get profile_edit => 'Redigera profil';
	@override String get profile_stats => 'Mina resultat';
	@override String get profile_settings => 'Inställningar';
	@override String get profile_invite => 'Bjud in en vän';
	@override String get profile_help => 'Hjälp';
	@override String get profile_logout_confirm => 'Är du säker på att du vill logga ut?';
	@override String get profile_yes_logout => 'Ja, logga ut';
	@override String get home_dashboard => 'Instrumentpanel';
	@override String get home_my_progress => 'Min framsteg';
	@override String get home_overall_score => 'Totalt resultat';
	@override String get home_passed => 'Godkänd';
	@override String get home_failed => 'Underkänd';
	@override String get home_total => 'Totalt';
	@override String get home_in_progress => 'Pågående';
	@override String get home_recent_activity => 'Senaste aktivitet';
	@override String get home_by_category => 'Per kategori';
	@override String get home_this_week => 'Denna vecka';
	@override String get home_this_month => 'Denna månad';
	@override String get home_no_attempts => 'Inga försök än!';
	@override String get home_no_attempts_sub => 'När du slutfört ett prov visas dina resultat här.';
	@override String get home_take_quiz => 'Ta ditt första prov';
	@override String get home_paused => 'Pausad';
	@override String get home_resume => 'Återuppta';
	@override String get home_attempts => 'försök';
	@override String get home_active => 'aktiv';
	@override String get home_tests => 'prov';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on TranslationsSv {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'home': return 'Hem';
			case 'tests': return 'Prov';
			case 'profile': return 'Profil';
			case 'welcome_message': return 'Välkommen till TaxiQuiz';
			case 'save': return 'Spara';
			case 'cancel': return 'Avbryt';
			case 'delete': return 'Ta bort';
			case 'logout': return 'Logga ut';
			case 'loading': return 'Laddar...';
			case 'settings_title': return 'Inställningar';
			case 'settings_appearance': return 'Utseende';
			case 'settings_test_prefs': return 'Provpreferenser';
			case 'settings_timed_test': return 'Tidsbegränsat prov';
			case 'settings_timed_test_sub': return 'Aktivera tidsgräns för provet';
			case 'settings_instant_marking': return 'Omedelbar rättning';
			case 'settings_instant_marking_sub': return 'Visa rätt svar efter varje fråga';
			case 'settings_num_questions': return 'Antal frågor';
			case 'settings_enter_num': return 'Ange antal frågor:';
			case 'settings_include_saved': return 'Inkludera sparade frågor';
			case 'settings_include_saved_sub': return 'Inkludera frågor du tidigare sparat';
			case 'settings_dark_mode': return 'Mörkt läge';
			case 'settings_dark_mode_sub': return 'Växla mellan ljust och mörkt tema';
			case 'settings_language': return 'Språk';
			case 'settings_language_sub': return 'Välj ditt föredragna språk';
			case 'settings_version': return 'Versionsinformation';
			case 'settings_app_version': return 'Appversion';
			case 'settings_commit': return 'Commit';
			case 'settings_branch': return 'Gren';
			case 'settings_last_update': return 'Senaste uppdatering';
			case 'settings_date': return 'Datum';
			case 'settings_saved': return 'Inställningar sparades';
			case 'profile_student': return 'STUDENT';
			case 'profile_edit': return 'Redigera profil';
			case 'profile_stats': return 'Mina resultat';
			case 'profile_settings': return 'Inställningar';
			case 'profile_invite': return 'Bjud in en vän';
			case 'profile_help': return 'Hjälp';
			case 'profile_logout_confirm': return 'Är du säker på att du vill logga ut?';
			case 'profile_yes_logout': return 'Ja, logga ut';
			case 'home_dashboard': return 'Instrumentpanel';
			case 'home_my_progress': return 'Min framsteg';
			case 'home_overall_score': return 'Totalt resultat';
			case 'home_passed': return 'Godkänd';
			case 'home_failed': return 'Underkänd';
			case 'home_total': return 'Totalt';
			case 'home_in_progress': return 'Pågående';
			case 'home_recent_activity': return 'Senaste aktivitet';
			case 'home_by_category': return 'Per kategori';
			case 'home_this_week': return 'Denna vecka';
			case 'home_this_month': return 'Denna månad';
			case 'home_no_attempts': return 'Inga försök än!';
			case 'home_no_attempts_sub': return 'När du slutfört ett prov visas dina resultat här.';
			case 'home_take_quiz': return 'Ta ditt första prov';
			case 'home_paused': return 'Pausad';
			case 'home_resume': return 'Återuppta';
			case 'home_attempts': return 'försök';
			case 'home_active': return 'aktiv';
			case 'home_tests': return 'prov';
			default: return null;
		}
	}
}
