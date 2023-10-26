import 'package:flutter/foundation.dart';
import 'package:iot_esp32_app/services/alarm_service.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'database_service.dart';
import 'notification_service.dart';

class MqttService with ChangeNotifier {
  late MqttServerClient client;
  double temperature = 0.0;
  double humidity = 0.0;
  ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  final alarmService = AlarmService();
  final notificationService = NotificationService();
  final databaseService =
      DatabaseService.instance; // Get the singleton instance of DatabaseService

  ValueNotifier<double>? temperatureUpperBound;
  ValueNotifier<double>? temperatureLowerBound;
  ValueNotifier<double>? humidityUpperBound;
  ValueNotifier<double>? humidityLowerBound;

  MqttService() {
    initializeBounds();
  }

  Future<void> initializeBounds() async {
    temperatureUpperBound =
        ValueNotifier<double>(await alarmService.getTemperatureUpperBound());
    temperatureLowerBound =
        ValueNotifier<double>(await alarmService.getTemperatureLowerBound());
    humidityUpperBound =
        ValueNotifier<double>(await alarmService.getHumidityUpperBound());
    humidityLowerBound =
        ValueNotifier<double>(await alarmService.getHumidityLowerBound());
    notifyListeners();
  }

  Future<void> connect(String broker) async {
    print('Attempting to connect to $broker');
    client = MqttServerClient.withPort(broker, "mqtt_test", 1883);
    client.keepAlivePeriod = 5;

    client.onConnected = () {
      print('Connected');
      isConnected.value = true;
      subscribeToNewTopics();
    };

    client.onDisconnected = () {
      print('Disconnected');
      isConnected.value = false;
    };

    try {
      await client.connect();
    } catch (e, stackTrace) {
      print('Exception: $e');
      print('Stack trace: $stackTrace');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT client connected');
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>?>? c) {
        final MqttPublishMessage recMess = c?[0]?.payload as MqttPublishMessage;
        final payload = recMess.payload.message;
        final String pt = MqttPublishPayload.bytesToStringAsString(payload);

        print('Received message:$pt from topic: ${c?[0]?.topic ?? ''}>');

        if (c?[0]?.topic == 'temp_esp32_791') {
          temperature = double.tryParse(pt) ?? 0.0;
          databaseService.insertData(
              temperature, humidity); // Insert data into the database
          if (temperatureUpperBound != null && temperatureLowerBound != null) {
            if (temperature > temperatureUpperBound!.value ||
                temperature < temperatureLowerBound!.value) {
              // Check the limits before sending a notification
              notificationService.sendNotification(
                  title: 'Temperature Alert',
                  body: 'Temperature is now $temperature°C');
            }
          }
          notifyListeners();
        } else if (c?[0]?.topic == 'humid_esp32_791') {
          humidity = double.tryParse(pt) ?? 0.0;
          databaseService.insertData(
              temperature, humidity); // Insert data into the database
          if (humidityUpperBound != null && humidityLowerBound != null) {
            if (humidity > humidityUpperBound!.value ||
                humidity < humidityLowerBound!.value) {
              // Check the limits before sending a notification
              notificationService.sendNotification(
                  title: 'Humidity Alert', body: 'Humidity is now $humidity%');
            }
          }
          notifyListeners();
        }
      });
    } else {
      print('ERROR: MQTT client connection failed - '
          'disconnecting, state is ${client.connectionStatus!.state}');
      client.disconnect();
    }
  }

  void subscribe(String topic) {
    const qos = MqttQos.atLeastOnce;
    client.subscribe(topic, qos);
  }

  void subscribeToNewTopics() {
    String temperatureTopic = "temp_esp32_791";
    String humidityTopic = "humid_esp32_791";

    subscribe(temperatureTopic);
    subscribe(humidityTopic);
  }

  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    print('Publishing message $message to topic $topic');
    client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  Future<void> updateBounds() async {
    temperatureUpperBound?.value =
        await alarmService.getTemperatureUpperBound();
    temperatureLowerBound?.value =
        await alarmService.getTemperatureLowerBound();
    humidityUpperBound?.value = await alarmService.getHumidityUpperBound();
    humidityLowerBound?.value = await alarmService.getHumidityLowerBound();
  }
}
