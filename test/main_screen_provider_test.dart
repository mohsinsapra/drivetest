import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_exam_app/main_screen.dart';

void main() {
  test('MainScreenProvider only notifies when index changes', () {
    final provider = MainScreenProvider();
    var notifications = 0;

    provider.addListener(() {
      notifications++;
    });

    provider.setIndex(0);
    expect(notifications, 0);

    provider.setIndex(4);
    expect(provider.currentIndex, 4);
    expect(notifications, 1);

    provider.setIndex(4);
    expect(notifications, 1);
  });
}
