// lib/screens/my_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MyScheduleScreen extends StatefulWidget {
  const MyScheduleScreen({super.key});
  @override
  State<MyScheduleScreen> createState() => _MyScheduleScreenState();
}

class _MyScheduleScreenState extends State<MyScheduleScreen> {
  List<dynamic> schedules = [];
  bool isLoading = true;
  String myId = "";

  @override
  void initState() {
    super.initState();
    // 로그인된 내 아이디 꺼내기
    final box = Hive.box('preferences');
    myId = box.get('user_login_id', defaultValue: '');
    _fetchMySchedules();
  }

  Future<void> _fetchMySchedules() async {
    setState(() => isLoading = true);
    final data = await ApiService.getSchedules(myId);
    setState(() {
      schedules = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('내 스케줄 확인', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => Get.back()),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.black), onPressed: _fetchMySchedules)],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : schedules.isEmpty
              ? const Center(child: Text('예정된 스케줄이 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  schedule['work_date'] ?? '날짜 없음',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                ),
                                const Icon(Icons.event_available, color: AppTheme.primaryColor, size: 20)
                              ],
                            ),
                            const Divider(height: 20, thickness: 1),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.business, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  schedule['site_name'] ?? '현장 미정',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ],
                            ),
                            if (schedule['memo'] != null && schedule['memo'].toString().isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.yellow.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: Text('📌 메모: ${schedule['memo']}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}