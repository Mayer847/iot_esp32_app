import 'package:flutter/material.dart';
import 'package:iot_notify/screens/home_page.dart';
import 'package:iot_notify/screens/settings_page.dart';
import 'package:iot_notify/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:iot_notify/services/mqtt_service.dart';
import 'package:iot_notify/services/alarm_service.dart';
import 'package:iot_notify/services/notification_service.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.init(
    foregroundTaskOptions: ForegroundTaskOptions(
      autoRunOnBoot: true,
    ),
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: "iot_Notify", // your_channel_id
      channelName: "iot_Notify", // Your Channel Name
      channelDescription:
          "Channel for IoT Notify notifications", // Your Channel Description
    ),
    iosNotificationOptions: IOSNotificationOptions(),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MqttService()),
        ChangeNotifierProvider<AlarmService>(
          create: (_) => AlarmService(),
          child: MyApp(),
        ),
        Provider(create: (_) => NotificationService()),
        Provider.value(value: DatabaseService.instance),
      ],
      child: MaterialApp(
        title: 'IoT Notify',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomePage(),
        routes: {
          '/settings': (context) =>
              SettingsPage(), // Add a route for the new SettingsPage
        },
      ),
    );
  }
}
