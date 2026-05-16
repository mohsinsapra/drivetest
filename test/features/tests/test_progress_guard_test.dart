import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/features/tests/test_progress_guard.dart';

void main() {
  group('hasResumableProgressChanges', () {
    test('returns false when selections and question index are unchanged', () {
      final changed = hasResumableProgressChanges(
        initialSelections: const {0: 'A', 1: 'B'},
        currentSelections: const {0: 'A', 1: 'B'},
        initialQuestionIndex: 3,
        currentQuestionIndex: 3,
      );

      expect(changed, isFalse);
    });

    test('returns true when selections change', () {
      final changed = hasResumableProgressChanges(
        initialSelections: const {0: 'A', 1: 'B'},
        currentSelections: const {0: 'A', 1: 'C'},
        initialQuestionIndex: 3,
        currentQuestionIndex: 3,
      );

      expect(changed, isTrue);
    });

    test('returns true when only question index changes', () {
      final changed = hasResumableProgressChanges(
        initialSelections: const {0: 'A', 1: 'B'},
        currentSelections: const {0: 'A', 1: 'B'},
        initialQuestionIndex: 3,
        currentQuestionIndex: 5,
      );

      expect(changed, isTrue);
    });
  });
}
