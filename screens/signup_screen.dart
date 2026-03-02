// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  bool isLoading = false;
  bool _isObscure = true; // 🌟 비밀번호 숨김/표시 상태를 관리하는 변수

  void _register() async {
    if (_idCtrl.text.isEmpty || _pwCtrl.text.isEmpty || _nameCtrl.text.isEmpty) {
      Get.snackbar('알림', '필수 항목을 모두 입력해주세요.'); return;
    }
    setState(() => isLoading = true);
    
    final result = await ApiService.register(_idCtrl.text, _pwCtrl.text, _nameCtrl.text, _phoneCtrl.text);
    
    setState(() => isLoading = false);

    if (result['status'] == 'success') {
      Get.back(); // 로그인 화면으로 돌아가기
      Get.snackbar('가입 완료', '성공적으로 가입되었습니다. 로그인해주세요!', backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('가입 실패', result['message'], backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('팀원 등록을 위해\n정보를 입력해주세요.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4)),
              const SizedBox(height: 40),
              TextField(controller: _idCtrl, decoration: InputDecoration(labelText: '사용할 아이디 (필수)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 15),
              
              // 🌟 비밀번호 표시 (눈알 아이콘) 기능 추가
              TextField(
                controller: _pwCtrl, 
                obscureText: _isObscure, // 변수에 따라 글씨를 가리거나 보여줌
                decoration: InputDecoration(
                  labelText: '비밀번호 (필수)', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure; // 버튼 누를 때마다 상태 반전
                      });
                    },
                  )
                )
              ),
              
              const SizedBox(height: 15),
              TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: '이름 (필수)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 15),
              TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: '연락처 (- 없이 입력)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: isLoading ? null : _register,
                child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('가입 완료하기', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}