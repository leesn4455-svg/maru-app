// lib/screens/schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _box = Hive.box('preferences');
  List<Map<String, dynamic>> _schedules = [];
  String _userRole = '팀원'; 

  @override
  void initState() {
    super.initState();
    _loadSchedules();
    // 🌟 내 정보에서 설정한 직급(Role)을 불러옵니다.
    _userRole = _box.get('user_role', defaultValue: '팀원');
  }

  void _loadSchedules() {
    final stored = _box.get('company_schedules', defaultValue: []);
    _schedules = List<Map<String, dynamic>>.from(stored.map((e) => Map<String, dynamic>.from(e)));
    
    // 날짜가 빠른 순(다가오는 일정 순)으로 정렬
    _schedules.sort((a, b) => DateTime.parse(a['date']).compareTo(DateTime.parse(b['date'])));
    setState(() {});
  }

  void _saveSchedules() {
    _box.put('company_schedules', _schedules);
    _loadSchedules();
  }

  // 🌟 스케줄 배정 팝업 (팀장/대표 전용)
  void _showAddScheduleDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1)); // 기본값: 내일
    final siteCtrl = TextEditingController();
    final membersCtrl = TextEditingController(); // 임시로 직접 텍스트 입력 (서버 연동 시 체크박스로 변경 예정)

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
              left: 20, right: 20, top: 20
            ),
            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('새 스케줄 배정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  
                  // 날짜 선택
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.grey)),
                    leading: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                    title: const Text('출근 날짜 선택', style: TextStyle(fontSize: 14)),
                    subtitle: Text(DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setModalState(() => selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 15),

                  // 현장명 입력
                  TextField(
                    controller: siteCtrl,
                    decoration: const InputDecoration(labelText: '출근 현장명 (예: 철산 자이)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),

                  // 배정 인원 입력 (추후 서버가 붙으면 팀원 목록을 불러와서 체크박스로 바꿀 예정)
                  TextField(
                    controller: membersCtrl,
                    decoration: const InputDecoration(labelText: '출근 인원 지정 (예: 김마루, 이세노)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),

                  // 등록 및 알림 발송 버튼
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () {
                      if (siteCtrl.text.trim().isEmpty || membersCtrl.text.trim().isEmpty) {
                        Get.snackbar('알림', '현장명과 출근 인원을 모두 입력해주세요.');
                        return;
                      }
                      
                      _schedules.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'date': selectedDate.toIso8601String(),
                        'siteName': siteCtrl.text.trim(),
                        'assignedMembers': membersCtrl.text.trim(),
                        'assignedBy': _box.get('user_name', defaultValue: '관리자'),
                      });
                      
                      _saveSchedules();
                      Get.back();

                      // 🌟 나중에 푸시 알림 서버 코드가 들어갈 자리입니다!
                      Get.snackbar(
                        '스케줄 배정 완료 🔔', 
                        '지정된 팀원들에게 출근 알림이 전송되었습니다! (현재는 임시 알림입니다)', 
                        backgroundColor: Colors.blueAccent, 
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3)
                      );
                    },
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    label: const Text('스케줄 배정 및 알림 발송', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  )
                ],
              ),
            ),
          );
        }
      ),
      isScrollControlled: true,
    );
  }

  void _deleteSchedule(int index) {
    Get.defaultDialog(
      title: '일정 취소', middleText: '이 스케줄을 취소하시겠습니까?', textConfirm: '예', textCancel: '아니오',
      confirmTextColor: Colors.white, buttonColor: Colors.redAccent, cancelTextColor: Colors.black,
      onConfirm: () { _schedules.removeAt(index); _saveSchedules(); Get.back(); }
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = _userRole == '대표' || _userRole == '팀장';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 지나간 일정과 다가오는 일정을 분리
    final upcomingSchedules = _schedules.where((s) => !DateTime.parse(s['date']).isBefore(today)).toList();
    final pastSchedules = _schedules.where((s) => DateTime.parse(s['date']).isBefore(today)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('팀 스케줄 관리', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: upcomingSchedules.isEmpty && pastSchedules.isEmpty
          ? Center(
              child: Text(
                isAdmin ? '예정된 스케줄이 없습니다.\n우측 하단 버튼을 눌러 팀원들에게 현장을 배정하세요.' : '현재 배정된 출근 스케줄이 없습니다.', 
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)
              )
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (upcomingSchedules.isNotEmpty) ...[
                  const Text('다가오는 일정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  const SizedBox(height: 10),
                  ...upcomingSchedules.map((schedule) => _buildScheduleCard(schedule, isAdmin, true)).toList(),
                  const SizedBox(height: 20),
                ],
                if (pastSchedules.isNotEmpty) ...[
                  const Text('지난 일정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  ...pastSchedules.map((schedule) => _buildScheduleCard(schedule, isAdmin, false)).toList(),
                ]
              ],
            ),
      // 🌟 관리자에게만 배정 버튼 노출
      floatingActionButton: isAdmin 
        ? FloatingActionButton.extended(
            backgroundColor: AppTheme.primaryColor,
            onPressed: _showAddScheduleDialog,
            icon: const Icon(Icons.add_task, color: Colors.white),
            label: const Text('스케줄 배정', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ) 
        : null, 
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule, bool isAdmin, bool isUpcoming) {
    final scheduleDate = DateTime.parse(schedule['date']);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: isUpcoming ? 2 : 0,
      color: isUpcoming ? Colors.white : Colors.grey[100],
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(DateFormat('MM/dd').format(scheduleDate), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isUpcoming ? Colors.black : Colors.grey)),
            Text(DateFormat('E', 'ko_KR').format(scheduleDate), style: TextStyle(color: isUpcoming ? AppTheme.primaryColor : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        title: Text(schedule['siteName'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isUpcoming ? Colors.black : Colors.grey)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            children: [
              Icon(Icons.group, size: 14, color: isUpcoming ? Colors.indigoAccent : Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text(schedule['assignedMembers'], style: TextStyle(color: isUpcoming ? Colors.black87 : Colors.grey))),
            ],
          ),
        ),
        trailing: isAdmin
            ? IconButton(
                icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                onPressed: () {
                  int index = _schedules.indexWhere((s) => s['id'] == schedule['id']);
                  if (index != -1) _deleteSchedule(index);
                },
              )
            : null,
      ),
    );
  }
}