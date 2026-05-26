import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../models/inventory.dart';
import '../database/database_helper.dart';


/// Provides database access for points of interest linked to species records.
class PoiDao {
  final DatabaseHelper _dbHelper;

  PoiDao(this._dbHelper);

  /// Inserts a new [Poi] record into the database.
  ///
  /// Sets [poi.id] with the generated row ID upon success.
  /// Returns the new row ID, or `0` if an error occurs.
  Future<int?> insertPoi(Poi poi) async {
    final db = await _dbHelper.database;
    try {
      int? id = await db?.insert('pois', poi.toMap(poi.speciesId));
      poi.id = id;
      return id;
    } catch (e) {
      debugPrint('Error inserting POI: $e');
      return 0;
    }
  }

  /// Returns all [Poi] records associated with the given [speciesId].
  Future<List<Poi>> getPoisForSpecies(int speciesId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'pois',
      where: 'speciesId = ?',
      whereArgs: [speciesId],
    ) ?? [];
    return List.generate(maps.length, (i) {
      return Poi.fromMap(maps[i]);
    });
  }

  /// Updates the database record for the given [poi] using its [Poi.id].
  Future<void> updatePoi(Poi poi) async {
    final db = await _dbHelper.database;
    await db?.update(
      'pois',
      poi.toMap(poi.speciesId),
      where: 'id = ?',
      whereArgs: [poi.id],
    );
  }

  /// Deletes the [Poi] record identified by [poiId] from the database.
  Future<void> deletePoi(int poiId) async {
    final db = await _dbHelper.database;
    await db?.delete('pois', where: 'id = ?', whereArgs: [poiId]);
  }

  /// Returns the total number of [Poi] records stored in the database.
  Future<int> countAllPois() async {
    final db = await _dbHelper.database;
    final result = await db?.rawQuery('SELECT COUNT(*) FROM pois');
    return Sqflite.firstIntValue(result!) ?? 0;
  }
}