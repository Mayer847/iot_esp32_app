import 'package:flutter/foundation.dart';
import 'package:iot_esp32_app/services/alarm_service.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'database_service.dart';
import 'notification_service.dart';
import 'dart:async';

class MqttService with ChangeNotifier {
  late MqttServerClient client;
  double temperature = 0.0;
  double humidity = 0.0;
  ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  StreamController<String>? _updatesController;

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

  Stream<String> get updates {
    _updatesController ??= StreamController<String>.broadcast();
    return _updatesController!.stream;
  }

  void unsubscribe(String topic) {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      try {
        client.unsubscribe(topic);
      } catch (e) {
        print('Error unsubscribing from $topic: $e');
      }
    } else {
      print(
          'Cannot unsubscribe from topic because MQTT client is not connected');
    }
  }

  Future<void> connect(String broker) async {
    print('Attempting to connect to $broker');
    client = MqttServerClient.withPort(broker, "mqtt_test", 1883);
    client.keepAlivePeriod = 5 * 30; //keep the connection alive for 5 minutes

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

        _updatesController?.add(pt); // add the message to the updates stream

        print('Received message:$pt from topic: ${c?[0]?.topic ?? ''}>');

        if (c?[0]?.topic == 'sensor_data_791') {
          var data = pt.split(',');
          var tempData = data[0].split('=')[1];
          var humidData = data[1].split('=')[1];

          temperature = double.tryParse(tempData) ?? 0.0;
          humidity = double.tryParse(humidData) ?? 0.0;

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
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      const qos = MqttQos.atLeastOnce;
      client.subscribe(topic, qos);
    } else {
      print('Cannot subscribe to topic because MQTT client is not connected');
    }
  }

  void subscribeToNewTopics() {
    String sensorDataTopic = "sensor_data_791";
    subscribe(sensorDataTopic);
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

  void publishThreshold(int thresholdType, double value) {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString('$thresholdType:$value');
      print('Publishing message $thresholdType:$value to topic set_threshold');
      client.publishMessage(
          'set_threshold', MqttQos.exactlyOnce, builder.payload!);
    } else {
      print('Cannot publish message because MQTT client is not connected');
    }
  }

  @override
  void dispose() {
    _updatesController?.close();
    super.dispose();
  }
}
