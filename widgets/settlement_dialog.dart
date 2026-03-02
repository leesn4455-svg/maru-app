// lib/widgets/settlement_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // [에러 해결] 숫자만 입력받게 하는 필수 부품 추가!
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // [에러 해결] 숫자 콤마(,) 찍어주는 필수 부품 추가!

import '../models/app_models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';

void showSettlementDialog(BuildContext context, WidgetRef ref, AppSettings appSettings) {
  final startCtrl = TextEditingController(text: appSettings.settlementStartDay.toString());
  final endCtrl = TextEditingController(text: appSettings.settlementEndDay.toString());
  final taxCtrl = TextEditingController(text: appSettings.taxType == 'none' ? '0.0' : appSettings.taxType);
  final wageCtrl = TextEditingController(text: appSettings.defaultWage != null && appSettings.defaultWage! > 0 ? NumberFormat('#,###').format(appSettings.defaultWage) : '');
  final targetSalaryCtrl = TextEditingController(text: appSettings.targetSalary != null && appSettings.targetSalary! > 0 ? NumberFormat('#,###').format(appSettings.targetSalary) : '');
  final targetHoursCtrl = TextEditingController(text: appSettings.targetHours != null && appSettings.targetHours! > 0 ? appSettings.targetHours.toString() : '');

  Get.dialog(Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('정산 및 목표 설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(children: [Expanded(child: TextField(controller: startCtrl, decoration: const InputDecoration(labelText: '시작일', border: OutlineInputBorder()))), const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('~')), Expanded(child: TextField(controller: endCtrl, decoration: const InputDecoration(labelText: '마감일', border: OutlineInputBorder())))]),
            const SizedBox(height: 15),
            TextField(controller: taxCtrl, decoration: const InputDecoration(labelText: '세금(%) 예: 3.3', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: wageCtrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()], decoration: const InputDecoration(labelText: '기본 단가', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            const Divider(),
            const Text('목표 설정 (둘 중 하나만 적어도 됨)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TextField(controller: targetSalaryCtrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()], decoration: const InputDecoration(labelText: '목표 금액(원)', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: targetHoursCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: '목표 공수', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(onPressed: () => Get.back(), child: const Text('취소')),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: () {
                    int? parsedWage, parsedTargetSalary; double? parsedTargetHours;
                    if(wageCtrl.text.isNotEmpty) parsedWage = int.parse(wageCtrl.text.replaceAll(',', ''));
                    if(targetSalaryCtrl.text.isNotEmpty) parsedTargetSalary = int.parse(targetSalaryCtrl.text.replaceAll(',', ''));
                    if(targetHoursCtrl.text.isNotEmpty) parsedTargetHours = double.tryParse(targetHoursCtrl.text);
                    
                    ref.read(appSettingsProvider.notifier).saveProfile(
                      settlementStartDay: int.tryParse(startCtrl.text) ?? 1,
                      settlementEndDay: int.tryParse(endCtrl.text) ?? 31,
                      taxType: taxCtrl.text,
                      defaultWage: parsedWage ?? -1, targetSalary: parsedTargetSalary ?? -1, targetHours: parsedTargetHours ?? -1,
                    );
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text('저장', style: TextStyle(color: Colors.white)),
                ),
              ],
            )
          ],
        ),
      ),
    ),
  ));
}