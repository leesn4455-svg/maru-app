// lib/screens/settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'site_manager_screen.dart'; 
import 'developer_screen.dart'; // 🌟 [추가] 새로 만들 비밀의 방 연결
import '../providers/app_provider.dart';
import '../models/app_models.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('내 정보 및 설정', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: false),
      body: ListView(
        children: [
          _buildProfileCard(context, appSettings, ref), const Divider(),
          
          _buildSectionTitle('앱 및 정산 설정'),
          ListTile(leading: const Icon(Icons.calendar_month, color: Color(0xFF5A55F5)), title: const Text('정산 시작일 설정'), subtitle: Text('현재: 매월 ${appSettings.settlementStartDay}일'), onTap: () => _showStartDayPicker(context, ref, appSettings)),
          ListTile(leading: const Icon(Icons.dark_mode, color: Color(0xFF5A55F5)), title: const Text('다크 모드'), trailing: Switch(activeColor: const Color(0xFF5A55F5), value: appSettings.isDarkMode, onChanged: (val) { ref.read(appSettingsProvider.notifier).saveProfile(isDarkMode: val); })), const Divider(),
          
          _buildSectionTitle('데이터 관리'),
          ListTile(leading: const Icon(Icons.cloud_upload, color: Colors.blue), title: const Text('클라우드 백업'), subtitle: const Text('현재 기기의 데이터를 안전하게 보관합니다.'), onTap: () { Get.snackbar('알림', '백업 기능을 연결 중입니다!'); }),
          ListTile(leading: const Icon(Icons.cloud_download, color: Colors.green), title: const Text('데이터 복원'), subtitle: const Text('클라우드에서 이전 데이터를 불러옵니다.'), onTap: () { Get.snackbar('알림', '복원 기능을 연결 중입니다!'); }),
          const Divider(),

          _buildSectionTitle('현장 정보 관리'),
          ListTile(leading: const Icon(Icons.business, color: Color(0xFF5A55F5)), title: const Text('저장된 현장 목록'), subtitle: const Text('주소, 담당자 연락처, 창고 위치 등'), onTap: () => Get.to(() => const SiteManagerScreen())),
          
          const SizedBox(height: 30),
          // 🌟 [추가] 개발자 전용 비밀 통로
          ListTile(
            leading: const Icon(Icons.developer_board, color: Colors.grey),
            title: const Text('시스템 관리자 모드', style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () => _showDeveloperLogin(context),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // 🌟 [추가] 비밀번호를 묻는 보안 팝업
  void _showDeveloperLogin(BuildContext context) {
    final pwCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('개발자 인증'),
        content: TextField(
          controller: pwCtrl,
          obscureText: true, // 비밀번호 숨김 처리
          decoration: const InputDecoration(hintText: '관리자 코드를 입력하세요'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A55F5), foregroundColor: Colors.white),
            onPressed: () {
              // 🔑 비밀번호 설정: 'maru2026' (원하시는 대로 변경 가능합니다!)
              if (pwCtrl.text == 'maru2026') {
                Get.back();
                Get.to(() => const DeveloperScreen()); // 비밀의 방으로 이동!
              } else {
                Get.back();
                Get.snackbar('경고', '인증 코드가 일치하지 않습니다.', backgroundColor: Colors.redAccent, colorText: Colors.white);
              }
            },
            child: const Text('진입'),
          )
        ],
      )
    );
  }

  Widget _buildSectionTitle(String title) { return Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), child: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold))); }

  Widget _buildProfileCard(BuildContext context, AppSettings settings, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(20), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async { final picker = ImagePicker(); final XFile? image = await picker.pickImage(source: ImageSource.gallery); if (image != null) { ref.read(appSettingsProvider.notifier).saveProfile(profileImagePath: image.path); } },
            child: CircleAvatar(radius: 35, backgroundColor: Colors.grey[200], backgroundImage: settings.profileImagePath != null ? FileImage(File(settings.profileImagePath!)) : null, child: settings.profileImagePath == null ? const Icon(Icons.person, size: 30, color: Colors.grey) : null),
          ),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(settings.userName ?? '사용자', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(settings.phoneNumber ?? '연락처 미등록', style: const TextStyle(color: Colors.grey))])),
        ],
      ),
    );
  }

  void _showStartDayPicker(BuildContext context, WidgetRef ref, AppSettings settings) {
    showModalBottomSheet(context: context, builder: (context) { return Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('정산 시작일 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 10), const Text('매달 이 날짜를 기준으로 한 달 공수를 합산합니다.', style: TextStyle(color: Colors.grey, fontSize: 13)), const SizedBox(height: 20), SizedBox(height: 150, child: ListView.builder(itemCount: 31, itemBuilder: (context, index) { final day = index + 1; return ListTile(title: Text('$day 일', textAlign: TextAlign.center), onTap: () { ref.read(appSettingsProvider.notifier).saveProfile(settlementStartDay: day); Navigator.pop(context); }); }))])); });
  }
}