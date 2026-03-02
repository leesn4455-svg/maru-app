// lib/models/app_models.dart
import 'package:hive/hive.dart';

part 'app_models.g.dart'; 

@HiveType(typeId: 0)
class WorkRecord extends HiveObject {
  @HiveField(0) DateTime date;
  @HiveField(1, defaultValue: 1.0) double workHours;
  @HiveField(2, defaultValue: 0) int dailyWage;
  @HiveField(3, defaultValue: '') String siteName;
  @HiveField(4) String? memo;
  @HiveField(5) String? photoPath; // 구버전 호환용 (단일 사진)
  @HiveField(6) String? weather;
  @HiveField(7, defaultValue: false) bool isSchedule; 
  
  @HiveField(8) String? userId; 
  @HiveField(9) String? userName; 
  @HiveField(10) String? companyCode; 
  
  // 🌟 [추가] 사진 여러 장을 담을 수 있는 바구니 추가!
  @HiveField(11) List<String>? photoPaths;

  WorkRecord({
    required this.date, required this.workHours, required this.dailyWage, required this.siteName, 
    this.memo, this.photoPath, this.weather, this.isSchedule = false,
    this.userId, this.userName, this.companyCode, this.photoPaths,
  });
}

@HiveType(typeId: 1)
class AppSettings extends HiveObject {
  @HiveField(0) String? userName; @HiveField(1) String? phoneNumber; @HiveField(2, defaultValue: false) bool isDarkMode; @HiveField(3, defaultValue: 1) int settlementStartDay; @HiveField(4, defaultValue: 31) int settlementEndDay; @HiveField(5, defaultValue: 'none') String taxType; @HiveField(6) int? defaultWage; @HiveField(7) int? targetSalary; @HiveField(8) double? targetHours; @HiveField(9) DateTime? birthDate; @HiveField(10) DateTime? joinDate; @HiveField(11) String? profileImagePath; @HiveField(12) String? language; @HiveField(13) String? uid; @HiveField(14) String? companyCode; @HiveField(15, defaultValue: 'worker') String role; @HiveField(16) String? position; 
  AppSettings({this.userName, this.phoneNumber, this.isDarkMode = false, this.settlementStartDay = 1, this.settlementEndDay = 31, this.taxType = 'none', this.defaultWage, this.targetSalary, this.targetHours, this.birthDate, this.joinDate, this.profileImagePath, this.language, this.uid, this.companyCode, this.role = 'worker', this.position});
}

@HiveType(typeId: 2)
class SiteInfo extends HiveObject {
  @HiveField(0, defaultValue: '') String siteName; @HiveField(1, defaultValue: '') String address; @HiveField(2, defaultValue: '') String warehouseLocation; @HiveField(3, defaultValue: '') String managerOffice; @HiveField(4, defaultValue: '') String managerContact; @HiveField(5) String? commonEntrance; @HiveField(6) String? memo; @HiveField(7) String? companyCode; @HiveField(8) String? entrancePhotoUrl; @HiveField(9) String? parkingTip; @HiveField(12) String? mapUrl; 
  SiteInfo({required this.siteName, required this.address, required this.warehouseLocation, required this.managerOffice, required this.managerContact, this.commonEntrance, this.memo, this.companyCode, this.entrancePhotoUrl, this.parkingTip, this.mapUrl});
}