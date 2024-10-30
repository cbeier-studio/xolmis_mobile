import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/inventory.dart';
import '../data/database/repositories/weather_repository.dart';

class WeatherProvider with ChangeNotifier {
  final WeatherRepository _weatherRepository;

  WeatherProvider(this._weatherRepository);

  final Map<String, List<Weather>> _weatherMap = {};
  GlobalKey<AnimatedListState>? weatherListKey;

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

  List<Weather> getWeatherForInventory(String inventoryId) {
    return _weatherMap[inventoryId] ?? [];
  }

  Future<void> addWeather(BuildContext context, String inventoryId, Weather weather) async {
    // Insert the weather data in the database
    await _weatherRepository.insertWeather(weather);

    // Add the POI to the list of the provider
    _weatherMap[inventoryId] = _weatherMap[inventoryId] ?? [];
    _weatherMap[inventoryId]!.add(weather);

    weatherListKey?.currentState?.insertItem(
        getWeatherForInventory(inventoryId).length - 1);
    notifyListeners();

    // (context as Element).markNeedsBuild(); // Force screen to update
  }

  Future<void> removeWeather(String inventoryId, int weatherId) async {
    await _weatherRepository.deleteWeather(weatherId);

    final weatherList = _weatherMap[inventoryId];
    if (weatherList != null) {
      // listKey.currentState?.removeItem(index, (context, animation) => Container());
      weatherList.removeWhere((v) => v.id == weatherId);
    }
    notifyListeners();
  }
}