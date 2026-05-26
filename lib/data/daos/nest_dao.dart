import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/core_consts.dart';
import '../models/nest.dart';
import '../database/database_helper.dart';
import 'nest_revision_dao.dart';
import 'egg_dao.dart';


/// Provides persistence helpers for nests and their related child records.
class NestDao {
  final DatabaseHelper _dbHelper;
  final NestRevisionDao _nestRevisionDao;
  final EggDao _eggDao;

  NestDao(this._dbHelper, this._nestRevisionDao, this._eggDao);

  /// Inserts a new [Nest] record into the database.
  ///
  /// Uses [ConflictAlgorithm.replace] to handle duplicate entries.
  /// Sets [nest.id] with the generated row ID upon success.
  /// Returns the new row ID, or `0` if an error occurs.
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
      debugPrint('Error inserting nest: $e');
      return 0;
    }
  }

  /// Imports a [Nest] into the database, ignoring any pre-existing ID so that
  /// the database assigns a new auto-incremented ID.
  ///
  /// After inserting the nest, also inserts all associated [NestRevision] and
  /// [Egg] records, linking them to the newly generated nest ID.
  /// Returns `true` on success, or `false` if an error occurs.
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
      debugPrint('Error importing nest: $e');
      return false;
    }
  }

  /// Returns all [Nest] records from the database, each populated with its
  /// associated [NestRevision] and [Egg] lists.
  Future<List<Nest>> getNests() async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db?.query('nests') ?? [];

      List<Nest> nests = await Future.wait(maps.map((map) async {
        List<NestRevision> revisionsList = await _nestRevisionDao.getNestRevisionsForNest(map['id']);
        List<Egg> eggsList = await _eggDao.getEggsForNest(map['id']);

        Nest nest = Nest.fromMap(map, revisionsList, eggsList);

        return nest;
      }).toList());

      debugPrint('Loaded nests: ${nests.length}');
      return nests;
    } catch (e) {
      debugPrint('Error loading nests: $e');
      // Handle the error, e.g.: return an empty list or rethrow exception
      return []; // Or rethrow;
    }
  }

  /// Returns a paginated list of [Nest] records, ordered by `foundTime` descending.
  ///
  /// [offset] is the number of records to skip, and [limit] is the maximum
  /// number of records to return. Each nest is populated with its associated
  /// [NestRevision] and [Egg] lists.
  Future<List<Nest>> getNestsPaged(int offset, int limit) async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db?.query(
        'nests',
        offset: offset,
        limit: limit,
        orderBy: 'foundTime DESC',
      ) ?? [];

      List<Nest> nests = await Future.wait(maps.map((map) async {
        List<NestRevision> revisionsList = await _nestRevisionDao.getNestRevisionsForNest(map['id']);
        List<Egg> eggsList = await _eggDao.getEggsForNest(map['id']);
        Nest nest = Nest.fromMap(map, revisionsList, eggsList);
        return nest;
      }).toList());

      debugPrint('Loaded ${nests.length} nests (offset: $offset, limit: $limit)');
      return nests;
    } catch (e) {
      debugPrint('Error loading paginated nests: $e');
      return [];
    }
  }

  /// Returns the total number of [Nest] records stored in the database.
  Future<int> getNestsCount() async {
    final db = await _dbHelper.database;
    try {
      final result = await db?.rawQuery('SELECT COUNT(*) as count FROM nests') ?? [];
      if (result.isNotEmpty) {
        return (result.first['count'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error counting nests: $e');
      return 0;
    }
  }

  /// Returns all [Nest] records whose `speciesName` matches [speciesName],
  /// each populated with its associated [NestRevision] and [Egg] lists.
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

  /// Returns the [Nest] identified by [nestId], populated with its associated
  /// [NestRevision] and [Egg] lists.
  ///
  /// Throws an [Exception] if no nest with the given ID is found.
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

  /// Updates the database record for the given [nest] using its [Nest.id].
  ///
  /// Returns the number of rows affected.
  Future<int?> updateNest(Nest nest) async {
    final db = await _dbHelper.database;
    return await db?.update(
      'nests',
      nest.toMap(),
      where: 'id = ?',
      whereArgs: [nest.id],
    );
  }

  /// Deletes the [Nest] record identified by [nestId] from the database.
  Future<void> deleteNest(int nestId) async {
    final db = await _dbHelper.database;
    await db?.delete('nests', where: 'id = ?', whereArgs: [nestId]);
  }

  /// Returns `true` if a nest with the given [fieldNumber] already exists
  /// in the database (case-insensitive comparison).
  Future<bool> nestFieldNumberExists(String fieldNumber) async {
    final db = await _dbHelper.database;
    final result = await db?.query(
      'nests',
      where: 'LOWER(fieldNumber) = ?',
      whereArgs: [fieldNumber.toLowerCase()],
    );
    return result!.isNotEmpty;
  }

  /// Returns the next available sequential number for a nest field number,
  /// based on the given observer [abbreviation], [ano] (year), and [mes] (month).
  ///
  /// The field number prefix is built as `<acronym><year><month padded to 2 digits>`.
  /// If no existing nest matches the prefix, returns `1`.
  Future<int> getNextSequentialNumber(String abbreviation, int ano, int mes) async {
    final db = await _dbHelper.database;

    final prefix = "$abbreviation$ano${mes.toString().padLeft(2, '0')}";

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

  /// Returns a sorted list of distinct locality names recorded across all nests.
  ///
  /// Excludes `null` values. Returns an empty list if the database is
  /// unavailable or an error occurs.
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
      localities.sort();
      
      debugPrint('Distinct localities from nests: $localities');
      return localities;
    } catch (e, s) {
      debugPrint('Error fetching nests distinct localities: $e\n$s');
      return [];
    }
  }

  /// Returns a sorted list of distinct nest support descriptions recorded
  /// across all nests.
  ///
  /// Excludes `null` values. Returns an empty list if the database is
  /// unavailable or an error occurs.
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
      supports.sort();

      debugPrint('Distinct supports from nests: $supports');
      return supports;
    } catch (e, s) {
      debugPrint('Error fetching nests distinct supports: $e\n$s');
      return [];
    }
  }

  /// Returns a summary list of all [Nest] records, including aggregate counts
  /// for revisions (`revisionCount`) and eggs (`eggCount`), but without
  /// loading the full [NestRevision] and [Egg] sub-lists.
  ///
  /// Results are ordered by `foundTime` descending.
  Future<List<Nest>> getNestsSummary() async {
    final db = await _dbHelper.database;
    try {
      final result = await db?.rawQuery('''
         SELECT 
           n.*,
           COUNT(DISTINCT nr.id) as revisionCount,
           COUNT(DISTINCT e.id) as eggCount
         FROM nests n
         LEFT JOIN nest_revisions nr ON nr.nestId = n.id
         LEFT JOIN eggs e ON e.nestId = n.id
         GROUP BY n.id
         ORDER BY n.foundTime DESC
       ''');

      if (result == null) return [];

      return result.map((map) {
        return Nest(
          id: (map['id'] as int?),
          fieldNumber: map['fieldNumber'] as String?,
          speciesName: map['speciesName'] as String?,
          localityName: map['localityName'] as String?,
          longitude: (map['longitude'] as double?),
          latitude: (map['latitude'] as double?),
          support: map['support'] as String?,
          heightAboveGround: (map['heightAboveGround'] as double?),
          foundTime: map['foundTime'] != null ? DateTime.parse(map['foundTime'] as String) : null,
          lastTime: map['lastTime'] != null ? DateTime.parse(map['lastTime'] as String) : null,
          nestFate: map['nestFate'] != null ? NestFateType.values[map['nestFate'] as int] : NestFateType.fatUnknown,
          male: map['male'] as String?,
          female: map['female'] as String?,
          helpers: map['helpers'] as String?,
          observer: map['observer'] as String?,
          isActive: (map['isActive'] as int?) == 1,
          revisionsList: [],
          eggsList: [],
          revisionCount: ((map['revisionCount'] as int?) ?? 0),
          eggCount: ((map['eggCount'] as int?) ?? 0),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading nests summary: $e');
      return [];
    }
  }

  /// Returns the [Nest] identified by [nestId] with its full [NestRevision]
  /// and [Egg] sub-lists loaded. Intended for detail views or statistics.
  ///
  /// Throws an [Exception] if no nest with the given ID is found.
  Future<Nest> getNestWithDetails(int nestId) async {
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

  /// Returns a list of distinct species names recorded across all nests,
  /// excluding `null` values.
  Future<List<String>> getUniqueSpeciesNames() async {
    final db = await _dbHelper.database;
    try {
      final result = await db?.query(
        'nests',
        distinct: true,
        columns: ['speciesName'],
        where: 'speciesName IS NOT NULL',
      );
      return result?.map((row) => row['speciesName'] as String).toList() ?? [];
    } catch (e) {
      debugPrint('Error fetching unique nest species: $e');
      return [];
    }
  }
}