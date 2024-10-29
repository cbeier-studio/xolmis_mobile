import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:geolocator/geolocator.dart';
import 'inventory.dart';
import 'nest.dart';
import 'specimen.dart';

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
      version: 6, // Increase the version number
      onCreate: (db, version) {
        // Create the tables
        db.execute(
          'CREATE TABLE inventories('
              'id TEXT PRIMARY KEY, '
              'type INTEGER, '
              'duration INTEGER, '
              'maxSpecies INTEGER, '
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
              'inventoryId TEXT NOT NULL, '
              'name TEXT, '
              'isOutOfInventory INTEGER, '
              'count INTEGER, '
              'FOREIGN KEY (inventoryId) REFERENCES inventories(id) ON DELETE CASCADE )',
        );
        db.execute(
          'CREATE TABLE vegetation ('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'inventoryId TEXT NOT NULL, '
              'sampleTime TEXT NOT NULL, '
              'longitude REAL, '
              'latitude REAL, '
              'herbsProportion INTEGER, '
              'herbsDistribution INTEGER, '
              'herbsHeight INTEGER, '
              'shrubsProportion INTEGER, '
              'shrubsDistribution INTEGER, '
              'shrubsHeight INTEGER, '
              'treesProportion INTEGER, '
              'treesDistribution INTEGER, '
              'treesHeight INTEGER, '
              'notes TEXT, '
              'FOREIGN KEY (inventoryId) REFERENCES inventories(id) ON DELETE CASCADE )'
        );
        db.execute(
          'CREATE TABLE pois ('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'speciesId INTEGER NOT NULL, '
              'longitude REAL NOT NULL, '
              'latitude REAL NOT NULL, '
              'FOREIGN KEY (speciesId) REFERENCES species(id) ON DELETE CASCADE )'
        );
        db.execute(
          'CREATE TABLE weather ('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'inventoryId INTEGER NOT NULL, '
              'sampleTime TEXT NOT NULL, '
              'cloudCover INTEGER, '
              'precipitation INTEGER, '
              'temperature REAL, '
              'windSpeed INTEGER, '
              'FOREIGN KEY (inventoryId) REFERENCES inventories(id) ON DELETE CASCADE )'
        );
        db.execute('''
        CREATE TABLE nests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fieldNumber TEXT,
          speciesName TEXT,
          localityName TEXT,
          longitude REAL,
          latitude REAL,
          support TEXT,
          heightAboveGround REAL,
          foundTime TEXT,
          lastTime TEXT,
          nestFate INTEGER,
          male TEXT,
          female TEXT,
          helpers TEXT,
          isActive INTEGER
        )
      ''');
        db.execute('''
        CREATE TABLE eggs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nestId INTEGER,
          sampleTime TEXT,
          fieldNumber TEXT,
          eggShape INTEGER,
          width REAL,
          length REAL,
          mass REAL,
          speciesName TEXT,
          FOREIGN KEY (nestId) REFERENCES nests(id) ON DELETE CASCADE
        )
      ''');
        db.execute('''
        CREATE TABLE nest_revisions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nestId INTEGER,
          sampleTime TEXT,
          nestStatus INTEGER,
          nestStage INTEGER,
          eggsHost INTEGER,
          nestlingsHost INTEGER,
          eggsParasite INTEGER,
          nestlingsParasite INTEGER,
          hasPhilornisLarvae INTEGER,
          notes TEXT,
          FOREIGN KEY (nestId) REFERENCES nests(id) ON DELETE CASCADE
        )
      ''');
        db.execute('''
        CREATE TABLE specimens (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sampleTime TEXT,
          fieldNumber TEXT,
          type INTEGER,
          longitude REAL,
          latitude REAL,
          locality TEXT,
          speciesName TEXT,
          notes TEXT
        )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) {
        // Add logic to update the database from previous versions
        if (oldVersion < 2) {
          db.execute(
            'ALTER TABLE inventories ADD COLUMN maxSpecies INTEGER',
          );
        }
        if (oldVersion < 3) {
          db.execute(
              'CREATE TABLE weather ('
                  'id INTEGER PRIMARY KEY AUTOINCREMENT, '
                  'inventoryId INTEGER NOT NULL, '
                  'sampleTime TEXT NOT NULL, '
                  'cloudCover INTEGER, '
                  'precipitation INTEGER, '
                  'temperature REAL, '
                  'windSpeed INTEGER, '
                  'FOREIGN KEY (inventoryId) REFERENCES inventories(id) ON DELETE CASCADE)'
          );
        }
        if (oldVersion < 4) {
          db.execute('''
        CREATE TABLE nests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fieldNumber TEXT,
          speciesName TEXT,
          localityName TEXT,
          longitude REAL,
          latitude REAL,
          support TEXT,
          heightAboveGround REAL,
          foundTime TEXT,
          lastTime TEXT,
          nestFate INTEGER,
          male TEXT,
          female TEXT,
          helpers TEXT
        )
      ''');
          db.execute('''
        CREATE TABLE eggs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nestId INTEGER,
          sampleTime TEXT,
          fieldNumber TEXT,
          eggShape INTEGER,
          width REAL,
          length REAL,
          mass REAL,
          speciesName TEXT,
          FOREIGN KEY (nestId) REFERENCES nests(id) ON DELETE CASCADE
        )
      ''');
          db.execute('''
        CREATE TABLE nest_revisions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nestId INTEGER,
          sampleTime TEXT,
          nestStatus INTEGER,
          nestStage INTEGER,
          eggsHost INTEGER,
          nestlingsHost INTEGER,
          eggsParasite INTEGER,
          nestlingsParasite INTEGER,
          hasPhilornisLarvae INTEGER,
          notes TEXT,
          FOREIGN KEY (nestId) REFERENCES nests(id) ON DELETE CASCADE
        )
      ''');
        }
        if (oldVersion < 5) {
          db.execute(
            'ALTER TABLE nests ADD COLUMN isActive INTEGER',
          );
        }
        if (oldVersion < 6) {
          db.execute('''
        CREATE TABLE specimens (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sampleTime TEXT,
          fieldNumber TEXT,
          type INTEGER,
          longitude REAL,
          latitude REAL,
          locality TEXT,
          speciesName TEXT,
          notes TEXT
        )
      ''');
        }
      },
    );
  }

  // Inventories

  Future<bool> inventoryIdExists(String id) async {
    final db = await database;
    final result = await db?.query(
      'inventories',
      where: 'LOWER(id) = ?',
      whereArgs: [id.toLowerCase()],
    );
    return result!.isNotEmpty;
  }

  Future<bool> insertInventory(Inventory inventory) async {
    final db = await database;
    try {
      inventory.startTime = DateTime.now();
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      inventory.startLatitude = position.latitude;
      inventory.startLongitude = position.longitude;

      int? id = await db?.insert(
        'inventories',
        inventory.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id != null && id > 0;
    } on DatabaseException catch (e) {
      if (kDebugMode) {
        print('Database error: $e');
        print('Exception type: ${e.runtimeType}');
        print('Detailed message: ${e.toString()}');
      }
      return false;
      // Handle the database error
    } catch (e) {
      if (kDebugMode) {
        print('Generic error: $e');
        print('Exception type: ${e.runtimeType}');
        print('Detailed message: ${e.toString()}');
      }
      // Handle other errors
      return false;
    }
  }

  Future<void> deleteInventory(String? inventoryId) async {
    final db = await database;
    await db?.delete(
      'inventories',
      where: 'id = ?',
      whereArgs: [inventoryId],
    );
  }

  Future<void> updateInventory(Inventory inventory) async {
    final db = await database;
    await db?.update(
      'inventories',
      inventory.toMap(),where: 'id = ?',
      whereArgs: [inventory.id],
    );
  }

  Future<void> updateInventoryElapsedTime(String inventoryId, double elapsedTime) async {
    final db = await database;
    await db?.update(
      'inventories',
      {'elapsedTime': elapsedTime},
      where: 'id = ?',
      whereArgs: [inventoryId],
    );
  }

  Future<int> getActiveInventoriesCount() async {
    final db = await database;
    final result = await db?.rawQuery('SELECT COUNT(*) FROM inventories WHERE isFinished = 0');
    return Sqflite.firstIntValue(result!) ?? 0;
  }

  Future<int?> insertSpecies(String inventoryId, Species species) async {
    final db = await database;
    try {
      int? id = await db?.insert('species', species.toMap(inventoryId));
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting species: $e');
      }
      return 0;
    }
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
        List<Weather> weatherList = await getWeatherByInventory(map['id']);
        // return Inventory.fromMap(map, speciesList, vegetationList);
        // Create Inventory instance using the main constructor
        Inventory inventory = Inventory(
          id: map['id'],
          type: InventoryType.values[map['type']],
          duration: map['duration'],
          maxSpecies: map['maxSpecies'],
          isPaused: map['isPaused'] == 1,
          isFinished: map['isFinished'] == 1,
          elapsedTime: map['elapsedTime'],
          startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
          endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
          startLongitude: map['startLongitude'],
          startLatitude: map['startLatitude'],
          endLongitude: map['endLongitude'],
          endLatitude: map['endLatitude'],
          speciesList: speciesList,
          vegetationList: vegetationList,
          weatherList: weatherList,
        );

        return inventory;
      }).toList());

      if (kDebugMode) {
        print('Loaded inventories: ${inventories.length}');
      }
      return inventories;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading inventories: $e');
      }
      // Handle the error, e.g.: return an empty list or rethrow exception
      return []; // Or rethrow;
    }
  }

  Future<Inventory> getInventoryById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db?.query(
        'inventories',
        where: 'id = ?',
        whereArgs: [id]
    ) ?? [];
    if (maps.isNotEmpty) {
      final map = maps.first;
      List<Species> speciesList = await getSpeciesByInventory(map['id']);
      List<Vegetation> vegetationList = await getVegetationByInventory(map['id']);
      List<Weather> weatherList = await getWeatherByInventory(map['id']);
      return Inventory.fromMap(map, speciesList, vegetationList, weatherList);
    } else {
      throw Exception('Inventory not found with ID $id');
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
      final pois = await getPoisForSpecies(id);
      return Species.fromMap(maps.first, pois);
    } else {
      throw Exception('Species not found with ID $id');
    }
  }

  Future<List<Species>> getSpeciesByInventory(String inventoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'species',
      where: 'inventoryId = ?',
      whereArgs: [inventoryId],
    ) ?? [];
    // if (kDebugMode) {
    //   print('Species loaded for inventory $inventoryId: ${maps.length}');
    // }
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
    // if (kDebugMode) {
    //   print('Vegetation data loaded for inventory $inventoryId: ${maps.length}');
    // }
    return List.generate(maps.length, (i) {
      return Vegetation.fromMap(maps[i]);
    });
  }

  Future<List<Weather>> getWeatherByInventory(String inventoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'weather',
      where: 'inventoryId = ?',
      whereArgs: [inventoryId],
    ) ?? [];
    // if (kDebugMode) {
    //   print('Vegetation data loaded for inventory $inventoryId: ${maps.length}');
    // }
    return List.generate(maps.length, (i) {
      return Weather.fromMap(maps[i]);
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
      List<Weather> weatherList = await getWeatherByInventory(map['id']);
      inventories.add(Inventory.fromMap(map, speciesList, vegetationList, weatherList));
    }
    if (kDebugMode) {
      print('Finished inventories loaded: ${inventories.length}');
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
      List<Weather> weatherList = await getWeatherByInventory(map['id']);
      inventories.add(Inventory.fromMap(map, speciesList, vegetationList, weatherList));
    }

    return inventories;
  }

  // Species

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

  // Vegetation data

  Future<int?> insertVegetation(Vegetation vegetation) async {
    final db = await database;
    try {
      int? id = await db?.insert(
        'vegetation',
        vegetation.toMap(vegetation.inventoryId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting vegetation data: $e');
      }
      return 0;
    }
  }

  Future<void> deleteVegetation(int? vegetationId) async {
    final db = await database;
    await db?.delete(
      'vegetation',
      where: 'id = ?',
      whereArgs: [vegetationId],
    );
  }

  // Weather data

  Future<int?> insertWeather(Weather weather) async {
    final db = await database;
    try {
      int? id = await db?.insert(
        'weather',
        weather.toMap(weather.inventoryId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting weather data: $e');
      }
      return 0;
    }
  }

  Future<void> deleteWeather(int? weatherId) async {
    final db = await database;
    await db?.delete(
      'weather',
      where: 'id = ?',
      whereArgs: [weatherId],
    );
  }

  // Species POI

  Future<void> insertPoi(Poi poi) async {
    final db = await database;
    try {
      await db?.insert('pois', poi.toMap(poi.speciesId));
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting POI: $e');
      }
    }
  }

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

  Future<void> updatePoi(Poi poi) async {
    final db = await database;
    await db?.update(
      'pois',
      poi.toMap(poi.speciesId),
      where: 'id = ?',
      whereArgs: [poi.id],
    );
  }

  Future<void> deletePoi(int poiId) async {
    final db = await database;
    await db?.delete('pois', where: 'id = ?', whereArgs: [poiId]);
  }

  // Nests

  Future<void> insertNest(Nest nest) async {
    final db = await database;
    await db?.insert(
      'nests',
      nest.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Nest>> getNests() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db?.query('nests') ?? [];

      List<Nest> nests = await Future.wait(maps.map((map) async {
        List<NestRevision> revisionsList = await getNestRevisionsForNest(map['id']);
        List<Egg> eggsList = await getEggsForNest(map['id']);
        // Create Inventory instance using the main constructor
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

  Future<int?> updateNest(Nest nest) async {
    final db = await database;
    return await db?.update(
      'nests',
      nest.toMap(),
      where: 'id = ?',
      whereArgs: [nest.id],
    );
  }

  Future<void> deleteNest(int nestId) async {
    final db = await database;
    await db?.delete('nests', where: 'id = ?', whereArgs: [nestId]);
  }

  Future<bool> nestFieldNumberExists(String fieldNumber) async {
    final db = await database;
    final result = await db?.query(
      'nests',
      where: 'LOWER(fieldNumber) = ?',
      whereArgs: [fieldNumber.toLowerCase()],
    );
    return result!.isNotEmpty;
  }

  // Nest revisions

  Future<void> insertNestRevision(NestRevision nestRevision) async {
    final db = await database;
    await db?.insert(
      'nest_revisions',
      nestRevision.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NestRevision>> getNestRevisionsForNest(int nestId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'nest_revisions',
      where: 'nestId = ?',
      whereArgs: [nestId],
    ) ?? [];
    return List.generate(maps.length, (i) {
      return NestRevision.fromMap(maps[i]);
    });
  }

  Future<void> deleteNestRevision(int nestRevisionId) async {
    final db = await database;
    await db?.delete('nest_revisions', where: 'id = ?', whereArgs: [nestRevisionId]);
  }

  // Eggs

  Future<void> insertEgg(Egg egg) async {
    final db = await database;
    await db?.insert(
      'eggs',
      egg.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Egg>> getEggsForNest(int nestId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'eggs',
      where: 'nestId = ?',
      whereArgs: [nestId],
    ) ?? [];
    return List.generate(maps.length, (i) {
      return Egg.fromMap(maps[i]);
    });
  }

  Future<void> deleteEgg(int eggId) async {
    final db = await database;
    await db?.delete('eggs', where: 'id = ?', whereArgs: [eggId]);
  }

  Future<bool> eggFieldNumberExists(String fieldNumber) async {
    final db = await database;
    final result = await db?.query(
      'eggs',
      where: 'LOWER(fieldNumber) = ?',
      whereArgs: [fieldNumber.toLowerCase()],
    );
    return result!.isNotEmpty;
  }

  // Specimens

  Future<void> insertSpecimen(Specimen specimen) async {
    final db = await database;
    await db?.insert(
      'specimens',
      specimen.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Specimen>> getSpecimens() async {
    final db = await database;
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

  Future<int?> updateSpecimen(Specimen specimen) async {
    final db = await database;
    return await db?.update(
      'specimens',
      specimen.toMap(),
    );
  }

  Future<void> deleteSpecimen(int specimenId) async {
    final db = await database;
    await db?.delete('specimens', where: 'id = ?', whereArgs: [specimenId]);
  }

  Future<bool> specimenFieldNumberExists(String fieldNumber) async {
    final db = await database;
    final result = await db?.query(
      'specimens',
      where: 'LOWER(fieldNumber) = ?',
      whereArgs: [fieldNumber.toLowerCase()],
    );
    return result!.isNotEmpty;
  }
}

