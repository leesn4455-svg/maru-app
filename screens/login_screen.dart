// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'signup_screen.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  
  bool isLoading = false;
  bool _isObscure = true; // 🌟 로그인 창에도 눈알 기능 추가

  void _login() async {
    if (_idCtrl.text.isEmpty || _pwCtrl.text.isEmpty) {
      Get.snackbar('알림', '아이디와 비밀번호를 입력해주세요.'); return;
    }
    setState(() => isLoading = true);
    
    final result = await ApiService.login(_idCtrl.text, _pwCtrl.text);
    
    setState(() => isLoading = false);

    if (result['status'] == 'success') {
      final box = Hive.box('preferences');
      box.put('is_logged_in', true);
      box.put('user_login_id', result['user']['login_id']);
      box.put('user_name', result['user']['name']);
      box.put('user_position', result['user']['position']);
      box.put('user_role', result['user']['role']);

      Get.offAll(() => const MainScreen()); 
    } else {
      Get.snackbar('로그인 실패', result['message'], backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.apartment, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 20),
              const Text('마루이음', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              const SizedBox(height: 50),
              TextField(controller: _idCtrl, decoration: InputDecoration(labelText: '아이디', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 15),
              
              // 🌟 비밀번호 표시 (눈알 아이콘) 기능 추가
              TextField(
                controller: _pwCtrl, 
                obscureText: _isObscure, 
                decoration: InputDecoration(
                  labelText: '비밀번호', 
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  )
                )
              ),
              
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: isLoading ? null : _login,
                child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('로그인', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => Get.to(() => const SignupScreen()),
                child: const Text('아직 계정이 없으신가요? 회원가입', style: TextStyle(color: Colors.grey)),
              )
            ],
          ),
        ),
      ),
    );
  }
}