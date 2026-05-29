import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Gemini API key build config', () {
    test('Android Fastlane forwards GEMINI_API_KEY from root env', () {
      final fastfile = File('android/fastlane/Fastfile').readAsStringSync();

      expect(fastfile, contains('gemini_api_key = env_vars["GEMINI_API_KEY"]'));
      expect(
        fastfile,
        contains(
          'defines << "--dart-define=GEMINI_API_KEY=#{gemini_api_key}"',
        ),
      );
    });

    test('web build paths pass GEMINI_API_KEY as a dart define', () {
      final makefile = File('Makefile').readAsStringSync();
      final buildWeb = File('scripts/build_web.sh').readAsStringSync();
      final runWeb = File('scripts/run_web.sh').readAsStringSync();
      final preserveGit = File('build_web_preserve_git.sh').readAsStringSync();

      expect(
        '--dart-define=GEMINI_API_KEY'.allMatches(makefile).length,
        greaterThanOrEqualTo(5),
      );
      expect(buildWeb, contains('--dart-define=GEMINI_API_KEY'));
      expect(runWeb, contains('--dart-define=GEMINI_API_KEY'));
      expect(preserveGit, contains('--dart-define=GEMINI_API_KEY'));
    });
  });
}
