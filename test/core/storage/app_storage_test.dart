import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/models/local_notification.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('app_storage_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(LocalNotificationAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('clearUserData clears an already-open typed notifications box', () async {
    final box = await Hive.openBox<LocalNotification>(AppStorage.kNotifications);
    await box.add(
      LocalNotification(
        title: 't',
        body: 'b',
        receivedAt: DateTime(2026, 5, 3),
      ),
    );

    await AppStorage.clearUserData();

    expect(box.isOpen, isTrue);
    expect(box.isEmpty, isTrue);
  });
}
