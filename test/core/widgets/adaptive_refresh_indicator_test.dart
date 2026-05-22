import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/widgets/adaptive_refresh_indicator.dart';

void main() {
  group('AdaptiveRefreshIndicator haptic ticks', () {
    late List<MethodCall> hapticCalls;

    setUp(() {
      hapticCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(call);
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('Android: fires haptic ticks during overscroll drag', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            body: AdaptiveRefreshIndicator(
              onRefresh: () async {},
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [const SizedBox(height: 2000)],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pumpAndSettle();

      expect(hapticCalls, isNotEmpty);
    });

    testWidgets('iOS: fires haptic ticks via ScrollUpdateNotification when pixels go negative', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          home: Scaffold(
            body: AdaptiveRefreshIndicator(
              onRefresh: () async {},
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [const SizedBox(height: 2000)],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pumpAndSettle();

      expect(hapticCalls, isNotEmpty);
    });

    testWidgets('does not fire haptic when scrolling down (not overscroll)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            body: AdaptiveRefreshIndicator(
              onRefresh: () async {},
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    List.generate(50, (_) => const SizedBox(height: 60)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Scroll down (not overscroll at top)
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(hapticCalls, isEmpty);
    });

    testWidgets('resets counters after release so next drag fires fresh ticks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: Scaffold(
            body: AdaptiveRefreshIndicator(
              onRefresh: () async {},
              slivers: [
                SliverList(
                  delegate: SliverChildListDelegate(
                    [const SizedBox(height: 2000)],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // First drag
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pumpAndSettle();
      final firstCount = hapticCalls.length;
      expect(firstCount, greaterThan(0));

      hapticCalls.clear();

      // Second drag after release — should fire again from scratch
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pumpAndSettle();
      expect(hapticCalls.length, greaterThan(0));
    });
  });
}
