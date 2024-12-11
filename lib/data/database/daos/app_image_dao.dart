import 'package:flutter/foundation.dart';

import '../../models/app_image.dart';
import '../database_helper.dart';


class AppImageDao {
  final DatabaseHelper _dbHelper;

  AppImageDao(this._dbHelper);

  // Insert image into database linked to a vegetation record
  Future<int?> insertImageToVegetation(AppImage appImage, int vegetationId) async {
    final db = await _dbHelper.database;
    try {
      final imageWithVegetationId = appImage.copyWith(vegetationId: vegetationId);
      int? id = await db?.insert('images', imageWithVegetationId.toMap());
      appImage.id = id;
      return id;
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting image to vegetation: $e');
      }
      return 0;
    }
  }

  // Get list of images linked to a vegetation record
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

  // Insert image into database linked to a nest revision
  Future<void> insertImageToNestRevision(AppImage appImage, int revisionId) async {
    final db = await _dbHelper.database;
    try {
      final imageWithNestRevisionId = appImage.copyWith(nestRevisionId: revisionId);
      await db?.insert('images', imageWithNestRevisionId.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting image to nest revision: $e');
      }
    }
  }

  // Get list of images linked to a nest revision
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

  // Insert image into database linked to an egg
  Future<void> insertImageToEgg(AppImage appImage, int eggId) async {
    final db = await _dbHelper.database;
    try {
      final imageWithEggId = appImage.copyWith(eggId: eggId);
      await db?.insert('images', imageWithEggId.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting image to egg: $e');
      }
    }
  }

  // Get list of images linked to an egg
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

  // Insert image into database linked to a specimen
  Future<void> insertImageToSpecimen(AppImage appImage, int specimenId) async {
    final db = await _dbHelper.database;
    try {
      final imageWithSpecimenId = appImage.copyWith(specimenId: specimenId);
      await db?.insert('images', imageWithSpecimenId.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting image to specimen: $e');
      }
    }
  }

  // Get list of images linked to a specimen
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

  // Update image data in the database
  Future<void> updateImage(AppImage appImage) async {
    final db = await _dbHelper.database;
    await db?.update(
      'images',
      appImage.toMap(),
      where: 'id = ?',
      whereArgs: [appImage.id],
    );
  }

  // Delete image from database
  Future<void> deleteImage(int appImageId) async {
    final db = await _dbHelper.database;
    await db?.delete('images', where: 'id = ?', whereArgs: [appImageId]);
  }
}