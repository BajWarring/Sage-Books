// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry.dart'; // <-- THIS IS THE FIX

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EntryAdapter extends TypeAdapter<Entry> {
  @override
    final int typeId = 1;

      @override
        Entry read(BinaryReader reader) {
            final numOfFields = reader.readByte();
                final fields = <int, dynamic>{
                      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
                          };
                              return Entry(
                                    cashFlow: fields[0] as String,
                                          dateTime: fields[1] as DateTime,
                                                amount: fields[2] as double,
                                                      remarks: fields[3] as String,
                                                            category: fields[4] as String?,
                                                                  paymentMethod: fields[5] as String?,
                                                                        // --- NEW: Read field 6 ---
                                                                              changeLog: (fields[6] as List?)?.cast<String>(),
                                                                                  );
                                                                                    }

                                                                                      @override
                                                                                        void write(BinaryWriter writer, Entry obj) {
                                                                                            writer
                                                                                                  // --- UPDATED: Now 7 fields (0-6) ---
                                                                                                        ..writeByte(7)
                                                                                                              ..writeByte(0)
                                                                                                                    ..write(obj.cashFlow)
                                                                                                                          ..writeByte(1)
                                                                                                                                ..write(obj.dateTime)
                                                                                                                                      ..writeByte(2)
                                                                                                                                            ..write(obj.amount)
                                                                                                                                                  ..writeByte(3)
                                                                                                                                                        ..write(obj.remarks)
                                                                                                                                                              ..writeByte(4)
                                                                                                                                                                    ..write(obj.category)
                                                                                                                                                                          ..writeByte(5)
                                                                                                                                                                                ..write(obj.paymentMethod)
                                                                                                                                                                                      // --- NEW: Write field 6 ---
                                                                                                                                                                                            ..writeByte(6)
                                                                                                                                                                                                  ..write(obj.changeLog);
                                                                                                                                                                                                    }

                                                                                                                                                                                                      @override
                                                                                                                                                                                                        int get hashCode => typeId.hashCode;

                                                                                                                                                                                                          @override
                                                                                                                                                                                                            bool operator ==(Object other) =>
                                                                                                                                                                                                                  identical(this, other) ||
                                                                                                                                                                                                                        other is EntryAdapter &&
                                                                                                                                                                                                                                  runtimeType == other.runtimeType &&
                                                                                                                                                                                                                                            typeId == other.typeId;
                                                                                                                                                                                                                                            }
                                                                                                                                                                                                                                            
