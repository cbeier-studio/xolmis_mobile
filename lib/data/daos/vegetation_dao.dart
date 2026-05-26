import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../models/inventory.dart';
import '../database/database_helper.dart';


/// Provides database access for vegetation samples linked to inventories.
class VegetationDao {
  final DatabaseHelper _dbHelper;

  VegetationDao(this._dbHelper);

  /// Inserts a new [Vegetation] record into the database.
  ///
  /// Uses [ConflictAlgorithm.replace] to handle duplicate entries.
  /// Sets [vegetation.id] with the generated row ID upon success.
  /// Returns the new row ID, or `0` if an error occurs.
  Future<int?> insertVegetation(Vegetation vegetation) async {
    final db = await _dbHelper.database;
    try {
      int? id = await db?.insert(
        'vegetation',
        vegetation.toMap(vegetation.inventoryId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      vegetation.id = id;
      return id;
    } catch (e) {
      debugPrint('Error inserting vegetation data: $e');
      return 0;
    }
  }

  /// Updates the database record for the given [vegetation] using its [Vegetation.id].
  Future<void> updateVegetation(Vegetation vegetation) async {
    final db = await _dbHelper.database;
    await db?.update(
      'vegetation',
      vegetation.toMap(vegetation.inventoryId),
      where: 'id = ?',
      whereArgs: [vegetation.id],
    );
  }

  /// Deletes the [Vegetation] record identified by [vegetationId] from the database.
  Future<void> deleteVegetation(int? vegetationId) async {
    final db = await _dbHelper.database;
    await db?.delete(
      'vegetation',
      where: 'id = ?',
      whereArgs: [vegetationId],
    );
  }

  /// Returns all [Vegetation] records associated with the inventory identified
  /// by [inventoryId].
  Future<List<Vegetation>> getVegetationByInventory(String inventoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'vegetation',
      where: 'inventoryId = ?',
      whereArgs: [inventoryId],
    ) ?? [];
    return List.generate(maps.length, (i) {
      return Vegetation.fromMap(maps[i]);
    });
  }


}