// lib/screens/intro_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _box = Hive.box('preferences');
  
  File? _profileImage;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _companyCodeCtrl = TextEditingController();
  
  // 🌟 권한 시스템을 위한 직급 변수 (기본값: 팀원)
  String _selectedRole = '팀원';
  final List<String> _roles = ['팀원', '팀장', '대표'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    String? imgPath = _box.get('profile_image');
    if (imgPath != null && File(imgPath).existsSync()) {
      _profileImage = File(imgPath);
    }
    _nameCtrl.text = _box.get('user_name', defaultValue: '');
    _phoneCtrl.text = _box.get('user_phone', defaultValue: '');
    _companyCodeCtrl.text = _box.get('company_code', defaultValue: '');
    
    // 저장된 직급 불러오기
    String savedRole = _box.get('user_role', defaultValue: '팀원');
    if (_roles.contains(savedRole)) {
      _selectedRole = savedRole;
    }
    setState(() {});
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  void _saveProfile() {
    if (_nameCtrl.text.trim().isEmpty) {
      Get.snackbar('알림', '이름을 입력해주세요.');
      return;
    }

    _box.put('user_name', _nameCtrl.text.trim());
    _box.put('user_phone', _phoneCtrl.text.trim());
    _box.put('company_code', _companyCodeCtrl.text.trim());
    _box.put('user_role', _selectedRole); // 🌟 직급 저장
    
    if (_profileImage != null) {
      _box.put('profile_image', _profileImage!.path);
    }

    Get.snackbar('저장 완료', '내 정보가 성공적으로 수정되었습니다.', backgroundColor: Colors.green, colorText: Colors.white);
    Future.delayed(const Duration(seconds: 1), () => Get.back());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('내 정보 수정', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 프로필 사진 영역
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 2. 입력 폼 영역
              const Text('이름', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(controller: _nameCtrl, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), hintText: '실명을 입력하세요')),
              const SizedBox(height: 20),

              const Text('연락처', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), hintText: '010-0000-0000')),
              const SizedBox(height: 20),

              const Text('회사 코드', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextField(controller: _companyCodeCtrl, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), hintText: '소속된 회사의 코드를 입력하세요')),
              const SizedBox(height: 20),

              // 🌟 3. 직급(권한) 선택 폼 추가
              const Text('직급 (권한 설정)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: _roles.map((String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role, style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) setState(() => _selectedRole = newValue);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 4. 저장 버튼
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _saveProfile,
                child: const Text('정보 저장하기', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      ),
    );
  }
}