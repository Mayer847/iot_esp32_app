import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final notifications = FlutterLocalNotificationsPlugin();

  NotificationService() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // Specify your app icon here
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    notifications.initialize(initializationSettings);
  }

  Future<void> sendNotification(
      {required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('iot_Notify', 'iot_Notify',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false,
            sound: RawResourceAndroidNotificationSound(
                'alarm')); // Specify your custom sound file here
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await notifications.show(0, title, body, platformChannelSpecifics);
  }
}
