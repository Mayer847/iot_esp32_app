import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AlarmService with ChangeNotifier {
  final player = AudioPlayer();

  Future<double> getTemperatureUpperBound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('temperatureUpperBound') ??
        30.0; // default value is 30.0
  }

  Future<double> getTemperatureLowerBound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('temperatureLowerBound') ??
        10.0; // default value is 10.0
  }

  Future<double> getHumidityUpperBound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('humidityUpperBound') ??
        70.0; // default value is 70.0
  }

  Future<double> getHumidityLowerBound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('humidityLowerBound') ??
        30.0; // default value is 30.0
  }

  Future<String> getTemperatureUpperBoundAsString() async {
    final value = await getTemperatureUpperBound();
    return value.toString();
  }

  Future<String> getTemperatureLowerBoundAsString() async {
    final value = await getTemperatureLowerBound();
    return value.toString();
  }

  Future<String> getHumidityUpperBoundAsString() async {
    final value = await getHumidityUpperBound();
    return value.toString();
  }

  Future<String> getHumidityLowerBoundAsString() async {
    final value = await getHumidityLowerBound();
    return value.toString();
  }

  Future<void> setTemperatureBounds(
      {required double upperBound, required double lowerBound}) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('temperatureUpperBound', upperBound);
    prefs.setDouble('temperatureLowerBound', lowerBound);
    notifyListeners(); // Notify listeners about changes
  }

  Future<void> setHumidityBounds(
      {required double upperBound, required double lowerBound}) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('humidityUpperBound', upperBound);
    prefs.setDouble('humidityLowerBound', lowerBound);
    notifyListeners(); // Notify listeners about changes
  }
}
