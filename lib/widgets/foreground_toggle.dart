import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundServiceToggleButton extends StatefulWidget {
  const ForegroundServiceToggleButton({Key? key}) : super(key: key);

  @override
  _ForegroundServiceToggleButtonState createState() =>
      _ForegroundServiceToggleButtonState();
}

class _ForegroundServiceToggleButtonState
    extends State<ForegroundServiceToggleButton> {
  bool _isServiceRunning = false;

  void _toggleService() {
    if (_isServiceRunning) {
      FlutterForegroundTask.stopService();
    } else {
      FlutterForegroundTask.startService(
        notificationTitle: "App is Running",
        notificationText: "Tap to return to the app",
      );
    }

    setState(() {
      _isServiceRunning = !_isServiceRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _toggleService,
      icon: Icon(
        Icons.sync,
        color: _isServiceRunning ? Colors.red : Colors.grey,
      ),
    );
  }
}
