// lib/widgets/day_detail_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'dart:io';

import '../models/app_models.dart';
import '../providers/work_provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import 'add_record_modal.dart';
import 'edit_record_modal.dart';

class DayDetailModal extends ConsumerWidget {
  final DateTime selectedDate;
  const DayDetailModal({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workRecords = ref.watch(workProvider);
    final appSettings = ref.watch(appSettingsProvider);
    final dailyRecords = workRecords.where((r) => r.date.year == selectedDate.year && r.date.month == selectedDate.month && r.date.day == selectedDate.day).toList();

    WorkRecord? latestRecord;
    if (workRecords.isNotEmpty) {
      final sortedRecords = [...workRecords]..sort((a, b) => b.date.compareTo(a.date));
      latestRecord = sortedRecords.firstWhere((r) => !r.isSchedule, orElse: () => sortedRecords.first);
    }
    
    final templateRecord = globalClipboardRecord ?? latestRecord;
    final btnLabel = globalClipboardRecord != null ? '붙여넣기' : '빠른추가';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20, top: 20, left: 20, right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
            ]
          ),
          const Divider(),
          if (dailyRecords.isEmpty)
            const Padding(padding: EdgeInsets.all(30), child: Text('등록된 공수나 일정이 없습니다.', style: TextStyle(color: Colors.grey)))
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: dailyRecords.map((record) => _buildRecordItem(context, record, ref, appSettings)).toList(),
                ),
              ),
            ),
          
          const SizedBox(height: 20),
          Row(
            children: [
              if (templateRecord != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
                    onPressed: () {
                      ref.read(workProvider.notifier).addRecord(
                        WorkRecord(date: selectedDate, workHours: templateRecord.workHours, dailyWage: templateRecord.dailyWage, siteName: templateRecord.siteName, memo: templateRecord.memo, weather: templateRecord.weather, isSchedule: false)
                      );
                      Get.back(); Get.snackbar('빠른 추가 ⚡', '${templateRecord.siteName} 기록이 추가되었습니다.');
                    },
                    icon: Icon(globalClipboardRecord != null ? Icons.paste : Icons.flash_on), 
                    label: Text(btnLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 12)),
                  onPressed: () {
                    Get.back();
                    Future.delayed(const Duration(milliseconds: 150), () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (_) => AddRecordModal(selectedDate: selectedDate))); 
                  },
                  icon: const Icon(Icons.add, color: Colors.white), label: const Text('새로 추가', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                ),
              ),
            ]
          )
        ]
      )
    );
  }

  Widget _buildRecordItem(BuildContext context, WorkRecord record, WidgetRef ref, AppSettings appSettings) {
    return InkWell(
      onTap: () { Get.back(); Future.delayed(const Duration(milliseconds: 150), () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (_) => EditRecordModal(record: record))); },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: record.isSchedule ? Colors.blue.withOpacity(0.05) : Theme.of(context).cardColor, borderRadius: BorderRadius.circular(15), border: record.isSchedule ? Border.all(color: Colors.blueAccent.withOpacity(0.3)) : Border.all(color: Colors.grey.withOpacity(0.2))),
        child: Row(
          children: [
            Stack(
              children: [
                Container(width: 50, height: 50, decoration: BoxDecoration(color: record.isSchedule ? Colors.blue[100] : const Color(0xFFEEF0FF), shape: BoxShape.circle, border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2))), alignment: Alignment.center, child: record.isSchedule ? const Text('예정', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 14)) : Text(record.workHours.toStringAsFixed(1), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16))),
                if (record.photoPath != null || (record.photoPaths != null && record.photoPaths!.isNotEmpty)) 
                  Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle), child: const Icon(Icons.camera_alt, size: 12, color: Colors.white))),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Row(children: [Text(record.siteName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), if (record.weather != null) Text(' ${record.weather}', style: const TextStyle(fontSize: 16))]), 
                  Text(record.isSchedule ? '예상 단가: ${NumberFormat('#,###').format(record.dailyWage)}원' : '단가: ${NumberFormat('#,###').format(record.dailyWage)}원', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  // 🌟 [해결 5] 메모가 있을 경우 확실하게 보여주도록 추가!
                  if (record.memo != null && record.memo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text('📝 ${record.memo}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    )
                ]
              )
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (record.isSchedule) IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 24), onPressed: () { record.isSchedule = false; ref.read(workProvider.notifier).updateRecord(record); Get.snackbar('완료', '일정이 처리되었습니다.'); })
              else Text('${NumberFormat('#,###').format((record.workHours * record.dailyWage).toInt())}원', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(icon: const Icon(Icons.copy, color: Colors.blueAccent, size: 20), onPressed: () { globalClipboardRecord = record; Get.snackbar('복사 완료', '기록이 복사되었습니다.'); }),
              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => ref.read(workProvider.notifier).deleteRecord(record))
            ])
          ],
        ),
      ),
    );
  }
}