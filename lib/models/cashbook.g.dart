// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cashbook.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CashbookAdapter extends TypeAdapter<Cashbook> {
  @override
  final int typeId = 0;

  @override
  Cashbook read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Cashbook(
      name: fields[0] as String,
      entries: (fields[1] as HiveList?)?.castHiveList(),
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Cashbook obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.entries)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashbookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
