// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SmartProgressAdapter extends TypeAdapter<SmartProgress> {
  @override
  final int typeId = 6;

  @override
  SmartProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SmartProgress(
      testBcdId: fields[0] as int,
      chunkIndex: fields[1] as int,
      isPassed: fields[2] as bool,
      completedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SmartProgress obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.testBcdId)
      ..writeByte(1)
      ..write(obj.chunkIndex)
      ..writeByte(2)
      ..write(obj.isPassed)
      ..writeByte(3)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
