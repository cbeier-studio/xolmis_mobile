import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/core_consts.dart';
import '../models/specimen.dart';
import '../database/database_helper.dart';


/// Provides database access for specimen records.
class SpecimenDao {
  final DatabaseHelper _dbHelper;

  SpecimenDao(this._dbHelper);

  /// Inserts a new [Specimen] record into the database.
  ///
  /// Uses [ConflictAlgorithm.replace] to handle duplicate entries.
  /// Sets [specimen.id] with the generated row ID upon success.
  /// Throws a [DatabaseInsertException] if the generated ID is `null` or if a
  /// database error occurs, and a generic [Exception] for any other error.
  Future<int> insertSpecimen(Specimen specimen) async {
    final db = await _dbHelper.database;
    try {
      int? id = await db?.insert('specimens', specimen.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      if (id == null) {
        throw DatabaseInsertException('Failed to insert specimen: ID is null');
      }
      specimen.id = id;
      return id;
    } on DatabaseException catch (e) {
      // Handle database exceptions
      debugPrint('Database error: $e');
      throw DatabaseInsertException('Failed to insert specimen: ${e.toString()}');
    } catch (e) {
      // Handle other exceptions
      debugPrint('Generic error: $e');
      throw Exception('Failed to insert specimen: ${e.toString()}');
    }
  }

  /// Imports a [Specimen] into the database, ignoring any pre-existing ID so
  /// that the database assigns a new auto-incremented ID.
  ///
  /// Sets [specimen.id] with the newly generated ID upon success.
  /// Returns `true` on success, or `false` if an error occurs.
  Future<bool> importSpecimen(Specimen specimen) async {
    final db = await _dbHelper.database;
    try {
      // Create a map from the specimen, but explicitly set id to null
      // to allow autoincrement to assign a new ID.
      Map<String, dynamic> specimenMap = specimen.toMap();
      specimenMap['id'] = null; // Ensure ID is null for autoincrement

      int? newSpecimenId = await db?.insert(
        'specimens',
        specimenMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (newSpecimenId != null) {
        // Update the original specimen object's ID with the new ID from the database
        specimen.id = newSpecimenId;
      }
      return true;
    } catch (e) {
      debugPrint('Error importing specimen: $e');
      return false;
    }
  }

  /// Returns all [Specimen] records stored in the database.
  ///
  /// Returns an empty list if an error occurs.
  Future<List<Specimen>> getSpecimens() async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db?.query('specimens') ?? [];
      return List.generate(maps.length, (i) {
        return Specimen.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error loading specimens: $e');
      // Handle the error, e.g.: return an empty list or rethrow exception
      return []; // Or rethrow;
    }
  }

  /// Returns all [Specimen] records whose type matches the given [type].
  Future<List<Specimen>> getSpecimensByType(SpecimenType type) async {
    final db = await _dbHelper.database;
    final maps = await db?.query('specimens',
        where: 'type = ?', whereArgs: [type.index]) ?? [];
    return List.generate(maps.length, (i) {
      return Specimen.fromMap(maps[i]);
    });
  }

  /// Returns all [Specimen] records whose `speciesName` matches [speciesName].
  Future<List<Specimen>> getSpecimensBySpecies(String speciesName) async {
    final db = await _dbHelper.database;
    final maps = await db?.query('specimens',
        where: 'speciesName = ?', whereArgs: [speciesName]) ?? [];
    return List.generate(maps.length, (i) {
      return Specimen.fromMap(maps[i]);
    });
  }

  /// Returns the [Specimen] identified by [specimenId].
  ///
  /// Throws an [Exception] if no specimen with the given ID is found.
  Future<Specimen> getSpecimenById(int specimenId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
        'specimens',
        where: 'id = ?',
        whereArgs: [specimenId]
    ) ?? [];
    if (maps.isNotEmpty) {
      final map = maps.first;
      return Specimen.fromMap(map);
    } else {
      throw Exception('Nest not found with ID $specimenId');
    }
  }

  /// Updates the database record for the given [specimen] using its [Specimen.id].
  ///
  /// Returns the number of rows affected.
  Future<int?> updateSpecimen(Specimen specimen) async {
    final db = await _dbHelper.database;
    return await db?.update(
      'specimens',
      specimen.toMap(),
      where: 'id = ?',
      whereArgs: [specimen.id],
    );
  }

  /// Deletes the [Specimen] record identified by [specimenId] from the database.
  Future<void> deleteSpecimen(int specimenId) async {
    final db = await _dbHelper.database;
    await db?.delete('specimens', where: 'id = ?', whereArgs: [specimenId]);
  }

  /// Returns `true` if a specimen with the given [fieldNumber] already exists
  /// in the database (case-insensitive comparison).
  Future<bool> specimenFieldNumberExists(String fieldNumber) async {
    final db = await _dbHelper.database;
    final result = await db?.query(
      'specimens',
      where: 'LOWER(fieldNumber) = ?',
      whereArgs: [fieldNumber.toLowerCase()],
    );
    return result!.isNotEmpty;
  }

  /// Returns the next available sequential number for a specimen field number,
  /// based on the given observer [acronym], [ano] (year), and [mes] (month).
  ///
  /// The field number prefix is built as `<acronym><year><month padded to 2 digits>`.
  /// If no existing specimen matches the prefix, returns `1`.
  Future<int> getNextSequentialNumber(String acronym, int ano, int mes) async {
    final db = await _dbHelper.database;

    final prefix = "$acronym$ano${mes.toString().padLeft(2, '0')}";

    final results = await db?.query(
      'specimens',
      where: 'fieldNumber LIKE ?',
      whereArgs: ["$prefix%"],
      orderBy: 'fieldNumber DESC',
      limit: 1,
    );

    if (results!.isNotEmpty) {
      final lastSpecimenId = results.first['fieldNumber'] as String;
      final sequentialNumberString = lastSpecimenId.replaceFirst(prefix, '');
      final sequentialNumber = int.tryParse(sequentialNumberString) ?? 0;
      return sequentialNumber + 1;
    } else {
      return 1;
    }
  }

  /// Returns a sorted list of distinct locality names recorded across all
  /// specimens, excluding `null` values.
  ///
  /// Returns an empty list if the database is unavailable or an error occurs.
  Future<List<String>> getDistinctLocalities() async {
    try {
      final db = await _dbHelper.database;

      if (db == null) {
        throw Exception('Database is not available');
      }

      final List<Map<String, Object?>> results = await db.query(
        'specimens',
        distinct: true,
        columns: ['locality'],
        where: 'locality IS NOT NULL', // Ensure we only retrieve non-null locality names
      );

      final localities = results.map((row) => row['locality'] as String).toList();
      localities.sort();
      
      debugPrint('Distinct localities from specimens: $localities');
      return localities;
    } catch (e, s) {
      debugPrint('Error fetching specimens distinct localities: $e\n$s');
      return [];
    }
  }
}
