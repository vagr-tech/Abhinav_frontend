// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_shop.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineShopAdapter extends TypeAdapter<OfflineShop> {
  @override
  final int typeId = 1;

  @override
  OfflineShop read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineShop(
      shopName: fields[0] as String,
      address: fields[1] as String,
      base64Image: fields[2] as String,
      lat: fields[3] as double,
      lng: fields[4] as double,
      segment: fields[5] as String,
      createdBy: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineShop obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.shopName)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.base64Image)
      ..writeByte(3)
      ..write(obj.lat)
      ..writeByte(4)
      ..write(obj.lng)
      ..writeByte(5)
      ..write(obj.segment)
      ..writeByte(6)
      ..write(obj.createdBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineShopAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
