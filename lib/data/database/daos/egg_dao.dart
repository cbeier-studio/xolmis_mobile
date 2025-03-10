import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/nest.dart';
import '../database_helper.dart';


class EggDao {
  final DatabaseHelper _dbHelper;

  EggDao(this._dbHelper);

  // Insert egg data into database
  Future<void> insertEgg(Egg egg) async {
    final db = await _dbHelper.database;
    int? id = await db?.insert(
      'eggs',
      egg.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (id == null) {
      if (kDebugMode) {
        print('Failed to insert egg: ID is null');
      }
      return;
    }
    egg.id = id;
  }

  // Get list of eggs for a nest ID
  Future<List<Egg>> getEggsForNest(int nestId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'eggs',
      where: 'nestId = ?',
      whereArgs: [nestId],
    ) ?? [];
    return List.generate(maps.length, (i) {
      return Egg.fromMap(maps[i]);
    });
  }

  // Get list of all eggs for a species
  Future<List<Egg>> getEggsBySpecies(String speciesName) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'eggs',
      where: 'speciesName = ?',
      whereArgs: [speciesName],
    ) ?? [];
    return List.generate(maps.length, (i) {
      return Egg.fromMap(maps[i]);
    });
  }

  // Update vegetation record in the database
  Future<void> updateEgg(Egg egg) async {
    final db = await _dbHelper.database;
    await db?.update(
      'eggs',
      egg.toMap(),
      where: 'id = ?',
      whereArgs: [egg.id],
    );
  }

  // Delete egg from database
  Future<void> deleteEgg(int eggId) async {
    final db = await _dbHelper.database;
    await db?.delete('eggs', where: 'id = ?', whereArgs: [eggId]);
  }

  // Check if an egg field number already exists
  Future<bool> eggFieldNumberExists(String fieldNumber) async {
    final db = await _dbHelper.database;
    final result = await db?.query(
      'eggs',
      where: 'LOWER(fieldNumber) = ?',
      whereArgs: [fieldNumber.toLowerCase()],
    );
    return result!.isNotEmpty;
  }

  // Concatenate the next egg field number
  Future<int> getNextSequentialNumber(String? nestFieldNumber) async {
    final db = await _dbHelper.database;

    final prefix = nestFieldNumber;

    final results = await db?.query(
      'eggs',
      where: 'fieldNumber LIKE ?',
      whereArgs: ["$prefix%"],
      orderBy: 'fieldNumber DESC',
      limit: 1,
    );

    if (results!.isNotEmpty) {
      final lastEggId = results.first['fieldNumber'] as String;
      final sequentialNumberString = lastEggId.replaceFirst(prefix ?? '', '');
      final sequentialNumber = int.tryParse(sequentialNumberString) ?? 0;
      return sequentialNumber + 1;
    } else {
      return 1;
    }
  }
}