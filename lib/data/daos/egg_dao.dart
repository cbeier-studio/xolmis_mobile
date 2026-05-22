import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../models/nest.dart';
import '../database/database_helper.dart';


class EggDao {
  final DatabaseHelper _dbHelper;

  EggDao(this._dbHelper);

  /// Inserts a new [Egg] record into the database.
  ///
  /// Uses [ConflictAlgorithm.replace] to handle duplicate entries.
  /// Sets [egg.id] with the generated row ID upon success.
  /// Logs a debug message and returns early if the generated ID is `null`.
  Future<void> insertEgg(Egg egg) async {
    final db = await _dbHelper.database;
    int? id = await db?.insert(
      'eggs',
      egg.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (id == null) {
      debugPrint('Failed to insert egg: ID is null');
      return;
    }
    egg.id = id;
  }

  /// Returns all [Egg] records stored in the database.
  Future<List<Egg>> getAllEggs() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'eggs',
    ) ?? [];
    return List.generate(maps.length, (i) {
      return Egg.fromMap(maps[i]);
    });
  }

  /// Returns all [Egg] records associated with the given [nestId].
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

  /// Returns all [Egg] records whose `speciesName` matches [speciesName].
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

  /// Updates the database record for the given [egg] using its [Egg.id].
  Future<void> updateEgg(Egg egg) async {
    final db = await _dbHelper.database;
    await db?.update(
      'eggs',
      egg.toMap(),
      where: 'id = ?',
      whereArgs: [egg.id],
    );
  }

  /// Deletes the [Egg] record identified by [eggId] from the database.
  Future<void> deleteEgg(int eggId) async {
    final db = await _dbHelper.database;
    await db?.delete('eggs', where: 'id = ?', whereArgs: [eggId]);
  }

  /// Returns `true` if an egg with the given [fieldNumber] already exists in
  /// the database (case-insensitive comparison).
  Future<bool> eggFieldNumberExists(String fieldNumber) async {
    final db = await _dbHelper.database;
    final result = await db?.query(
      'eggs',
      where: 'LOWER(fieldNumber) = ?',
      whereArgs: [fieldNumber.toLowerCase()],
    );
    return result!.isNotEmpty;
  }

  /// Returns the next available sequential number for an egg field number,
  /// based on the parent nest's [nestFieldNumber] as prefix.
  ///
  /// Queries existing eggs whose `fieldNumber` starts with [nestFieldNumber],
  /// extracts the trailing numeric suffix of the last match, and returns that
  /// number incremented by one. Returns `1` if no matching record is found.
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