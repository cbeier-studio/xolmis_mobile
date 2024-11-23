import 'package:sqflite/sqflite.dart';

import '../../models/nest.dart';
import '../database_helper.dart';


class EggDao {
  final DatabaseHelper _dbHelper;

  EggDao(this._dbHelper);

  Future<void> insertEgg(Egg egg) async {
    final db = await _dbHelper.database;
    int? id = await db?.insert(
      'eggs',
      egg.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (id == null) {
      print('Failed to insert egg: ID is null');
      return;
    }
    egg.id = id;
  }

  Future<List<Egg>> getEggsForNest(int nestId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
      'eggs',
      where: 'nestId = ?',
      whereArgs: [nestId],
    ) ?? [];
    return List.generate(maps.length, (i) {
      return Egg.fromMap(maps[i]);
    });
  }

  Future<void> deleteEgg(int eggId) async {
    final db = await _dbHelper.database;
    await db?.delete('eggs', where: 'id = ?', whereArgs: [eggId]);
  }

  Future<bool> eggFieldNumberExists(String fieldNumber) async {
    final db = await _dbHelper.database;
    final result = await db?.query(
      'eggs',
      where: 'LOWER(fieldNumber) = ?',
      whereArgs: [fieldNumber.toLowerCase()],
    );
    return result!.isNotEmpty;
  }
}