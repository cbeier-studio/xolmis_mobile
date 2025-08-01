import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';

import '../database_helper.dart';
import '../../models/inventory.dart';
import '../daos/species_dao.dart';
import '../daos/vegetation_dao.dart';
import '../daos/weather_dao.dart';

import '../../../utils/utils.dart';

class InventoryDao {
  final DatabaseHelper _dbHelper;
  final SpeciesDao _speciesDao;
  final VegetationDao _vegetationDao;
  final WeatherDao _weatherDao;

  InventoryDao(this._dbHelper, this._speciesDao, this._vegetationDao, this._weatherDao);

  // Insert new inventory to database
  Future<bool> insertInventory(Inventory inventory) async {
    final db = await _dbHelper.database;
    try {
      inventory.startTime = DateTime.now();
      Position? position = await getPosition();
      if (position != null) {
        inventory.startLatitude = position.latitude;
        inventory.startLongitude = position.longitude;
      }

      int? recordId = await db?.insert(
        'inventories',
        inventory.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return recordId != null && recordId > 0;
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

  // Insert an imported inventory to database
  Future<bool> importInventory(Inventory inventory) async {
    final db = await _dbHelper.database;
    if (db == null) {
      if (kDebugMode) {
        print('Database instance is null. Cannot import inventory.');
      }
      return false;
    }

    try {
      return await db.transaction((txn) async {
        inventory.isFinished = true;
        // The inventory.id might be pre-set if it's an import.
        // If it's meant to be auto-generated by the DB, it should be null here.
        // However, ConflictAlgorithm.replace handles existing IDs.
        // Let's assume inventory.id is the intended ID for the imported record.
        int? recordId = await txn.insert(
          'inventories',
          inventory.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // It's crucial that inventory.id is correctly set for foreign keys.
        // If recordId is from an auto-incrementing PK and inventory.id was different,
        // this could be an issue. Assuming inventory.id is the source of truth.
        final String currentInventoryId = inventory.id; // Assuming inventory.id is non-null and is the key

        for (final species in inventory.speciesList) {
          species.id = null; // Ensure new ID from DB
          int? speciesId = await txn.insert(
            'species',
            species.toMap(currentInventoryId), // Use the parent inventory's ID
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          species.id = speciesId; // Update object with new DB-generated ID

          if (speciesId == null) {
            // If species insertion failed, the transaction will roll back.
            // We can throw an exception to ensure rollback.
            throw Exception('Failed to insert species: ${species.toString()}');
          }

          for (final poi in species.pois) {
            poi.id = null; // Ensure new ID from DB
            int? poiId = await txn.insert(
              'pois',
              poi.toMap(speciesId), // Use the parent species' new ID
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            poi.id = poiId; // Update object with new DB-generated ID
            if (poiId == null) {
              throw Exception('Failed to insert POI: ${poi.toString()}');
            }
          }
        }

        for (final vegetation in inventory.vegetationList) {
          vegetation.id = null; // Ensure new ID from DB
          int? vegetationId = await txn.insert(
            'vegetation',
            vegetation.toMap(currentInventoryId), // Use the parent inventory's ID
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          vegetation.id = vegetationId; // Update object with new DB-generated ID
          if (vegetationId == null) {
            throw Exception('Failed to insert vegetation: ${vegetation.toString()}');
          }
        }

        for (final weather in inventory.weatherList) {
          weather.id = null; // Ensure new ID from DB
          int? weatherId = await txn.insert(
            'weather',
            weather.toMap(currentInventoryId), // Use the parent inventory's ID
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          weather.id = weatherId; // Update object with new DB-generated ID
          if (weatherId == null) {
            throw Exception('Failed to insert weather: ${weather.toString()}');
          }
        }

        return recordId != null && recordId > 0;
      });
    } on DatabaseException catch (e) {
      if (kDebugMode) {
        print('Database error during importInventory transaction: $e');
        print('Exception type: ${e.runtimeType}');
        print('Detailed message: ${e.toString()}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Generic error during importInventory transaction: $e');
        print('Exception type: ${e.runtimeType}');
        print('Detailed message: ${e.toString()}');
      }
      return false;
    }
  }

  // Delete the inventory from database
  Future<void> deleteInventory(String? inventoryId) async {
    final db = await _dbHelper.database;
    await db?.delete(
      'inventories',
      where: 'id = ?',
      whereArgs: [inventoryId],
    );
  }

  // Update inventory data in the database
  Future<void> updateInventory(Inventory inventory) async {
    final db = await _dbHelper.database;
    await db?.update(
      'inventories',
      inventory.toMap(),
      where: 'id = ?',
      whereArgs: [inventory.id],
    );
  }

  // Update the elapsed time of the inventory in the database
  Future<void> updateInventoryElapsedTime(String inventoryId, double elapsedTime) async {
    final db = await _dbHelper.database;
    await db?.update(
      'inventories',
      {'elapsedTime': elapsedTime},
      where: 'id = ?',
      whereArgs: [inventoryId],
    );
  }

  // Update the current interval of the inventory in the database
  Future<void> updateInventoryCurrentInterval(String inventoryId, int currentInterval) async {
    final db = await _dbHelper.database;
    await db?.update(
      'inventories',
      {'currentInterval': currentInterval},
      where: 'id = ?',
      whereArgs: [inventoryId],
    );
  }

  // Update the number of intervals without new species of the inventory in the database
  Future<void> updateInventoryIntervalsWithoutSpecies(String inventoryId, int intervalsWithoutSpecies) async {
    final db = await _dbHelper.database;
    await db?.update(
      'inventories',
      {'intervalsWithoutNewSpecies': intervalsWithoutSpecies},
      where: 'id = ?',
      whereArgs: [inventoryId],
    );
  }

  // Update the current interval species count of the inventory in the database
  Future<void> updateInventoryCurrentIntervalSpeciesCount(String inventoryId, int speciesCount) async {
    final db = await _dbHelper.database;
    await db?.update(
      'inventories',
      {'currentIntervalSpeciesCount': speciesCount},
      where: 'id = ?',
      whereArgs: [inventoryId],
    );
  }

  // Update the ID of the inventory in the database
  Future<void> changeInventoryId(String oldId, String newId) async {
    final db = await _dbHelper.database;
    await db?.transaction((txn) async {
      await txn.execute('PRAGMA foreign_keys = OFF;');
      await txn.update(
        'inventories',
        {'id': newId},
        where: 'id = ?',
        whereArgs: [oldId],
      );
      await txn.update(
        'species',
        {'inventoryId': newId},
        where: 'inventoryId = ?',
        whereArgs: [oldId],
      );
      await txn.update(
        'vegetation',
        {'inventoryId': newId},
        where: 'inventoryId = ?',
        whereArgs: [oldId],
      );
      await txn.update(
        'weather',
        {'inventoryId': newId},
        where: 'inventoryId = ?',
        whereArgs: [oldId],
      );
      await txn.execute('PRAGMA foreign_keys = ON;');
    });
  }

  // Check if the ID already exists
  Future<bool> inventoryIdExists(String id) async {
    final db = await _dbHelper.database;
    final result = await db?.query(
      'inventories',
      where: 'LOWER(id) = ?',
      whereArgs: [id.toLowerCase()],
    );
    return result!.isNotEmpty;
  }

  // Get the number of active inventories
  Future<int> getActiveInventoriesCount() async {
    final db = await _dbHelper.database;
    final result = await db?.rawQuery('SELECT COUNT(*) FROM inventories WHERE isFinished = 0');
    return Sqflite.firstIntValue(result!) ?? 0;
  }

  // Get list of all inventories
  Future<List<Inventory>> getInventories() async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db?.query('inventories') ?? [];

      List<Inventory> inventories = await Future.wait(maps.map((map) async {
        List<Species> speciesList = await _speciesDao.getSpeciesByInventory(map['id']);
        List<Vegetation> vegetationList = await _vegetationDao.getVegetationByInventory(map['id']);
        List<Weather> weatherList = await _weatherDao.getWeatherByInventory(map['id']);
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
          currentInterval: map['currentInterval'] ?? 1,
          intervalsWithoutNewSpecies: map['intervalsWithoutNewSpecies'] ?? 0,
          currentIntervalSpeciesCount: map['currentIntervalSpeciesCount'] ?? 0,
          localityName: map['localityName'],
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

  // Find and get inventory by ID
  Future<Inventory> getInventoryById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
        'inventories',
        where: 'id = ?',
        whereArgs: [id]
    ) ?? [];
    if (maps.isNotEmpty) {
      final map = maps.first;
      List<Species> speciesList = await _speciesDao.getSpeciesByInventory(map['id']);
      List<Vegetation> vegetationList = await _vegetationDao.getVegetationByInventory(map['id']);
      List<Weather> weatherList = await _weatherDao.getWeatherByInventory(map['id']);
      return Inventory.fromMap(map, speciesList, vegetationList, weatherList);
    } else {
      throw Exception('Inventory not found with ID $id');
    }
  }

  // Concatenate the next inventory ID
  Future<int> getNextSequentialNumber(String? local, String observer, int ano, int mes, int dia, String? typeChar) async {
    final db = await _dbHelper.database;

    final prefix = "${local != null ? '$local-' : ''}$observer-$ano${mes.toString().padLeft(2, '0')}${dia.toString().padLeft(2, '0')}-${typeChar ?? ''}";

    final results = await db?.query(
      'inventories',
      where: 'id LIKE ?',
      whereArgs: ["$prefix%"],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (results!.isNotEmpty) {
      final lastInventoryId = results.first['id'] as String;
      final sequentialNumberString = lastInventoryId.replaceFirst(prefix, '');
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
        'inventories',
        distinct: true,
        columns: ['localityName'],
        where: 'localityName IS NOT NULL', // Ensure we only retrieve non-null locality names
      );

      final localities = results.map((row) => row['localityName'] as String).toList();
      
      debugPrint('Distinct localities from inventories: $localities');
      return localities;
    } catch (e, s) {
      debugPrint('Error fetching inventories distinct localities: $e\n$s');
      return [];
    }
  }
}