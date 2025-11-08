import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/nest.dart';
import '../database/database_helper.dart';


class NestRevisionDao {
  final DatabaseHelper _dbHelper;

  NestRevisionDao(this._dbHelper);

  // Insert nest revision into database
  Future<void> insertNestRevision(NestRevision nestRevision) async {
    final db = await _dbHelper.database;
    int? id = await db?.insert(
      'nest_revisions',
      nestRevision.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (id == null) {
      if (kDebugMode) {
        print('Failed to insert nest revision: ID is null');
      }
      return;
    }
    nestRevision.id = id;
  }

  // Get list of nest revisions for a nest ID
  Future<List<NestRevision>> getNestRevisionsForNest(int nestId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'nest_revisions',
      where: 'nestId = ?',
      whereArgs: [nestId],
    ) ?? [];
    return List.generate(maps.length, (i) {
      return NestRevision.fromMap(maps[i]);
    });
  }

  // Update nest revision record in the database
  Future<void> updateNestRevision(NestRevision nestRevision) async {
    final db = await _dbHelper.database;
    await db?.update(
      'nest_revisions',
      nestRevision.toMap(),
      where: 'id = ?',
      whereArgs: [nestRevision.id],
    );
  }

  // Delete nest revision from database
  Future<void> deleteNestRevision(int nestRevisionId) async {
    final db = await _dbHelper.database;
    await db?.delete('nest_revisions', where: 'id = ?', whereArgs: [nestRevisionId]);
  }
}