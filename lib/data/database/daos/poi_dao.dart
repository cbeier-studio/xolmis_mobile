import 'package:flutter/foundation.dart';

import '../../models/inventory.dart';
import '../database_helper.dart';


class PoiDao {
  final DatabaseHelper _dbHelper;

  PoiDao(this._dbHelper);

  // Insert POI to database
  Future<void> insertPoi(Poi poi) async {
    final db = await _dbHelper.database;
    try {
      await db?.insert('pois', poi.toMap(poi.speciesId));
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting POI: $e');
      }
    }
  }

  // Get list of POIs for a species ID
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

  // Update POI data in the database
  Future<void> updatePoi(Poi poi) async {
    final db = await _dbHelper.database;
    await db?.update(
      'pois',
      poi.toMap(poi.speciesId),
      where: 'id = ?',
      whereArgs: [poi.id],
    );
  }

  // Delete POI from database
  Future<void> deletePoi(int poiId) async {
    final db = await _dbHelper.database;
    await db?.delete('pois', where: 'id = ?', whereArgs: [poiId]);
  }
}