// lib/screens/developer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../providers/app_provider.dart';

class DeveloperScreen extends ConsumerStatefulWidget {
  const DeveloperScreen({super.key});
  @override
  ConsumerState<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends ConsumerState<DeveloperScreen> {
  late TextEditingController _companyCodeCtrl;
  late TextEditingController _positionCtrl;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    final appSettings = ref.read(appSettingsProvider);
    _companyCodeCtrl = TextEditingController(text: appSettings.companyCode);
    _positionCtrl = TextEditingController(text: appSettings.position);
    _selectedRole = appSettings.role; // 기본값 worker
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개발자 / 관리자 설정', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent)),
              child: const Text('이곳은 앱 관리자와 개발자를 위한 비밀 공간입니다. 함부로 코드를 유출하지 마세요.', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),

            // 1. 내 폰(개발자 폰)의 권한을 강제로 조작하는 기능
            const Text('내 기기 권한 오버라이드 (개발자용)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            TextField(controller: _companyCodeCtrl, decoration: const InputDecoration(labelText: '소속 회사 코드 (예: MARU_HQ)', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _positionCtrl, decoration: const InputDecoration(labelText: '내 직함 (예: 시스템 관리자)', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            
            const Text('내 앱 접근 권한', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 5),
            CupertinoSlidingSegmentedControl<String>(
              groupValue: _selectedRole,
              children: const {
                'worker': Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10), child: Text('일반 팀원')),
                'manager': Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10), child: Text('팀장')),
                'admin': Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10), child: Text('대표/개발자')),
              },
              onValueChanged: (val) => setState(() => _selectedRole = val!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () {
                ref.read(appSettingsProvider.notifier).saveProfile(
                  companyCode: _companyCodeCtrl.text,
                  position: _positionCtrl.text,
                  role: _selectedRole,
                );
                Get.snackbar('권한 변경 완료', '현재 기기에 [$_selectedRole] 권한이 부여되었습니다.', backgroundColor: Colors.green, colorText: Colors.white);
              },
              child: const Text('내 권한 강제 적용', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 50),
            const Divider(),
            const SizedBox(height: 20),

            // 2. 다른 사용자의 권한을 관리하는 시스템 (클라우드 연동 준비)
            const Text('전체 사용자 직급 관리', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            const Text('파이어베이스(Firestore)에 연동된 모든 사용자의 목록을 불러오고, 원격으로 직급(팀장/팀원)을 부여하는 기능이 이곳에 들어올 예정입니다.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 15),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), foregroundColor: Colors.blueAccent),
              onPressed: () {
                // TODO: Firebase Users 컬렉션 불러오기 화면으로 이동
                Get.snackbar('준비 중', '파이어베이스 사용자 연동 시스템을 먼저 구축해야 합니다.');
              },
              icon: const Icon(Icons.cloud_sync),
              label: const Text('클라우드 사용자 목록 불러오기'),
            )
          ],
        ),
      ),
    );
  }
}