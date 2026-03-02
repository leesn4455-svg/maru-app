// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _selectedImagePath;
  DateTime? _selectedBirthDate;
  DateTime? _selectedJoinDate;
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final appSettings = ref.read(appSettingsProvider);
    nameCtrl.text = appSettings.userName ?? '';
    phoneCtrl.text = appSettings.phoneNumber ?? '';
    _selectedBirthDate = appSettings.birthDate; 
    _selectedJoinDate = appSettings.joinDate;
  }

  Widget _buildLabel(String text) { return Padding(padding: const EdgeInsets.only(bottom: 8.0, left: 4.0), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))); }

  // [UX 개선] 스마트 휠 스크롤 적용 완료
  void _showScrollDatePicker(DateTime? initialDate, Function(DateTime) onDateSelected) {
    DateTime selected = initialDate ?? DateTime.now();
    onDateSelected(selected); 

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: const Text('선택 완료', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5A55F5))), onPressed: () => Get.back())
                ],
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selected,
                  maximumDate: DateTime.now().add(const Duration(days: 365)),
                  onDateTimeChanged: (val) { onDateSelected(val); },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(appSettingsProvider);
    final displayImagePath = _selectedImagePath ?? appSettings.profileImagePath;

    return Scaffold(
      appBar: AppBar(title: const Text('내 정보 수정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () async { final img = await ImagePicker().pickImage(source: ImageSource.gallery); if (img != null) setState(() => _selectedImagePath = img.path); },
                    child: CircleAvatar(radius: 65, backgroundColor: Colors.grey[300], backgroundImage: displayImagePath != null ? FileImage(File(displayImagePath)) : null, child: displayImagePath == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null),
                  ),
                  Positioned(
                    bottom: -5, right: -5,
                    child: GestureDetector(
                      onTap: () async { final img = await ImagePicker().pickImage(source: ImageSource.gallery); if (img != null) setState(() => _selectedImagePath = img.path); },
                      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF5A55F5), shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3)), child: const Icon(Icons.camera_alt, size: 20, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            _buildLabel('이름'), TextField(controller: nameCtrl, decoration: InputDecoration(hintText: '이름을 입력하세요', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 20),
            _buildLabel('생년월일'), OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), alignment: Alignment.centerLeft, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _showScrollDatePicker(_selectedBirthDate, (d) => setState(() => _selectedBirthDate = d)), child: Text(_selectedBirthDate == null ? '선택해주세요' : DateFormat('yyyy년 MM월 dd일').format(_selectedBirthDate!), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16))), const SizedBox(height: 20),
            _buildLabel('연락처'), TextField(controller: phoneCtrl, decoration: InputDecoration(hintText: '- 없이 숫자만 입력', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))), const SizedBox(height: 20),
            _buildLabel('입사일'), OutlinedButton(style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12), alignment: Alignment.centerLeft, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => _showScrollDatePicker(_selectedJoinDate, (d) => setState(() => _selectedJoinDate = d)), child: Text(_selectedJoinDate == null ? '선택해주세요' : DateFormat('yyyy년 MM월 dd일').format(_selectedJoinDate!), style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 16))), const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A55F5), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () {
                ref.read(appSettingsProvider.notifier).saveProfile(
                  userName: nameCtrl.text, birthDate: _selectedBirthDate,
                  phoneNumber: phoneCtrl.text, joinDate: _selectedJoinDate, profileImagePath: displayImagePath,
                );
                Get.back(); Get.snackbar('알림', '프로필이 성공적으로 저장되었습니다.');
              },
              child: const Text('저장하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}