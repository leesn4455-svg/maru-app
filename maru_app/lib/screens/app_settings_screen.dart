// lib/screens/app_settings_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/app_provider.dart';
import '../providers/work_provider.dart';
import '../models/app_models.dart';
import '../services/notification_service.dart';
import 'main_screen.dart';
import 'developer_screen.dart'; // 🌟 [추가] 비밀의 방(개발자 스크린) 연결!

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});
  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  late bool _isReminderOn;
  late TimeOfDay _reminderTime;
  final _prefs = Hive.box('preferences');
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _isReminderOn = _prefs.get('reminder_on', defaultValue: false);
    int hour = _prefs.get('reminder_hour', defaultValue: 20);
    int minute = _prefs.get('reminder_minute', defaultValue: 0);
    _reminderTime = TimeOfDay(hour: hour, minute: minute);
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; 

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      setState(() => _currentUser = userCredential.user);
      Get.snackbar('로그인 성공', '${_currentUser?.displayName}님 환영합니다!', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('로그인 실패', '다시 시도해주세요.', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    setState(() => _currentUser = null);
    Get.snackbar('로그아웃', '안전하게 로그아웃 되었습니다.');
  }

  Future<void> _backupToCloud() async {
    if (_currentUser == null) {
      Get.snackbar('알림', '먼저 구글 로그인을 진행해주세요.');
      return;
    }
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final box = Hive.box<WorkRecord>('work_records');
      List<Map<String, dynamic>> jsonData = box.values.map((r) => {
        'date': r.date.toIso8601String(), 'workHours': r.workHours, 'dailyWage': r.dailyWage,
        'siteName': r.siteName, 'memo': r.memo, 'weather': r.weather, 'isSchedule': r.isSchedule
      }).toList();

      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set({
        'work_records': jsonData,
        'last_backup': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('서버 응답 시간 초과 (인터넷 상태를 확인하세요)');
      });

      if (Get.isDialogOpen ?? false) Get.back(); 
      Get.snackbar('클라우드 백업 성공 ☁️', '소중한 데이터가 구글 서버에 안전하게 보관되었습니다!', backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('백업 오류', '문제가 발생했습니다: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> _restoreFromCloud(WidgetRef ref) async {
    if (_currentUser == null) return;
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get().timeout(const Duration(seconds: 10));
      
      if (!doc.exists || doc.data() == null) {
        if (Get.isDialogOpen ?? false) Get.back();
        Get.snackbar('복원 실패', '클라우드에 저장된 백업 데이터가 없습니다.');
        return;
      }

      List<dynamic> jsonData = doc.data()!['work_records'] ?? [];
      final box = Hive.box<WorkRecord>('work_records');
      await box.clear(); 

      for (var item in jsonData) {
        await box.add(WorkRecord(
          date: DateTime.parse(item['date']), workHours: (item['workHours'] as num).toDouble(), 
          dailyWage: item['dailyWage'], siteName: item['siteName'], 
          memo: item['memo'] ?? '', weather: item['weather'], isSchedule: item['isSchedule'] ?? false,
        ));
      }

      ref.read(workProvider.notifier).loadRecords(); 
      if (Get.isDialogOpen ?? false) Get.back(); 
      Get.snackbar('클라우드 복원 성공 🎉', '모든 데이터가 완벽하게 복구되었습니다!', backgroundColor: Colors.green, colorText: Colors.white);
      Future.delayed(const Duration(seconds: 1), () => Get.offAll(() => const MainScreen()));
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('복원 오류', '데이터를 가져오는 중 문제가 발생했습니다: $e');
    }
  }

  void _updateReminder(bool isOn, TimeOfDay time) {
    setState(() { _isReminderOn = isOn; _reminderTime = time; });
    _prefs.put('reminder_on', isOn); _prefs.put('reminder_hour', time.hour); _prefs.put('reminder_minute', time.minute);
    if (isOn) {
      NotificationService().scheduleDailyReminder(time.hour, time.minute);
      Get.snackbar('알림 설정 완료', '매일 ${time.format(context)}에 알림이 울립니다.');
    } else {
      NotificationService().cancelReminder();
    }
  }

  void _showScrollTimePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250, color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            SizedBox(height: 190, child: CupertinoDatePicker(mode: CupertinoDatePickerMode.time, initialDateTime: DateTime(2020, 1, 1, _reminderTime.hour, _reminderTime.minute), onDateTimeChanged: (DateTime newTime) => _updateReminder(true, TimeOfDay(hour: newTime.hour, minute: newTime.minute)))),
            CupertinoButton(child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)), onPressed: () => Get.back())
          ],
        ),
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
              // 🔑 비밀번호 설정: 'maru2026'
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

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('앱 설정', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: ListView(
        children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('구글 클라우드 계정', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent))),
          if (_currentUser == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 12), elevation: 2),
                onPressed: _signInWithGoogle,
                icon: Image.network('https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg', width: 24),
                label: const Text('Google 계정으로 연동하기', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          else ...[
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.check, color: Colors.white)),
              title: Text(_currentUser!.email ?? '구글 계정 연결됨', style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: OutlinedButton(onPressed: _signOut, child: const Text('로그아웃', style: TextStyle(fontSize: 12))),
            ),
            ListTile(leading: const Icon(Icons.cloud_upload, color: Colors.blueAccent), title: const Text('클라우드에 내 데이터 백업하기'), onTap: _backupToCloud),
            ListTile(leading: const Icon(Icons.cloud_download, color: Colors.orangeAccent), title: const Text('클라우드에서 데이터 복구하기'), onTap: () => _restoreFromCloud(ref)),
          ],

          const Divider(),
          const Padding(padding: EdgeInsets.all(16), child: Text('디스플레이', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          SwitchListTile(
            title: const Text('다크 모드'), subtitle: const Text('화면을 어둡게 하여 눈의 피로를 줄입니다.'),
            value: appSettings.isDarkMode, activeColor: const Color(0xFF5A55F5),
            onChanged: (val) => ref.read(appSettingsProvider.notifier).saveProfile(isDarkMode: val),
          ),
          
          const Divider(),
          const Padding(padding: EdgeInsets.all(16), child: Text('편의 기능', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          SwitchListTile(
            title: Text('공수 입력 알림 (${_reminderTime.format(context)})'), subtitle: const Text('지정된 시간에 푸시 알림을 보냅니다.'),
            value: _isReminderOn, activeColor: const Color(0xFF5A55F5),
            onChanged: (val) => _updateReminder(val, _reminderTime),
          ),
          if (_isReminderOn) ListTile(leading: const Icon(Icons.access_time, color: Color(0xFF5A55F5)), title: const Text('알림 시간 변경하기'), onTap: _showScrollTimePicker),

          const Divider(),
          const Padding(padding: EdgeInsets.all(16), child: Text('로컬 파일 관리 & 초기화', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          ListTile(leading: const Icon(Icons.file_download, color: Colors.grey), title: const Text('백업 파일 기기에 다운로드'), onTap: _backupData),
          ListTile(leading: const Icon(Icons.file_upload, color: Colors.grey), title: const Text('기기에 저장된 파일로 복원'), onTap: () => _restoreData(ref)),
          
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text('공수 전체 초기화', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              Get.defaultDialog(
                title: '경고',
                middleText: '입력된 모든 공수와 일정이 삭제됩니다.\n정말 초기화하시겠습니까?',
                textConfirm: '전체 삭제', textCancel: '취소',
                confirmTextColor: Colors.white, buttonColor: Colors.redAccent, cancelTextColor: Colors.black,
                onConfirm: () async {
                  await Hive.box<WorkRecord>('work_records').clear();
                  ref.read(workProvider.notifier).loadRecords();
                  Get.back();
                  Get.snackbar('초기화 완료', '모든 기록이 깨끗하게 삭제되었습니다.');
                }
              );
            },
          ),
          
          // 🌟 [추가] 개발자 전용 비밀 통로를 이 파일에 넣었습니다!
          const Divider(),
          ListTile(
            leading: const Icon(Icons.developer_board, color: Colors.grey),
            title: const Text('시스템 관리자 모드', style: TextStyle(color: Colors.grey, fontSize: 12)),
            onTap: () => _showDeveloperLogin(context),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<void> _backupData() async {
    try {
      final box = Hive.box<WorkRecord>('work_records');
      List<Map<String, dynamic>> jsonData = box.values.map((r) => {'date': r.date.toIso8601String(), 'workHours': r.workHours, 'dailyWage': r.dailyWage, 'siteName': r.siteName, 'memo': r.memo, 'weather': r.weather, 'isSchedule': r.isSchedule}).toList();
      final String jsonString = jsonEncode(jsonData);
      final directory = await getTemporaryDirectory();
      File file = File('${directory.path}/maru_backup.json');
      await file.writeAsString(jsonString);
      await Share.shareXFiles([XFile(file.path)], text: 'Maru 앱 데이터 백업 파일입니다.');
    } catch (e) { Get.snackbar('오류', '백업 중 문제가 발생했습니다: $e'); }
  }

  Future<void> _restoreData(WidgetRef ref) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result != null) {
        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();
        List<dynamic> jsonData = jsonDecode(jsonString);
        final box = Hive.box<WorkRecord>('work_records');
        await box.clear();
        for (var item in jsonData) {
          await box.add(WorkRecord(date: DateTime.parse(item['date']), workHours: item['workHours'], dailyWage: item['dailyWage'], siteName: item['siteName'], memo: item['memo'] ?? '', weather: item['weather'], isSchedule: item['isSchedule'] ?? false));
        }
        ref.read(workProvider.notifier).loadRecords();
        Get.snackbar('복원 성공 🎉', '데이터가 복구되었습니다!');
        Get.offAll(() => const MainScreen());
      }
    } catch (e) { Get.snackbar('오류', '복원 중 문제가 발생했습니다.'); }
  }
}