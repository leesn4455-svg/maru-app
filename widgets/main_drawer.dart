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
import '../screens/main_screen.dart'; 

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  // 입사일 기준 D-Day 계산 함수 (원본 유지)
  String _getDDayString(DateTime? joinDate) {
    if (joinDate == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final join = DateTime(joinDate.year, joinDate.month, joinDate.day);
    final diffDays = today.difference(join).inDays;
    if (diffDays < 0) return ' (D${diffDays})'; 
    int months = (now.year - join.year) * 12 + now.month - join.month;
    if (now.day < join.day) months--;
    int years = months ~/ 12;
    int remainingMonths = months % 12;
    if (years > 0 && remainingMonths > 0) return ' ($years년 $remainingMonths개월 차)';
    if (years > 0) return ' ($years년 차)';
    if (months > 0) return ' ($months개월 차)';
    return ' (신규 입사)';
  }

  // 🌟 카테고리 타이틀 디자인 함수
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 25, bottom: 10),
      child: Text(
        title, 
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // 1. 프로필 헤더 영역
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(color: Color(0xFF5A55F5)), // 메인 브랜드 컬러
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white24,
                  backgroundImage: appSettings.profileImagePath != null ? FileImage(File(appSettings.profileImagePath!)) : null,
                  child: appSettings.profileImagePath == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Text(appSettings.userName ?? '사용자', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                      child: Text(appSettings.role, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 5),
                Text('${appSettings.position ?? '직책 미등록'}${_getDDayString(appSettings.joinDate)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          
          // 2. 카테고리별 메뉴 리스트 영역
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildSectionTitle('🏢 업무 및 소통'),
                ListTile(leading: const Icon(Icons.campaign, color: Colors.redAccent), title: const Text('사내 공지사항'), onTap: () { Get.back(); Get.to(() => const NoticeScreen()); }),
                ListTile(leading: const Icon(Icons.event_available, color: Colors.indigoAccent), title: const Text('팀 스케줄 관리'), onTap: () { Get.back(); Get.to(() => const ScheduleScreen()); }),
                ListTile(leading: const Icon(Icons.chat_bubble, color: Colors.blueAccent), title: const Text('사내 채팅방'), onTap: () { Get.back(); Get.to(() => const ChatRoomListScreen()); }),
                ListTile(leading: const Icon(Icons.business, color: Colors.brown), title: const Text('현장 정보 관리'), onTap: () { Get.back(); Get.to(() => const SiteInfoScreen()); }),

                _buildSectionTitle('📊 정산 및 기록'),
                ListTile(leading: const Icon(Icons.assignment, color: Colors.teal), title: const Text('동산보드 작성'), onTap: () { Get.back(); Get.to(() => const BoardScreen()); }),
                ListTile(leading: const Icon(Icons.photo_album, color: Colors.green), title: const Text('현장 사진첩'), onTap: () { Get.back(); Get.to(() => const PhotoAlbumScreen()); }),
                ListTile(leading: const Icon(Icons.bar_chart, color: Colors.orange), title: const Text('통계 및 정산 내역'), onTap: () { Get.back(); Get.to(() => const StatisticsScreen()); }),
                ListTile(leading: const Icon(Icons.edit_note, color: Colors.amber), title: const Text('퀵 메모'), onTap: () { Get.back(); Get.to(() => const MemoScreen()); }),
                ListTile(leading: const Icon(Icons.folder, color: Colors.blueGrey), title: const Text('파일 및 작업 일지'), onTap: () { Get.back(); Get.to(() => const WorkLogScreen()); }),

                _buildSectionTitle('⚙️ 설정'),
                ListTile(leading: const Icon(Icons.person, color: Colors.purple), title: const Text('내 정보 수정'), onTap: () { Get.back(); Get.to(() => const IntroScreen()); }),
                ListTile(leading: const Icon(Icons.settings, color: Colors.grey), title: const Text('앱 설정'), onTap: () { Get.back(); Get.to(() => const AppSettingsScreen()); }),
                
                const SizedBox(height: 30), 
              ],
            ),
          ),
        ],
      ),
    );
  }
}