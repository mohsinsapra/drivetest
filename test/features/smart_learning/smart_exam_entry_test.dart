import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/features/smart_learning/screens/smart_learning_screen.dart';

SmartExamEntry _entry({
  required bool isTestFree,
  required bool categorySubscribed,
  Map<String, dynamic>? subscriptionProduct,
}) {
  return SmartExamEntry(
    testBcdId: 1,
    testName: 'Test',
    categoryName: 'Cat',
    parentCategoryBcdId: 1,
    subcategoryName: '',
    questionCount: 10,
    passScore: 7,
    timeLimit: 0,
    chunkSizes: const [5, 5],
    isTestFree: isTestFree,
    categorySubscribed: categorySubscribed,
    subscriptionProduct: subscriptionProduct,
  );
}

void main() {
  group('SmartExamEntry.isLocked', () {
    test('free category (null product) is never locked', () {
      expect(
        _entry(isTestFree: false, categorySubscribed: false).isLocked,
        isFalse,
      );
    });

    test('paid + subscribed is not locked', () {
      expect(
        _entry(
          isTestFree: false,
          categorySubscribed: true,
          subscriptionProduct: const {'id': 5},
        ).isLocked,
        isFalse,
      );
    });

    test('paid + unsubscribed + paid test is locked', () {
      expect(
        _entry(
          isTestFree: false,
          categorySubscribed: false,
          subscriptionProduct: const {'id': 5},
        ).isLocked,
        isTrue,
      );
    });

    test('paid + unsubscribed but free test is not locked', () {
      expect(
        _entry(
          isTestFree: true,
          categorySubscribed: false,
          subscriptionProduct: const {'id': 5},
        ).isLocked,
        isFalse,
      );
    });
  });
}
