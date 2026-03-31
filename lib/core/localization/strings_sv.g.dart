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
	TranslationsSv({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
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

	@override 
	TranslationsSv $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsSv(meta: meta ?? this.$meta);

	// Translations
	@override String get home => 'Hem';
	@override String get tests => 'Prov';
	@override String get profile => 'Profil';
	@override String get welcome_message => 'Välkommen till Drive Test';
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
	@override String get intro_slide1_body => 'Lär dig och öva inför ditt körkort enkelt.';
	@override String get intro_slide2_title => 'Interaktiva prov';
	@override String get intro_slide2_body => 'Övningsprov med direkt feedback och förklaringar.';
	@override String get intro_slide3_title => 'Bli godkänd';
	@override String get intro_slide3_body => 'Klara dina prov och bli en godkänd förare.';
	@override String get intro_skip => 'Hoppa över';
	@override String get intro_get_started => 'Kom igång';
	@override String get auth_welcome_title => 'Välkommen till Drive Test!';
	@override String get auth_welcome_subtitle => 'Öva och förbered dig inför dina körprov!';
	@override String get auth_login_btn => 'LOGGA IN';
	@override String get auth_signup_btn => 'REGISTRERA';
	@override String get auth_skip_demo => 'HOPPA ÖVER (PROVA DEMO)';
	@override String get auth_demo_error => 'Kunde inte logga in med demokontot. Försök igen.';
	@override String get auth_or => 'ELLER';
	@override String get auth_login_title => 'Logga in';
	@override String get auth_contact_support => 'Kontakta support';
	@override String get auth_username => 'Användarnamn';
	@override String get auth_email => 'E-post';
	@override String get auth_password => 'Lösenord';
	@override String get auth_remember_me => 'Kom ihåg mig';
	@override String get auth_forgot_password => 'Glömt lösenord?';
	@override String get auth_invalid_credentials => 'Ogiltigt användarnamn eller lösenord';
	@override String get auth_no_account => 'Har du inget konto? ';
	@override String get auth_sign_up_link => 'Registrera dig';
	@override String get auth_skip_demo_short => 'Hoppa över (Prova demo)';
	@override String get auth_google_continue => 'Fortsätt med Google';
	@override String get auth_feedback_type => 'Typ';
	@override String get auth_feedback_email_optional => 'E-post (valfritt)';
	@override String get auth_feedback_subject_optional => 'Ämne (valfritt)';
	@override String get auth_feedback_message => 'Meddelande';
	@override String get auth_feedback_sent => 'Tack! Din feedback skickades.';
	@override String get auth_feedback_error => 'Kunde inte skicka feedback. Försök igen.';
	@override String get auth_submit => 'Skicka';
	@override String get auth_feedback_login_issue => 'Inloggningsproblem';
	@override String get auth_feedback_signup_issue => 'Registreringsproblem';
	@override String get auth_feedback_app_issue => 'Appproblem';
	@override String get auth_feedback_feature_request => 'Funktionsförfrågan';
	@override String get auth_feedback_other => 'Övrigt';
	@override String get auth_create_account => 'Skapa konto';
	@override String get auth_sign_up_btn => 'Registrera';
	@override String get auth_val_username_required => 'Vänligen ange ett användarnamn';
	@override String get auth_val_username_length => 'Användarnamnet måste vara minst 4 tecken';
	@override String get auth_val_email_required => 'Vänligen ange en e-postadress';
	@override String get auth_val_email_invalid => 'Vänligen ange en giltig e-postadress';
	@override String get auth_val_password_required => 'Vänligen ange ett lösenord';
	@override String get auth_val_password_length => 'Lösenordet måste vara minst 6 tecken';
	@override String get auth_signup_success => 'Registreringen lyckades! Vänligen logga in.';
	@override String get auth_signup_failed => 'Registreringen misslyckades. Rätta felen.';
	@override String get auth_generic_error => 'Ett fel uppstod. Försök igen.';
	@override String get auth_express_google => 'Express-inloggning via Google';
	@override String get auth_google_label => 'Google';
	@override String get auth_tab_login => 'Logga in';
	@override String get auth_tab_signup => 'Registrera dig';
	@override String get auth_show_password => 'Visa';
	@override String get auth_hide_password => 'Dölj';
	@override String get auth_forgot_title => 'Glömt lösenord';
	@override String get auth_forgot_heading => 'Återställ ditt lösenord';
	@override String get auth_forgot_subtitle => 'Ange din e-postadress så skickar vi instruktioner för att återställa ditt lösenord.';
	@override String get auth_forgot_email_label => 'E-postadress';
	@override String get auth_forgot_send_btn => 'Skicka instruktioner';
	@override String get auth_forgot_back_login => 'Tillbaka till inloggning';
	@override String get auth_forgot_success => 'Instruktioner för lösenordsåterställning har skickats till din e-post.';
	@override String get auth_forgot_error => 'Det gick inte att skicka återställningsmail. Försök igen.';
	@override String get purchase_success_title => 'Ditt köp har\nbekräftats';
	@override String get purchase_success_start_tests => 'Starta prov';
	@override String get purchase_success_back_home => 'Tillbaka till start';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on TranslationsSv {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'home': return 'Hem';
			case 'tests': return 'Prov';
			case 'profile': return 'Profil';
			case 'welcome_message': return 'Välkommen till Drive Test';
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
			case 'intro_slide1_body': return 'Lär dig och öva inför ditt körkort enkelt.';
			case 'intro_slide2_title': return 'Interaktiva prov';
			case 'intro_slide2_body': return 'Övningsprov med direkt feedback och förklaringar.';
			case 'intro_slide3_title': return 'Bli godkänd';
			case 'intro_slide3_body': return 'Klara dina prov och bli en godkänd förare.';
			case 'intro_skip': return 'Hoppa över';
			case 'intro_get_started': return 'Kom igång';
			case 'auth_welcome_title': return 'Välkommen till Drive Test!';
			case 'auth_welcome_subtitle': return 'Öva och förbered dig inför dina körprov!';
			case 'auth_login_btn': return 'LOGGA IN';
			case 'auth_signup_btn': return 'REGISTRERA';
			case 'auth_skip_demo': return 'HOPPA ÖVER (PROVA DEMO)';
			case 'auth_demo_error': return 'Kunde inte logga in med demokontot. Försök igen.';
			case 'auth_or': return 'ELLER';
			case 'auth_login_title': return 'Logga in';
			case 'auth_contact_support': return 'Kontakta support';
			case 'auth_username': return 'Användarnamn';
			case 'auth_email': return 'E-post';
			case 'auth_password': return 'Lösenord';
			case 'auth_remember_me': return 'Kom ihåg mig';
			case 'auth_forgot_password': return 'Glömt lösenord?';
			case 'auth_invalid_credentials': return 'Ogiltigt användarnamn eller lösenord';
			case 'auth_no_account': return 'Har du inget konto? ';
			case 'auth_sign_up_link': return 'Registrera dig';
			case 'auth_skip_demo_short': return 'Hoppa över (Prova demo)';
			case 'auth_google_continue': return 'Fortsätt med Google';
			case 'auth_feedback_type': return 'Typ';
			case 'auth_feedback_email_optional': return 'E-post (valfritt)';
			case 'auth_feedback_subject_optional': return 'Ämne (valfritt)';
			case 'auth_feedback_message': return 'Meddelande';
			case 'auth_feedback_sent': return 'Tack! Din feedback skickades.';
			case 'auth_feedback_error': return 'Kunde inte skicka feedback. Försök igen.';
			case 'auth_submit': return 'Skicka';
			case 'auth_feedback_login_issue': return 'Inloggningsproblem';
			case 'auth_feedback_signup_issue': return 'Registreringsproblem';
			case 'auth_feedback_app_issue': return 'Appproblem';
			case 'auth_feedback_feature_request': return 'Funktionsförfrågan';
			case 'auth_feedback_other': return 'Övrigt';
			case 'auth_create_account': return 'Skapa konto';
			case 'auth_sign_up_btn': return 'Registrera';
			case 'auth_val_username_required': return 'Vänligen ange ett användarnamn';
			case 'auth_val_username_length': return 'Användarnamnet måste vara minst 4 tecken';
			case 'auth_val_email_required': return 'Vänligen ange en e-postadress';
			case 'auth_val_email_invalid': return 'Vänligen ange en giltig e-postadress';
			case 'auth_val_password_required': return 'Vänligen ange ett lösenord';
			case 'auth_val_password_length': return 'Lösenordet måste vara minst 6 tecken';
			case 'auth_signup_success': return 'Registreringen lyckades! Vänligen logga in.';
			case 'auth_signup_failed': return 'Registreringen misslyckades. Rätta felen.';
			case 'auth_generic_error': return 'Ett fel uppstod. Försök igen.';
			case 'auth_express_google': return 'Express-inloggning via Google';
			case 'auth_google_label': return 'Google';
			case 'auth_tab_login': return 'Logga in';
			case 'auth_tab_signup': return 'Registrera dig';
			case 'auth_show_password': return 'Visa';
			case 'auth_hide_password': return 'Dölj';
			case 'auth_forgot_title': return 'Glömt lösenord';
			case 'auth_forgot_heading': return 'Återställ ditt lösenord';
			case 'auth_forgot_subtitle': return 'Ange din e-postadress så skickar vi instruktioner för att återställa ditt lösenord.';
			case 'auth_forgot_email_label': return 'E-postadress';
			case 'auth_forgot_send_btn': return 'Skicka instruktioner';
			case 'auth_forgot_back_login': return 'Tillbaka till inloggning';
			case 'auth_forgot_success': return 'Instruktioner för lösenordsåterställning har skickats till din e-post.';
			case 'auth_forgot_error': return 'Det gick inte att skicka återställningsmail. Försök igen.';
			case 'purchase_success_title': return 'Ditt köp har\nbekräftats';
			case 'purchase_success_start_tests': return 'Starta prov';
			case 'purchase_success_back_home': return 'Tillbaka till start';
			default: return null;
		}
	}
}

