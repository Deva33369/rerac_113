// ignore_for_file: prefer_const_constructors

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // make the class a singleton
  static final NotificationService _notificationService =
      NotificationService._internal();
  // define a factory constructor to return the instance of the singleton class
  factory NotificationService() {
    return _notificationService;
  }

  // initialize FlutterLocalNotificationsPlugin object
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  NotificationService._internal();

  Future<void> initNotification() async {
    final AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_stat_account_box');
    // define Darwin initialization settings for iOS with permission requests for alerts, badges, and sounds set to false
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    // define InitializationSettings with Android and iOS initialization settings
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // initialize FlutterLocalNotificationsPlugin with initializationSettings
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(
      int id, String title, String body, int seconds) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds)),
      const NotificationDetails(
        android: AndroidNotificationDetails('main_channel', 'main channel',
            importance: Importance.max,
            priority: Priority.max,
            icon: '@drawable/ic_stat_account_box'),
        iOS: DarwinNotificationDetails(
          // sound: 'default.wav',
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }
}
