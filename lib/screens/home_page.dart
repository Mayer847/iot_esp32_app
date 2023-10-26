import 'package:flutter/material.dart';
import 'package:iot_esp32_app/screens/database_page.dart';
import 'package:iot_esp32_app/screens/settings_page.dart';
import 'package:iot_esp32_app/widgets/realtime_chart.dart';
import 'package:provider/provider.dart';
import 'package:iot_esp32_app/services/mqtt_service.dart';
import 'dart:collection';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller =
      TextEditingController(text: 'test.mosquitto.org');
  final Queue<double> temperatureData = Queue();
  final Queue<double> humidityData = Queue();
  final int maxDataPoints = 20;

  @override
  Widget build(BuildContext context) {
    final mqttService = Provider.of<MqttService>(context);

    temperatureData.add(mqttService.temperature);
    humidityData.add(mqttService.humidity);

    // Remove oldest data points when maxDataPoints is reached
    if (temperatureData.length > maxDataPoints) {
      temperatureData.removeFirst();
    }
    if (humidityData.length > maxDataPoints) {
      humidityData.removeFirst();
    }

    int temperatureStartIndex = temperatureData.length -
        (mqttService.isConnected.value
            ? maxDataPoints
            : temperatureData.length);
    if (temperatureStartIndex < 0) {
      temperatureStartIndex = 0;
    }

    int humidityStartIndex = humidityData.length -
        (mqttService.isConnected.value ? maxDataPoints : humidityData.length);
    if (humidityStartIndex < 0) {
      humidityStartIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Notify'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.history), // Change this to your preferred icon
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => DatabasePage()));
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SettingsPage()));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Added SingleChildScrollView
          child: Column(
            children: <Widget>[
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Enter MQTT broker address',
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  mqttService.connect(_controller.text);
                  setState(() {});
                },
                child: Text('Connect'),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Temperature: ${mqttService.temperature}°C',
                style:
                    (Theme.of(context).textTheme.headlineMedium ?? TextStyle())
                        .copyWith(color: Colors.brown),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Humidity: ${mqttService.humidity}%',
                style:
                    (Theme.of(context).textTheme.headlineMedium ?? TextStyle())
                        .copyWith(color: Colors.lightGreen),
              ),
              const SizedBox(height: 16.0),
              Text(
                'Connection Status: ${mqttService.isConnected.value ? "Connected" : "Disconnected"}',
                style:
                    (Theme.of(context).textTheme.headlineMedium ?? TextStyle())
                        .copyWith(
                  color:
                      mqttService.isConnected.value ? Colors.green : Colors.red,
                ),
              ),
              RealtimeChart(
                data: temperatureData.toList().sublist(temperatureStartIndex),
              ),
              RealtimeChart(
                data: humidityData.toList().sublist(humidityStartIndex),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
