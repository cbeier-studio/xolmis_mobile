import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/journal.dart';
import '../database_helper.dart';

class FieldJournalDao {
  final DatabaseHelper _dbHelper;

  FieldJournalDao(this._dbHelper);

  // Insert field journal entry into database
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
      if (kDebugMode) {
        print('Database error: $e');
      }
      throw DatabaseInsertException('Failed to insert field journal entry: ${e.toString()}');
    } catch (e) {
      // Handle other exceptions
      if (kDebugMode) {
        print('Generic error: $e');
      }
      throw Exception('Failed to insert field journal entry: ${e.toString()}');
    }
  }

  // Get list of all field journal entries
  Future<List<FieldJournal>> getJournalEntries() async {
    final db = await _dbHelper.database;
    try {
      final List<Map<String, dynamic>> maps = await db?.query('field_journal') ?? [];
      return List.generate(maps.length, (i) {
        return FieldJournal.fromMap(maps[i]);
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading field journal entries: $e');
      }
      // Handle the error, e.g.: return an empty list or rethrow exception
      return []; // Or rethrow;
    }
  }

  // Find and get a field journal entry by ID
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

  // Update field journal entry in the database
  Future<int?> updateJournalEntry(FieldJournal journal) async {
    final db = await _dbHelper.database;
    return await db?.update(
      'field_journal',
      journal.toMap(),
      where: 'id = ?',
      whereArgs: [journal.id],
    );
  }

  // Delete field journal entry from database
  Future<void> deleteJournalEntry(int entryId) async {
    final db = await _dbHelper.database;
    await db?.delete('field_journal', where: 'id = ?', whereArgs: [entryId]);
  }
}

class DatabaseInsertException implements Exception {
  final String message;

  DatabaseInsertException(this.message);

  @override
  String toString() => 'DatabaseInsertException: $message';
}