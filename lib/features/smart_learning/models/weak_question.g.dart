// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weak_question.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WeakQuestionAdapter extends TypeAdapter<WeakQuestion> {
  @override
  final int typeId = 7;

  @override
  WeakQuestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeakQuestion(
      testBcdId: fields[0] as int,
      questionId: fields[1] as String,
      wrongCount: fields[2] as int,
      correctStreak: fields[3] as int,
      lastSeen: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WeakQuestion obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.testBcdId)
      ..writeByte(1)
      ..write(obj.questionId)
      ..writeByte(2)
      ..write(obj.wrongCount)
      ..writeByte(3)
      ..write(obj.correctStreak)
      ..writeByte(4)
      ..write(obj.lastSeen);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeakQuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
