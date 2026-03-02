// lib/providers/work_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_models.dart';

class WorkRecordNotifier extends StateNotifier<List<WorkRecord>> {
  WorkRecordNotifier() : super([]) {
    loadRecords();
  }

  final String _boxName = 'work_records';

  void loadRecords() {
    final box = Hive.box<WorkRecord>(_boxName);
    // [핵심 변경] 완전히 새로운 리스트 객체로 덮어씌워 화면이 100% 즉시 갱신되도록 강제함
    state = [...box.values.toList()];
  }

  Future<void> addRecord(WorkRecord record) async {
    final box = Hive.box<WorkRecord>(_boxName);
    await box.add(record);
    loadRecords();
  }

  Future<void> updateRecord(WorkRecord record) async {
    await record.save();
    loadRecords();
  }

  Future<void> deleteRecord(WorkRecord record) async {
    await record.delete();
    loadRecords();
  }
}

final workProvider = StateNotifierProvider<WorkRecordNotifier, List<WorkRecord>>((ref) {
  return WorkRecordNotifier();
});