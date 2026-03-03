// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookingHiveModelAdapter extends TypeAdapter<BookingHiveModel> {
  @override
  final int typeId = 0;

  @override
  BookingHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookingHiveModel()
      ..bookingId = fields[0] as String
      ..restaurantId = fields[1] as String
      ..name = fields[2] as String
      ..phone = fields[3] as String
      ..guests = fields[4] as int
      ..status = fields[5] as String
      ..bookingDate = fields[6] as String
      ..startTime = fields[7] as String
      ..endTime = fields[8] as String
      ..totalPrice = fields[9] as double
      ..restaurantCategoryId = fields[10] as String?
      ..selectedExtras = (fields[11] as List?)?.cast<String>()
      ..menuSelections = (fields[12] as Map?)?.cast<String, String>()
      ..restaurantName = fields[13] as String?
      ..categoryName = fields[14] as String?
      ..extrasNames = (fields[15] as List?)?.cast<String>()
      ..menuItemCategories = (fields[16] as List?)?.cast<String>()
      ..menuItemNames = (fields[17] as List?)?.cast<String>();
  }

  @override
  void write(BinaryWriter writer, BookingHiveModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.bookingId)
      ..writeByte(1)
      ..write(obj.restaurantId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.guests)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.bookingDate)
      ..writeByte(7)
      ..write(obj.startTime)
      ..writeByte(8)
      ..write(obj.endTime)
      ..writeByte(9)
      ..write(obj.totalPrice)
      ..writeByte(10)
      ..write(obj.restaurantCategoryId)
      ..writeByte(11)
      ..write(obj.selectedExtras)
      ..writeByte(12)
      ..write(obj.menuSelections)
      ..writeByte(13)
      ..write(obj.restaurantName)
      ..writeByte(14)
      ..write(obj.categoryName)
      ..writeByte(15)
      ..write(obj.extrasNames)
      ..writeByte(16)
      ..write(obj.menuItemCategories)
      ..writeByte(17)
      ..write(obj.menuItemNames);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
