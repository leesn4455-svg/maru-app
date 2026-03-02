// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkRecordAdapter extends TypeAdapter<WorkRecord> {
  @override
  final int typeId = 0;

  @override
  WorkRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkRecord(
      date: fields[0] as DateTime,
      workHours: fields[1] == null ? 1.0 : fields[1] as double,
      dailyWage: fields[2] == null ? 0 : fields[2] as int,
      siteName: fields[3] == null ? '' : fields[3] as String,
      memo: fields[4] as String?,
      photoPath: fields[5] as String?,
      weather: fields[6] as String?,
      isSchedule: fields[7] == null ? false : fields[7] as bool,
      userId: fields[8] as String?,
      userName: fields[9] as String?,
      companyCode: fields[10] as String?,
      photoPaths: (fields[11] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkRecord obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.workHours)
      ..writeByte(2)
      ..write(obj.dailyWage)
      ..writeByte(3)
      ..write(obj.siteName)
      ..writeByte(4)
      ..write(obj.memo)
      ..writeByte(5)
      ..write(obj.photoPath)
      ..writeByte(6)
      ..write(obj.weather)
      ..writeByte(7)
      ..write(obj.isSchedule)
      ..writeByte(8)
      ..write(obj.userId)
      ..writeByte(9)
      ..write(obj.userName)
      ..writeByte(10)
      ..write(obj.companyCode)
      ..writeByte(11)
      ..write(obj.photoPaths);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 1;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      userName: fields[0] as String?,
      phoneNumber: fields[1] as String?,
      isDarkMode: fields[2] == null ? false : fields[2] as bool,
      settlementStartDay: fields[3] == null ? 1 : fields[3] as int,
      settlementEndDay: fields[4] == null ? 31 : fields[4] as int,
      taxType: fields[5] == null ? 'none' : fields[5] as String,
      defaultWage: fields[6] as int?,
      targetSalary: fields[7] as int?,
      targetHours: fields[8] as double?,
      birthDate: fields[9] as DateTime?,
      joinDate: fields[10] as DateTime?,
      profileImagePath: fields[11] as String?,
      language: fields[12] as String?,
      uid: fields[13] as String?,
      companyCode: fields[14] as String?,
      role: fields[15] == null ? 'worker' : fields[15] as String,
      position: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.userName)
      ..writeByte(1)
      ..write(obj.phoneNumber)
      ..writeByte(2)
      ..write(obj.isDarkMode)
      ..writeByte(3)
      ..write(obj.settlementStartDay)
      ..writeByte(4)
      ..write(obj.settlementEndDay)
      ..writeByte(5)
      ..write(obj.taxType)
      ..writeByte(6)
      ..write(obj.defaultWage)
      ..writeByte(7)
      ..write(obj.targetSalary)
      ..writeByte(8)
      ..write(obj.targetHours)
      ..writeByte(9)
      ..write(obj.birthDate)
      ..writeByte(10)
      ..write(obj.joinDate)
      ..writeByte(11)
      ..write(obj.profileImagePath)
      ..writeByte(12)
      ..write(obj.language)
      ..writeByte(13)
      ..write(obj.uid)
      ..writeByte(14)
      ..write(obj.companyCode)
      ..writeByte(15)
      ..write(obj.role)
      ..writeByte(16)
      ..write(obj.position);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SiteInfoAdapter extends TypeAdapter<SiteInfo> {
  @override
  final int typeId = 2;

  @override
  SiteInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SiteInfo(
      siteName: fields[0] == null ? '' : fields[0] as String,
      address: fields[1] == null ? '' : fields[1] as String,
      warehouseLocation: fields[2] == null ? '' : fields[2] as String,
      managerOffice: fields[3] == null ? '' : fields[3] as String,
      managerContact: fields[4] == null ? '' : fields[4] as String,
      commonEntrance: fields[5] as String?,
      memo: fields[6] as String?,
      companyCode: fields[7] as String?,
      entrancePhotoUrl: fields[8] as String?,
      parkingTip: fields[9] as String?,
      mapUrl: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SiteInfo obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.siteName)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.warehouseLocation)
      ..writeByte(3)
      ..write(obj.managerOffice)
      ..writeByte(4)
      ..write(obj.managerContact)
      ..writeByte(5)
      ..write(obj.commonEntrance)
      ..writeByte(6)
      ..write(obj.memo)
      ..writeByte(7)
      ..write(obj.companyCode)
      ..writeByte(8)
      ..write(obj.entrancePhotoUrl)
      ..writeByte(9)
      ..write(obj.parkingTip)
      ..writeByte(12)
      ..write(obj.mapUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SiteInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
