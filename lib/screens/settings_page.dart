import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iot_esp32_app/services/mqtt_service.dart';
import 'package:iot_esp32_app/widgets/foreground_toggle.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:provider/provider.dart';
import 'package:iot_esp32_app/services/alarm_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _tempUpperController = TextEditingController();
  final TextEditingController _tempLowerController = TextEditingController();
  final TextEditingController _humidUpperController = TextEditingController();
  final TextEditingController _humidLowerController = TextEditingController();

  // ValueNotifiers for the check mark
  final tempUpperStatus = ValueNotifier<bool?>(null);
  final tempLowerStatus = ValueNotifier<bool?>(null);
  final humidUpperStatus = ValueNotifier<bool?>(null);
  final humidLowerStatus = ValueNotifier<bool?>(null);

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
    // final mqttService = Provider.of<MqttService>(context, listen: false);

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
            thresholdField(_tempUpperController,
                'Enter upper bound for temperature', tempUpperStatus, () async {
              double tempUpper =
                  double.tryParse(_tempUpperController.text) ?? 30.0;
              double tempLower =
                  double.tryParse(_tempLowerController.text) ?? 10.0;
              await alarmService.setTemperatureBounds(
                  upperBound: tempUpper, lowerBound: tempLower);
              final mqttService =
                  Provider.of<MqttService>(context, listen: false);
              mqttService.publishThreshold(1, tempUpper);
              await mqttService.updateBounds();
            }, "temp_upper"),
            thresholdField(_tempLowerController,
                'Enter lower bound for temperature', tempLowerStatus, () async {
              double tempUpper =
                  double.tryParse(_tempUpperController.text) ?? 30.0;
              double tempLower =
                  double.tryParse(_tempLowerController.text) ?? 10.0;
              await alarmService.setTemperatureBounds(
                  upperBound: tempUpper, lowerBound: tempLower);
              final mqttService =
                  Provider.of<MqttService>(context, listen: false);
              mqttService.publishThreshold(2, tempLower);
              await mqttService.updateBounds();
            }, "temp_lower"),
            thresholdField(_humidUpperController,
                'Enter upper bound for humidity', humidUpperStatus, () async {
              double humidUpper =
                  double.tryParse(_humidUpperController.text) ?? 70.0;
              double humidLower =
                  double.tryParse(_humidLowerController.text) ?? 20.0;

              await alarmService.setHumidityBounds(
                upperBound: humidUpper,
                lowerBound: humidLower,
              );
              final mqttService =
                  Provider.of<MqttService>(context, listen: false);
              mqttService.publishThreshold(3, humidUpper);
              await mqttService.updateBounds();
            }, "humid_upper"),
            thresholdField(_humidLowerController,
                'Enter lower bound for humidity', humidLowerStatus, () async {
              double humidUpper =
                  double.tryParse(_humidUpperController.text) ?? 70.0;
              double humidLower =
                  double.tryParse(_humidLowerController.text) ?? 20.0;

              await alarmService.setHumidityBounds(
                upperBound: humidUpper,
                lowerBound: humidLower,
              );

              final mqttService =
                  Provider.of<MqttService>(context, listen: false);
              mqttService.publishThreshold(4, humidLower);
              await mqttService.updateBounds();
            }, "humid_lower"),
          ],
        ),
      ),
    );
  }

  Widget thresholdField(TextEditingController controller, String label,
      ValueNotifier<bool?> status, Function onSave, String valueName) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
            ),
          ),
        ),
        ValueListenableBuilder<bool?>(
          valueListenable: status,
          builder: (context, value, child) {
            if (value == null) return Container(); // No icon if value is null
            return Icon(value ? Icons.check : Icons.close,
                color: value ? Colors.green : Colors.red);
          },
        ),
        ElevatedButton(
          onPressed: () async {
            onSave();
            final mqttService =
                Provider.of<MqttService>(context, listen: false);
            mqttService.subscribe("confirmation");
            status.value =
                null; // reset the status while waiting for confirmation
            bool isUnsubscribed = false; // add this flag

            Timer(Duration(seconds: 3), () async {
              // make the callback async
              try {
                if (!mounted) return; // Check if the widget is still mounted
                if (status.value == null) {
                  // if status is still null after 3 seconds, set it to false
                  status.value = false;
                }
                if (!isUnsubscribed &&
                    mqttService.client.connectionStatus!.state ==
                        MqttConnectionState.connected) {
                  // only unsubscribe if not already done and client is connected
                  mqttService.unsubscribe("confirmation");
                  isUnsubscribed = true;
                }
                // Reconnect to the MQTT client
                await mqttService.connect(
                    "test.mosquitto.org"); // replace "your_broker" with your actual broker
              } catch (e) {
                print('Exception in timer callback: $e');
              }
            });

            StreamSubscription? subscription;
            subscription = mqttService.updates.listen((message) {
              try {
                if (!mounted) return; // Check if the widget is still mounted
                if (message == "$valueName changed!") {
                  status.value = true;
                  subscription
                      ?.cancel(); // cancel the subscription after receiving the message
                  if (!isUnsubscribed &&
                      mqttService.client.connectionStatus!.state ==
                          MqttConnectionState.connected) {
                    // only unsubscribe if not already done and client is connected
                    mqttService.unsubscribe("confirmation");
                    isUnsubscribed = true;
                  }
                }
              } catch (e) {
                print('Exception in updates listener: $e');
              }
            });
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}
