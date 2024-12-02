import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/inventory.dart';
import '../database_helper.dart';


class VegetationDao {
  final DatabaseHelper _dbHelper;

  VegetationDao(this._dbHelper);

  // Insert vegetation record in the database
  Future<int?> insertVegetation(Vegetation vegetation) async {
    final db = await _dbHelper.database;
    try {
      int? id = await db?.insert(
        'vegetation',
        vegetation.toMap(vegetation.inventoryId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting vegetation data: $e');
      }
      return 0;
    }
  }

  // Delete vegetation record from database
  Future<void> deleteVegetation(int? vegetationId) async {
    final db = await _dbHelper.database;
    await db?.delete(
      'vegetation',
      where: 'id = ?',
      whereArgs: [vegetationId],
    );
  }

  // Get list of vegetation record for inventory ID
  Future<List<Vegetation>> getVegetationByInventory(String inventoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'vegetation',
      where: 'inventoryId = ?',
      whereArgs: [inventoryId],
    ) ?? [];
    // if (kDebugMode) {
    //   print('Vegetation data loaded for inventory $inventoryId: ${maps.length}');
    // }
    return List.generate(maps.length, (i) {
      return Vegetation.fromMap(maps[i]);
    });
  }


}