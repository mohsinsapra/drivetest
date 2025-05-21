// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_attempt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TestAttemptAdapter extends TypeAdapter<TestAttempt> {
  @override
  final int typeId = 0;

  @override
  TestAttempt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TestAttempt(
      testId: fields[0] as String,
      dateTime: fields[1] as DateTime,
      userSelections: (fields[2] as Map).cast<int, String>(),
      score: fields[3] as double,
      hasPassed: fields[4] as bool,
      questions: (fields[5] as List).cast<Question>(),
    );
  }

  @override
  void write(BinaryWriter writer, TestAttempt obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.testId)
      ..writeByte(1)
      ..write(obj.dateTime)
      ..writeByte(2)
      ..write(obj.userSelections)
      ..writeByte(3)
      ..write(obj.score)
      ..writeByte(4)
      ..write(obj.hasPassed)
      ..writeByte(5)
      ..write(obj.questions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestAttemptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
