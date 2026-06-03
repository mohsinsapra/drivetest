import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/features/splash/splash_screen.dart';

void main() {
  test('splash timing is tuned for lighter startup motion', () {
    expect(kSplashEntryDuration, const Duration(milliseconds: 700));
    expect(kSplashLoopDuration, const Duration(milliseconds: 1600));
    expect(kSplashMinVisibleDuration, const Duration(milliseconds: 1000));
    expect(kSplashNavTransitionDuration, const Duration(milliseconds: 240));
    expect(
      kSplashNavReverseTransitionDuration,
      const Duration(milliseconds: 160),
    );
  });
}
