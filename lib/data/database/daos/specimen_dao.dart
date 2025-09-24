import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/specimen.dart';
import '../database_helper.dart';


class SpecimenDao {
  final DatabaseHelper _dbHelper;

  SpecimenDao(this._dbHelper);

  // Insert specimen into database
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
      if (kDebugMode) {
        print('Database error: $e');
      }
      throw DatabaseInsertException('Failed to insert specimen: ${e.toString()}');
    } catch (e) {
      // Handle other exceptions
      if (kDebugMode) {
        print('Generic error: $e');
      }
      throw Exception('Failed to insert specimen: ${e.toString()}');
    }
  }

  // Import specimen into database, ignoring id if present
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
      if (kDebugMode) {
        print('Error importing specimen: $e');
      }
      return false;
    }
  }

  // Get list of all specimens
  Future<List<Specimen>> getSpecimens() async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db?.query('specimens') ?? [];
      return List.generate(maps.length, (i) {
        return Specimen.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading specimens: $e');
      }
      // Handle the error, e.g.: return an empty list or rethrow exception
      return []; // Or rethrow;
    }
  }

  // Get list of specimens by type
  Future<List<Specimen>> getSpecimensByType(SpecimenType type) async {
    final db = await _dbHelper.database;
    final maps = await db?.query('specimens',
        where: 'type = ?', whereArgs: [type.index]) ?? [];
    return List.generate(maps.length, (i) {
      return Specimen.fromMap(maps[i]);
    });
  }

  // Get list of specimens by species
  Future<List<Specimen>> getSpecimensBySpecies(String speciesName) async {
    final db = await _dbHelper.database;
    final maps = await db?.query('specimens',
        where: 'speciesName = ?', whereArgs: [speciesName]) ?? [];
    return List.generate(maps.length, (i) {
      return Specimen.fromMap(maps[i]);
    });
  }

  // Find and get a specimen by ID
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

  // Update specimen data in the database
  Future<int?> updateSpecimen(Specimen specimen) async {
    final db = await _dbHelper.database;
    return await db?.update(
      'specimens',
      specimen.toMap(),
      where: 'id = ?',
      whereArgs: [specimen.id],
    );
  }

  // Delete specimen from database
  Future<void> deleteSpecimen(int specimenId) async {
    final db = await _dbHelper.database;
    await db?.delete('specimens', where: 'id = ?', whereArgs: [specimenId]);
  }

  // Check if a specimen field number already exists
  Future<bool> specimenFieldNumberExists(String fieldNumber) async {
    final db = await _dbHelper.database;
    final result = await db?.query(
      'specimens',
      where: 'LOWER(fieldNumber) = ?',
      whereArgs: [fieldNumber.toLowerCase()],
    );
    return result!.isNotEmpty;
  }

  // Get the next field number for new specimen
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

  // Get list of distinct localities for autocomplete
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
      
      debugPrint('Distinct localities from specimens: $localities');
      return localities;
    } catch (e, s) {
      debugPrint('Error fetching specimens distinct localities: $e\n$s');
      return [];
    }
  }
}

class DatabaseInsertException implements Exception {
  final String message;

  DatabaseInsertException(this.message);

  @override
  String toString() => 'DatabaseInsertException: $message';
}