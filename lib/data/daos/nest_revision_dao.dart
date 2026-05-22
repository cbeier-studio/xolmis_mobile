import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../models/nest.dart';
import '../database/database_helper.dart';


class NestRevisionDao {
  final DatabaseHelper _dbHelper;

  NestRevisionDao(this._dbHelper);

  /// Inserts a new [NestRevision] record into the database.
  ///
  /// Uses [ConflictAlgorithm.replace] to handle duplicate entries.
  /// Sets [nestRevision.id] with the generated row ID upon success.
  /// Logs a debug message and returns early if the generated ID is `null`.
  Future<void> insertNestRevision(NestRevision nestRevision) async {
    final db = await _dbHelper.database;
    int? id = await db?.insert(
      'nest_revisions',
      nestRevision.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (id == null) {
      debugPrint('Failed to insert nest revision: ID is null');
      return;
    }
    nestRevision.id = id;
  }

  /// Returns all [NestRevision] records associated with the given [nestId].
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

  /// Updates the database record for the given [nestRevision] using its [NestRevision.id].
  Future<void> updateNestRevision(NestRevision nestRevision) async {
    final db = await _dbHelper.database;
    await db?.update(
      'nest_revisions',
      nestRevision.toMap(),
      where: 'id = ?',
      whereArgs: [nestRevision.id],
    );
  }

  /// Deletes the [NestRevision] record identified by [nestRevisionId] from the database.
  Future<void> deleteNestRevision(int nestRevisionId) async {
    final db = await _dbHelper.database;
    await db?.delete('nest_revisions', where: 'id = ?', whereArgs: [nestRevisionId]);
  }
}