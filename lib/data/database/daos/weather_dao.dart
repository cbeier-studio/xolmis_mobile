import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/inventory.dart';
import '../database_helper.dart';


class WeatherDao {
  final DatabaseHelper _dbHelper;

  WeatherDao(this._dbHelper);

  // Insert weather record into database
  Future<int?> insertWeather(Weather weather) async {
    final db = await _dbHelper.database;
    try {
      int? id = await db?.insert(
        'weather',
        weather.toMap(weather.inventoryId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting weather data: $e');
      }
      return 0;
    }
  }

  // Delete weather record from database
  Future<void> deleteWeather(int? weatherId) async {
    final db = await _dbHelper.database;
    await db?.delete(
      'weather',
      where: 'id = ?',
      whereArgs: [weatherId],
    );
  }

  // Get list of weather records for inventory ID
  Future<List<Weather>> getWeatherByInventory(String inventoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'weather',
      where: 'inventoryId = ?',
      whereArgs: [inventoryId],
    ) ?? [];
    // if (kDebugMode) {
    //   print('Vegetation data loaded for inventory $inventoryId: ${maps.length}');
    // }
    return List.generate(maps.length, (i) {
      return Weather.fromMap(maps[i]);
    });
  }


}