import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/core_consts.dart';
import '../models/journal.dart';
import '../database/database_helper.dart';

class FieldJournalDao {
  final DatabaseHelper _dbHelper;

  FieldJournalDao(this._dbHelper);

  /// Inserts a new [FieldJournal] entry into the database.
  ///
  /// Uses [ConflictAlgorithm.replace] to handle duplicate entries.
  /// Sets [journal.id] with the generated row ID upon success.
  /// Throws a [DatabaseInsertException] if the generated ID is `null` or if a
  /// database error occurs, and a generic [Exception] for any other error.
  Future<int> insertJournalEntry(FieldJournal journal) async {
    final db = await _dbHelper.database;
    try {
      int? id = await db?.insert('field_journal', journal.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      if (id == null) {
        throw DatabaseInsertException('Failed to insert field journal entry: ID is null');
      }
      journal.id = id;
      return id;
    } on DatabaseException catch (e) {
      // Handle database exceptions
      debugPrint('Database error: $e');
      throw DatabaseInsertException('Failed to insert field journal entry: ${e.toString()}');
    } catch (e) {
      // Handle other exceptions
      debugPrint('Generic error: $e');
      throw Exception('Failed to insert field journal entry: ${e.toString()}');
    }
  }

  /// Returns all [FieldJournal] entries stored in the database.
  ///
  /// Returns an empty list if an error occurs.
  Future<List<FieldJournal>> getJournalEntries() async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db?.query('field_journal') ?? [];
      return List.generate(maps.length, (i) {
        return FieldJournal.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('Error loading field journal entries: $e');
      // Handle the error, e.g.: return an empty list or rethrow exception
      return []; // Or rethrow;
    }
  }

  /// Returns the [FieldJournal] entry identified by [entryId].
  ///
  /// Throws an [Exception] if no entry with the given ID is found.
  Future<FieldJournal> getJournalEntryById(int entryId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db?.query(
        'field_journal',
        where: 'id = ?',
        whereArgs: [entryId]
    ) ?? [];
    if (maps.isNotEmpty) {
      final map = maps.first;
      return FieldJournal.fromMap(map);
    } else {
      throw Exception('Field journal entry not found with ID $entryId');
    }
  }

  /// Updates the database record for the given [journal] using its [FieldJournal.id].
  ///
  /// Returns the number of rows affected.
  Future<int?> updateJournalEntry(FieldJournal journal) async {
    final db = await _dbHelper.database;
    return await db?.update(
      'field_journal',
      journal.toMap(),
      where: 'id = ?',
      whereArgs: [journal.id],
    );
  }

  /// Deletes the [FieldJournal] entry identified by [entryId] from the database.
  Future<void> deleteJournalEntry(int entryId) async {
    final db = await _dbHelper.database;
    await db?.delete('field_journal', where: 'id = ?', whereArgs: [entryId]);
  }
}
