import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/specimen.dart';
import '../database_helper.dart';


class SpecimenDao {
  final DatabaseHelper _dbHelper;

  SpecimenDao(this._dbHelper);

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
      // Trate a exceção específica do banco de dados
      if (kDebugMode) {
        print('Database error: $e');
      }
      // Lance uma exceção personalizada ou retorne um valor indicando falha
      throw DatabaseInsertException('Failed to insert specimen: ${e.toString()}');
    } catch (e) {
      // Trate outras exceções
      if (kDebugMode) {
        print('Generic error: $e');
      }
      throw Exception('Failed to insert specimen: ${e.toString()}');
    }
  }

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

  Future<List<Specimen>> getSpecimensByType(SpecimenType type) async {
    final db = await _dbHelper.database;
    final maps = await db?.query('specimens',
        where: 'type = ?', whereArgs: [type.index]) ?? [];
    return List.generate(maps.length, (i) {
      return Specimen.fromMap(maps[i]);
    });
  }

  Future<int?> updateSpecimen(Specimen specimen) async {
    final db = await _dbHelper.database;
    return await db?.update(
      'specimens',
      specimen.toMap(),
    );
  }

  Future<void> deleteSpecimen(int specimenId) async {
    final db = await _dbHelper.database;
    await db?.delete('specimens', where: 'id = ?', whereArgs: [specimenId]);
  }

  Future<bool> specimenFieldNumberExists(String fieldNumber) async {
    final db = await _dbHelper.database;
    final result = await db?.query(
      'specimens',
      where: 'LOWER(fieldNumber) = ?',
      whereArgs: [fieldNumber.toLowerCase()],
    );
    return result!.isNotEmpty;
  }

  Future<List<String>> getDistinctLocalities() async {
    final db = await _dbHelper.database;

    final results = await db?.rawQuery('SELECT DISTINCT locality FROM specimens');

    if (results!.isNotEmpty) {
      return results.map((row) => row['locality'] as String).toList();
    } else {
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