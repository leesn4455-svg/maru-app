// lib/widgets/main_drawer.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../providers/app_provider.dart';
import '../screens/app_settings_screen.dart';
import '../screens/site_info_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/intro_screen.dart'; 
import '../screens/photo_album_screen.dart';
import '../screens/memo_screen.dart';
import '../screens/chat_room_list_screen.dart';
import '../screens/work_log_screen.dart';
import '../screens/schedule_screen.dart';
import '../screens/notice_screen.dart';
import '../screens/board_screen.dart';
import '../screens/calendar_screen.dart'; 

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  String _getDDayString(DateTime? joinDate) {
    if (joinDate == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final join = DateTime(joinDate.year, joinDate.month, joinDate.day);
    final diffDays = today.difference(join).inDays;
    if (diffDays < 0) return ' (D${diffDays})'; 
    int months = (now.year - join.year) * 12 + now.month - join.month; 
    if (now.day < join.day) months--; 
    return ' (D+${diffDays}일, ${months + 1}개월 차)'; 
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);

    return Drawer(
      // 🌟 [해결] SafeArea로 감싸서 상단 시간/배터리 영역과 하단 스와이프 영역 침범을 완벽히 차단!
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(color: Color(0xFF5A55F5)),
                    accountName: Row(
                      children: [
                        Text(appSettings.userName ?? '작업자님', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
                        Text(_getDDayString(appSettings.joinDate), style: const TextStyle(fontSize: 13, color: Colors.white70))
                      ]
                    ),
                    accountEmail: Text(appSettings.phoneNumber ?? ''),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Colors.white, 
                      backgroundImage: appSettings.profileImagePath != null ? FileImage(File(appSettings.profileImagePath!)) : null, 
                      child: appSettings.profileImagePath == null ? const Icon(Icons.person, size: 40, color: Color(0xFF5A55F5)) : null
                    ),
                  ),
                  
                  _buildSectionTitle('🛠️ 현장 업무'),
                  // 🌟 [수정] 메뉴 이름 변경
                  ListTile(leading: const Icon(Icons.camera_alt, color: Colors.deepPurple), title: const Text('동산보드', style: TextStyle(fontWeight: FontWeight.bold)), onTap: () { Get.back(); Get.to(() => const BoardScreen()); }),
                  ListTile(leading: const Icon(Icons.calendar_month, color: Colors.blue), title: const Text('공수 달력'), onTap: () { Get.back(); Get.to(() => Scaffold(appBar: AppBar(title: const Text('공수 달력', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.bar_chart, color: Color(0xFF5A55F5)), onPressed: () => Get.to(() => const StatisticsScreen()))]), body: const CalendarScreen())); }),
                  ListTile(leading: const Icon(Icons.edit_note, color: Colors.teal), title: const Text('퀵 메모장'), onTap: () { Get.back(); Get.to(() => const MemoScreen()); }),
                  ListTile(leading: const Icon(Icons.description, color: Colors.brown), title: const Text('작업일지 양식'), onTap: () { Get.back(); Get.to(() => const WorkLogScreen()); }),
                  ListTile(leading: const Icon(Icons.business, color: Colors.indigo), title: const Text('현장 정보 관리'), onTap: () { Get.back(); Get.to(() => const SiteInfoScreen()); }),

                  _buildSectionTitle('💬 소통 및 일정'),
                  ListTile(leading: const Icon(Icons.campaign, color: Colors.redAccent), title: const Text('사내 공지사항'), onTap: () { Get.back(); Get.to(() => const NoticeScreen()); }),
                  ListTile(leading: const Icon(Icons.event_available, color: Colors.indigoAccent), title: const Text('팀 스케줄 관리'), onTap: () { Get.back(); Get.to(() => const ScheduleScreen()); }),
                  ListTile(leading: const Icon(Icons.chat_bubble, color: Colors.blueAccent), title: const Text('사내 채팅방'), onTap: () { Get.back(); Get.to(() => const ChatRoomListScreen()); }),
                  
                  _buildSectionTitle('📊 정산 및 기록'),
                  ListTile(leading: const Icon(Icons.photo_album, color: Colors.green), title: const Text('현장 사진첩'), onTap: () { Get.back(); Get.to(() => const PhotoAlbumScreen()); }),
                  ListTile(leading: const Icon(Icons.bar_chart, color: Colors.orange), title: const Text('통계 및 정산 내역'), onTap: () { Get.back(); Get.to(() => const StatisticsScreen()); }),
                  
                  _buildSectionTitle('⚙️ 설정'),
                  ListTile(leading: const Icon(Icons.edit, color: Colors.purple), title: const Text('내 정보 수정'), onTap: () { Get.back(); Get.to(() => const IntroScreen()); }),
                  ListTile(leading: const Icon(Icons.settings), title: const Text('앱 설정'), onTap: () { Get.back(); Get.to(() => const AppSettingsScreen()); }),
                  
                  const SizedBox(height: 20), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}