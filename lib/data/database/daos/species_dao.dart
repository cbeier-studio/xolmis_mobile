import 'package:flutter/foundation.dart';

import '../../models/inventory.dart';
import '../../database/database_helper.dart';
import '../../database/daos/poi_dao.dart';

class SpeciesDao {
  final DatabaseHelper _dbHelper;
  final PoiDao _poiDao;

  SpeciesDao(this._dbHelper, this._poiDao);

  // Insert species to inventory in the database
  Future<int?> insertSpecies(String inventoryId, Species species) async {
    final db = await _dbHelper.database;
    try {
      int? id = await db?.insert('species', species.toMap(inventoryId));
      species.id = id;
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting species: $e');
      }
      return 0;
    }
  }

  // Update species data in the database
  Future<void> updateSpecies(Species species) async {
    final db = await _dbHelper.database;
    await db?.update(
      'species',
      species.toMap(species.inventoryId),
      where: 'id = ?',
      whereArgs: [species.id],
    );
  }

  // Delete species from database finding by ID
  Future<void> deleteSpecies(int? speciesId) async {
    final db = await _dbHelper.database;
    await db?.delete(
      'species',
      where: 'id = ?',
      whereArgs: [speciesId],
    );
  }

  // Delete species from database finding by inventory and name
  Future<void> deleteSpeciesFromInventory(String inventoryId, String speciesName) async {
    final db = await _dbHelper.database;
    await db?.delete(
      'species',
      where: 'inventoryId = ? AND name = ?',
      whereArgs: [inventoryId, speciesName],
    );
  }

  // Get species data by ID
  Future<Species> getSpeciesById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
        'species',
        where: 'id = ?',
        whereArgs: [id]
    ) ?? [];
    if (maps.isNotEmpty) {
      final pois = await _poiDao.getPoisForSpecies(id);
      return Species.fromMap(maps.first, pois);
    } else {
      throw Exception('Species not found with ID $id');
    }
  }

  // Get list of species from inventory
  Future<List<Species>> getSpeciesByInventory(String inventoryId) async {
    final db = await _dbHelper.database;
    final speciesMaps = await db?.query(
      'species',
      where: 'inventoryId = ?',
      whereArgs: [inventoryId],
    ) ?? [];

    if (speciesMaps.isEmpty) return [];

    final speciesIds = speciesMaps.map((map) => map['id'] as int).toList();
    final poisMaps = await db?.query(
      'pois',
      where: 'speciesId IN (${speciesIds.join(',')})',
    ) ?? [];

    // Get the species POIs 
    final poisBySpeciesId = <int, List<Poi>>{};
    for (final poiMap in poisMaps) {
      final speciesId = poiMap['speciesId'] as int;
      poisBySpeciesId.putIfAbsent(speciesId, () => []);
      poisBySpeciesId[speciesId]!.add(Poi.fromMap(poiMap));
    }

    return speciesMaps.map((map) {
      final speciesId = map['id'] as int;
      final pois = poisBySpeciesId[speciesId] ?? [];
      return Species.fromMap(map, pois);
    }).toList();
  }

}