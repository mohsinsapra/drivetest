// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscribed_exam.dart';

class SubscribedExamAdapter extends TypeAdapter<SubscribedExam> {
  @override
  final int typeId = 4;

  @override
  SubscribedExam read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubscribedExam(
      id: fields[0] as String,
      name: fields[1] as String,
      hasCategories: fields[2] as bool,
      nodes: (fields[3] as List).cast<ExamNode>(),
      subscribedAt: fields[4] as DateTime,
      // field 5 is new — default false for records written before this field existed
      isBcd: fields[5] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, SubscribedExam obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.hasCategories)
      ..writeByte(3)
      ..write(obj.nodes)
      ..writeByte(4)
      ..write(obj.subscribedAt)
      ..writeByte(5)
      ..write(obj.isBcd);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscribedExamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
