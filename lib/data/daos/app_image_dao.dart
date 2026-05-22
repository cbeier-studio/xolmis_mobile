import 'package:flutter/material.dart';

import '../models/app_image.dart';
import '../database/database_helper.dart';


class AppImageDao {
  final DatabaseHelper _dbHelper;

  AppImageDao(this._dbHelper);

  /// Inserts a new [AppImage] into the database linked to the [Vegetation]
  /// record identified by [vegetationId].
  ///
  /// Sets [appImage.id] with the generated row ID upon success.
  /// Returns the new row ID, or `0` if an error occurs.
  Future<int?> insertImageToVegetation(AppImage appImage, int vegetationId) async {
    final db = await _dbHelper.database;
    try {
      final imageWithVegetationId = appImage.copyWith(vegetationId: vegetationId);
      int? id = await db?.insert('images', imageWithVegetationId.toMap());
      appImage.id = id;
      return id;
    } catch (e) {
      debugPrint('Error inserting image to vegetation: $e');
      return 0;
    }
  }

  /// Returns all [AppImage] records associated with the [Vegetation] record
  /// identified by [vegetationId].
  Future<List<AppImage>> getImagesForVegetation(int vegetationId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'images',
      where: 'vegetationId = ?',
      whereArgs: [vegetationId],
    ) ?? [];
    return List.generate(maps.length, (i) {
      return AppImage.fromMap(maps[i]);
    });
  }

  /// Inserts a new [AppImage] into the database linked to the [NestRevision]
  /// record identified by [revisionId].
  ///
  /// Logs a debug message if an error occurs.
  Future<void> insertImageToNestRevision(AppImage appImage, int revisionId) async {
    final db = await _dbHelper.database;
    try {
      final imageWithNestRevisionId = appImage.copyWith(nestRevisionId: revisionId);
      await db?.insert('images', imageWithNestRevisionId.toMap());
    } catch (e) {
      debugPrint('Error inserting image to nest revision: $e');
    }
  }

  /// Returns all [AppImage] records associated with the [NestRevision] record
  /// identified by [revisionId].
  Future<List<AppImage>> getImagesForNestRevision(int revisionId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'images',
      where: 'nestRevisionId = ?',
      whereArgs: [revisionId],
    ) ?? [];
    return List.generate(maps.length, (i) {
      return AppImage.fromMap(maps[i]);
    });
  }

  /// Inserts a new [AppImage] into the database linked to the [Egg] record
  /// identified by [eggId].
  ///
  /// Logs a debug message if an error occurs.
  Future<void> insertImageToEgg(AppImage appImage, int eggId) async {
    final db = await _dbHelper.database;
    try {
      final imageWithEggId = appImage.copyWith(eggId: eggId);
      await db?.insert('images', imageWithEggId.toMap());
    } catch (e) {
      debugPrint('Error inserting image to egg: $e');
    }
  }

  /// Returns all [AppImage] records associated with the [Egg] record
  /// identified by [eggId].
  Future<List<AppImage>> getImagesForEgg(int eggId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'images',
      where: 'eggId = ?',
      whereArgs: [eggId],
    ) ?? [];
    return List.generate(maps.length, (i) {
      return AppImage.fromMap(maps[i]);
    });
  }

  /// Inserts a new [AppImage] into the database linked to the [Specimen] record
  /// identified by [specimenId].
  ///
  /// Logs a debug message if an error occurs.
  Future<void> insertImageToSpecimen(AppImage appImage, int specimenId) async {
    final db = await _dbHelper.database;
    try {
      final imageWithSpecimenId = appImage.copyWith(specimenId: specimenId);
      await db?.insert('images', imageWithSpecimenId.toMap());
    } catch (e) {
      debugPrint('Error inserting image to specimen: $e');
    }
  }

  /// Returns all [AppImage] records associated with the [Specimen] record
  /// identified by [specimenId].
  Future<List<AppImage>> getImagesForSpecimen(int specimenId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'images',
      where: 'specimenId = ?',
      whereArgs: [specimenId],
    ) ?? [];
    return List.generate(maps.length, (i) {
      return AppImage.fromMap(maps[i]);
    });
  }

  /// Updates the database record for the given [appImage] using its [AppImage.id].
  Future<void> updateImage(AppImage appImage) async {
    final db = await _dbHelper.database;
    await db?.update(
      'images',
      appImage.toMap(),
      where: 'id = ?',
      whereArgs: [appImage.id],
    );
  }

  /// Deletes the [AppImage] record identified by [appImageId] from the database.
  Future<void> deleteImage(int appImageId) async {
    final db = await _dbHelper.database;
    await db?.delete('images', where: 'id = ?', whereArgs: [appImageId]);
  }
}