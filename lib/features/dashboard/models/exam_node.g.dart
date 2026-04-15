// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_node.dart';

class ExamNodeAdapter extends TypeAdapter<ExamNode> {
  @override
  final int typeId = 5;

  @override
  ExamNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExamNode(
      id: fields[0] as String,
      name: fields[1] as String,
      nodeTypeIndex: fields[2] as int,
      parentId: fields[3] as String?,
      targetDurationSeconds: fields[4] as int,
      sortOrder: fields[5] as int,
      // field 6 is new — default 0 for records written before this field existed
      passScore: fields[6] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, ExamNode obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.nodeTypeIndex)
      ..writeByte(3)
      ..write(obj.parentId)
      ..writeByte(4)
      ..write(obj.targetDurationSeconds)
      ..writeByte(5)
      ..write(obj.sortOrder)
      ..writeByte(6)
      ..write(obj.passScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
