import 'package:sqflite/sqflite.dart';

import '../../models/nest.dart';
import '../database_helper.dart';


class NestRevisionDao {
  final DatabaseHelper _dbHelper;

  NestRevisionDao(this._dbHelper);

  Future<void> insertNestRevision(NestRevision nestRevision) async {
    final db = await _dbHelper.database;
    int? id = await db?.insert(
      'nest_revisions',
      nestRevision.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (id == null) {
      print('Failed to insert nest revision: ID is null');
      return;
    }
    nestRevision.id = id;
  }

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

  Future<void> deleteNestRevision(int nestRevisionId) async {
    final db = await _dbHelper.database;
    await db?.delete('nest_revisions', where: 'id = ?', whereArgs: [nestRevisionId]);
  }
}