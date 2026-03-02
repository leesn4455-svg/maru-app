// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../widgets/main_drawer.dart'; 
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';

import 'calendar_screen.dart';
import 'board_screen.dart';
import 'site_info_screen.dart';
import 'schedule_screen.dart';
import 'notice_screen.dart';
import 'statistics_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {

  Widget _buildHomeButton({required String title, required IconData icon, required Color color, required VoidCallback onTap, bool isLarge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isLarge ? 24 : 16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: isLarge ? 48 : 32, color: color),
            ),
            SizedBox(height: isLarge ? 15 : 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isLarge ? 18 : 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(appSettingsProvider);

    return Scaffold(
      // 🌟 [수정] Maru 홈 -> Maru 로 변경
      appBar: AppBar(title: const Text('Maru', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      drawer: const MainDrawer(), 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('안녕하세요, ${appSettings.userName ?? '작업자'}님!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('오늘도 안전하고 즐거운 하루 되세요.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 30),

            // 🌟 [수정] 이름 변경: 동산보드
            SizedBox(
              height: 160,
              child: _buildHomeButton(
                title: '동산보드', 
                icon: Icons.camera_alt, 
                color: Colors.deepPurple, 
                isLarge: true,
                onTap: () => Get.to(() => const BoardScreen())
              ),
            ),
            const SizedBox(height: 15),

            // 🌟 [수정] 4개의 버튼 라인업 완벽 교체
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.1,
              children: [
                _buildHomeButton(
                  title: '공수 달력', 
                  icon: Icons.calendar_month, 
                  color: Colors.blue, 
                  // 🌟 [해결] 공수 달력 우측 상단에 정산으로 가는 바로가기 버튼 추가!
                  onTap: () => Get.to(() => Scaffold(
                    appBar: AppBar(
                      title: const Text('공수 달력', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true,
                      actions: [
                        IconButton(icon: const Icon(Icons.bar_chart, color: AppTheme.primaryColor, size: 28), onPressed: () => Get.to(() => const StatisticsScreen())),
                        const SizedBox(width: 8)
                      ],
                    ), 
                    body: const CalendarScreen()
                  ))
                ),
                _buildHomeButton(
                  title: '팀 스케줄 관리', 
                  icon: Icons.event_available, 
                  color: Colors.indigoAccent, 
                  onTap: () => Get.to(() => const ScheduleScreen())
                ),
                _buildHomeButton(
                  title: '사내 공지사항', 
                  icon: Icons.campaign, 
                  color: Colors.redAccent, 
                  onTap: () => Get.to(() => const NoticeScreen())
                ),
                _buildHomeButton(
                  title: '현장 정보 관리', 
                  icon: Icons.business, 
                  color: Colors.brown, 
                  onTap: () => Get.to(() => const SiteInfoScreen())
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}