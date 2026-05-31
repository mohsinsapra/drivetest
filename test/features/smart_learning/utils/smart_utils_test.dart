import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/features/smart_learning/utils/smart_utils.dart';

void main() {
  group('SmartUtils.computeChunkSizes', () {
    test('no split for 10 questions', () {
      expect(SmartUtils.computeSmartSizes(10), [10]);
    });

    test('no split for 9 questions', () {
      expect(SmartUtils.computeSmartSizes(9), [9]);
    });

    test('15 questions → [8, 7]', () {
      expect(SmartUtils.computeSmartSizes(15), [8, 7]);
    });

    test('20 questions → [10, 10]', () {
      expect(SmartUtils.computeSmartSizes(20), [10, 10]);
    });

    test('25 questions → [13, 12]', () {
      expect(SmartUtils.computeSmartSizes(25), [13, 12]);
    });

    test('40 questions → [14, 13, 13]', () {
      expect(SmartUtils.computeSmartSizes(40), [14, 13, 13]);
    });

    test('70 questions → 5 chunks of 14', () {
      expect(SmartUtils.computeSmartSizes(70), [14, 14, 14, 14, 14]);
    });

    test('65 questions → 5 chunks of 13', () {
      expect(SmartUtils.computeSmartSizes(65), [13, 13, 13, 13, 13]);
    });

    test('total of sizes always equals input', () {
      for (final n in [11, 20, 25, 30, 45, 60, 70, 80]) {
        final sizes = SmartUtils.computeSmartSizes(n);
        expect(sizes.fold(0, (a, b) => a + b), n,
            reason: 'sizes must sum to $n');
      }
    });
  });

  group('SmartUtils.chunkOffset', () {
    test('offset 0 is always 0', () {
      expect(SmartUtils.smartOffset([8, 7], 0), 0);
    });

    test('offset 1 equals first chunk size', () {
      expect(SmartUtils.smartOffset([8, 7], 1), 8);
    });

    test('offset 2 equals sum of first two', () {
      expect(SmartUtils.smartOffset([14, 14, 14, 14, 14], 2), 28);
    });

    test('offset 4 equals sum of first four', () {
      expect(SmartUtils.smartOffset([14, 14, 14, 14, 14], 4), 56);
    });
  });
}
