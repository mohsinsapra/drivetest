import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/features/auth/auth_screen.dart';
import 'package:introduction_screen/introduction_screen.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Welcome to TaxiQuiz",
          body: "Learn and practice for your taxi license with ease.",
          image: _buildImage('assets/images/slide1.png'),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Interactive Tests",
          body: "Practice tests with real-time feedback and explanations.",
          image: _buildImage('assets/images/slide2.png'),
          decoration: _getPageDecoration(),
        ),
        PageViewModel(
          title: "Get Certified",
          body: "Ace your exams and become a certified taxi driver.",
          image: _buildImage('assets/images/slide3.png'),
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
      skip: const Text("Skip"),
      next: const Icon(Icons.arrow_forward),
      done: const Text("Get Started",
          style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: _getDotsDecorator(),
    );
  }

  Widget _buildImage(String assetName) {
    return Center(child: Image.asset(assetName, width: 300));
  }

  PageDecoration _getPageDecoration() {
    return const PageDecoration(
      titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      bodyTextStyle: TextStyle(fontSize: 16),
      // descriptionPadding: EdgeInsets.all(16).copyWith(bottom: 0),
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
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }
}
