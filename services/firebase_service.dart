// lib/services/firebase_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

class FirebaseService {
  // 파이어베이스 초기화 (앱 켤 때 한 번만 실행)
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('🔥 Firebase 연결 성공!');
    } catch (e) {
      debugPrint('🔥 Firebase 연결 실패: $e');
      rethrow;
    }
  }

  // TODO: 나중에 여기에 회사 로그인/로그아웃, 권한 체크 로직이 추가될 예정입니다!
}