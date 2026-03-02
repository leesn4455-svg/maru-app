// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // 앱의 메인 브랜드 컬러 (이것만 바꿔도 전체 테마가 바뀝니다!)
  static const Color primaryColor = Color(0xFF5A55F5);
  static const Color primaryRed = Color(0xFFFE3939);
  
  static const Color backgroundLight = Color(0xFFF5F6F8);
  static const Color backgroundDark = Color(0xFF121212);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Pretendard',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed, 
        primary: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight, 
        foregroundColor: Colors.black, 
        elevation: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Pretendard',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryRed, 
        primary: primaryColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}