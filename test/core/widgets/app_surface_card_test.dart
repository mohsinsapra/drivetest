import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/core/widgets/app_surface_card.dart';

void main() {
  testWidgets('uses visible light-mode surface treatment', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const Scaffold(
          body: AppSurfaceCard(
            child: SizedBox(width: 100, height: 40),
          ),
        ),
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape! as RoundedRectangleBorder;

    expect(card.elevation, 10);
    expect(shape.side.width, 1);
  });
}
