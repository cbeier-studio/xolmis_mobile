import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/inventory.dart';
import '../data/database/repositories/weather_repository.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherRepository _weatherRepository;

  WeatherProvider(this._weatherRepository);

  final Map<String, List<Weather>> _weatherMap = {};

  // Load weather records for an inventory ID
  Future<void> loadWeatherForInventory(String inventoryId) async {
    try {
      final weatherList = await _weatherRepository.getWeatherByInventory(inventoryId);
      _weatherMap[inventoryId] = weatherList;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading weather for inventory $inventoryId: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  // Get weather records for an inventory ID from list
  List<Weather> getWeatherForInventory(String inventoryId) {
    return _weatherMap[inventoryId] ?? [];
  }

  // Add weather record to the database and the list
  Future<void> addWeather(BuildContext context, String inventoryId, Weather weather) async {
    // Insert the weather data in the database
    await _weatherRepository.insertWeather(weather);

    // Add the weather data to the list of the provider
    _weatherMap[inventoryId] = await _weatherRepository.getWeatherByInventory(inventoryId);
    // _weatherMap[inventoryId] = _weatherMap[inventoryId] ?? [];
    // _weatherMap[inventoryId]!.add(weather);

    notifyListeners();
  }

  // Remove weather record from database and from list
  Future<void> removeWeather(String inventoryId, int weatherId) async {
    await _weatherRepository.deleteWeather(weatherId);

    final weatherList = _weatherMap[inventoryId];
    if (weatherList != null) {
      weatherList.removeWhere((v) => v.id == weatherId);
    }
    notifyListeners();
  }
}