// lib/providers/app_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_models.dart';

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(AppSettings()) { _loadSettings(); }
  final _box = Hive.box<AppSettings>('app_settings');

  Future<void> _loadSettings() async {
    if (_box.isEmpty) await _box.add(AppSettings());
    if (_box.isNotEmpty) state = _box.values.first;
  }

  Future<void> saveProfile({
    String? userName, String? phoneNumber, DateTime? birthDate, DateTime? joinDate,
    String? profileImagePath, bool? isDarkMode, int? settlementStartDay,
    int? settlementEndDay, String? taxType, int? defaultWage,
    int? targetSalary, double? targetHours, String? language,
    // 🌟 [기업용 확장] 새로 추가된 파라미터들
    String? uid, String? companyCode, String? role, String? position,
  }) async {
    final current = _box.values.first; 
    current.userName = userName ?? current.userName;
    current.phoneNumber = phoneNumber ?? current.phoneNumber;
    current.birthDate = birthDate ?? current.birthDate;
    current.joinDate = joinDate ?? current.joinDate;
    current.profileImagePath = profileImagePath ?? current.profileImagePath;
    current.isDarkMode = isDarkMode ?? current.isDarkMode;
    current.settlementStartDay = settlementStartDay ?? current.settlementStartDay;
    current.settlementEndDay = settlementEndDay ?? current.settlementEndDay;
    current.taxType = taxType ?? current.taxType;
    if (defaultWage != null) current.defaultWage = defaultWage == -1 ? null : defaultWage;
    if (targetSalary != null) current.targetSalary = targetSalary == -1 ? null : targetSalary;
    if (targetHours != null) current.targetHours = targetHours == -1 ? null : targetHours; 
    current.language = language ?? current.language;
    
    // 🌟 [기업용 확장] 새로 추가된 데이터 저장
    current.uid = uid ?? current.uid;
    current.companyCode = companyCode ?? current.companyCode;
    current.role = role ?? current.role;
    current.position = position ?? current.position;
    
    await current.save();

    state = AppSettings(
      userName: current.userName, phoneNumber: current.phoneNumber,
      birthDate: current.birthDate, joinDate: current.joinDate,
      profileImagePath: current.profileImagePath, isDarkMode: current.isDarkMode,
      settlementStartDay: current.settlementStartDay, settlementEndDay: current.settlementEndDay,
      taxType: current.taxType, defaultWage: current.defaultWage,
      targetSalary: current.targetSalary, targetHours: current.targetHours, language: current.language,
      // 🌟 상태 갱신
      uid: current.uid, companyCode: current.companyCode, role: current.role, position: current.position,
    );
  }
}
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) => AppSettingsNotifier());