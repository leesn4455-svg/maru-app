// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/app_models.dart';
import 'providers/app_provider.dart';
import 'screens/intro_screen.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart'; // 🌟 [추가] 로그인 화면 불러오기
import 'services/notification_service.dart';
import 'services/firebase_service.dart'; // [유지] 파이어베이스 서비스
import 'theme/app_theme.dart'; 


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await initializeDateFormatting('ko_KR', null);
    
    // [유지] 기존 파이어베이스 세팅 완벽 보존
    await FirebaseService.initialize();
    
    await Hive.initFlutter();
    
    // [유지] 기존 데이터베이스 어댑터 세팅 완벽 보존
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(WorkRecordAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AppSettingsAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(SiteInfoAdapter());

    try { await Hive.openBox<WorkRecord>('work_records'); } 
    catch (e) { await Hive.deleteBoxFromDisk('work_records'); await Hive.openBox<WorkRecord>('work_records'); }

    try { await Hive.openBox<AppSettings>('app_settings'); } 
    catch (e) { await Hive.deleteBoxFromDisk('app_settings'); await Hive.openBox<AppSettings>('app_settings'); }

    try { await Hive.openBox<SiteInfo>('site_info'); } 
    catch (e) { await Hive.deleteBoxFromDisk('site_info'); await Hive.openBox<SiteInfo>('site_info'); }

    try { await Hive.openBox('preferences'); } 
    catch (e) { await Hive.deleteBoxFromDisk('preferences'); await Hive.openBox('preferences'); }

    // [유지] 알림 서비스 보존
    await NotificationService().init();

    runApp(const ProviderScope(child: MaruApp()));
  } catch (e) {
    debugPrint('초기화 중 에러 발생: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                '앱 초기화 실패 😭\n\n원인: $e\n\n이 화면을 캡처해서 개발자에게 알려주세요!',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      )
    );
  }
}

class MaruApp extends ConsumerWidget {
  const MaruApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(appSettingsProvider);
    
    // 🌟 [추가] 로그인 여부 확인 로직
    final box = Hive.box('preferences');
    bool isLoggedIn = box.get('is_logged_in', defaultValue: false);

    // 🌟 [추가] 시작 화면 결정 로직
    Widget initialScreen;
    if (!isLoggedIn) {
      initialScreen = const LoginScreen(); // 1. 로그인 안 했으면 무조건 로그인 화면!
    } else if (appSettings.userName == null || appSettings.userName!.isEmpty) {
      initialScreen = const IntroScreen(); // 2. 로그인 했지만 프로필 없으면 인트로 화면!
    } else {
      initialScreen = const MainScreen();  // 3. 다 되어있으면 메인 화면!
    }

    return GetMaterialApp(
      title: 'Maru',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko', 'KR')],
      
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appSettings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      
      // 🌟 [수정] 위에서 결정한 시작 화면(initialScreen)을 띄워줍니다.
      home: initialScreen,
    );
  }
}