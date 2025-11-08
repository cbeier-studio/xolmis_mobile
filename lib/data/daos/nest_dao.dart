import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/nest.dart';
import '../database/database_helper.dart';
import 'nest_revision_dao.dart';
import 'egg_dao.dart';


class NestDao {
  final DatabaseHelper _dbHelper;
  final NestRevisionDao _nestRevisionDao;
  final EggDao _eggDao;

  NestDao(this._dbHelper, this._nestRevisionDao, this._eggDao);

  // Insert nest into database
  Future<int?> insertNest(Nest nest) async {
    final db = await _dbHelper.database;
    try {
      int? id = await db?.insert(
        'nests',
        nest.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      nest.id = id;
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting nest: $e');
      }
      return 0;
    }
  }

  // Import nest into database, ignoring id if present
  Future<bool> importNest(Nest nest) async {
    final db = await _dbHelper.database;
    try {
      // Create a map from the nest, but explicitly set id to null
      // to allow autoincrement to assign a new ID.
      Map<String, dynamic> nestMap = nest.toMap();
      nestMap['id'] = null; // Ensure ID is null for autoincrement

      int? newNestId = await db?.insert(
        'nests',
        nestMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (newNestId != null) {
        // Update the original nest object's ID with the new ID from the database
        nest.id = newNestId;

        // Now, import related revisions and eggs, associating them with the new nest ID
        if (nest.revisionsList != null && nest.revisionsList!.isNotEmpty) {
          for (var revision in nest.revisionsList!) {
            revision.nestId = newNestId;
            await _nestRevisionDao.insertNestRevision(revision);
          }
        }
        if (nest.eggsList != null && nest.eggsList!.isNotEmpty) {
          for (var egg in nest.eggsList!) {
            egg.nestId = newNestId;
            await _eggDao.insertEgg(egg);
          }
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error importing nest: $e');
      }
      return false;
    }
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
        // Nest nest = Nest(
        //   id: map['id']?.toInt(),
        //   fieldNumber: map['fieldNumber'],
        //   speciesName: map['speciesName'],
        //   localityName: map['localityName'],
        //   longitude: map['longitude']?.toDouble(),
        //   latitude: map['latitude']?.toDouble(),
        //   support: map['support'],
        //   heightAboveGround: map['heightAboveGround']?.toDouble(),
        //   foundTime: map['foundTime'] != null ? DateTime.parse(map['foundTime']) : null,
        //   lastTime: map['lastTime'] != null ? DateTime.parse(map['lastTime']) : null,
        //   nestFate: NestFateType.values[map['nestFate']],
        //   male: map['male'],
        //   female: map['female'],
        //   helpers: map['helpers'],
        //   isActive: map['isActive'] == 1,
        //   revisionsList: revisionsList,
        //   eggsList: eggsList,
        // );
        Nest nest = Nest.fromMap(map, revisionsList, eggsList);

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

  // Get list of all nests of a species
  Future<List<Nest>> getNestsBySpecies(String speciesName) async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db?.query(
      'nests',
      where: 'speciesName = ?',
      whereArgs: [speciesName],
    ) ?? [];

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

    return nests;
  }

  // Find and get a nest by ID
  Future<Nest> getNestById(int nestId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
        'nests',
        where: 'id = ?',
        whereArgs: [nestId]
    ) ?? [];
    if (maps.isNotEmpty) {
      final map = maps.first;
      List<NestRevision> revisionsList = await _nestRevisionDao.getNestRevisionsForNest(map['id']);
      List<Egg> eggsList = await _eggDao.getEggsForNest(map['id']);
      return Nest.fromMap(map, revisionsList, eggsList);
    } else {
      throw Exception('Nest not found with ID $nestId');
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

    final results = await db?.query(
      'nests',
      where: 'fieldNumber LIKE ?',
      whereArgs: ["$prefix%"],
      orderBy: 'fieldNumber DESC',
      limit: 1,
    );

    if (results!.isNotEmpty) {
      final lastNestId = results.first['fieldNumber'] as String;
      final sequentialNumberString = lastNestId.replaceFirst(prefix, '');
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
        'nests',
        distinct: true,
        columns: ['localityName'],
        where: 'localityName IS NOT NULL', // Ensure we only retrieve non-null locality names
      );

      final localities = results.map((row) => row['localityName'] as String).toList();
      
      debugPrint('Distinct localities from nests: $localities');
      return localities;
    } catch (e, s) {
      debugPrint('Error fetching nests distinct localities: $e\n$s');
      return [];
    }
  }

  // Get list of distinct nest supports for autocomplete
  Future<List<String>> getDistinctSupports() async {
    try {
      final db = await _dbHelper.database;

      if (db == null) {
        throw Exception('Database is not available');
      }

      final List<Map<String, Object?>> results = await db.query(
        'nests',
        distinct: true,
        columns: ['support'],
        where: 'support IS NOT NULL', // Ensure we only retrieve non-null supports
      );

      final supports = results.map((row) => row['support'] as String).toList();

      debugPrint('Distinct supports from nests: $supports');
      return supports;
    } catch (e, s) {
      debugPrint('Error fetching nests distinct supports: $e\n$s');
      return [];
    }
  }
}