import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite/sqflite.dart';

import '../database_helper.dart';
import '../../models/inventory.dart';
import '../daos/species_dao.dart';
import '../daos/vegetation_dao.dart';
import '../daos/weather_dao.dart';

import '../../../screens/utils.dart';

class InventoryDao {
  final DatabaseHelper _dbHelper;
  final SpeciesDao _speciesDao;
  final VegetationDao _vegetationDao;
  final WeatherDao _weatherDao;

  InventoryDao(this._dbHelper, this._speciesDao, this._vegetationDao, this._weatherDao);

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

  Future<void> deleteInventory(String? inventoryId) async {
    final db = await _dbHelper.database;
    await db?.delete(
      'inventories',
      where: 'id = ?',
      whereArgs: [inventoryId],
    );
  }

  Future<void> updateInventory(Inventory inventory) async {
    final db = await _dbHelper.database;
    await db?.update(
      'inventories',
      inventory.toMap(),where: 'id = ?',
      whereArgs: [inventory.id],
    );
  }

  Future<void> updateInventoryElapsedTime(String inventoryId, double elapsedTime) async {
    final db = await _dbHelper.database;
    await db?.update(
      'inventories',
      {'elapsedTime': elapsedTime},
      where: 'id = ?',
      whereArgs: [inventoryId],
    );
  }

  Future<bool> inventoryIdExists(String id) async {
    final db = await _dbHelper.database;
    final result = await db?.query(
      'inventories',
      where: 'LOWER(id) = ?',
      whereArgs: [id.toLowerCase()],
    );
    return result!.isNotEmpty;
  }

  Future<int> getActiveInventoriesCount() async {
    final db = await _dbHelper.database;
    final result = await db?.rawQuery('SELECT COUNT(*) FROM inventories WHERE isFinished = 0');
    return Sqflite.firstIntValue(result!) ?? 0;
  }

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


}