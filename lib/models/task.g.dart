// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      title: fields[0] as String,
      date: fields[1] as DateTime,
      isDone: fields[2] as bool,
      description: fields[3] as String,
      subject: fields[4] as String,
      taskType: fields[5] as String,
      professor: fields[6] as String,
      submission: fields[7] as String,
      notes: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.isDone)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.subject)
      ..writeByte(5)
      ..write(obj.taskType)
      ..writeByte(6)
      ..write(obj.professor)
      ..writeByte(7)
      ..write(obj.submission)
      ..writeByte(8)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
