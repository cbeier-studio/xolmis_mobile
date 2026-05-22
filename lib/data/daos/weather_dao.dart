import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../models/inventory.dart';
import '../database/database_helper.dart';


class WeatherDao {
  final DatabaseHelper _dbHelper;

  WeatherDao(this._dbHelper);

  /// Inserts a new [Weather] record into the database.
  ///
  /// Uses [ConflictAlgorithm.replace] to handle duplicate entries.
  /// Sets [weather.id] with the generated row ID upon success.
  /// Returns the new row ID, or `0` if an error occurs.
  Future<int?> insertWeather(Weather weather) async {
    final db = await _dbHelper.database;
    try {
      int? id = await db?.insert(
        'weather',
        weather.toMap(weather.inventoryId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      weather.id = id;
      return id;
    } catch (e) {
      debugPrint('Error inserting weather data: $e');
      return 0;
    }
  }

  /// Updates the database record for the given [weather] using its [Weather.id].
  Future<void> updateWeather(Weather weather) async {
    final db = await _dbHelper.database;
    await db?.update(
      'weather',
      weather.toMap(weather.inventoryId),
      where: 'id = ?',
      whereArgs: [weather.id],
    );
  }

  /// Deletes the [Weather] record identified by [weatherId] from the database.
  Future<void> deleteWeather(int? weatherId) async {
    final db = await _dbHelper.database;
    await db?.delete(
      'weather',
      where: 'id = ?',
      whereArgs: [weatherId],
    );
  }

  /// Returns all [Weather] records associated with the inventory identified
  /// by [inventoryId].
  Future<List<Weather>> getWeatherByInventory(String inventoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'weather',
      where: 'inventoryId = ?',
      whereArgs: [inventoryId],
    ) ?? [];
    return List.generate(maps.length, (i) {
      return Weather.fromMap(maps[i]);
    });
  }


}