import 'package:hive/hive.dart';

part 'local_notification.g.dart';

@HiveType(typeId: 3)
class LocalNotification extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String body;

  @HiveField(2)
  final DateTime receivedAt;

  @HiveField(3)
  bool isRead;

  @HiveField(4)
  final String type;

  LocalNotification({
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
    this.type = 'general',
  });
}
