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
  TranslationsSv(
      {Map<String, Node>? overrides,
      PluralResolver? cardinalResolver,
      PluralResolver? ordinalResolver,
      TranslationMetadata<AppLocale, Translations>? meta})
      : assert(overrides == null,
            'Set "translation_overrides: true" in order to enable this feature.'),
        $meta = meta ??
            TranslationMetadata(
              locale: AppLocale.sv,
              overrides: overrides ?? {},
              cardinalResolver: cardinalResolver,
              ordinalResolver: ordinalResolver,
            ) {
    $meta.setFlatMapFunction(_flatMapFunction);
  }

  /// Metadata for the translations of <sv>.
  @override
  final TranslationMetadata<AppLocale, Translations> $meta;

  /// Access flat map
  @override
  dynamic operator [](String key) => $meta.getTranslation(key);

  late final TranslationsSv _root = this; // ignore: unused_field

  @override
  TranslationsSv $copyWith(
          {TranslationMetadata<AppLocale, Translations>? meta}) =>
      TranslationsSv(meta: meta ?? this.$meta);

  // Translations
  @override
  String get home => 'Hem';
  @override
  String get tests => 'Prov';
  @override
  String get profile => 'Profil';
  @override
  String get welcome_message => 'Välkommen till Drive Test';
  @override
  String get save => 'Spara';
  @override
  String get cancel => 'Avbryt';
  @override
  String get delete => 'Ta bort';
  @override
  String get logout => 'Logga ut';
  @override
  String get loading => 'Laddar...';
  @override
  String get settings_title => 'Inställningar';
  @override
  String get settings_appearance => 'Utseende';
  @override
  String get settings_test_prefs => 'Provpreferenser';
  @override
  String get settings_timed_test => 'Tidsbegränsat prov';
  @override
  String get settings_timed_test_sub => 'Aktivera tidsgräns för provet';
  @override
  String get settings_instant_marking => 'Omedelbar rättning';
  @override
  String get settings_instant_marking_sub => 'Visa rätt svar efter varje fråga';
  @override
  String get settings_num_questions => 'Antal frågor';
  @override
  String get settings_enter_num => 'Ange antal frågor:';
  @override
  String get settings_include_saved => 'Inkludera sparade frågor';
  @override
  String get settings_include_saved_sub =>
      'Inkludera frågor du tidigare sparat';
  @override
  String get settings_notifications => 'Aviseringar';
  @override
  String get settings_notifications_toggle => 'Push-aviseringar';
  @override
  String get settings_notifications_on_sub =>
      'Du kommer att få påminnelser och uppdateringar om dina prov';
  @override
  String get settings_notifications_off_sub => 'Aviseringar är avstängda';
  @override
  String get settings_notifications_denied =>
      'Behörighet nekad — tryck nedan för att öppna Inställningar';
  @override
  String get settings_notifications_open_settings => 'Öppna inställningar';
  @override
  String get settings_dark_mode => 'Mörkt läge';
  @override
  String get settings_dark_mode_sub => 'Växla mellan ljust och mörkt tema';
  @override
  String get settings_language => 'Språk';
  @override
  String get settings_language_sub => 'Välj ditt föredragna språk';
  @override
  String get settings_version => 'Versionsinformation';
  @override
  String get settings_app_version => 'Appversion';
  @override
  String get settings_commit => 'Commit';
  @override
  String get settings_branch => 'Gren';
  @override
  String get settings_last_update => 'Senaste uppdatering';
  @override
  String get settings_date => 'Datum';
  @override
  String get settings_saved => 'Inställningar sparades';
  @override
  String get profile_student => 'STUDENT';
  @override
  String get profile_edit => 'Redigera profil';
  @override
  String get profile_stats => 'Mina resultat';
  @override
  String get profile_statistics => 'Statistik';
  @override
  String get stats_no_tests_yet => 'Inga avslutade prov ännu';
  @override
  String get stats_attempt_history => 'FÖRSÖKSHISTORIK';
  @override
  String get stats_avg_time => 'Snittid';
  @override
  String get stats_attempt_one => 'försök';
  @override
  String get stats_attempt_many => 'försök';
  @override
  String get stats_avg_label => 'Snitt';
  @override
  String get stats_unknown => 'Okänt';
  @override
  String get stats_best => 'Bäst';
  @override
  String get stats_average => 'Snitt';
  @override
  String get home_attempt_details => 'Försöksdetaljer';
  @override
  String get home_saved_questions_title => 'Sparade frågor';
  @override
  String get profile_settings => 'Inställningar';
  @override
  String get profile_invite => 'Bjud in en vän';
  @override
  String get profile_help => 'Hjälp';
  @override
  String get profile_manage_subscription => 'Hantera prenumeration';
  @override
  String get profile_purchase_history => 'Köphistorik';
  @override
  String get profile_receipt_title => 'Kvitto';
  @override
  String get profile_receipt_copy_number => 'Kopiera kvittonummer';
  @override
  String get profile_receipt_number_copied => 'Kvittonummer kopierat';
  @override
  String get profile_no_purchases => 'Inga köp ännu.';
  @override
  String get profile_receipt_payment_receipt => 'Betalningskvitto';
  @override
  String get profile_receipt_no => 'Kvittonr.';
  @override
  String get profile_receipt_product => 'Produkt';
  @override
  String get profile_receipt_duration => 'Varaktighet';
  @override
  String get profile_receipt_amount_paid => 'Betalt belopp';
  @override
  String get profile_receipt_payment_via => 'Betalning via';
  @override
  String get profile_receipt_via_iap => 'Apple App Store';
  @override
  String get profile_receipt_via_card => 'Kort (Stripe)';
  @override
  String get profile_receipt_transaction_id => 'Transaktions-ID';
  @override
  String get profile_receipt_payment_intent => 'Betalningsavsikt';
  @override
  String get profile_receipt_reference_no => 'Referensnr.';
  @override
  String get profile_receipt_footer =>
      'Spara detta kvitto. Kontakta support med ditt kvittonummer om du har frågor om detta köp.';
  @override
  String get profile_revisit_setup => 'Gör om inställningar';
  @override
  String get profile_send_feedback => 'Skicka feedback';
  @override
  String get profile_logout_confirm => 'Är du säker på att du vill logga ut?';
  @override
  String get profile_yes_logout => 'Ja, logga ut';
  @override
  String get home_dashboard => 'Instrumentpanel';
  @override
  String get home_my_progress => 'Min framsteg';
  @override
  String get home_overall_score => 'Totalt resultat';
  @override
  String get home_passed => 'Godkänd';
  @override
  String get home_failed => 'Underkänd';
  @override
  String get home_total => 'Totalt';
  @override
  String get home_in_progress => 'Pågående';
  @override
  String get home_recent_activity => 'Senaste aktivitet';
  @override
  String get home_by_category => 'Per kategori';
  @override
  String get home_this_week => 'Denna vecka';
  @override
  String get home_this_month => 'Denna månad';
  @override
  String get home_no_attempts => 'Inga försök än!';
  @override
  String get home_no_attempts_sub =>
      'När du slutfört ett prov visas dina resultat här.';
  @override
  String get home_take_quiz => 'Ta ditt första prov';
  @override
  String get home_paused => 'Pausad';
  @override
  String get home_resume => 'Återuppta';
  @override
  String get home_attempts => 'försök';
  @override
  String get home_active => 'aktiv';
  @override
  String get home_tests => 'prov';
  @override
  String get intro_slide1_body => 'Lär dig och öva inför ditt körkort enkelt.';
  @override
  String get intro_slide2_title => 'Interaktiva prov';
  @override
  String get intro_slide2_body =>
      'Övningsprov med direkt feedback och förklaringar.';
  @override
  String get intro_slide3_title => 'Bli godkänd';
  @override
  String get intro_slide3_body => 'Klara dina prov och bli en godkänd förare.';
  @override
  String get intro_skip => 'Hoppa över';
  @override
  String get intro_get_started => 'Kom igång';
  @override
  String get auth_welcome_title => 'Välkommen till Drive Test!';
  @override
  String get auth_welcome_subtitle => 'Öva. Klara prov tryggt.';
  @override
  String get auth_login_btn => 'LOGGA IN';
  @override
  String get auth_signup_btn => 'REGISTRERA';
  @override
  String get auth_skip_demo => 'HOPPA ÖVER (PROVA DEMO)';
  @override
  String get auth_demo_error =>
      'Kunde inte logga in med demokontot. Försök igen.';
  @override
  String get auth_or => 'ELLER';
  @override
  String get auth_login_title => 'Logga in';
  @override
  String get auth_contact_support => 'Kontakta support';
  @override
  String get auth_username => 'Användarnamn eller e-post';
  @override
  String get auth_email => 'E-post';
  @override
  String get auth_password => 'Lösenord';
  @override
  String get auth_remember_me => 'Kom ihåg mig';
  @override
  String get auth_forgot_password => 'Glömt lösenord?';
  @override
  String get auth_invalid_credentials => 'Ogiltigt användarnamn eller lösenord';
  @override
  String get auth_no_account => 'Har du inget konto? ';
  @override
  String get auth_sign_up_link => 'Registrera dig';
  @override
  String get auth_skip_demo_short => 'Hoppa över (Prova demo)';
  @override
  String get auth_google_continue => 'Fortsätt med Google';
  @override
  String get auth_feedback_type => 'Typ';
  @override
  String get auth_feedback_email_optional => 'E-post (valfritt)';
  @override
  String get auth_feedback_subject_optional => 'Ämne (valfritt)';
  @override
  String get auth_feedback_message => 'Meddelande';
  @override
  String get auth_feedback_sent => 'Tack! Din feedback skickades.';
  @override
  String get auth_feedback_error => 'Kunde inte skicka feedback. Försök igen.';
  @override
  String get auth_submit => 'Skicka';
  @override
  String get auth_feedback_login_issue => 'Inloggningsproblem';
  @override
  String get auth_feedback_signup_issue => 'Registreringsproblem';
  @override
  String get auth_feedback_app_issue => 'Appproblem';
  @override
  String get auth_feedback_feature_request => 'Funktionsförfrågan';
  @override
  String get auth_feedback_other => 'Övrigt';
  @override
  String get auth_create_account => 'Skapa konto';
  @override
  String get auth_sign_up_btn => 'Registrera';
  @override
  String get auth_val_username_required =>
      'Vänligen ange ditt användarnamn eller e-post';
  @override
  String get auth_val_username_length =>
      'Användarnamnet måste vara minst 4 tecken';
  @override
  String get auth_val_email_required => 'Vänligen ange en e-postadress';
  @override
  String get auth_val_email_invalid => 'Vänligen ange en giltig e-postadress';
  @override
  String get auth_val_password_required => 'Vänligen ange ett lösenord';
  @override
  String get auth_val_password_length => 'Lösenordet måste vara minst 6 tecken';
  @override
  String get auth_signup_success =>
      'Registreringen lyckades! Vänligen logga in.';
  @override
  String get auth_welcome_first_login => 'Välkommen, lycka till!';
  @override
  String get auth_welcome_returning => 'Välkommen tillbaka igen!';
  @override
  String get auth_deleted_account_welcome_back => 'Alltid välkommen tillbaka.';
  @override
  String get auth_signup_failed => 'Registreringen misslyckades. Rätta felen.';
  @override
  String get auth_generic_error => 'Ett fel uppstod. Försök igen.';
  @override
  String get auth_express_google => 'Express-inloggning via Google';
  @override
  String get auth_google_label => 'Google';
  @override
  String get auth_express_apple => 'Logga in med Apple';
  @override
  String get auth_apple_label => 'Apple';
  @override
  String get auth_signing_in => 'Loggar in...';
  @override
  String get auth_tab_login => 'Logga in';
  @override
  String get auth_tab_signup => 'Registrera dig';
  @override
  String get auth_show_password => 'Visa';
  @override
  String get auth_hide_password => 'Dölj';
  @override
  String get auth_forgot_title => 'Glömt lösenord';
  @override
  String get auth_forgot_heading => 'Återställ ditt lösenord';
  @override
  String get auth_forgot_subtitle =>
      'Ange din e-postadress så skickar vi instruktioner för att återställa ditt lösenord.';
  @override
  String get auth_forgot_email_label => 'E-postadress';
  @override
  String get auth_forgot_send_btn => 'Skicka instruktioner';
  @override
  String get auth_forgot_back_login => 'Tillbaka till inloggning';
  @override
  String get auth_forgot_success =>
      'Instruktioner för lösenordsåterställning har skickats till din e-post.';
  @override
  String get auth_forgot_error =>
      'Det gick inte att skicka återställningsmail. Försök igen.';
  @override
  String get auth_verify_title => 'Verifiera kod';
  @override
  String get auth_verify_heading => 'Kontrollera din e-post';
  @override
  String get auth_verify_subtitle =>
      'Vi skickade en återställningskod till\n{email}';
  @override
  String get auth_verify_code_label => 'Återställningskod';
  @override
  String get auth_verify_code_hint => 'Ange koden från din e-post';
  @override
  String get auth_verify_code_empty =>
      'Vänligen ange återställningskoden från din e-post.';
  @override
  String get auth_verify_resend => 'Skicka om kod';
  @override
  String get auth_reset_title => 'Återställ lösenord';
  @override
  String get auth_reset_heading => 'Ange nytt lösenord';
  @override
  String get auth_reset_subtitle => 'Ange ditt nya lösenord';
  @override
  String get auth_reset_new_password_label => 'Nytt lösenord';
  @override
  String get auth_reset_confirm_password_label => 'Bekräfta lösenord';
  @override
  String get auth_reset_empty => 'Vänligen ange ett nytt lösenord.';
  @override
  String get auth_reset_mismatch => 'Lösenorden stämmer inte överens.';
  @override
  String get auth_reset_invalid_code =>
      'Ogiltig eller utgången kod. Försök att begära en ny återställningslänk.';
  @override
  String get auth_reset_success_title => 'Klart!';
  @override
  String get auth_reset_success_body =>
      'Ditt lösenord har återställts. Du kan nu logga in med ditt nya lösenord.';
  @override
  String get auth_reset_go_to_login => 'Gå till inloggning';
  @override
  String get auth_google_connecting => 'Ansluter till Google...';
  @override
  String get auth_google_verifying => 'Verifierar konto...';
  @override
  String get auth_google_signing_in => 'Loggar in...';
  @override
  String get auth_google_creating => 'Skapar ditt konto...';
  @override
  String get auth_google_loading => 'Laddar din profil...';
  @override
  String get auth_landing_subtitle =>
      'Din resa mot framgång börjar med ett tryck.';
  @override
  String get auth_landing_new_here => 'Ny här?';
  @override
  String get auth_create_account_link => 'Skapa ett konto';
  @override
  String get auth_login_heading => 'Välkommen\ntillbaka';
  @override
  String get auth_login_subtitle => 'Fortsätt din inlärningsresa.';
  @override
  String get auth_username_hint => 'användarnamn eller e-post';
  @override
  String get auth_signup_heading_plain => 'Gå med i';
  @override
  String get auth_signup_heading_italic => 'Rörelsen.';
  @override
  String get auth_signup_subtitle => 'Accelerera din inlärning idag.';
  @override
  String get auth_signup_username_hint => 'Erik Andersson';
  @override
  String get auth_signup_email_hint => 'erik@example.se';
  @override
  String get auth_have_account => 'Har du redan ett konto?';
  @override
  String get auth_reset_onboarding_tooltip => 'Återställ onboarding';
  @override
  String get auth_language_english => 'Engelska';
  @override
  String get auth_language_swedish => 'Svenska';
  @override
  String get brand_drive => 'DRIVE ';
  @override
  String get brand_test => 'TEST';
  @override
  String get purchase_success_title => 'Ditt köp har\nbekräftats';
  @override
  String get purchase_success_start_tests => 'Starta prov';
  @override
  String get purchase_success_back_home => 'Tillbaka till start';
  @override
  String get bcd_drive_test => 'Drive Test';
  @override
  String get bcd_exams => 'Prov';
  @override
  String get bcd_exams_sub => 'Licenser, kategorier & prov';
  @override
  String get bcd_traffic_signs => 'Trafikskyltar';
  @override
  String get bcd_traffic_signs_sub => 'Bläddra bland alla trafikskyltar';
  @override
  String get bcd_subscriptions => 'Prenumerationer';
  @override
  String get bcd_subscriptions_sub => 'Visa planer och hantera åtkomst';
  @override
  String get bcd_hub_practice => 'Övning';
  @override
  String get bcd_hub_tests => 'Prov';
  @override
  String get bcd_hub_theory_docs => 'Teori-\ndokument';
  @override
  String get bcd_hub_traffic_signs => 'Trafikskyltar';
  @override
  String get bcd_hub_checklist => 'Checklista';
  @override
  String get bcd_hub_statistics => 'Statistik';
  @override
  String get bcd_hub_saved_questions => 'Sparade\nfrågor';
  @override
  String get bcd_no_free_practice =>
      'Inget gratis övningsprov tillgängligt för denna kategori.';
  @override
  String get bcd_failed_practice => 'Det gick inte att ladda övningsprovet.';
  @override
  String get bcd_no_saved_questions =>
      'Inga sparade frågor i denna kategori ännu.';
  @override
  String get bcd_no_saved_questions_found =>
      'Inga sparade frågor hittades i denna kategori.';
  @override
  String get bcd_failed_saved => 'Det gick inte att ladda sparade frågor.';
  @override
  String get bcd_no_subscription =>
      'Du har ingen aktiv prenumeration för denna kategori';
  @override
  String get bcd_free_content_desc =>
      'Övning, Trafikskyltar, Dokument och Checklistor är gratis. Prenumerera för att låsa upp Prov.';
  @override
  String get bcd_buy_subscription => 'Köp prenumeration';
  @override
  String get bcd_buy_subscription_arrow => 'Köp prenumeration →';
  @override
  String get bcd_not_subscribed => 'Du prenumererar inte på denna kategori';
  @override
  String get bcd_only_free_tests =>
      'Endast gratis övningsprov är tillgängliga. Prenumerera för att låsa upp alla prov.';
  @override
  String get bcd_no_free_practice_tests =>
      'Inga gratis övningsprov tillgängliga.';
  @override
  String get bcd_no_tests => 'Inga prov tillgängliga.';
  @override
  String get bcd_no_documents => 'Inga dokument tillgängliga.';
  @override
  String get bcd_no_checklists => 'Inga checklistor tillgängliga.';
  @override
  String get bcd_failed_tests => 'Det gick inte att ladda prov';
  @override
  String get bcd_subscription_required => 'Prenumeration krävs';
  @override
  String get bcd_subscribe_access =>
      'Prenumerera för att få tillgång till "{name}" och allt dess innehåll.';
  @override
  String get bcd_not_now => 'Inte nu';
  @override
  String get legal_terms_of_use => 'Användarvillkor';
  @override
  String get legal_privacy_policy => 'Integritetspolicy';
  @override
  String get bcd_buy => 'Köp';
  @override
  String get bcd_payment_failed => 'Betalning misslyckades. Försök igen.';
  @override
  String get iap_owned_by_other_title => 'Prenumeration redan kopplad';
  @override
  String get iap_owned_by_other_body =>
      'Den här prenumerationen är kopplad till ett annat konto. Logga in med det konto du ursprungligen köpte den på.';
  @override
  String get iap_owned_by_other_ok => 'OK';
  @override
  String get bcd_feedback_unavailable =>
      'Feedback ej tillgänglig för denna fråga.';
  @override
  String get bcd_feedback_submitted => 'Tack! Din feedback skickades.';
  @override
  String get bcd_feedback_failed => 'Kunde inte skicka feedback. Försök igen.';
  @override
  String get bcd_categories => 'Kategorier';
  @override
  String get bcd_search_categories => 'Sök kategorier…';
  @override
  String get bcd_no_categories => 'Inga kategorier tillgängliga.';
  @override
  String get bcd_no_match_search => 'Inga träffar hittades.';
  @override
  String get bcd_subscribed => 'Prenumererar';
  @override
  String get bcd_tap_to_subscribe => 'Tryck för att prenumerera';
  @override
  String get bcd_failed_categories => 'Det gick inte att ladda kategorier';
  @override
  String get bcd_plans_tab => 'Planer';
  @override
  String get bcd_my_subscriptions_tab => 'Mina prenumerationer';
  @override
  String get bcd_no_plans => 'Inga planer tillgängliga';
  @override
  String get bcd_active_label => 'Aktiv';
  @override
  String get bcd_subscribe_btn => 'Prenumerera';
  @override
  String get bcd_start_practice => 'Börja öva';
  @override
  String get bcd_no_active_subscriptions => 'Inga aktiva prenumerationer';
  @override
  String get bcd_browse_plans => 'Bläddra bland planer för att komma igång';
  @override
  String get bcd_expires => 'Upphör';
  @override
  String get bcd_failed_plans => 'Det gick inte att ladda planer';
  @override
  String get bcd_no_categories_linked =>
      'Inga kategorier kopplade till den här prenumerationen';
  @override
  String get bcd_failed_category => 'Det gick inte att ladda kategorin';
  @override
  String get bcd_search_signs => 'Sök skyltgrupper…';
  @override
  String get bcd_no_signs => 'Inga skyltar hittades';
  @override
  String get bcd_no_image => 'Ingen bild';
  @override
  String get bcd_signs_count_label => 'trafikskyltar';
  @override
  String get bcd_view => 'Visa';
  @override
  String get bcd_previous => 'Föregående';
  @override
  String get bcd_next => 'Nästa';
  @override
  String get bcd_failed_traffic_signs =>
      'Det gick inte att ladda trafikskyltar';
  @override
  String get bcd_search_hint => 'Sök…';
  @override
  String get bcd_no_subcategories => 'Inga underkategorier tillgängliga.';
  @override
  String get bcd_failed_subcategories =>
      'Det gick inte att ladda underkategorier';
  @override
  String get bcd_no_questions => 'Inga frågor hittades för det här provet.';
  @override
  String get bcd_failed_test_questions => 'Det gick inte att ladda provfrågor.';
  @override
  String get bcd_questions_label => 'frågor';
  @override
  String get bcd_pass_label => 'Godkänt';
  @override
  String get bcd_free_label => 'GRATIS';
  @override
  String get settings_theme_label => 'Tema';
  @override
  String get settings_theme_sub => 'Ljust, mörkt eller följ systemet';
  @override
  String get settings_theme_system => 'System';
  @override
  String get settings_theme_light => 'Ljust';
  @override
  String get settings_theme_dark => 'Mörkt';
  @override
  String get help_title => 'Hjälp & Support';
  @override
  String get help_need_help => 'Behöver du hjälp?';
  @override
  String get help_subtitle =>
      'Berätta om ditt problem så återkommer vi till dig.';
  @override
  String get help_your_information => 'Din information';
  @override
  String get help_username => 'Användarnamn';
  @override
  String get help_email => 'E-post';
  @override
  String get help_user_id => 'Användar-ID';
  @override
  String get help_subject => 'Ämne';
  @override
  String get help_subject_hint =>
      't.ex. Inloggningsproblem, Buggrapport, Funktionsförfrågan';
  @override
  String get help_subject_required => 'Ange ett ämne';
  @override
  String get help_description => 'Beskrivning';
  @override
  String get help_description_hint => 'Beskriv ditt problem i detalj...';
  @override
  String get help_description_required => 'Beskriv ditt problem';
  @override
  String get help_description_too_short =>
      'Ge mer information (minst 10 tecken)';
  @override
  String get help_submit => 'Skicka rapport';
  @override
  String get help_or_email =>
      'Eller mejla oss direkt på mohsin.sapra@gmail.com';
  @override
  String get help_opening_email => 'Öppnar e-postappen...';
  @override
  String get help_email_error =>
      'Kunde inte öppna e-postappen. Mejla mohsin.sapra@gmail.com direkt.';
  @override
  String get help_generic_error =>
      'Fel vid öppning av e-postappen. Försök igen.';
  @override
  String get notifications_title => 'Aviseringar';
  @override
  String get notifications_mark_all_read => 'Markera alla som lästa';
  @override
  String get notifications_clear => 'Rensa';
  @override
  String get notifications_clear_confirm_title => 'Rensa alla aviseringar?';
  @override
  String get notifications_clear_confirm_body =>
      'Detta tar bort alla aviseringar. Åtgärden kan inte ångras.';
  @override
  String get notifications_empty_title => 'Inga aviseringar';
  @override
  String get notifications_empty_subtitle =>
      'Du är à jour! Vi meddelar dig när något nytt händer.';
  @override
  String get notifications_just_now => 'Just nu';
  @override
  String get notifications_minutes_ago => '{n} min sedan';
  @override
  String get notifications_hours_ago => '{n} tim sedan';
  @override
  String get notifications_days_ago => '{n} dagar sedan';
  @override
  String get notifications_permission_off_title => 'Aviseringar är avstängda';
  @override
  String get notifications_permission_denied_body =>
      'Du har nekat behörighet för aviseringar. Öppna Inställningar för att aktivera dem.';
  @override
  String get notifications_permission_not_determined_body =>
      'Tillåt aviseringar för att hålla dig uppdaterad om dina provframsteg och påminnelser.';
  @override
  String get notifications_permission_open_settings => 'Öppna inställningar';
  @override
  String get notifications_permission_enable => 'Aktivera aviseringar';
  @override
  String get notifications_permission_web_dialog_title =>
      'Aktivera i webbläsaren';
  @override
  String get notifications_permission_web_dialog_body =>
      'För att aktivera aviseringar, klicka på låsikonen (🔒) i webbläsarens adressfält, hitta "Aviseringar" och ställ in det på "Tillåt". Ladda sedan om sidan.';
  @override
  String get notifications_permission_web_dialog_ok => 'Förstått';
  @override
  String get image_viewer_swipe_to_close => 'Svep nedåt för att stänga';
  @override
  String get image_viewer_load_error => 'Kunde inte ladda bilden';
  @override
  String get dash_my_progress => 'Mina framsteg';
  @override
  String get dash_sync_from_server => 'Synkronisera från server';
  @override
  String get dash_unknown_error => 'Något gick fel. Försök igen.';
  @override
  String get dash_network_error =>
      'Ingen internetanslutning. Kontrollera din anslutning och försök igen.';
  @override
  String get dash_server_error => 'Serverfel. Försök igen senare.';
  @override
  String get dash_retry => 'Försök igen';
  @override
  String get dash_my_exams => 'Mina prov';
  @override
  String get dash_tap_to_dive => 'Tryck på ett prov för att utforska';
  @override
  String get dash_overview => 'Översikt';
  @override
  String get dash_categories_header => 'Kategorier';
  @override
  String get dash_batches_header => 'Omgångar';
  @override
  String get dash_expand_categories =>
      'Expandera en kategori för att se omgångar';
  @override
  String get dash_weekly_streak => 'Veckosvit';
  @override
  String get dash_consistency_builds => 'Regelbundenhet bygger mästerskap';
  @override
  String get dash_smart_insights => 'Smarta insikter';
  @override
  String get dash_based_on_attempts => 'Baserat på dina försök';
  @override
  String get dash_continue_label => 'Fortsätt: {name}';
  @override
  String get dash_total_attempts => 'Totala försök';
  @override
  String get dash_batches_done => 'Avklarade omgångar';
  @override
  String get dash_avg_time => 'Snittid';
  @override
  String get dash_weakest_label => 'Svagast: {name} ({score}%)';
  @override
  String get dash_batches_completed_label =>
      '{done}/{total} omgångar avklarade';
  @override
  String get dash_weakness_low_score => 'Lågt resultat';
  @override
  String get dash_weakness_over_time => 'Tar för lång tid';
  @override
  String get dash_weakness_needs_work => 'Behöver övas';
  @override
  String get dash_weakness_on_track => 'På rätt spår';
  @override
  String get dash_not_started => 'Ej påbörjad';
  @override
  String get dash_attempt_one => '1 försök';
  @override
  String get dash_attempt_many => '{n} försök';
  @override
  String get dash_avg_duration => 'Snitt {duration}';
  @override
  String get dash_over_time_pct => '+{pct}% tid';
  @override
  String get dash_on_time => 'I tid';
  @override
  String get dash_insight_strongest => 'Starkaste område';
  @override
  String get dash_insight_weakest => 'Svagaste område';
  @override
  String get dash_insight_focus => 'Fokusrekommendation';
  @override
  String get dash_insight_continue_learning => 'Fortsätt lära dig';
  @override
  String get dash_insight_area_detail => '{name} — {score}% snitt';
  @override
  String get dash_insight_focus_detail =>
      'Arbeta med {name} härnäst för att fortsätta framåt';
  @override
  String get dash_insight_start =>
      'Börja med {name} — välj vilken omgång som helst.';
  @override
  String get dash_insight_all_done =>
      'Alla omgångar avklarade! Repetera omgångar med lågt resultat.';
  @override
  String get dash_insight_progress =>
      '{done}/{total} omgångar godkända. Fortsätt — du är {pct}% på väg!';
  @override
  String get dash_streak_current => 'Nuvarande\nsvit';
  @override
  String get dash_streak_best => 'Bästa\nsvit';
  @override
  String get dash_streak_weekly_goal => 'Veckans mål';
  @override
  String get dash_day_mon => 'M';
  @override
  String get dash_day_tue => 'T';
  @override
  String get dash_day_wed => 'O';
  @override
  String get dash_day_thu => 'T';
  @override
  String get dash_day_fri => 'F';
  @override
  String get dash_day_sat => 'L';
  @override
  String get dash_day_sun => 'S';
  @override
  String get dash_streak_msg_none =>
      'Starta en session idag för att börja din svit!';
  @override
  String get dash_streak_msg_amazing =>
      'Fantastiskt! {n} dagar i rad — håll i det!';
  @override
  String get dash_streak_msg_goal => 'Veckans mål nått! Du är i full gång 🔥';
  @override
  String get dash_streak_msg_progress_one =>
      '{n} dagars svit! 1 session kvar för att nå veckans mål.';
  @override
  String get dash_streak_msg_progress_other =>
      '{n} dagars svit! {left} sessioner kvar för att nå veckans mål.';
  @override
  String get dash_completed => 'Avklarad!';
  @override
  String get dash_tap_to_explore => 'Tryck för att utforska';
  @override
  String get onb_which_exams => 'Vilka prov förbereder du dig för?';
  @override
  String get onb_select_all_apply => 'Välj alla som passar';
  @override
  String get onb_exam_date_title => 'När är ditt prov?';
  @override
  String get onb_exam_date_subtitle => 'Sätt ett måldatum för att hålla koll';
  @override
  String get onb_practice_days_title =>
      'Hur många dagar i veckan kommer du öva?';
  @override
  String get onb_practice_days_subtitle =>
      'Var realistisk — konsistens är nyckeln';
  @override
  String get onb_recommendations_title => 'Rekommenderade för dig';
  @override
  String get onb_recommendations_subtitle =>
      'Prenumerera för full tillgång till dessa prov';
  @override
  String get onb_continue => 'Fortsätt';
  @override
  String get onb_weekday_mon_short => 'M';
  @override
  String get onb_weekday_tue_short => 'T';
  @override
  String get onb_weekday_wed_short => 'O';
  @override
  String get onb_weekday_thu_short => 'T';
  @override
  String get onb_weekday_fri_short => 'F';
  @override
  String get onb_weekday_sat_short => 'L';
  @override
  String get onb_weekday_sun_short => 'S';
  @override
  String get onb_get_started => 'Kom igång';
  @override
  String get onb_1_week => '1 vecka';
  @override
  String get onb_2_weeks => '2 veckor';
  @override
  String get onb_3_weeks => '3 veckor';
  @override
  String get onb_1_month => '1 månad';
  @override
  String get onb_2_months => '2 månader';
  @override
  String get onb_3_months => '3 månader';
  @override
  String get onb_custom_date => 'Eget datum';
  @override
  String get onb_subscribe => 'Prenumerera';
  @override
  String get onb_sign_in_to_subscribe => 'Logga in för att prenumerera';
  @override
  String get onb_sign_in_subtitle =>
      'Skapa ett gratis konto eller logga in för att få tillgång till fullständiga prov';
  @override
  String get onb_no_exams => 'Inga prov tillgängliga just nu';
  @override
  String get onb_days_week_label => '{n} dagar/vecka';
  @override
  String get onb_step_of => 'Steg {current} av {total}';
  @override
  String get onb_weekly_goal_title => 'Veckovis studiemål';
  @override
  String get onb_weekly_goal_sub => 'Välj de dagar du ska studera.';
  @override
  String get dash_exam_deadline => 'Provdatum';
  @override
  String get dash_days_remaining => '{n} dagar kvar';
  @override
  String get dash_deadline_today => 'Idag!';
  @override
  String get dash_deadline_passed => 'Deadline passerad';
  @override
  String get dash_no_deadline => 'Ingen deadline satt';
  @override
  String get dash_set_deadline => 'Sätt deadline';
  @override
  String get dash_change_deadline => 'Ändra deadline';
  @override
  String get dash_practice_days => '{n} dagar/vecka';
  @override
  String get dash_hero_sub_start => 'Dags att börja din resa!';
  @override
  String get dash_hero_sub_progress => 'Bra jobbat – fortsätt framåt!';
  @override
  String get dash_hero_sub_almost => 'Snart redo för examen!';
  @override
  String get dash_hero_sub_done => 'Allt avklarat – bra jobbat!';
  @override
  String get dash_performance_overview => 'Prestationsöversikt';
  @override
  String get dash_focus_areas => 'Fokusområden';
  @override
  String get dash_no_exams_found => 'Inga prov hittades.';
  @override
  String get dash_card_active => 'AKTIV';
  @override
  String get dash_card_inactive => 'INAKTIV';
  @override
  String get dash_card_expired => 'Upphörde {date}';
  @override
  String get dash_card_expires_today => 'Löper ut idag';
  @override
  String get dash_card_expires_tomorrow => 'Löper ut imorgon';
  @override
  String get dash_card_expires_days => 'Löper ut om {days} dagar';
  @override
  String get dash_card_expires_on => 'Löper ut {date}';
  @override
  String get dash_stat_completed => 'Klart';
  @override
  String get dash_stat_none_yet => 'Inga ännu';
  @override
  String get dash_stat_of_n => 'av {total}';
  @override
  String get dash_stat_per_session => 'Per omgång';
  @override
  String get dash_perf_title1 => 'Prestations';
  @override
  String get dash_perf_title2 => 'översikt';
  @override
  String get dash_period_today => 'Idag';
  @override
  String get dash_period_7days => '7 dagar';
  @override
  String get dash_period_all => 'Hela tiden';
  @override
  String get dash_perf_subtitle => 'Följ dina framsteg. Nå dina mål.';
  @override
  String get dash_perf_attempts_desc => 'Alla dina försök under perioden';
  @override
  String get dash_perf_batches_desc => 'Framsteg denna period';
  @override
  String get dash_avg_time_per_session => 'Snittid / pass';
  @override
  String get dash_perf_time_desc => 'Genomsnittlig tid per pass';
  @override
  String get dash_keep_it_up => 'Fortsätt så!';
  @override
  String get dash_consistency_today => 'Regelbundenhet idag, framgång imorgon.';
  @override
  String get dash_exam_type_taxi => 'TAXI';
  @override
  String get dash_exam_type_test => 'PROV';
  @override
  String get dash_streak_title => '{n} dagars svit!';
  @override
  String get dash_streak_days => '{n} dagar';
  @override
  String get dash_batches_count => '{n} omgångar';
  @override
  String get dash_avg_score_label => '{score}% snitt';
  @override
  String get dash_new_test => '+ Nytt test';
  @override
  String get dash_no_attempts_yet => 'Inga försök ännu';
  @override
  String get dash_previous_attempts => 'Tidigare försök';
  @override
  String get dash_see_all => 'Se alla';
  @override
  String get dash_all_attempts => 'Alla försök';
  @override
  String get tut_step1_title => 'Steg 1 av 3 — Översätt';
  @override
  String get tut_step1_body =>
      'Tryck på språkknappen för att öppna listan och välj sedan engelska (eller valfritt annat språk).';
  @override
  String get tut_step1b_title => 'Steg 1 av 3 — Välj ett språk';
  @override
  String get tut_step1b_body =>
      'Välj ett annat språk från listan, till exempel engelska.';
  @override
  String get tut_step2a_title => 'Steg 2 av 4 — Kika på originalet';
  @override
  String get tut_step2a_body =>
      'Tryck och håll var som helst på frågan (inte svarsalternativen) för att tillfälligt se den ursprungliga svenska texten.';
  @override
  String get tut_step2b_title => 'Steg 2 av 4 — Släpp nu';
  @override
  String get tut_step2b_body =>
      'Släpp fingret för att gå tillbaka till den översatta texten.';
  @override
  String get tut_step3a_title => 'Steg 3 av 4 — Nästa fråga';
  @override
  String get tut_step3a_body => 'Svep åt vänster för att gå till nästa fråga.';
  @override
  String get tut_step3b_title => 'Steg 4 av 4 — Kom tillbaka';
  @override
  String get tut_step3b_body =>
      'Svep nu åt höger för att gå tillbaka till föregående fråga.';
  @override
  String get tut_complete_title => 'Klart!';
  @override
  String get tut_complete_body =>
      'Bra jobbat med genomgången.\nDu vet nu hur du översätter frågor, kikar på originaltexten och navigerar mellan dem.';
  @override
  String get tut_complete_subtitle =>
      'Du är redo att förbereda dig för ditt taxikörkortsprov!';
  @override
  String get tut_start_practicing => 'Börja öva!';
  @override
  String get sg_title => 'Studiemål';
  @override
  String get sg_section_exam_date => 'PROVDATUM';
  @override
  String get sg_section_practice_days => 'ÖVNINGSDAGAR';
  @override
  String get sg_practice_days_sub =>
      'Välj de dagar du förbinder dig att öva varje vecka.';
  @override
  String get sg_days_per_week => '{n} dag(ar) / vecka';
  @override
  String get sg_save => 'Spara inställningar';
  @override
  String get sg_settings_saved => 'Inställningar sparade!';
  @override
  String get sg_months => 'MÅNADER';
  @override
  String get sg_custom_date => 'Eget datum';
  @override
  String get sg_deadline_passed => 'Provdatum har passerat';
  @override
  String get sg_days_remaining => '{n} dagar kvar';
  @override
  String get sg_notif_note =>
      'Du får två påminnelser varje övningsdag — en på morgonen och en på kvällen — vid slumpmässiga tider för att hjälpa dig bygga en vana.';
  @override
  String get sg_profile_menu_label => 'Studiemål';
  @override
  String get splash_tagline => 'HALLÅ SVERIGE';
  @override
  String get splash_loading => 'Förbereder din framgång...';
  @override
  String get splash_footer => 'AKADEMISK EXCELLENS GENOM KINETISKT LÄRANDE';
  @override
  String get onb_top_bar_title => 'KOM IGÅNG';
  @override
  String get onb_months => 'MÅNADER';
  @override
  String get onb_step1_plain => 'Vad studerar du ';
  @override
  String get onb_step1_italic => 'för?';
  @override
  String get onb_step2_plain => 'När är ditt ';
  @override
  String get onb_step2_italic => 'prov?';
  @override
  String get onb_step3_plain => 'Sätt ditt vecko-';
  @override
  String get onb_step3_italic => 'mål.';
  @override
  String get onb_step4_plain => 'Din väg till ';
  @override
  String get onb_step4_italic => 'mästerskap.';
  @override
  String get onb_step4_subtitle =>
      'Accelerera ditt lärande med personliga studieverktyg.';
  @override
  String get onb_no_plan_selected => 'Ingen plan vald.';
  @override
  String get onb_buy_bundle => 'Köp paket — {price}';
  @override
  String get onb_signin_to_purchase_title => 'Logga in för att prenumerera';
  @override
  String get onb_signin_to_purchase_subtitle =>
      'Skapa ett gratis konto eller logga in för att starta din prenumeration. Dina framsteg och prenumeration synkas på alla dina enheter.';
  @override
  String get onb_create_account_title => 'Skapa ditt gratis konto';
  @override
  String get onb_create_account_subtitle =>
      'Spara din studieplan och följ dina framsteg på alla dina enheter.';
  @override
  String get onb_start_practicing => 'Börja öva';
  @override
  String get onb_your_plan_badge => 'DIN PLAN';
  @override
  String get onb_days_per_week => 'dagar/vecka';
  @override
  String get onb_most_popular => 'MEST POPULÄR';
  @override
  String get onb_feature_mock_exams => 'Fullständigt provbibliotek';
  @override
  String get onb_feature_progress_tracking => 'Smart framstegsspårning';
  @override
  String get onb_feature_explanations => 'Detaljerade svarsförklaringar';
  @override
  String get onb_get_best_deal => 'Bästa erbjudandet';
  @override
  String get onb_best_value => 'BÄSTA VÄRDE';
  @override
  String get onb_choose_plan => 'Välj plan';
  @override
  String get onb_bundle_discount_title => 'Du får 20% rabatt';
  @override
  String get onb_bundle_saving => 'Sparar {amount}';
  @override
  String get onb_price_unavailable => 'Pris ej tillgängligt';
  @override
  String get onb_duration_year_access => '{n} års åtkomst';
  @override
  String get onb_duration_months_access => '{n} månaders åtkomst';
  @override
  String get onb_duration_one_day => '1 dag';
  @override
  String get onb_duration_days => '{n} dagar';
  @override
  String get onb_free_trial =>
      '7 DAGARS GRATIS PROVPERIOD. AVBRYT NÄR SOM HELST.';
  @override
  String get onb_start_free => 'Fortsätt som gäst';
  @override
  String get onb_skip_for_now => 'Hoppa över för nu';
  @override
  String get onb_pre_purchase_title => 'Ett snabbt steg';
  @override
  String get onb_pre_purchase_subtitle =>
      'Skapa ett gratis konto för att komma åt din prenumeration på alla dina enheter, eller fortsätt som gäst — du kan alltid skapa ett konto senare.';
  @override
  String get onb_pre_purchase_sign_in => 'Logga in / Skapa konto';
  @override
  String get onb_pre_purchase_guest => 'Fortsätt som gäst';
  @override
  String get auth_continue_as_guest => 'Fortsätt som gäst';
  @override
  String get auth_guest_session_error =>
      'Det gick inte att återställa din session. Försök igen.';
  @override
  String get free_trial_banner_badge => 'GRATIS';
  @override
  String get free_trial_banner_title =>
      'Testa vägmärken — ingen prenumeration krävs';
  @override
  String get free_trial_banner_subtitle =>
      'Vägmärkestest är helt gratis. Öva i din egen takt och känn på appen innan du prenumererar.';
  @override
  String get free_trial_banner_cta => 'Börja öva';
  @override
  String get guest_banner_title => 'Du surfar som gäst';
  @override
  String get guest_banner_subtitle =>
      'Skapa ett gratis konto för att spara dina framsteg och synka på alla dina enheter.';
  @override
  String get guest_banner_cta => 'Skapa konto';
  @override
  String get guest_convert_title => 'Spara dina framsteg';
  @override
  String get guest_convert_subtitle =>
      'Skapa ett gratis konto för att behålla allt du har övat på.';
  @override
  String get guest_username_hint => 'Välj ett användarnamn';
  @override
  String get guest_email_hint => 'E-postadress';
  @override
  String get guest_password_hint => 'Lösenord (min. 8 tecken)';
  @override
  String get guest_convert_cta => 'Skapa konto';
  @override
  String get dash_free_hub_title => 'Fullständig övning — gratis innehåll';
  @override
  String get dash_free_hub_subtitle =>
      'Övningsfrågor, teoridokument, checklistor och statistik — ingen prenumeration krävs.';
  @override
  String get dash_free_hub_badge => 'GRATIS';
  @override
  String get btn_save_changes => 'Spara ändringar';
  @override
  String get btn_set_password => 'Ange lösenord';
  @override
  String get btn_delete_account => 'Ta bort konto';
  @override
  String get btn_deleting => 'Tar bort...';
  @override
  String get btn_keep_going => 'Fortsätt';
  @override
  String get btn_exit => 'Avsluta';
  @override
  String get btn_save_and_exit => 'Spara & Avsluta';
  @override
  String get btn_submit => 'Skicka';
  @override
  String get btn_start_saved_test => 'Starta test med sparade frågor';
  @override
  String get btn_buy_now => 'Köp nu';
  @override
  String get btn_pay_now => 'Betala nu';
  @override
  String get home_all_tests_deleted => 'Alla tester har tagits bort.';
  @override
  String get home_delete_progress_title => 'Ta bort framsteg';
  @override
  String get home_delete_progress_body =>
      'Är du säker på att du vill ta bort det här sparade testet?';
  @override
  String get home_delete_all_tests_title => 'Ta bort alla tester';
  @override
  String get home_delete_all_tests_body =>
      'Är du säker på att du vill ta bort alla testförsök?';
  @override
  String get test_time_up_submitting => 'Tiden är ute! Skickar in ditt test.';
  @override
  String get test_first_question => 'Det här är den första frågan!';
  @override
  String get test_exit_title => 'Avsluta test';
  @override
  String get test_exit_save_prompt => 'Vill du spara dina framsteg?';
  @override
  String get test_save_backend_failed =>
      'Framstegen sparades på den här enheten, men synkronisering till ditt konto misslyckades. Försök igen.';
  @override
  String get test_feedback_unavailable =>
      'Feedback är inte tillgänglig för den här frågan.';
  @override
  String get test_feedback_title => 'Feedback';
  @override
  String get test_feedback_type => 'Typ';
  @override
  String get test_feedback_question_issue => 'Problem med frågan';
  @override
  String get test_feedback_wrong_answer => 'Fel svar';
  @override
  String get test_feedback_typo => 'Stavfel/textproblem';
  @override
  String get test_feedback_image_issue => 'Bildproblem';
  @override
  String get test_feedback_other => 'Övrigt';
  @override
  String get test_feedback_hint =>
      'Berätta vad som är fel med den här frågan...';
  @override
  String get test_feedback_submitted => 'Tack! Din feedback skickades.';
  @override
  String get test_feedback_failed => 'Kunde inte skicka feedback. Försök igen.';
  @override
  String get test_translation_failed =>
      'Översättningen misslyckades. Försök igen.';
  @override
  String get test_language_english => 'English';
  @override
  String get test_language_swedish => 'Svenska';
  @override
  String get test_turn_off_timer => 'Stäng av timer';
  @override
  String get test_turn_on_timer => 'Slå på timer';
  @override
  String get test_turn_off_instant_marking => 'Stäng av direkt rättning';
  @override
  String get test_turn_on_instant_marking => 'Slå på direkt rättning';
  @override
  String get test_question_saved => 'Frågan sparades';
  @override
  String get test_question_removed => 'Frågan togs bort från sparade';
  @override
  String get test_saved => 'Sparad';
  @override
  String get test_save_question => 'Spara fråga';
  @override
  String get test_questions_title => 'Frågor';
  @override
  String get test_question_progress => '{current} av {total}';
  @override
  String get test_question_label => 'Fråga {n}';
  @override
  String get test_answered => 'Besvarad';
  @override
  String get test_not_answered => 'Inte besvarad';
  @override
  String get test_finish_title => 'Avsluta test';
  @override
  String get test_finish_unanswered_prompt =>
      'Du har {count} obesvarade frågor. Vill du ändå avsluta testet?';
  @override
  String get test_finish_prompt => 'Vill du avsluta testet?';
  @override
  String get test_finish_no => 'Nej';
  @override
  String get test_finish_yes => 'Ja';
  @override
  String get test_result_congratulations => 'Grattis!';
  @override
  String get test_result_not_quite_there => 'Inte riktigt där än';
  @override
  String get test_result_passed_badge => 'GODKÄND';
  @override
  String get test_result_failed_badge => 'UNDERKÄND';
  @override
  String get test_result_pass_message => 'Du klarade testet. Bra jobbat!';
  @override
  String get test_result_fail_message =>
      'Fortsätt öva och försök igen. Du klarar det!';
  @override
  String get test_result_go_back => 'Gå tillbaka';
  @override
  String get test_result_see_results => 'Se resultat';
  @override
  String get test_result_screen_passed_title => 'Test godkänt';
  @override
  String get test_result_screen_failed_title => 'Test underkänt';
  @override
  String get test_result_question_review => 'Frågegranskning';
  @override
  String get test_result_score_label => 'Poäng';
  @override
  String get test_result_passed_message => 'Bra jobbat! Du klarade testet.';
  @override
  String get test_result_need_to_pass =>
      'Fortsätt öva. Du behöver {score}% för att bli godkänd.';
  @override
  String get test_result_correct => 'Rätt';
  @override
  String get test_result_wrong => 'Fel';
  @override
  String get test_result_skipped => 'Hoppade över';
  @override
  String get test_result_above_pass_mark => '{gap}% över godkäntgränsen';
  @override
  String get test_result_below_pass_mark => '{gap}% under godkäntgränsen';
  @override
  String get test_result_your_results => 'Dina resultat';
  @override
  String get test_result_your_score => 'Din poäng';
  @override
  String get test_result_pass_mark => 'Godkäntgräns';
  @override
  String get test_result_correct_answers => 'Rätta svar';
  @override
  String get test_result_wrong_answers => 'Felaktiga svar';
  @override
  String get test_result_question_row => 'F{n}: {text}';
  @override
  String get test_result_your_answer => 'Ditt svar: {answer}';
  @override
  String get error_too_many_requests =>
      'För många försök. Försök igen om {wait}.';
  @override
  String get error_service_unavailable =>
      'Tjänsten är tillfälligt otillgänglig. Försök igen om en stund.';
  @override
  String get error_connection_timeout =>
      'Anslutningen tog för lång tid. Kontrollera din anslutning och försök igen.';
  @override
  String get app_download_title => 'Bättre i appen';
  @override
  String get app_download_subtitle_android =>
      'Ladda ner Drive Test-appen på Google Play för en snabbare och smidigare upplevelse.';
  @override
  String get app_download_subtitle_ios =>
      'Ladda ner Drive Test-appen från App Store för en snabbare och smidigare upplevelse.';
  @override
  String get app_download_cta_android => 'Ladda ner på Google Play';
  @override
  String get app_download_cta_ios => 'Ladda ner från App Store';
  @override
  String get app_download_learn_more => 'Läs mer på drivetest.se';
  @override
  String get app_download_dismiss => 'Fortsätt i webbläsaren';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on TranslationsSv {
  dynamic _flatMapFunction(String path) {
    switch (path) {
      case 'home':
        return 'Hem';
      case 'tests':
        return 'Prov';
      case 'profile':
        return 'Profil';
      case 'welcome_message':
        return 'Välkommen till Drive Test';
      case 'save':
        return 'Spara';
      case 'cancel':
        return 'Avbryt';
      case 'delete':
        return 'Ta bort';
      case 'logout':
        return 'Logga ut';
      case 'loading':
        return 'Laddar...';
      case 'settings_title':
        return 'Inställningar';
      case 'settings_appearance':
        return 'Utseende';
      case 'settings_test_prefs':
        return 'Provpreferenser';
      case 'settings_timed_test':
        return 'Tidsbegränsat prov';
      case 'settings_timed_test_sub':
        return 'Aktivera tidsgräns för provet';
      case 'settings_instant_marking':
        return 'Omedelbar rättning';
      case 'settings_instant_marking_sub':
        return 'Visa rätt svar efter varje fråga';
      case 'settings_num_questions':
        return 'Antal frågor';
      case 'settings_enter_num':
        return 'Ange antal frågor:';
      case 'settings_include_saved':
        return 'Inkludera sparade frågor';
      case 'settings_include_saved_sub':
        return 'Inkludera frågor du tidigare sparat';
      case 'settings_notifications':
        return 'Aviseringar';
      case 'settings_notifications_toggle':
        return 'Push-aviseringar';
      case 'settings_notifications_on_sub':
        return 'Du kommer att få påminnelser och uppdateringar om dina prov';
      case 'settings_notifications_off_sub':
        return 'Aviseringar är avstängda';
      case 'settings_notifications_denied':
        return 'Behörighet nekad — tryck nedan för att öppna Inställningar';
      case 'settings_notifications_open_settings':
        return 'Öppna inställningar';
      case 'settings_dark_mode':
        return 'Mörkt läge';
      case 'settings_dark_mode_sub':
        return 'Växla mellan ljust och mörkt tema';
      case 'settings_language':
        return 'Språk';
      case 'settings_language_sub':
        return 'Välj ditt föredragna språk';
      case 'settings_version':
        return 'Versionsinformation';
      case 'settings_app_version':
        return 'Appversion';
      case 'settings_commit':
        return 'Commit';
      case 'settings_branch':
        return 'Gren';
      case 'settings_last_update':
        return 'Senaste uppdatering';
      case 'settings_date':
        return 'Datum';
      case 'settings_saved':
        return 'Inställningar sparades';
      case 'profile_student':
        return 'STUDENT';
      case 'profile_edit':
        return 'Redigera profil';
      case 'profile_stats':
        return 'Mina resultat';
      case 'profile_statistics':
        return 'Statistik';
      case 'stats_no_tests_yet':
        return 'Inga avslutade prov ännu';
      case 'stats_attempt_history':
        return 'FÖRSÖKSHISTORIK';
      case 'stats_avg_time':
        return 'Snittid';
      case 'stats_attempt_one':
        return 'försök';
      case 'stats_attempt_many':
        return 'försök';
      case 'stats_avg_label':
        return 'Snitt';
      case 'stats_unknown':
        return 'Okänt';
      case 'stats_best':
        return 'Bäst';
      case 'stats_average':
        return 'Snitt';
      case 'home_attempt_details':
        return 'Försöksdetaljer';
      case 'home_saved_questions_title':
        return 'Sparade frågor';
      case 'profile_settings':
        return 'Inställningar';
      case 'profile_invite':
        return 'Bjud in en vän';
      case 'profile_help':
        return 'Hjälp';
      case 'profile_manage_subscription':
        return 'Hantera prenumeration';
      case 'profile_purchase_history':
        return 'Köphistorik';
      case 'profile_receipt_title':
        return 'Kvitto';
      case 'profile_receipt_copy_number':
        return 'Kopiera kvittonummer';
      case 'profile_receipt_number_copied':
        return 'Kvittonummer kopierat';
      case 'profile_no_purchases':
        return 'Inga köp ännu.';
      case 'profile_receipt_payment_receipt':
        return 'Betalningskvitto';
      case 'profile_receipt_no':
        return 'Kvittonr.';
      case 'profile_receipt_product':
        return 'Produkt';
      case 'profile_receipt_duration':
        return 'Varaktighet';
      case 'profile_receipt_amount_paid':
        return 'Betalt belopp';
      case 'profile_receipt_payment_via':
        return 'Betalning via';
      case 'profile_receipt_via_iap':
        return 'Apple App Store';
      case 'profile_receipt_via_card':
        return 'Kort (Stripe)';
      case 'profile_receipt_transaction_id':
        return 'Transaktions-ID';
      case 'profile_receipt_payment_intent':
        return 'Betalningsavsikt';
      case 'profile_receipt_reference_no':
        return 'Referensnr.';
      case 'profile_receipt_footer':
        return 'Spara detta kvitto. Kontakta support med ditt kvittonummer om du har frågor om detta köp.';
      case 'profile_revisit_setup':
        return 'Gör om inställningar';
      case 'profile_send_feedback':
        return 'Skicka feedback';
      case 'profile_logout_confirm':
        return 'Är du säker på att du vill logga ut?';
      case 'profile_yes_logout':
        return 'Ja, logga ut';
      case 'home_dashboard':
        return 'Instrumentpanel';
      case 'home_my_progress':
        return 'Min framsteg';
      case 'home_overall_score':
        return 'Totalt resultat';
      case 'home_passed':
        return 'Godkänd';
      case 'home_failed':
        return 'Underkänd';
      case 'home_total':
        return 'Totalt';
      case 'home_in_progress':
        return 'Pågående';
      case 'home_recent_activity':
        return 'Senaste aktivitet';
      case 'home_by_category':
        return 'Per kategori';
      case 'home_this_week':
        return 'Denna vecka';
      case 'home_this_month':
        return 'Denna månad';
      case 'home_no_attempts':
        return 'Inga försök än!';
      case 'home_no_attempts_sub':
        return 'När du slutfört ett prov visas dina resultat här.';
      case 'home_take_quiz':
        return 'Ta ditt första prov';
      case 'home_paused':
        return 'Pausad';
      case 'home_resume':
        return 'Återuppta';
      case 'home_attempts':
        return 'försök';
      case 'home_active':
        return 'aktiv';
      case 'home_tests':
        return 'prov';
      case 'intro_slide1_body':
        return 'Lär dig och öva inför ditt körkort enkelt.';
      case 'intro_slide2_title':
        return 'Interaktiva prov';
      case 'intro_slide2_body':
        return 'Övningsprov med direkt feedback och förklaringar.';
      case 'intro_slide3_title':
        return 'Bli godkänd';
      case 'intro_slide3_body':
        return 'Klara dina prov och bli en godkänd förare.';
      case 'intro_skip':
        return 'Hoppa över';
      case 'intro_get_started':
        return 'Kom igång';
      case 'auth_welcome_title':
        return 'Välkommen till Drive Test!';
      case 'auth_welcome_subtitle':
        return 'Öva. Klara prov tryggt.';
      case 'auth_login_btn':
        return 'LOGGA IN';
      case 'auth_signup_btn':
        return 'REGISTRERA';
      case 'auth_skip_demo':
        return 'HOPPA ÖVER (PROVA DEMO)';
      case 'auth_demo_error':
        return 'Kunde inte logga in med demokontot. Försök igen.';
      case 'auth_or':
        return 'ELLER';
      case 'auth_login_title':
        return 'Logga in';
      case 'auth_contact_support':
        return 'Kontakta support';
      case 'auth_username':
        return 'Användarnamn eller e-post';
      case 'auth_email':
        return 'E-post';
      case 'auth_password':
        return 'Lösenord';
      case 'auth_remember_me':
        return 'Kom ihåg mig';
      case 'auth_forgot_password':
        return 'Glömt lösenord?';
      case 'auth_invalid_credentials':
        return 'Ogiltigt användarnamn eller lösenord';
      case 'auth_no_account':
        return 'Har du inget konto? ';
      case 'auth_sign_up_link':
        return 'Registrera dig';
      case 'auth_skip_demo_short':
        return 'Hoppa över (Prova demo)';
      case 'auth_google_continue':
        return 'Fortsätt med Google';
      case 'auth_feedback_type':
        return 'Typ';
      case 'auth_feedback_email_optional':
        return 'E-post (valfritt)';
      case 'auth_feedback_subject_optional':
        return 'Ämne (valfritt)';
      case 'auth_feedback_message':
        return 'Meddelande';
      case 'auth_feedback_sent':
        return 'Tack! Din feedback skickades.';
      case 'auth_feedback_error':
        return 'Kunde inte skicka feedback. Försök igen.';
      case 'auth_submit':
        return 'Skicka';
      case 'auth_feedback_login_issue':
        return 'Inloggningsproblem';
      case 'auth_feedback_signup_issue':
        return 'Registreringsproblem';
      case 'auth_feedback_app_issue':
        return 'Appproblem';
      case 'auth_feedback_feature_request':
        return 'Funktionsförfrågan';
      case 'auth_feedback_other':
        return 'Övrigt';
      case 'auth_create_account':
        return 'Skapa konto';
      case 'auth_sign_up_btn':
        return 'Registrera';
      case 'auth_val_username_required':
        return 'Vänligen ange ditt användarnamn eller e-post';
      case 'auth_val_username_length':
        return 'Användarnamnet måste vara minst 4 tecken';
      case 'auth_val_email_required':
        return 'Vänligen ange en e-postadress';
      case 'auth_val_email_invalid':
        return 'Vänligen ange en giltig e-postadress';
      case 'auth_val_password_required':
        return 'Vänligen ange ett lösenord';
      case 'auth_val_password_length':
        return 'Lösenordet måste vara minst 6 tecken';
      case 'auth_signup_success':
        return 'Registreringen lyckades! Vänligen logga in.';
      case 'auth_welcome_first_login':
        return 'Välkommen, lycka till!';
      case 'auth_welcome_returning':
        return 'Välkommen tillbaka igen!';
      case 'auth_deleted_account_welcome_back':
        return 'Alltid välkommen tillbaka.';
      case 'auth_signup_failed':
        return 'Registreringen misslyckades. Rätta felen.';
      case 'auth_generic_error':
        return 'Ett fel uppstod. Försök igen.';
      case 'auth_express_google':
        return 'Express-inloggning via Google';
      case 'auth_google_label':
        return 'Google';
      case 'auth_express_apple':
        return 'Logga in med Apple';
      case 'auth_apple_label':
        return 'Apple';
      case 'auth_signing_in':
        return 'Loggar in...';
      case 'auth_tab_login':
        return 'Logga in';
      case 'auth_tab_signup':
        return 'Registrera dig';
      case 'auth_show_password':
        return 'Visa';
      case 'auth_hide_password':
        return 'Dölj';
      case 'auth_forgot_title':
        return 'Glömt lösenord';
      case 'auth_forgot_heading':
        return 'Återställ ditt lösenord';
      case 'auth_forgot_subtitle':
        return 'Ange din e-postadress så skickar vi instruktioner för att återställa ditt lösenord.';
      case 'auth_forgot_email_label':
        return 'E-postadress';
      case 'auth_forgot_send_btn':
        return 'Skicka instruktioner';
      case 'auth_forgot_back_login':
        return 'Tillbaka till inloggning';
      case 'auth_forgot_success':
        return 'Instruktioner för lösenordsåterställning har skickats till din e-post.';
      case 'auth_forgot_error':
        return 'Det gick inte att skicka återställningsmail. Försök igen.';
      case 'auth_verify_title':
        return 'Verifiera kod';
      case 'auth_verify_heading':
        return 'Kontrollera din e-post';
      case 'auth_verify_subtitle':
        return 'Vi skickade en återställningskod till\n{email}';
      case 'auth_verify_code_label':
        return 'Återställningskod';
      case 'auth_verify_code_hint':
        return 'Ange koden från din e-post';
      case 'auth_verify_code_empty':
        return 'Vänligen ange återställningskoden från din e-post.';
      case 'auth_verify_resend':
        return 'Skicka om kod';
      case 'auth_reset_title':
        return 'Återställ lösenord';
      case 'auth_reset_heading':
        return 'Ange nytt lösenord';
      case 'auth_reset_subtitle':
        return 'Ange ditt nya lösenord';
      case 'auth_reset_new_password_label':
        return 'Nytt lösenord';
      case 'auth_reset_confirm_password_label':
        return 'Bekräfta lösenord';
      case 'auth_reset_empty':
        return 'Vänligen ange ett nytt lösenord.';
      case 'auth_reset_mismatch':
        return 'Lösenorden stämmer inte överens.';
      case 'auth_reset_invalid_code':
        return 'Ogiltig eller utgången kod. Försök att begära en ny återställningslänk.';
      case 'auth_reset_success_title':
        return 'Klart!';
      case 'auth_reset_success_body':
        return 'Ditt lösenord har återställts. Du kan nu logga in med ditt nya lösenord.';
      case 'auth_reset_go_to_login':
        return 'Gå till inloggning';
      case 'auth_google_connecting':
        return 'Ansluter till Google...';
      case 'auth_google_verifying':
        return 'Verifierar konto...';
      case 'auth_google_signing_in':
        return 'Loggar in...';
      case 'auth_google_creating':
        return 'Skapar ditt konto...';
      case 'auth_google_loading':
        return 'Laddar din profil...';
      case 'auth_landing_subtitle':
        return 'Din resa mot framgång börjar med ett tryck.';
      case 'auth_landing_new_here':
        return 'Ny här?';
      case 'auth_create_account_link':
        return 'Skapa ett konto';
      case 'auth_login_heading':
        return 'Välkommen\ntillbaka';
      case 'auth_login_subtitle':
        return 'Fortsätt din inlärningsresa.';
      case 'auth_username_hint':
        return 'användarnamn eller e-post';
      case 'auth_signup_heading_plain':
        return 'Gå med i';
      case 'auth_signup_heading_italic':
        return 'Rörelsen.';
      case 'auth_signup_subtitle':
        return 'Accelerera din inlärning idag.';
      case 'auth_signup_username_hint':
        return 'Erik Andersson';
      case 'auth_signup_email_hint':
        return 'erik@example.se';
      case 'auth_have_account':
        return 'Har du redan ett konto?';
      case 'auth_reset_onboarding_tooltip':
        return 'Återställ onboarding';
      case 'auth_language_english':
        return 'Engelska';
      case 'auth_language_swedish':
        return 'Svenska';
      case 'brand_drive':
        return 'DRIVE ';
      case 'brand_test':
        return 'TEST';
      case 'purchase_success_title':
        return 'Ditt köp har\nbekräftats';
      case 'purchase_success_start_tests':
        return 'Starta prov';
      case 'purchase_success_back_home':
        return 'Tillbaka till start';
      case 'bcd_drive_test':
        return 'Drive Test';
      case 'bcd_exams':
        return 'Prov';
      case 'bcd_exams_sub':
        return 'Licenser, kategorier & prov';
      case 'bcd_traffic_signs':
        return 'Trafikskyltar';
      case 'bcd_traffic_signs_sub':
        return 'Bläddra bland alla trafikskyltar';
      case 'bcd_subscriptions':
        return 'Prenumerationer';
      case 'bcd_subscriptions_sub':
        return 'Visa planer och hantera åtkomst';
      case 'bcd_hub_practice':
        return 'Övning';
      case 'bcd_hub_tests':
        return 'Prov';
      case 'bcd_hub_theory_docs':
        return 'Teori-\ndokument';
      case 'bcd_hub_traffic_signs':
        return 'Trafikskyltar';
      case 'bcd_hub_checklist':
        return 'Checklista';
      case 'bcd_hub_statistics':
        return 'Statistik';
      case 'bcd_hub_saved_questions':
        return 'Sparade\nfrågor';
      case 'bcd_no_free_practice':
        return 'Inget gratis övningsprov tillgängligt för denna kategori.';
      case 'bcd_failed_practice':
        return 'Det gick inte att ladda övningsprovet.';
      case 'bcd_no_saved_questions':
        return 'Inga sparade frågor i denna kategori ännu.';
      case 'bcd_no_saved_questions_found':
        return 'Inga sparade frågor hittades i denna kategori.';
      case 'bcd_failed_saved':
        return 'Det gick inte att ladda sparade frågor.';
      case 'bcd_no_subscription':
        return 'Du har ingen aktiv prenumeration för denna kategori';
      case 'bcd_free_content_desc':
        return 'Övning, Trafikskyltar, Dokument och Checklistor är gratis. Prenumerera för att låsa upp Prov.';
      case 'bcd_buy_subscription':
        return 'Köp prenumeration';
      case 'bcd_buy_subscription_arrow':
        return 'Köp prenumeration →';
      case 'bcd_not_subscribed':
        return 'Du prenumererar inte på denna kategori';
      case 'bcd_only_free_tests':
        return 'Endast gratis övningsprov är tillgängliga. Prenumerera för att låsa upp alla prov.';
      case 'bcd_no_free_practice_tests':
        return 'Inga gratis övningsprov tillgängliga.';
      case 'bcd_no_tests':
        return 'Inga prov tillgängliga.';
      case 'bcd_no_documents':
        return 'Inga dokument tillgängliga.';
      case 'bcd_no_checklists':
        return 'Inga checklistor tillgängliga.';
      case 'bcd_failed_tests':
        return 'Det gick inte att ladda prov';
      case 'bcd_subscription_required':
        return 'Prenumeration krävs';
      case 'bcd_subscribe_access':
        return 'Prenumerera för att få tillgång till "{name}" och allt dess innehåll.';
      case 'bcd_not_now':
        return 'Inte nu';
      case 'legal_terms_of_use':
        return 'Användarvillkor';
      case 'legal_privacy_policy':
        return 'Integritetspolicy';
      case 'bcd_buy':
        return 'Köp';
      case 'bcd_payment_failed':
        return 'Betalning misslyckades. Försök igen.';
      case 'iap_owned_by_other_title':
        return 'Prenumeration redan kopplad';
      case 'iap_owned_by_other_body':
        return 'Den här prenumerationen är kopplad till ett annat konto. Logga in med det konto du ursprungligen köpte den på.';
      case 'iap_owned_by_other_ok':
        return 'OK';
      case 'bcd_feedback_unavailable':
        return 'Feedback ej tillgänglig för denna fråga.';
      case 'bcd_feedback_submitted':
        return 'Tack! Din feedback skickades.';
      case 'bcd_feedback_failed':
        return 'Kunde inte skicka feedback. Försök igen.';
      case 'bcd_categories':
        return 'Kategorier';
      case 'bcd_search_categories':
        return 'Sök kategorier…';
      case 'bcd_no_categories':
        return 'Inga kategorier tillgängliga.';
      case 'bcd_no_match_search':
        return 'Inga träffar hittades.';
      case 'bcd_subscribed':
        return 'Prenumererar';
      case 'bcd_tap_to_subscribe':
        return 'Tryck för att prenumerera';
      case 'bcd_failed_categories':
        return 'Det gick inte att ladda kategorier';
      case 'bcd_plans_tab':
        return 'Planer';
      case 'bcd_my_subscriptions_tab':
        return 'Mina prenumerationer';
      case 'bcd_no_plans':
        return 'Inga planer tillgängliga';
      case 'bcd_active_label':
        return 'Aktiv';
      case 'bcd_subscribe_btn':
        return 'Prenumerera';
      case 'bcd_start_practice':
        return 'Börja öva';
      case 'bcd_no_active_subscriptions':
        return 'Inga aktiva prenumerationer';
      case 'bcd_browse_plans':
        return 'Bläddra bland planer för att komma igång';
      case 'bcd_expires':
        return 'Upphör';
      case 'bcd_failed_plans':
        return 'Det gick inte att ladda planer';
      case 'bcd_no_categories_linked':
        return 'Inga kategorier kopplade till den här prenumerationen';
      case 'bcd_failed_category':
        return 'Det gick inte att ladda kategorin';
      case 'bcd_search_signs':
        return 'Sök skyltgrupper…';
      case 'bcd_no_signs':
        return 'Inga skyltar hittades';
      case 'bcd_no_image':
        return 'Ingen bild';
      case 'bcd_signs_count_label':
        return 'trafikskyltar';
      case 'bcd_view':
        return 'Visa';
      case 'bcd_previous':
        return 'Föregående';
      case 'bcd_next':
        return 'Nästa';
      case 'bcd_failed_traffic_signs':
        return 'Det gick inte att ladda trafikskyltar';
      case 'bcd_search_hint':
        return 'Sök…';
      case 'bcd_no_subcategories':
        return 'Inga underkategorier tillgängliga.';
      case 'bcd_failed_subcategories':
        return 'Det gick inte att ladda underkategorier';
      case 'bcd_no_questions':
        return 'Inga frågor hittades för det här provet.';
      case 'bcd_failed_test_questions':
        return 'Det gick inte att ladda provfrågor.';
      case 'bcd_questions_label':
        return 'frågor';
      case 'bcd_pass_label':
        return 'Godkänt';
      case 'bcd_free_label':
        return 'GRATIS';
      case 'settings_theme_label':
        return 'Tema';
      case 'settings_theme_sub':
        return 'Ljust, mörkt eller följ systemet';
      case 'settings_theme_system':
        return 'System';
      case 'settings_theme_light':
        return 'Ljust';
      case 'settings_theme_dark':
        return 'Mörkt';
      case 'help_title':
        return 'Hjälp & Support';
      case 'help_need_help':
        return 'Behöver du hjälp?';
      case 'help_subtitle':
        return 'Berätta om ditt problem så återkommer vi till dig.';
      case 'help_your_information':
        return 'Din information';
      case 'help_username':
        return 'Användarnamn';
      case 'help_email':
        return 'E-post';
      case 'help_user_id':
        return 'Användar-ID';
      case 'help_subject':
        return 'Ämne';
      case 'help_subject_hint':
        return 't.ex. Inloggningsproblem, Buggrapport, Funktionsförfrågan';
      case 'help_subject_required':
        return 'Ange ett ämne';
      case 'help_description':
        return 'Beskrivning';
      case 'help_description_hint':
        return 'Beskriv ditt problem i detalj...';
      case 'help_description_required':
        return 'Beskriv ditt problem';
      case 'help_description_too_short':
        return 'Ge mer information (minst 10 tecken)';
      case 'help_submit':
        return 'Skicka rapport';
      case 'help_or_email':
        return 'Eller mejla oss direkt på mohsin.sapra@gmail.com';
      case 'help_opening_email':
        return 'Öppnar e-postappen...';
      case 'help_email_error':
        return 'Kunde inte öppna e-postappen. Mejla mohsin.sapra@gmail.com direkt.';
      case 'help_generic_error':
        return 'Fel vid öppning av e-postappen. Försök igen.';
      case 'notifications_title':
        return 'Aviseringar';
      case 'notifications_mark_all_read':
        return 'Markera alla som lästa';
      case 'notifications_clear':
        return 'Rensa';
      case 'notifications_clear_confirm_title':
        return 'Rensa alla aviseringar?';
      case 'notifications_clear_confirm_body':
        return 'Detta tar bort alla aviseringar. Åtgärden kan inte ångras.';
      case 'notifications_empty_title':
        return 'Inga aviseringar';
      case 'notifications_empty_subtitle':
        return 'Du är à jour! Vi meddelar dig när något nytt händer.';
      case 'notifications_just_now':
        return 'Just nu';
      case 'notifications_minutes_ago':
        return '{n} min sedan';
      case 'notifications_hours_ago':
        return '{n} tim sedan';
      case 'notifications_days_ago':
        return '{n} dagar sedan';
      case 'notifications_permission_off_title':
        return 'Aviseringar är avstängda';
      case 'notifications_permission_denied_body':
        return 'Du har nekat behörighet för aviseringar. Öppna Inställningar för att aktivera dem.';
      case 'notifications_permission_not_determined_body':
        return 'Tillåt aviseringar för att hålla dig uppdaterad om dina provframsteg och påminnelser.';
      case 'notifications_permission_open_settings':
        return 'Öppna inställningar';
      case 'notifications_permission_enable':
        return 'Aktivera aviseringar';
      case 'notifications_permission_web_dialog_title':
        return 'Aktivera i webbläsaren';
      case 'notifications_permission_web_dialog_body':
        return 'För att aktivera aviseringar, klicka på låsikonen (🔒) i webbläsarens adressfält, hitta "Aviseringar" och ställ in det på "Tillåt". Ladda sedan om sidan.';
      case 'notifications_permission_web_dialog_ok':
        return 'Förstått';
      case 'image_viewer_swipe_to_close':
        return 'Svep nedåt för att stänga';
      case 'image_viewer_load_error':
        return 'Kunde inte ladda bilden';
      case 'dash_my_progress':
        return 'Mina framsteg';
      case 'dash_sync_from_server':
        return 'Synkronisera från server';
      case 'dash_unknown_error':
        return 'Något gick fel. Försök igen.';
      case 'dash_network_error':
        return 'Ingen internetanslutning. Kontrollera din anslutning och försök igen.';
      case 'dash_server_error':
        return 'Serverfel. Försök igen senare.';
      case 'dash_retry':
        return 'Försök igen';
      case 'dash_my_exams':
        return 'Mina prov';
      case 'dash_tap_to_dive':
        return 'Tryck på ett prov för att utforska';
      case 'dash_overview':
        return 'Översikt';
      case 'dash_categories_header':
        return 'Kategorier';
      case 'dash_batches_header':
        return 'Omgångar';
      case 'dash_expand_categories':
        return 'Expandera en kategori för att se omgångar';
      case 'dash_weekly_streak':
        return 'Veckosvit';
      case 'dash_consistency_builds':
        return 'Regelbundenhet bygger mästerskap';
      case 'dash_smart_insights':
        return 'Smarta insikter';
      case 'dash_based_on_attempts':
        return 'Baserat på dina försök';
      case 'dash_continue_label':
        return 'Fortsätt: {name}';
      case 'dash_total_attempts':
        return 'Totala försök';
      case 'dash_batches_done':
        return 'Avklarade omgångar';
      case 'dash_avg_time':
        return 'Snittid';
      case 'dash_weakest_label':
        return 'Svagast: {name} ({score}%)';
      case 'dash_batches_completed_label':
        return '{done}/{total} omgångar avklarade';
      case 'dash_weakness_low_score':
        return 'Lågt resultat';
      case 'dash_weakness_over_time':
        return 'Tar för lång tid';
      case 'dash_weakness_needs_work':
        return 'Behöver övas';
      case 'dash_weakness_on_track':
        return 'På rätt spår';
      case 'dash_not_started':
        return 'Ej påbörjad';
      case 'dash_attempt_one':
        return '1 försök';
      case 'dash_attempt_many':
        return '{n} försök';
      case 'dash_avg_duration':
        return 'Snitt {duration}';
      case 'dash_over_time_pct':
        return '+{pct}% tid';
      case 'dash_on_time':
        return 'I tid';
      case 'dash_insight_strongest':
        return 'Starkaste område';
      case 'dash_insight_weakest':
        return 'Svagaste område';
      case 'dash_insight_focus':
        return 'Fokusrekommendation';
      case 'dash_insight_continue_learning':
        return 'Fortsätt lära dig';
      case 'dash_insight_area_detail':
        return '{name} — {score}% snitt';
      case 'dash_insight_focus_detail':
        return 'Arbeta med {name} härnäst för att fortsätta framåt';
      case 'dash_insight_start':
        return 'Börja med {name} — välj vilken omgång som helst.';
      case 'dash_insight_all_done':
        return 'Alla omgångar avklarade! Repetera omgångar med lågt resultat.';
      case 'dash_insight_progress':
        return '{done}/{total} omgångar godkända. Fortsätt — du är {pct}% på väg!';
      case 'dash_streak_current':
        return 'Nuvarande\nsvit';
      case 'dash_streak_best':
        return 'Bästa\nsvit';
      case 'dash_streak_weekly_goal':
        return 'Veckans mål';
      case 'dash_day_mon':
        return 'M';
      case 'dash_day_tue':
        return 'T';
      case 'dash_day_wed':
        return 'O';
      case 'dash_day_thu':
        return 'T';
      case 'dash_day_fri':
        return 'F';
      case 'dash_day_sat':
        return 'L';
      case 'dash_day_sun':
        return 'S';
      case 'dash_streak_msg_none':
        return 'Starta en session idag för att börja din svit!';
      case 'dash_streak_msg_amazing':
        return 'Fantastiskt! {n} dagar i rad — håll i det!';
      case 'dash_streak_msg_goal':
        return 'Veckans mål nått! Du är i full gång 🔥';
      case 'dash_streak_msg_progress_one':
        return '{n} dagars svit! 1 session kvar för att nå veckans mål.';
      case 'dash_streak_msg_progress_other':
        return '{n} dagars svit! {left} sessioner kvar för att nå veckans mål.';
      case 'dash_completed':
        return 'Avklarad!';
      case 'dash_tap_to_explore':
        return 'Tryck för att utforska';
      case 'onb_which_exams':
        return 'Vilka prov förbereder du dig för?';
      case 'onb_select_all_apply':
        return 'Välj alla som passar';
      case 'onb_exam_date_title':
        return 'När är ditt prov?';
      case 'onb_exam_date_subtitle':
        return 'Sätt ett måldatum för att hålla koll';
      case 'onb_practice_days_title':
        return 'Hur många dagar i veckan kommer du öva?';
      case 'onb_practice_days_subtitle':
        return 'Var realistisk — konsistens är nyckeln';
      case 'onb_recommendations_title':
        return 'Rekommenderade för dig';
      case 'onb_recommendations_subtitle':
        return 'Prenumerera för full tillgång till dessa prov';
      case 'onb_continue':
        return 'Fortsätt';
      case 'onb_weekday_mon_short':
        return 'M';
      case 'onb_weekday_tue_short':
        return 'T';
      case 'onb_weekday_wed_short':
        return 'O';
      case 'onb_weekday_thu_short':
        return 'T';
      case 'onb_weekday_fri_short':
        return 'F';
      case 'onb_weekday_sat_short':
        return 'L';
      case 'onb_weekday_sun_short':
        return 'S';
      case 'onb_get_started':
        return 'Kom igång';
      case 'onb_1_week':
        return '1 vecka';
      case 'onb_2_weeks':
        return '2 veckor';
      case 'onb_3_weeks':
        return '3 veckor';
      case 'onb_1_month':
        return '1 månad';
      case 'onb_2_months':
        return '2 månader';
      case 'onb_3_months':
        return '3 månader';
      case 'onb_custom_date':
        return 'Eget datum';
      case 'onb_subscribe':
        return 'Prenumerera';
      case 'onb_sign_in_to_subscribe':
        return 'Logga in för att prenumerera';
      case 'onb_sign_in_subtitle':
        return 'Skapa ett gratis konto eller logga in för att få tillgång till fullständiga prov';
      case 'onb_no_exams':
        return 'Inga prov tillgängliga just nu';
      case 'onb_days_week_label':
        return '{n} dagar/vecka';
      case 'onb_step_of':
        return 'Steg {current} av {total}';
      case 'onb_weekly_goal_title':
        return 'Veckovis studiemål';
      case 'onb_weekly_goal_sub':
        return 'Välj de dagar du ska studera.';
      case 'dash_exam_deadline':
        return 'Provdatum';
      case 'dash_days_remaining':
        return '{n} dagar kvar';
      case 'dash_deadline_today':
        return 'Idag!';
      case 'dash_deadline_passed':
        return 'Deadline passerad';
      case 'dash_no_deadline':
        return 'Ingen deadline satt';
      case 'dash_set_deadline':
        return 'Sätt deadline';
      case 'dash_change_deadline':
        return 'Ändra deadline';
      case 'dash_practice_days':
        return '{n} dagar/vecka';
      case 'dash_hero_sub_start':
        return 'Dags att börja din resa!';
      case 'dash_hero_sub_progress':
        return 'Bra jobbat – fortsätt framåt!';
      case 'dash_hero_sub_almost':
        return 'Snart redo för examen!';
      case 'dash_hero_sub_done':
        return 'Allt avklarat – bra jobbat!';
      case 'dash_performance_overview':
        return 'Prestationsöversikt';
      case 'dash_focus_areas':
        return 'Fokusområden';
      case 'dash_no_exams_found':
        return 'Inga prov hittades.';
      case 'dash_card_active':
        return 'AKTIV';
      case 'dash_card_inactive':
        return 'INAKTIV';
      case 'dash_card_expired':
        return 'Upphörde {date}';
      case 'dash_card_expires_today':
        return 'Löper ut idag';
      case 'dash_card_expires_tomorrow':
        return 'Löper ut imorgon';
      case 'dash_card_expires_days':
        return 'Löper ut om {days} dagar';
      case 'dash_card_expires_on':
        return 'Löper ut {date}';
      case 'dash_stat_completed':
        return 'Klart';
      case 'dash_stat_none_yet':
        return 'Inga ännu';
      case 'dash_stat_of_n':
        return 'av {total}';
      case 'dash_stat_per_session':
        return 'Per omgång';
      case 'dash_perf_title1':
        return 'Prestations';
      case 'dash_perf_title2':
        return 'översikt';
      case 'dash_period_today':
        return 'Idag';
      case 'dash_period_7days':
        return '7 dagar';
      case 'dash_period_all':
        return 'Hela tiden';
      case 'dash_perf_subtitle':
        return 'Följ dina framsteg. Nå dina mål.';
      case 'dash_perf_attempts_desc':
        return 'Alla dina försök under perioden';
      case 'dash_perf_batches_desc':
        return 'Framsteg denna period';
      case 'dash_avg_time_per_session':
        return 'Snittid / pass';
      case 'dash_perf_time_desc':
        return 'Genomsnittlig tid per pass';
      case 'dash_keep_it_up':
        return 'Fortsätt så!';
      case 'dash_consistency_today':
        return 'Regelbundenhet idag, framgång imorgon.';
      case 'dash_exam_type_taxi':
        return 'TAXI';
      case 'dash_exam_type_test':
        return 'PROV';
      case 'dash_streak_title':
        return '{n} dagars svit!';
      case 'dash_streak_days':
        return '{n} dagar';
      case 'dash_batches_count':
        return '{n} omgångar';
      case 'dash_avg_score_label':
        return '{score}% snitt';
      case 'dash_new_test':
        return '+ Nytt test';
      case 'dash_no_attempts_yet':
        return 'Inga försök ännu';
      case 'dash_previous_attempts':
        return 'Tidigare försök';
      case 'dash_see_all':
        return 'Se alla';
      case 'dash_all_attempts':
        return 'Alla försök';
      case 'tut_step1_title':
        return 'Steg 1 av 3 — Översätt';
      case 'tut_step1_body':
        return 'Tryck på språkknappen för att öppna listan och välj sedan engelska (eller valfritt annat språk).';
      case 'tut_step1b_title':
        return 'Steg 1 av 3 — Välj ett språk';
      case 'tut_step1b_body':
        return 'Välj ett annat språk från listan, till exempel engelska.';
      case 'tut_step2a_title':
        return 'Steg 2 av 4 — Kika på originalet';
      case 'tut_step2a_body':
        return 'Tryck och håll var som helst på frågan (inte svarsalternativen) för att tillfälligt se den ursprungliga svenska texten.';
      case 'tut_step2b_title':
        return 'Steg 2 av 4 — Släpp nu';
      case 'tut_step2b_body':
        return 'Släpp fingret för att gå tillbaka till den översatta texten.';
      case 'tut_step3a_title':
        return 'Steg 3 av 4 — Nästa fråga';
      case 'tut_step3a_body':
        return 'Svep åt vänster för att gå till nästa fråga.';
      case 'tut_step3b_title':
        return 'Steg 4 av 4 — Kom tillbaka';
      case 'tut_step3b_body':
        return 'Svep nu åt höger för att gå tillbaka till föregående fråga.';
      case 'tut_complete_title':
        return 'Klart!';
      case 'tut_complete_body':
        return 'Bra jobbat med genomgången.\nDu vet nu hur du översätter frågor, kikar på originaltexten och navigerar mellan dem.';
      case 'tut_complete_subtitle':
        return 'Du är redo att förbereda dig för ditt taxikörkortsprov!';
      case 'tut_start_practicing':
        return 'Börja öva!';
      case 'sg_title':
        return 'Studiemål';
      case 'sg_section_exam_date':
        return 'PROVDATUM';
      case 'sg_section_practice_days':
        return 'ÖVNINGSDAGAR';
      case 'sg_practice_days_sub':
        return 'Välj de dagar du förbinder dig att öva varje vecka.';
      case 'sg_days_per_week':
        return '{n} dag(ar) / vecka';
      case 'sg_save':
        return 'Spara inställningar';
      case 'sg_settings_saved':
        return 'Inställningar sparade!';
      case 'sg_months':
        return 'MÅNADER';
      case 'sg_custom_date':
        return 'Eget datum';
      case 'sg_deadline_passed':
        return 'Provdatum har passerat';
      case 'sg_days_remaining':
        return '{n} dagar kvar';
      case 'sg_notif_note':
        return 'Du får två påminnelser varje övningsdag — en på morgonen och en på kvällen — vid slumpmässiga tider för att hjälpa dig bygga en vana.';
      case 'sg_profile_menu_label':
        return 'Studiemål';
      case 'splash_tagline':
        return 'HALLÅ SVERIGE';
      case 'splash_loading':
        return 'Förbereder din framgång...';
      case 'splash_footer':
        return 'AKADEMISK EXCELLENS GENOM KINETISKT LÄRANDE';
      case 'onb_top_bar_title':
        return 'KOM IGÅNG';
      case 'onb_months':
        return 'MÅNADER';
      case 'onb_step1_plain':
        return 'Vad studerar du ';
      case 'onb_step1_italic':
        return 'för?';
      case 'onb_step2_plain':
        return 'När är ditt ';
      case 'onb_step2_italic':
        return 'prov?';
      case 'onb_step3_plain':
        return 'Sätt ditt vecko-';
      case 'onb_step3_italic':
        return 'mål.';
      case 'onb_step4_plain':
        return 'Din väg till ';
      case 'onb_step4_italic':
        return 'mästerskap.';
      case 'onb_step4_subtitle':
        return 'Accelerera ditt lärande med personliga studieverktyg.';
      case 'onb_no_plan_selected':
        return 'Ingen plan vald.';
      case 'onb_buy_bundle':
        return 'Köp paket — {price}';
      case 'onb_signin_to_purchase_title':
        return 'Logga in för att prenumerera';
      case 'onb_signin_to_purchase_subtitle':
        return 'Skapa ett gratis konto eller logga in för att starta din prenumeration. Dina framsteg och prenumeration synkas på alla dina enheter.';
      case 'onb_create_account_title':
        return 'Skapa ditt gratis konto';
      case 'onb_create_account_subtitle':
        return 'Spara din studieplan och följ dina framsteg på alla dina enheter.';
      case 'onb_start_practicing':
        return 'Börja öva';
      case 'onb_your_plan_badge':
        return 'DIN PLAN';
      case 'onb_days_per_week':
        return 'dagar/vecka';
      case 'onb_most_popular':
        return 'MEST POPULÄR';
      case 'onb_feature_mock_exams':
        return 'Fullständigt provbibliotek';
      case 'onb_feature_progress_tracking':
        return 'Smart framstegsspårning';
      case 'onb_feature_explanations':
        return 'Detaljerade svarsförklaringar';
      case 'onb_get_best_deal':
        return 'Bästa erbjudandet';
      case 'onb_best_value':
        return 'BÄSTA VÄRDE';
      case 'onb_choose_plan':
        return 'Välj plan';
      case 'onb_bundle_discount_title':
        return 'Du får 20% rabatt';
      case 'onb_bundle_saving':
        return 'Sparar {amount}';
      case 'onb_price_unavailable':
        return 'Pris ej tillgängligt';
      case 'onb_duration_year_access':
        return '{n} års åtkomst';
      case 'onb_duration_months_access':
        return '{n} månaders åtkomst';
      case 'onb_duration_one_day':
        return '1 dag';
      case 'onb_duration_days':
        return '{n} dagar';
      case 'onb_free_trial':
        return '7 DAGARS GRATIS PROVPERIOD. AVBRYT NÄR SOM HELST.';
      case 'onb_start_free':
        return 'Fortsätt som gäst';
      case 'onb_skip_for_now':
        return 'Hoppa över för nu';
      case 'onb_pre_purchase_title':
        return 'Ett snabbt steg';
      case 'onb_pre_purchase_subtitle':
        return 'Skapa ett gratis konto för att komma åt din prenumeration på alla dina enheter, eller fortsätt som gäst — du kan alltid skapa ett konto senare.';
      case 'onb_pre_purchase_sign_in':
        return 'Logga in / Skapa konto';
      case 'onb_pre_purchase_guest':
        return 'Fortsätt som gäst';
      case 'auth_continue_as_guest':
        return 'Fortsätt som gäst';
      case 'auth_guest_session_error':
        return 'Det gick inte att återställa din session. Försök igen.';
      case 'free_trial_banner_badge':
        return 'GRATIS';
      case 'free_trial_banner_title':
        return 'Testa vägmärken — ingen prenumeration krävs';
      case 'free_trial_banner_subtitle':
        return 'Vägmärkestest är helt gratis. Öva i din egen takt och känn på appen innan du prenumererar.';
      case 'free_trial_banner_cta':
        return 'Börja öva';
      case 'guest_banner_title':
        return 'Du surfar som gäst';
      case 'guest_banner_subtitle':
        return 'Skapa ett gratis konto för att spara dina framsteg och synka på alla dina enheter.';
      case 'guest_banner_cta':
        return 'Skapa konto';
      case 'guest_convert_title':
        return 'Spara dina framsteg';
      case 'guest_convert_subtitle':
        return 'Skapa ett gratis konto för att behålla allt du har övat på.';
      case 'guest_username_hint':
        return 'Välj ett användarnamn';
      case 'guest_email_hint':
        return 'E-postadress';
      case 'guest_password_hint':
        return 'Lösenord (min. 8 tecken)';
      case 'guest_convert_cta':
        return 'Skapa konto';
      case 'dash_free_hub_title':
        return 'Fullständig övning — gratis innehåll';
      case 'dash_free_hub_subtitle':
        return 'Övningsfrågor, teoridokument, checklistor och statistik — ingen prenumeration krävs.';
      case 'dash_free_hub_badge':
        return 'GRATIS';
      case 'btn_save_changes':
        return 'Spara ändringar';
      case 'btn_set_password':
        return 'Ange lösenord';
      case 'btn_delete_account':
        return 'Ta bort konto';
      case 'btn_deleting':
        return 'Tar bort...';
      case 'btn_keep_going':
        return 'Fortsätt';
      case 'btn_exit':
        return 'Avsluta';
      case 'btn_save_and_exit':
        return 'Spara & Avsluta';
      case 'btn_submit':
        return 'Skicka';
      case 'btn_start_saved_test':
        return 'Starta test med sparade frågor';
      case 'btn_buy_now':
        return 'Köp nu';
      case 'btn_pay_now':
        return 'Betala nu';
      case 'home_all_tests_deleted':
        return 'Alla tester har tagits bort.';
      case 'home_delete_progress_title':
        return 'Ta bort framsteg';
      case 'home_delete_progress_body':
        return 'Är du säker på att du vill ta bort det här sparade testet?';
      case 'home_delete_all_tests_title':
        return 'Ta bort alla tester';
      case 'home_delete_all_tests_body':
        return 'Är du säker på att du vill ta bort alla testförsök?';
      case 'test_time_up_submitting':
        return 'Tiden är ute! Skickar in ditt test.';
      case 'test_first_question':
        return 'Det här är den första frågan!';
      case 'test_exit_title':
        return 'Avsluta test';
      case 'test_exit_save_prompt':
        return 'Vill du spara dina framsteg?';
      case 'test_save_backend_failed':
        return 'Framstegen sparades på den här enheten, men synkronisering till ditt konto misslyckades. Försök igen.';
      case 'test_feedback_unavailable':
        return 'Feedback är inte tillgänglig för den här frågan.';
      case 'test_feedback_title':
        return 'Feedback';
      case 'test_feedback_type':
        return 'Typ';
      case 'test_feedback_question_issue':
        return 'Problem med frågan';
      case 'test_feedback_wrong_answer':
        return 'Fel svar';
      case 'test_feedback_typo':
        return 'Stavfel/textproblem';
      case 'test_feedback_image_issue':
        return 'Bildproblem';
      case 'test_feedback_other':
        return 'Övrigt';
      case 'test_feedback_hint':
        return 'Berätta vad som är fel med den här frågan...';
      case 'test_feedback_submitted':
        return 'Tack! Din feedback skickades.';
      case 'test_feedback_failed':
        return 'Kunde inte skicka feedback. Försök igen.';
      case 'test_translation_failed':
        return 'Översättningen misslyckades. Försök igen.';
      case 'test_language_english':
        return 'English';
      case 'test_language_swedish':
        return 'Svenska';
      case 'test_turn_off_timer':
        return 'Stäng av timer';
      case 'test_turn_on_timer':
        return 'Slå på timer';
      case 'test_turn_off_instant_marking':
        return 'Stäng av direkt rättning';
      case 'test_turn_on_instant_marking':
        return 'Slå på direkt rättning';
      case 'test_question_saved':
        return 'Frågan sparades';
      case 'test_question_removed':
        return 'Frågan togs bort från sparade';
      case 'test_saved':
        return 'Sparad';
      case 'test_save_question':
        return 'Spara fråga';
      case 'test_questions_title':
        return 'Frågor';
      case 'test_question_progress':
        return '{current} av {total}';
      case 'test_question_label':
        return 'Fråga {n}';
      case 'test_answered':
        return 'Besvarad';
      case 'test_not_answered':
        return 'Inte besvarad';
      case 'test_finish_title':
        return 'Avsluta test';
      case 'test_finish_unanswered_prompt':
        return 'Du har {count} obesvarade frågor. Vill du ändå avsluta testet?';
      case 'test_finish_prompt':
        return 'Vill du avsluta testet?';
      case 'test_finish_no':
        return 'Nej';
      case 'test_finish_yes':
        return 'Ja';
      case 'test_result_congratulations':
        return 'Grattis!';
      case 'test_result_not_quite_there':
        return 'Inte riktigt där än';
      case 'test_result_passed_badge':
        return 'GODKÄND';
      case 'test_result_failed_badge':
        return 'UNDERKÄND';
      case 'test_result_pass_message':
        return 'Du klarade testet. Bra jobbat!';
      case 'test_result_fail_message':
        return 'Fortsätt öva och försök igen. Du klarar det!';
      case 'test_result_go_back':
        return 'Gå tillbaka';
      case 'test_result_see_results':
        return 'Se resultat';
      case 'test_result_screen_passed_title':
        return 'Test godkänt';
      case 'test_result_screen_failed_title':
        return 'Test underkänt';
      case 'test_result_question_review':
        return 'Frågegranskning';
      case 'test_result_score_label':
        return 'Poäng';
      case 'test_result_passed_message':
        return 'Bra jobbat! Du klarade testet.';
      case 'test_result_need_to_pass':
        return 'Fortsätt öva. Du behöver {score}% för att bli godkänd.';
      case 'test_result_correct':
        return 'Rätt';
      case 'test_result_wrong':
        return 'Fel';
      case 'test_result_skipped':
        return 'Hoppade över';
      case 'test_result_above_pass_mark':
        return '{gap}% över godkäntgränsen';
      case 'test_result_below_pass_mark':
        return '{gap}% under godkäntgränsen';
      case 'test_result_your_results':
        return 'Dina resultat';
      case 'test_result_your_score':
        return 'Din poäng';
      case 'test_result_pass_mark':
        return 'Godkäntgräns';
      case 'test_result_correct_answers':
        return 'Rätta svar';
      case 'test_result_wrong_answers':
        return 'Felaktiga svar';
      case 'test_result_question_row':
        return 'F{n}: {text}';
      case 'test_result_your_answer':
        return 'Ditt svar: {answer}';
      case 'error_too_many_requests':
        return 'För många försök. Försök igen om {wait}.';
      case 'error_service_unavailable':
        return 'Tjänsten är tillfälligt otillgänglig. Försök igen om en stund.';
      case 'error_connection_timeout':
        return 'Anslutningen tog för lång tid. Kontrollera din anslutning och försök igen.';
      case 'app_download_title':
        return 'Bättre i appen';
      case 'app_download_subtitle_android':
        return 'Ladda ner Drive Test-appen på Google Play för en snabbare och smidigare upplevelse.';
      case 'app_download_subtitle_ios':
        return 'Ladda ner Drive Test-appen från App Store för en snabbare och smidigare upplevelse.';
      case 'app_download_cta_android':
        return 'Ladda ner på Google Play';
      case 'app_download_cta_ios':
        return 'Ladda ner från App Store';
      case 'app_download_learn_more':
        return 'Läs mer på drivetest.se';
      case 'app_download_dismiss':
        return 'Fortsätt i webbläsaren';
      default:
        return null;
    }
  }
}
