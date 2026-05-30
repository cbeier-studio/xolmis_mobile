import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../models/predefined_tag.dart';
import '../models/tag.dart';
import '../database/database_helper.dart';

/// Provides database access for journal tags.
class TagDao {
  final DatabaseHelper _dbHelper;

  TagDao(this._dbHelper);

  /// Finds or creates a tag definition in `predefined_tags` and returns its ID.
  Future<int> upsertTagDefinition(JournalTag tag, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _dbHelper.database;
    if (db == null) {
      throw Exception('Database is not available');
    }

    final existing = await db.query(
      'predefined_tags',
      columns: ['id'],
      where: 'LOWER(name) = ?',
      whereArgs: [tag.name.trim().toLowerCase()],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return await db.insert('predefined_tags', {
      'name': tag.name.trim(),
      'colorIndex': tag.colorIndex,
      'isCustom': tag.isCustom ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Inserts a new [JournalTag] into the database.
  ///
  /// Sets [tag.id] with the generated row ID upon success.
  Future<int> insertTag(JournalTag tag) async {
    final db = await _dbHelper.database;
    if (db == null) {
      throw Exception('Database is not available');
    }
    try {
      final tagId = await upsertTagDefinition(tag, executor: db);
      int id = await db.insert('journal_tags', {
        'journalId': tag.journalId,
        'tagId': tagId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      tag.id = id;
      return id;
    } catch (e) {
      debugPrint('Error inserting tag: $e');
      throw Exception('Failed to insert tag: ${e.toString()}');
    }
  }

  /// Returns all tags associated with the given [journalId].
  ///
  /// Returns an empty list if an error occurs.
  Future<List<JournalTag>> getTagsByJournalId(int journalId) async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps =
          await db?.rawQuery(
            '''
        SELECT
          jt.id,
          jt.journalId,
          jt.tagId,
          pt.name,
          pt.colorIndex,
          pt.isCustom
        FROM journal_tags jt
        INNER JOIN predefined_tags pt ON pt.id = jt.tagId
        WHERE jt.journalId = ?
        ORDER BY pt.name COLLATE NOCASE ASC
      ''',
            [journalId],
          ) ??
          [];
      return List.generate(maps.length, (i) {
        return JournalTag.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error loading tags: $e');
      return [];
    }
  }

  /// Inserts multiple tags in a single transaction.
  ///
  /// All tags must have the same [journalId].
  Future<void> insertMultipleTags(List<JournalTag> tags) async {
    final db = await _dbHelper.database;
    if (db == null) return;

    try {
      await db.transaction((txn) async {
        for (var tag in tags) {
          final tagId = await upsertTagDefinition(tag, executor: txn);
          await txn.insert('journal_tags', {
            'journalId': tag.journalId,
            'tagId': tagId,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    } catch (e) {
      debugPrint('Error inserting multiple tags: $e');
      throw Exception('Failed to insert multiple tags: ${e.toString()}');
    }
  }

  /// Deletes all tags associated with the given [journalId].
  Future<void> deleteTagsByJournalId(int journalId) async {
    final db = await _dbHelper.database;
    try {
      await db?.delete('journal_tags', where: 'journalId = ?', whereArgs: [journalId]);
    } catch (e) {
      debugPrint('Error deleting tags: $e');
      throw Exception('Failed to delete tags: ${e.toString()}');
    }
  }

  /// Deletes a specific tag by [tagId].
  Future<void> deleteTagById(int tagId) async {
    final db = await _dbHelper.database;
    try {
      await db?.delete('journal_tags', where: 'id = ?', whereArgs: [tagId]);
    } catch (e) {
      debugPrint('Error deleting tag: $e');
      throw Exception('Failed to delete tag: ${e.toString()}');
    }
  }

  /// Returns all unique tag names used across all journal entries.
  ///
  /// Useful for autocomplete suggestions.
  Future<List<String>> getAllTagNames() async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps =
          await db?.rawQuery('SELECT name FROM predefined_tags ORDER BY name COLLATE NOCASE ASC') ?? [];
      return maps.map((m) => m['name'] as String).toList();
    } catch (e) {
      debugPrint('Error loading tag names: $e');
      return [];
    }
  }

  /// Inserts a predefined tag if it doesn't already exist.
  Future<void> insertPredefinedTag(String name) async {
    final db = await _dbHelper.database;
    try {
      await db?.insert('predefined_tags', {
        'name': name.trim(),
        'colorIndex': 0,
        'isCustom': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      debugPrint('Error inserting predefined tag: $e');
    }
  }

  /// Returns all predefined tag names.
  Future<List<String>> getPredefinedTags() async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps =
          await db?.query(
            'predefined_tags',
            columns: ['name'],
            where: 'isCustom = 0',
            orderBy: 'name COLLATE NOCASE ASC',
          ) ??
          [];
      return maps.map((m) => m['name'] as String).toList();
    } catch (e) {
      debugPrint('Error loading predefined tags: $e');
      return [];
    }
  }

  /// Returns all tag definitions (predefined and custom) with colors.
  Future<List<PredefinedTag>> getAllTagDefinitions() async {
    final db = await _dbHelper.database;
    try {
      final maps = await db?.query('predefined_tags', orderBy: 'name COLLATE NOCASE ASC') ?? <Map<String, dynamic>>[];
      return maps.map(PredefinedTag.fromMap).toList();
    } catch (e) {
      debugPrint('Error loading tag definitions: $e');
      return [];
    }
  }

  /// Inserts a new custom tag definition and returns its row ID.
  Future<int> insertCustomTagDefinition({required String name, required int colorIndex}) async {
    final db = await _dbHelper.database;
    if (db == null) {
      throw Exception('Database is not available');
    }

    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw Exception('Tag name cannot be empty');
    }

    final existing = await db.query(
      'predefined_tags',
      columns: ['id'],
      where: 'LOWER(name) = ?',
      whereArgs: [normalizedName.toLowerCase()],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw Exception('Tag already exists');
    }

    return db.insert('predefined_tags', {
      'name': normalizedName,
      'colorIndex': colorIndex,
      'isCustom': 1,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  /// Updates the color for an existing tag definition.
  Future<void> updateTagColor({required int tagId, required int colorIndex}) async {
    final db = await _dbHelper.database;
    await db?.update('predefined_tags', {'colorIndex': colorIndex}, where: 'id = ?', whereArgs: [tagId]);
  }

  /// Deletes a custom tag definition and all journal references to it.
  Future<void> deleteCustomTagDefinition(int tagId) async {
    final db = await _dbHelper.database;
    await db?.delete('predefined_tags', where: 'id = ? AND isCustom = 1', whereArgs: [tagId]);
  }
}
