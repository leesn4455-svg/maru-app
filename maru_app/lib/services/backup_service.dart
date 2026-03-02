// lib/services/backup_service.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';

import '../models/app_models.dart';
import 'cloud_manager.dart'; // [연결] 택배 기사 호출!

class BackupService {
  
  // 1. 클라우드 백업하기
  static Future<void> backupData() async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

      final settingsBox = Hive.box<AppSettings>('app_settings');
      final workBox = Hive.box<WorkRecord>('work_records');
      
      if (settingsBox.isEmpty) throw Exception('백업할 설정 데이터가 없습니다.');
      final settings = settingsBox.values.first;
      
      final String userId = (settings.phoneNumber?.isNotEmpty == true) 
          ? settings.phoneNumber! 
          : (settings.userName ?? 'unknown_user');

      // 날짜 데이터를 서버가 읽을 수 있게 글자로 포장!
      Map<String, dynamic> settingsData = {
        'userName': settings.userName,
        'phoneNumber': settings.phoneNumber,
        'isDarkMode': settings.isDarkMode,
        'settlementStartDay': settings.settlementStartDay,
        'settlementEndDay': settings.settlementEndDay,
        'taxType': settings.taxType,
        'defaultWage': settings.defaultWage,
        'targetSalary': settings.targetSalary,
        'targetHours': settings.targetHours,
        'profileImagePath': settings.profileImagePath,
        'language': settings.language,
        'birthDate': settings.birthDate?.toIso8601String(),
        'joinDate': settings.joinDate?.toIso8601String(),
        'lastBackupTime': DateTime.now().toIso8601String(),
      };

      List<Map<String, dynamic>> workData = workBox.values.map((r) => {
        'date': r.date.toIso8601String(),
        'workHours': r.workHours,
        'dailyWage': r.dailyWage,
        'siteName': r.siteName,
        'memo': r.memo,
        'photoPath': r.photoPath,
        'weather': r.weather,
        'isSchedule': r.isSchedule,
      }).toList();

      // [핵심] CloudManager(택배기사)에게 배달 요청!
      await CloudManager.saveDocument(
        collection: 'backups',
        docId: userId,
        data: { 'settings': settingsData, 'records': workData }
      );

      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('백업 완료 ☁️', '클라우드에 데이터가 안전하게 저장되었습니다!', backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('백업 실패', '오류: $e', backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 5));
    }
  }

  // 2. 클라우드에서 복원하기
  static Future<void> restoreData() async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

      final settingsBox = Hive.box<AppSettings>('app_settings');
      final workBox = Hive.box<WorkRecord>('work_records');
      
      final settings = settingsBox.isNotEmpty ? settingsBox.values.first : AppSettings();
      final String userId = (settings.phoneNumber?.isNotEmpty == true) 
          ? settings.phoneNumber! 
          : (settings.userName ?? 'unknown_user');

      // [핵심] CloudManager(택배기사)에게 서버에 있는 박스 가져오라고 요청!
      final data = await CloudManager.getDocument(collection: 'backups', docId: userId);

      if (data == null) {
        throw Exception('클라우드에 저장된 백업 데이터가 없습니다.');
      }

      final Map<String, dynamic> savedSettings = data['settings'] ?? {};
      final List<dynamic> savedRecords = data['records'] ?? [];

      // 박스 풀어서 로컬 금고에 다시 넣기
      settings.userName = savedSettings['userName'];
      settings.phoneNumber = savedSettings['phoneNumber'];
      settings.isDarkMode = savedSettings['isDarkMode'] ?? false;
      settings.settlementStartDay = savedSettings['settlementStartDay'] ?? 1;
      settings.settlementEndDay = savedSettings['settlementEndDay'] ?? 31;
      settings.taxType = savedSettings['taxType'] ?? 'none';
      settings.defaultWage = savedSettings['defaultWage'];
      settings.targetSalary = savedSettings['targetSalary'];
      settings.targetHours = savedSettings['targetHours'];
      settings.profileImagePath = savedSettings['profileImagePath'];
      settings.language = savedSettings['language'];
      
      if (savedSettings['birthDate'] != null) settings.birthDate = DateTime.parse(savedSettings['birthDate']);
      if (savedSettings['joinDate'] != null) settings.joinDate = DateTime.parse(savedSettings['joinDate']);
      
      await settings.save();

      await workBox.clear(); 
      for (var r in savedRecords) {
        await workBox.add(WorkRecord(
          date: DateTime.parse(r['date']), 
          workHours: (r['workHours'] as num).toDouble(),
          dailyWage: r['dailyWage'] as int,
          siteName: r['siteName'] ?? '',
          memo: r['memo'],
          photoPath: r['photoPath'],
          weather: r['weather'],
          isSchedule: r['isSchedule'] ?? false,
        ));
      }

      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('복원 완료 🔄', '클라우드에서 데이터를 성공적으로 불러왔습니다!', backgroundColor: Colors.blueAccent, colorText: Colors.white);

    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('복원 실패', '오류: $e', backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 5));
    }
  }
}