// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationEntityAdapter extends TypeAdapter<NotificationEntity> {
  @override
  final int typeId = 0;

  @override
  NotificationEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationEntity()
      ..notificationId = fields[0] as String
      ..title = fields[1] as String
      ..message = fields[2] as String
      ..type = fields[3] as String
      ..timestamp = fields[4] as DateTime
      ..isRead = fields[5] as bool
      ..metadata = fields[6] as String?;
  }

  @override
  void write(BinaryWriter writer, NotificationEntity obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.notificationId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.message)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.isRead)
      ..writeByte(6)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
