// lib/widgets/calendar_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import '../providers/work_provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart'; // [추가] 디자인 통제소 연결
import 'record_modals.dart'; // [추가] 모달창 함수 연결

class CalendarHeader extends ConsumerWidget {
  final DateTime focusedDay;
  const CalendarHeader({super.key, required this.focusedDay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workRecords = ref.watch(workProvider);
    final appSettings = ref.watch(appSettingsProvider);

    final startDay = appSettings.settlementStartDay;
    DateTime startDate, endDate;
    if (startDay == 1) {
      startDate = DateTime(focusedDay.year, focusedDay.month, 1);
      endDate = DateTime(focusedDay.year, focusedDay.month + 1, 0);
    } else {
      if (focusedDay.day >= startDay) {
        startDate = DateTime(focusedDay.year, focusedDay.month, startDay);
        endDate = DateTime(focusedDay.year, focusedDay.month + 1, startDay - 1);
      } else {
        startDate = DateTime(focusedDay.year, focusedDay.month - 1, startDay);
        endDate = DateTime(focusedDay.year, focusedDay.month, startDay - 1);
      }
    }

    final monthlyRecords = workRecords.where((r) => !r.isSchedule && r.date.isAfter(startDate.subtract(const Duration(days: 1))) && r.date.isBefore(endDate.add(const Duration(days: 1)))).toList();
    double totalMonthHours = 0; int totalMonthSalary = 0;
    for (var r in monthlyRecords) { totalMonthHours += r.workHours; totalMonthSalary += (r.dailyWage * r.workHours).toInt(); }
    
    // 목표 달성률 계산
    double progress = 0.0; String targetLabel = '';
    if (appSettings.targetSalary != null && appSettings.targetSalary! > 0) {
      progress = totalMonthSalary / appSettings.targetSalary!;
      targetLabel = '목표: ${NumberFormat('#,###').format(appSettings.targetSalary)}원';
    } else if (appSettings.targetHours != null && appSettings.targetHours! > 0) {
      progress = totalMonthHours / appSettings.targetHours!;
      targetLabel = '목표: ${appSettings.targetHours}공수';
    }
    if (progress > 1.0) progress = 1.0;

    return Container(
      margin: const EdgeInsets.all(12.0), padding: const EdgeInsets.all(16.0),
      // [최적화] 이제 색상을 바꿀 때 AppTheme 하나만 고치면 됩니다!
      decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              Text('정산 (${startDate.month}/${startDate.day}~${endDate.month}/${endDate.day})', style: const TextStyle(color: Colors.white70, fontSize: 14)), 
              GestureDetector(
                // 이제 record_modals.dart에 있는 함수를 정상적으로 인식합니다!
                onTap: () => showSettlementDialog(context, ref, appSettings), 
                child: const Icon(Icons.settings, color: Colors.white, size: 22)
              )
            ]
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, 
            children: [
              Text('${NumberFormat('#,###').format(totalMonthSalary)}원', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)), 
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text('총 $totalMonthHours 공수', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))
            ]
          ),
          if (targetLabel.isNotEmpty) ...[
            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(targetLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)), Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]),
            const SizedBox(height: 5),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: Colors.white.withOpacity(0.2), valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? Colors.greenAccent : Colors.orangeAccent)))
          ]
        ],
      ),
    );
  }
}