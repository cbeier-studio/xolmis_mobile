import 'package:flutter/material.dart';

import '../data/models/inventory.dart';
import '../data/daos/weather_dao.dart';

/// Manages weather samples grouped by inventory identifier.
class WeatherProvider with ChangeNotifier {
  final WeatherDao _weatherDao;

  WeatherProvider(this._weatherDao);

  final Map<String, List<Weather>> _weatherMap = {};

  /// Notifies listeners without changing provider state.
  void refreshState() {
    notifyListeners();
  }

  /// Loads all weather samples associated with [inventoryId].
  Future<void> loadWeatherForInventory(String inventoryId) async {
    try {
      final weatherList = await _weatherDao.getWeatherByInventory(inventoryId);
      _weatherMap[inventoryId] = weatherList;
    } catch (e) {
      debugPrint('Error loading weather for inventory $inventoryId: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Returns the cached weather samples for [inventoryId].
  List<Weather> getWeatherForInventory(String inventoryId) {
    return _weatherMap[inventoryId] ?? [];
  }

  /// Persists [weather] for [inventoryId] and refreshes the local cache.
  Future<void> addWeather(BuildContext context, String inventoryId, Weather weather) async {
    // Insert the weather data in the database
    await _weatherDao.insertWeather(weather);

    // Add the weather data to the list of the provider
    _weatherMap[inventoryId] = await _weatherDao.getWeatherByInventory(inventoryId);

    notifyListeners();
  }

  /// Updates a weather sample in storage and refreshes the corresponding cache.
  Future<void> updateWeather(Weather weather) async {
    await _weatherDao.updateWeather(weather);

    _weatherMap[weather.inventoryId] = await _weatherDao.getWeatherByInventory(weather.inventoryId);

    notifyListeners();
  }

  /// Deletes a weather sample from storage and removes it from the cache.
  Future<void> removeWeather(String inventoryId, int weatherId) async {
    await _weatherDao.deleteWeather(weatherId);

    final weatherList = _weatherMap[inventoryId];
    if (weatherList != null) {
      weatherList.removeWhere((v) => v.id == weatherId);
    }
    notifyListeners();
  }
}