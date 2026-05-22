import 'package:flutter/material.dart';

import '../models/inventory.dart';
import '../database/database_helper.dart';
import 'poi_dao.dart';

class SpeciesDao {
  final DatabaseHelper _dbHelper;
  final PoiDao _poiDao;

  SpeciesDao(this._dbHelper, this._poiDao);

  /// Inserts a new [Species] record linked to [inventoryId] into the database.
  ///
  /// Sets [species.id] with the generated row ID upon success.
  /// Returns the new row ID, or `0` if an error occurs.
  Future<int?> insertSpecies(String inventoryId, Species species) async {
    final db = await _dbHelper.database;
    try {
      int? id = await db?.insert('species', species.toMap(inventoryId));
      species.id = id;
      return id;
    } catch (e) {
      debugPrint('Error inserting species: $e');
      return 0;
    }
  }

  /// Updates the database record for the given [species] using its [Species.id].
  Future<void> updateSpecies(Species species) async {
    final db = await _dbHelper.database;
    await db?.update(
      'species',
      species.toMap(species.inventoryId),
      where: 'id = ?',
      whereArgs: [species.id],
    );
  }

  /// Deletes the [Species] record identified by [speciesId] from the database.
  Future<void> deleteSpecies(int? speciesId) async {
    final db = await _dbHelper.database;
    await db?.delete(
      'species',
      where: 'id = ?',
      whereArgs: [speciesId],
    );
  }

  /// Deletes the [Species] record matching both [inventoryId] and [speciesName]
  /// from the database.
  Future<void> deleteSpeciesFromInventory(String inventoryId, String speciesName) async {
    final db = await _dbHelper.database;
    await db?.delete(
      'species',
      where: 'inventoryId = ? AND name = ?',
      whereArgs: [inventoryId, speciesName],
    );
  }

  /// Returns the [Species] identified by [id], populated with its associated
  /// [Poi] list.
  ///
  /// Throws an [Exception] if no species with the given ID is found.
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

  /// Returns all [Species] records belonging to the inventory identified by
  /// [inventoryId], each populated with its associated [Poi] list.
  ///
  /// When [onlySpeciesInSample] is `true`, only records with
  /// `isOutOfInventory = 0` are returned. POIs for all matching species are
  /// fetched in a single batch query to avoid N+1 round trips.
  Future<List<Species>> getSpeciesByInventory(String inventoryId, bool onlySpeciesInSample) async {
    final db = await _dbHelper.database;
    final speciesMaps = await db?.query(
      'species',
      where: onlySpeciesInSample ? 'inventoryId = ? AND isOutOfInventory = 0' : 'inventoryId = ?',
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

  /// Returns the total number of rows in the `species` table.
  Future<int> countAllSpeciesRecords() async {
    final db = await _dbHelper.database;
    final result = await db?.rawQuery('SELECT COUNT(*) FROM species');
    final count = result?.first['COUNT(*)'] ?? 0;
    return (count as int);
  }

  /// Returns all [Species] records whose name matches [speciesName], each
  /// populated with its associated [Poi] list.
  ///
  /// POIs for all matching species are fetched in a single batch query.
  Future<List<Species>> getAllRecordsBySpecies(String speciesName) async {
    final db = await _dbHelper.database;
    final speciesMaps = await db?.query(
      'species',
      where: 'name = ?',
      whereArgs: [speciesName],
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

  /// Returns every [Species] record stored in the database, each populated
  /// with its associated [Poi] list.
  ///
  /// POIs for all species are fetched in a single batch query.
  Future<List<Species>> getAllSpeciesRecords() async {
    final db = await _dbHelper.database;
    final speciesMaps = await db?.query(
      'species',
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

  /// Returns the `sampleTime` of the most recently recorded [Species] entry
  /// for the inventory identified by [inventoryId], or `null` if no records
  /// exist for that inventory.
  Future<DateTime?> getLastSpeciesTimeByInventory(String inventoryId) async {
    final db = await _dbHelper.database;
    final result = await db?.query(
      'species',
      where: 'inventoryId = ?',
      whereArgs: [inventoryId],
      orderBy: 'sampleTime DESC',
      limit: 1,
    );
    if (result!.isNotEmpty) {
      return DateTime.parse(result.first['sampleTime'] as String);
    }
    return null;
  }

}