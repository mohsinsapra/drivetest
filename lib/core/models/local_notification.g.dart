// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_notification.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalNotificationAdapter extends TypeAdapter<LocalNotification> {
  @override
  final int typeId = 3;

  @override
  LocalNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalNotification(
      title: fields[0] as String,
      body: fields[1] as String,
      receivedAt: fields[2] as DateTime,
      isRead: fields[3] as bool,
      type: fields[4] == null ? 'general' : fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocalNotification obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.body)
      ..writeByte(2)
      ..write(obj.receivedAt)
      ..writeByte(3)
      ..write(obj.isRead)
      ..writeByte(4)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalNotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
