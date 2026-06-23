// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BusinessProfileAdapter extends TypeAdapter<BusinessProfile> {
  @override
  final int typeId = 3;

  @override
  BusinessProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BusinessProfile(
      restaurantName: fields[0] as String,
      address: fields[1] as String,
      phone: fields[2] as String,
      upiId: fields[3] as String,
      payeeName: fields[4] as String,
      merchantCode: fields[5] as String,
      footerText: fields[6] as String,
      paperSizeMm: fields[7] as int,
      currencySymbol: fields[8] as String,
      defaultTaxRatePercent: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, BusinessProfile obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.restaurantName)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.upiId)
      ..writeByte(4)
      ..write(obj.payeeName)
      ..writeByte(5)
      ..write(obj.merchantCode)
      ..writeByte(6)
      ..write(obj.footerText)
      ..writeByte(7)
      ..write(obj.paperSizeMm)
      ..writeByte(8)
      ..write(obj.currencySymbol)
      ..writeByte(9)
      ..write(obj.defaultTaxRatePercent);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
