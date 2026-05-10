import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/core_consts.dart';
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

  // Get paginated list of nests (for lazy loading)
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

      if (kDebugMode) {
        print('Loaded ${nests.length} nests (offset: $offset, limit: $limit)');
      }
      return nests;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading paginated nests: $e');
      }
      return [];
    }
  }

  // Get total count of nests
  Future<int> getNestsCount() async {
    final db = await _dbHelper.database;
    try {
      final result = await db?.rawQuery('SELECT COUNT(*) as count FROM nests') ?? [];
      if (result.isNotEmpty) {
        return (result.first['count'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error counting nests: $e');
      }
      return 0;
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
      localities.sort();
      
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
       supports.sort();

       debugPrint('Distinct supports from nests: $supports');
       return supports;
     } catch (e, s) {
       debugPrint('Error fetching nests distinct supports: $e\n$s');
       return [];
     }
   }

   // Get list of nests with summary data (no sublists, but with count aggregates)
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
       if (kDebugMode) {
         print('Error loading nests summary: $e');
       }
       return [];
     }
   }

   // Load full details for a single nest (for detail views or stats)
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

   // Get distinct species names for filter
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
       if (kDebugMode) {
         print('Error fetching unique nest species: $e');
       }
       return [];
     }
   }
}