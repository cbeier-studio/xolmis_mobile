import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/nest.dart';
import '../database_helper.dart';
import '../daos/nest_revision_dao.dart';
import '../daos/egg_dao.dart';


class NestDao {
  final DatabaseHelper _dbHelper;
  final NestRevisionDao _nestRevisionDao;
  final EggDao _eggDao;

  NestDao(this._dbHelper, this._nestRevisionDao, this._eggDao);

  // Insert nest into database
  Future<void> insertNest(Nest nest) async {
    final db = await _dbHelper.database;
    int? id = await db?.insert(
      'nests',
      nest.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (id == null) {
      if (kDebugMode) {
        print('Failed to insert nest: ID is null');
      }
      return;
    }
    nest.id = id;
  }

  // Get list of all nests
  Future<List<Nest>> getNests() async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db?.query('nests') ?? [];

      List<Nest> nests = await Future.wait(maps.map((map) async {
        List<NestRevision> revisionsList = await _nestRevisionDao.getNestRevisionsForNest(map['id']);
        List<Egg> eggsList = await _eggDao.getEggsForNest(map['id']);
        // Create Nest instance using the main constructor
        Nest nest = Nest(
          id: map['id']?.toInt(),
          fieldNumber: map['fieldNumber'],
          speciesName: map['speciesName'],
          localityName: map['localityName'],
          longitude: map['longitude']?.toDouble(),
          latitude: map['latitude']?.toDouble(),
          support: map['support'],
          heightAboveGround: map['heightAboveGround']?.toDouble(),
          foundTime: map['foundTime'] != null ? DateTime.parse(map['foundTime']) : null,
          lastTime: map['lastTime'] != null ? DateTime.parse(map['lastTime']) : null,
          nestFate: NestFateType.values[map['nestFate']],
          male: map['male'],
          female: map['female'],
          helpers: map['helpers'],
          isActive: map['isActive'] == 1,
          revisionsList: revisionsList,
          eggsList: eggsList,
        );

        return nest;
      }).toList());

      if (kDebugMode) {
        print('Loaded nests: ${nests.length}');
      }
      return nests;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading nests: $e');
      }
      // Handle the error, e.g.: return an empty list or rethrow exception
      return []; // Or rethrow;
    }
  }

  // Update nest data in the database
  Future<int?> updateNest(Nest nest) async {
    final db = await _dbHelper.database;
    return await db?.update(
      'nests',
      nest.toMap(),
      where: 'id = ?',
      whereArgs: [nest.id],
    );
  }

  // Delete nest from database
  Future<void> deleteNest(int nestId) async {
    final db = await _dbHelper.database;
    await db?.delete('nests', where: 'id = ?', whereArgs: [nestId]);
  }

  // Check if the nest field number already exists
  Future<bool> nestFieldNumberExists(String fieldNumber) async {
    final db = await _dbHelper.database;
    final result = await db?.query(
      'nests',
      where: 'LOWER(fieldNumber) = ?',
      whereArgs: [fieldNumber.toLowerCase()],
    );
    return result!.isNotEmpty;
  }

  // Get the next field number for new nest
  Future<int> getNextSequentialNumber(String acronym, int ano, int mes) async {
    final db = await _dbHelper.database;

    final prefix = "$acronym$ano${mes.toString().padLeft(2, '0')}";

    final resultants = await db?.query(
      'nests',
      where: 'fieldNumber LIKE ?',
      whereArgs: ["$prefix%"],
    );

    return resultants!.isNotEmpty ? resultants.length + 1 : 1;
  }

  // Get list of distinct localities for autocomplete
  Future<List<String>> getDistinctLocalities() async {
    final db = await _dbHelper.database;

    final results = await db?.rawQuery('SELECT DISTINCT localityName FROM nests');

    if (results!.isNotEmpty) {
      return results.map((row) => row['localityName'] as String).toList();
    } else {
      return [];
    }
  }

  // Get list of distinct nest supports for autocomplete
  Future<List<String>> getDistinctSupports() async {
    final db = await _dbHelper.database;

    final results = await db?.rawQuery('SELECT DISTINCT support FROM nests');

    if (results!.isNotEmpty) {
      return results.map((row) => row['support'] as String).toList();
    } else {
      return [];
    }
  }
}