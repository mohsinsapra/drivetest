import 'package:taxi_exam_app/core/utils/app_page_route.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:taxi_exam_app/core/widgets/app_lottie.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: t.welcome_message,
          body: t.intro_slide1_body,
          image: _buildLottie('animations/animation1.json'),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: t.intro_slide2_title,
          body: t.intro_slide2_body,
          image: _buildLottie('animations/animation2.json'),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: t.intro_slide3_title,
          body: t.intro_slide3_body,
          image: _buildLottie('animations/animation3.json'),
          decoration: _getPageDecoration(),
        ),
      ],
      onDone: () async {
        await _completeOnboarding(context);
      },
      onSkip: () async {
        await _completeOnboarding(context);
      },
      showSkipButton: true,
      skip: Text(
        t.intro_skip,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
      ),
      next: const Icon(
        Icons.arrow_forward,
        size: 28,
      ),
      done: Text(
        t.intro_get_started,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      dotsDecorator: _getDotsDecorator(),
    );
  }

  Widget _buildLottie(String assetName) {
    return Center(
      child: AppLottie(
        asset: assetName,
        width: 700,
      ),
    );
  }

  PageDecoration _getPageDecoration() {
    return const PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color.fromRGBO(0, 0, 0, 0.7),
      ),
      bodyTextStyle: TextStyle(
        fontSize: 20,
        color: Color.fromRGBO(0, 0, 0, 0.6),
      ),
      imagePadding: EdgeInsets.all(24),
      pageColor: Colors.white,
    );
  }

  DotsDecorator _getDotsDecorator() {
    return const DotsDecorator(
      size: Size(10, 10),
      color: Colors.black26,
      activeSize: Size(22, 10),
      activeColor: Colors.blue,
      activeShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(25)),
      ),
    );
  }

  Future<void> _completeOnboarding(BuildContext context) async {
    // Save completion flag in shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    // Check if the widget is still mounted before navigating
    if (context.mounted) {
      // Navigate to Auth Screen
      Navigator.of(context).pushReplacement(
        AppPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }
}
