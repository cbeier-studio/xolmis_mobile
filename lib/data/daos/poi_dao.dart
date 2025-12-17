import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/inventory.dart';
import '../database/database_helper.dart';


class PoiDao {
  final DatabaseHelper _dbHelper;

  PoiDao(this._dbHelper);

  // Insert POI to database
  Future<int?> insertPoi(Poi poi) async {
    final db = await _dbHelper.database;
    try {
      int? id = await db?.insert('pois', poi.toMap(poi.speciesId));
      poi.id = id;
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting POI: $e');
      }
      return 0;
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

  Future<int> countAllPois() async {
    final db = await _dbHelper.database;
    // `Sqflite.firstIntValue` é uma forma eficiente de obter um único valor numérico, como uma contagem.
    // Ele executa 'SELECT COUNT(*) FROM pois' e retorna o resultado.
    final result = await db?.rawQuery('SELECT COUNT(*) FROM pois');
    return Sqflite.firstIntValue(result!) ?? 0;
  }
}