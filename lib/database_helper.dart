import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'inventory.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await initDatabase();
    return _database;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'inventory_database.db');
    return await openDatabase(
      path,
      version: 1, // Increase the version number
      onCreate: (db, version) {
        // Create the tables
        db.execute(
          'CREATE TABLE inventories('
              'id TEXT PRIMARY KEY, '
              'type INTEGER, '
              'duration INTEGER, '
              'isPaused INTEGER, '
              'isFinished INTEGER, '
              'elapsedTime REAL, '
              'startTime TEXT, '
              'endTime TEXT, '
              'startLongitude REAL, '
              'startLatitude REAL, '
              'endLongitude REAL, '
              'endLatitude REAL)', // Add the new columns
        );
        db.execute(
          'CREATE TABLE species('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'inventoryId TEXT, '
              'name TEXT, '
              'count INTEGER)',
        );
        db.execute(
          'CREATE TABLE vegetation ('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'inventoryId TEXT NOT NULL, '
              'sampleTime TEXT NOT NULL, '
              'longitude REAL, '
              'latitude REAL, '
              'herbsProportion REAL, '
              'herbsDistribution REAL, '
              'herbsHeight REAL, '
              'shrubsProportion REAL, '
              'shrubsDistribution REAL, '
              'shrubsHeight REAL, '
              'treesProportion REAL, '
              'treesDistribution REAL, '
              'treesHeight REAL, '
              'notes TEXT)'
        );
        db.execute(
          'CREATE TABLE pois ('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'speciesId INTEGER NOT NULL,'
              'longitude REAL NOT NULL,'
              'latitude REAL NOT NULL,'
              'FOREIGN KEY (speciesId) REFERENCES species(id))'
        );
      },
      // onUpgrade: (db, oldVersion, newVersion) {
      //   // Add logic to update the database from previous versions
      //   if (oldVersion < 2) {
      //     db.execute(
      //       'ALTER TABLE inventories ADD COLUMN elapsedTime REAL',
      //     );
      //     db.execute(
      //       'ALTER TABLE inventories ADD COLUMN startTime TEXT',
      //     );
      //     db.execute(
      //       'ALTER TABLE inventories ADD COLUMN endTime TEXT',
      //     );
      //     db.execute(
      //       'ALTER TABLE species ADD COLUMN isOutOfInventory INTEGER',
      //     );
      //   }
      // },
    );
  }

  Future<bool> insertInventory(Inventory inventory) async {
    final db = await database;
    try {
      int? id = await db?.insert(
        'inventories',
        inventory.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id != null && id > 0;
    } on DatabaseException catch (e) {
      if (kDebugMode) {
        print('Erro de banco de dados: $e');
        print('Tipo de exceção: ${e.runtimeType}');
        print('Mensagem detalhada: ${e.toString()}');
      }
      return false;
      // Handle the database error
    } catch (e) {
      if (kDebugMode) {
        print('Erro genérico: $e');
        print('Tipo de exceção: ${e.runtimeType}');
        print('Mensagem detalhada: ${e.toString()}');
      }
      // Handle other errors
      return false;
    }
  }

  Future<void> insertSpecies(Species species) async {
    final db = await database;
    await db?.insert(
      'species',
      species.toMap(species.inventoryId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSpeciesFromInventory(String inventoryId, String speciesName) async {
    final db = await database;
    await db?.delete(
      'species',
      where: 'inventoryId = ? AND name = ?',
      whereArgs: [inventoryId, speciesName],
    );
  }

  Future<List<Inventory>> getInventories() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db?.query('inventories') ?? [];

      List<Inventory> inventories = await Future.wait(maps.map((map) async {
        List<Species> speciesList = await getSpeciesByInventory(map['id']);
        List<Vegetation> vegetationList = await getVegetationByInventory(map['id']);
        return Inventory.fromMap(map, speciesList, vegetationList);
      }).toList());

      if (kDebugMode) {
        print('Inventários carregados: ${inventories.length}');
      }
      return inventories;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar inventários: $e');
      }
      // Handle the error, e.g.: return an empty list or rethrow exception
      return []; // Or rethrow;
    }
  }

  Future<Species> getSpeciesById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db?.query(
        'species',
        where: 'id = ?',
        whereArgs: [id]
    ) ?? [];
    if (maps.isNotEmpty) {
      final pois = await getPoisForSpecies(id); // Obter os POIs para a espécie
      return Species.fromMap(maps.first, pois); // Passar os POIs para o fromMap
    } else {
      throw Exception('Espécie não encontrada com o ID $id');
    }
  }

  Future<List<Species>> getSpeciesByInventory(String inventoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'species',
      where: 'inventoryId = ?',
      whereArgs: [inventoryId],
    ) ?? [];
    if (kDebugMode) {
      print('Espécies carregadas para o inventário $inventoryId: ${maps.length}');
    }
    // Create the species list with the corresponding POIs
    final speciesList = await Future.wait(maps.map((map) async {
      final speciesId = map['id'] as int;
      final pois = await getPoisForSpecies(speciesId);
      return Species.fromMap(map, pois);
    }).toList());

    return speciesList;
  }

  Future<List<Vegetation>> getVegetationByInventory(String inventoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'vegetation',
      where: 'inventoryId = ?',
      whereArgs: [inventoryId],
    ) ?? [];
    if (kDebugMode) {
      print('Dados de vegetação carregados para o inventário $inventoryId: ${maps.length}');
    }
    return List.generate(maps.length, (i) {
      return Vegetation.fromMap(maps[i]);
    });
  }

  Future<List<Inventory>> getFinishedInventories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'inventories',
      where: 'isFinished = ?',
      whereArgs: [1],
    ) ?? [];
    List<Inventory> inventories = [];

    for (Map<String, dynamic> map in maps) {
      List<Species> speciesList = await getSpeciesByInventory(map['id']);
      List<Vegetation> vegetationList = await getVegetationByInventory(map['id']);
      inventories.add(Inventory.fromMap(map, speciesList, vegetationList));
    }
    if (kDebugMode) {
      print('Inventários finalizados carregados: ${inventories.length}');
    }
    return inventories;
  }

  Future<List<Inventory>> loadActiveInventories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'inventories',
      where: 'isFinished = ?',
      whereArgs: [0],
    ) ?? [];
    List<Inventory> inventories = [];

    for (Map<String, dynamic> map in maps) {
      List<Species> speciesList = await getSpeciesByInventory(map['id']);
      List<Vegetation> vegetationList = await getVegetationByInventory(map['id']);
      inventories.add(Inventory.fromMap(map, speciesList, vegetationList));
    }

    return inventories;
  }

  Future<void> deleteSpecies(int? speciesId) async {
    final db = await database;
    await db?.delete(
      'species',
      where: 'id = ?',
      whereArgs: [speciesId],
    );
  }

  Future<Species?> getSpeciesByNameAndInventoryId(String name, String inventoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'species',
      where: 'name = ? AND inventoryId = ?',
      whereArgs: [name, inventoryId],
    ) ?? [];

    if (maps.isNotEmpty) {
      final speciesId = maps.first['id'] as int;
      final pois = await getPoisForSpecies(speciesId);
      return Species.fromMap(maps.first, pois);
    } else {
      return null;
    }
  }

  Future<void> updateSpecies(Species species) async {
    final db = await database;
    await db?.update(
      'species',
      species.toMap(species.inventoryId),
      where: 'id = ?',
      whereArgs: [species.id],
    );
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db?.close();
  }

  Future<void> insertVegetation(Vegetation vegetation) async {
    final db = await database;
    await db?.insert(
      'vegetation',
      vegetation.toMap(vegetation.inventoryId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteVegetation(int? vegetationId) async {
    final db = await database;
    await db?.delete(
      'vegetation',
      where: 'id = ?',
      whereArgs: [vegetationId],
    );
  }

  Future<void> insertPoi(Poi poi) async {
    final db = await database;
    await db?.insert('pois', poi.toMap(poi.speciesId));}

  Future<List<Poi>> getPoisForSpecies(int speciesId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db?.query(
        'pois',
        where: 'speciesId = ?',
        whereArgs: [speciesId],
    ) ?? [];
    return List.generate(maps.length, (i) {
      return Poi.fromMap(maps[i]);
    });
  }

  Future<void> deletePoi(int poiId) async {
    final db = await database;
    await db?.delete('pois', where: 'id = ?', whereArgs: [poiId]);
  }
}

