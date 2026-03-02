// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      // [오류 해결] 기본 아이콘 이름을 확인합니다. 보통 안드로이드 기본은 'ic_launcher'입니다.
      // 만약 아래 설정에서도 에러가 난다면 아이콘 생성 명령어를 다시 실행해야 합니다.
      const AndroidInitializationSettings initializationSettingsAndroid = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const InitializationSettings initializationSettings = 
          InitializationSettings(android: initializationSettingsAndroid);
      
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          // 알림 클릭 시 동작
        },
      );
      
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      // 알림 초기화 실패 시 앱이 멈추지 않도록 로그만 찍고 넘깁니다.
      print("알림 초기화 실패 (아이콘 누락 가능성): $e");
    }
  }

  Future<void> scheduleDailyReminder(int hour, int minute) async {
    await flutterLocalNotificationsPlugin.cancelAll(); 

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminder_id', '공수 입력 리마인더',
      channelDescription: '매일 공수 입력을 잊지 않도록 알려줍니다.',
      importance: Importance.max, priority: Priority.high,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0, 'Maru 공수 기록', '오늘 하루도 고생 많으셨습니다! 잊지 말고 공수를 기록해주세요 📝', scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}