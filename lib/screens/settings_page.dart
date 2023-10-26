import 'package:flutter/material.dart';
import 'package:iot_notify/services/mqtt_service.dart';
import 'package:iot_notify/widgets/foreground_toggle.dart';
import 'package:provider/provider.dart';
import 'package:iot_notify/services/alarm_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _tempUpperController = TextEditingController();
  final TextEditingController _tempLowerController = TextEditingController();
  final TextEditingController _humidUpperController = TextEditingController();
  final TextEditingController _humidLowerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final alarmService = Provider.of<AlarmService>(context, listen: false);
      _tempUpperController.text =
          await alarmService.getTemperatureUpperBoundAsString();
      _tempLowerController.text =
          await alarmService.getTemperatureLowerBoundAsString();
      _humidUpperController.text =
          await alarmService.getHumidityUpperBoundAsString();
      _humidLowerController.text =
          await alarmService.getHumidityLowerBoundAsString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final alarmService = Provider.of<AlarmService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: <Widget>[
          ForegroundServiceToggleButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _tempUpperController,
              decoration: InputDecoration(
                labelText: 'Enter upper bound for temperature',
              ),
            ),
            TextField(
              controller: _tempLowerController,
              decoration: InputDecoration(
                labelText: 'Enter lower bound for temperature',
              ),
            ),
            TextField(
              controller: _humidUpperController,
              decoration: InputDecoration(
                labelText: 'Enter upper bound for humidity',
              ),
            ),
            TextField(
              controller: _humidLowerController,
              decoration: InputDecoration(
                labelText: 'Enter lower bound for humidity',
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await alarmService.setTemperatureBounds(
                  upperBound:
                      double.tryParse(_tempUpperController.text) ?? 30.0,
                  lowerBound:
                      double.tryParse(_tempLowerController.text) ?? 10.0,
                );
                await alarmService.setHumidityBounds(
                  upperBound:
                      double.tryParse(_humidUpperController.text) ?? 70.0,
                  lowerBound:
                      double.tryParse(_humidLowerController.text) ?? 30.0,
                );
                // Retrieve the current instance of MqttService and call updateBounds
                final mqttService =
                    Provider.of<MqttService>(context, listen: false);
                await mqttService.updateBounds();
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
