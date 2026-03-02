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
import 'services/notification_service.dart';
import 'services/firebase_service.dart'; // [추가] 파이어베이스 서비스
import 'theme/app_theme.dart'; 


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await initializeDateFormatting('ko_KR', null);
    
    // [수정 완료] 이제 파이어베이스 관리는 전용 서비스 파일에서 알아서 합니다!
    await FirebaseService.initialize();
    
    await Hive.initFlutter();
    
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
      
      home: (appSettings.userName == null || appSettings.userName!.isEmpty)
          ? const IntroScreen()
          : const MainScreen(),
    );
  }
}