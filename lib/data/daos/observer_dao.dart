import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/observer.dart';

/// Provides database access for individual observer records.
class ObserverDao {
  final DatabaseHelper _dbHelper;

  ObserverDao(this._dbHelper);

  /// Inserts a new [Observer] record into the database.
  Future<void> insertObserver(Observer observer) async {
    final db = await _dbHelper.database;
    await db?.insert(
      'observers',
      observer.toMap(),
    );
  }

  /// Updates an existing [Observer] record.
  Future<void> updateObserver(Observer observer) async {
    final db = await _dbHelper.database;
    await db?.update(
      'observers',
      observer.toMap(),
      where: 'observerAbbrev = ?',
      whereArgs: [observer.observerAbbrev],
    );
  }

  /// Deletes an [Observer] record.
  Future<void> deleteObserver(String observerAbbrev) async {
    final db = await _dbHelper.database;
    await db?.delete(
      'observers',
      where: 'observerAbbrev = ?',
      whereArgs: [observerAbbrev],
    );
  }

  /// Returns all [Observer] records from the database.
  Future<List<Observer>> getAllObservers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query('observers') ?? [];
    return maps.map((map) => Observer.fromMap(map)).toList();
  }

  /// Returns an [Observer] by its abbreviation.
  Future<Observer?> getObserverByAbbrev(String abbrev) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'observers',
      where: 'observerAbbrev = ?',
      whereArgs: [abbrev],
    ) ?? [];
    if (maps.isNotEmpty) {
      return Observer.fromMap(maps.first);
    }
    return null;
  }

  /// Returns observers for a specific inventory.
  Future<List<Observer>> getObserversByInventory(String inventoryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.rawQuery('''
      SELECT o.* FROM observers o
      INNER JOIN inventoryObservers io ON o.observerAbbrev = io.observerAbbrev
      WHERE io.inventoryId = ?
    ''', [inventoryId]) ?? [];
    return maps.map((map) => Observer.fromMap(map)).toList();
  }

  /// Returns observers for a specific species record.
  Future<List<Observer>> getObserversBySpecies(int speciesId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.rawQuery('''
      SELECT o.* FROM observers o
      INNER JOIN speciesObservers so ON o.observerAbbrev = so.observerAbbrev
      WHERE so.speciesId = ?
    ''', [speciesId]) ?? [];
    return maps.map((map) => Observer.fromMap(map)).toList();
  }
}
