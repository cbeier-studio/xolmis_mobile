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
      inventory.toMap(),where: 'id = ?',
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
    db?.execute('PRAGMA foreign_keys = OFF;');
    await db?.update(
      'inventories',
      {'id': newId},
      where: 'id = ?',
      whereArgs: [oldId],
    );
    await db?.update(
      'species',
      {'inventoryId': newId},
      where: 'inventoryId = ?',
      whereArgs: [oldId],
    );
    await db?.update(
      'vegetation',
      {'inventoryId': newId},
      where: 'inventoryId = ?',
      whereArgs: [oldId],
    );
    await db?.update(
      'weather',
      {'inventoryId': newId},
      where: 'inventoryId = ?',
      whereArgs: [oldId],
    );
    db?.execute('PRAGMA foreign_keys = ON;');
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
          currentInterval: map['currentInterval'] ?? 1,
          intervalsWithoutNewSpecies: map['intervalsWithoutNewSpecies'] ?? 0,
          currentIntervalSpeciesCount: map['currentIntervalSpeciesCount'] ?? 0,
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
}