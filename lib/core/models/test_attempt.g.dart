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
      licenceName: fields[6] as String?,
      categoryName: fields[7] as String?,
      status: fields[8] as String? ?? 'completed',
      currentQuestionIndex: fields[9] as int? ?? 0,
      licenceId: fields[10] as String?,
      categoryId: fields[11] as String?,
      durationSeconds: fields[12] as int?,
      bcdCategoryId: fields[13] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, TestAttempt obj) {
    writer
      ..writeByte(14)
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
      ..write(obj.questions)
      ..writeByte(6)
      ..write(obj.licenceName)
      ..writeByte(7)
      ..write(obj.categoryName)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.currentQuestionIndex)
      ..writeByte(10)
      ..write(obj.licenceId)
      ..writeByte(11)
      ..write(obj.categoryId)
      ..writeByte(12)
      ..write(obj.durationSeconds)
      ..writeByte(13)
      ..write(obj.bcdCategoryId);
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
