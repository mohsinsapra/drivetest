import 'package:taxi_exam_app/core/widgets/app_loading_indicator.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _kConsentKey = 'gdpr_consent_accepted';

Future<void> showGdprConsentIfNeeded(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_kConsentKey) == true) return;
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _GdprConsentSheet(),
  );
}

Future<void> markGdprConsentAccepted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kConsentKey, true);
}

bool _isSwedish() {
  if (kIsWeb) return false;
  try {
    return Platform.localeName.startsWith('sv');
  } catch (_) {
    return false;
  }
}

class _GdprConsentSheet extends StatefulWidget {
  const _GdprConsentSheet();

  @override
  State<_GdprConsentSheet> createState() => _GdprConsentSheetState();
}

class _GdprConsentSheetState extends State<_GdprConsentSheet> {
  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    await markGdprConsentAccepted();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sv = _isSwedish();

    return PopScope(
      canPop: false,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              32,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Icon + title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        Icon(Icons.shield_rounded, color: cs.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      sv
                          ? 'Din integritet är viktig för oss'
                          : 'Your privacy matters to us',
                      style: GoogleFonts.lexend(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Intro paragraph
              Text(
                sv
                    ? 'Innan du fortsätter vill vi informera dig om hur vi hanterar dina personuppgifter i enlighet med GDPR.'
                    : 'Before you continue, we want to inform you about how we handle your personal data in accordance with GDPR.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: cs.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 20),

              // Data points
              _DataPoint(
                icon: Icons.person_rounded,
                title: sv ? 'Kontouppgifter' : 'Account data',
                body: sv
                    ? 'Vi lagrar din e-postadress och ditt namn för att hantera ditt konto.'
                    : 'We store your email address and name to manage your account.',
              ),
              const SizedBox(height: 14),
              _DataPoint(
                icon: Icons.bar_chart_rounded,
                title: sv ? 'Studieframsteg' : 'Study progress',
                body: sv
                    ? 'Vi sparar dina provsvar och resultat för att visa din framsteg och anpassa övningsprov.'
                    : 'We save your quiz answers and results to show your progress and personalise practice tests.',
              ),
              const SizedBox(height: 14),
              _DataPoint(
                icon: Icons.notifications_rounded,
                title: sv ? 'Aviseringar' : 'Notifications',
                body: sv
                    ? 'Om du tillåter aviseringar lagrar vi din enhetstoken för att skicka påminnelser.'
                    : 'If you allow notifications, we store your device token to send reminders.',
              ),
              const SizedBox(height: 14),
              _DataPoint(
                icon: Icons.lock_rounded,
                title: sv ? 'Säkerhet' : 'Security',
                body: sv
                    ? 'Din data överförs krypterat och delas aldrig med tredje part för marknadsföring.'
                    : 'Your data is transferred encrypted and is never shared with third parties for marketing.',
              ),
              const SizedBox(height: 24),

              // Privacy policy link
              RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: sv
                          ? 'Genom att trycka på "Godkänn" samtycker du till vår '
                          : 'By tapping "Accept" you agree to our ',
                    ),
                    TextSpan(
                      text: sv ? 'integritetspolicy' : 'Privacy Policy',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(
                              Uri.parse(
                                  'https://drivetest.se/privacy-policy.html'),
                              mode: LaunchMode.externalApplication,
                            ),
                    ),
                    TextSpan(
                      text: sv
                          ? ' och vår behandling av personuppgifter.'
                          : ' and our processing of personal data.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Accept button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _accepting ? null : _accept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    disabledBackgroundColor: cs.primary.withValues(alpha: 0.3),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  child: _accepting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: AppLoadingIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          sv ? 'Godkänn och fortsätt' : 'Accept & Continue',
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataPoint extends StatelessWidget {
  const _DataPoint({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
