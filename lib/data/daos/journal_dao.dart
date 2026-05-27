import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/core_consts.dart';
import '../models/journal.dart';
import '../database/database_helper.dart';

/// Provides database access for field journal entries.
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

   /// Imports a [FieldJournal] into the database, optionally updating an existing
   /// entry when [FieldJournal.title] conflicts.
   ///
   /// When [updateExisting] is `false`, existing entries are left untouched
   /// and the method returns `false` for that incoming record.
   ///
   /// New imported records always receive a local auto-incremented ID, ignoring
   /// any numeric ID that may have come from another device.
   ///
   /// Sets [journal.id] with the persisted ID upon success.
   /// Returns `true` on success, or `false` if an error occurs.
   Future<bool> importJournal(
     FieldJournal journal, {
     bool updateExisting = true,
   }) async {
     final db = await _dbHelper.database;
     if (db == null) {
       return false;
     }

     try {
       return await db.transaction((txn) async {
         final journalMap = journal.toMap();
         final title = journal.title;

         if (title.isNotEmpty) {
           final existingJournalId = Sqflite.firstIntValue(
                 await txn.rawQuery(
                   'SELECT id FROM field_journal WHERE LOWER(title) = ? LIMIT 1',
                   [title.toLowerCase()],
                 ),
               );

           if (existingJournalId != null) {
             if (!updateExisting) {
               return false;
             }

             journalMap['id'] = existingJournalId;
             final updatedRows = await txn.update(
               'field_journal',
               journalMap,
               where: 'id = ?',
               whereArgs: [existingJournalId],
             );
             if (updatedRows > 0) {
               journal.id = existingJournalId;
               return true;
             }
             return false;
           }
         }

         journalMap['id'] = null;
         final insertedId = await txn.insert('field_journal', journalMap);
         if (insertedId <= 0) {
           return false;
         }
         journal.id = insertedId;
         return true;
       });
     } catch (e) {
       debugPrint('Error importing journal: $e');
       return false;
     }
   }

   /// Returns the local numeric ID for the journal entry identified by [title].
   ///
   /// Matching is case-insensitive. Returns `null` when no local journal has
   /// the provided title.
   Future<int?> getJournalIdByTitle(String title) async {
     final db = await _dbHelper.database;
     final result = await db?.query(
       'field_journal',
       columns: ['id'],
       where: 'LOWER(title) = ?',
       whereArgs: [title.toLowerCase()],
       limit: 1,
     );
     if (result == null || result.isEmpty) {
       return null;
     }
     return result.first['id'] as int?;
   }

   /// Returns `true` if a journal entry with the given [title] already exists
   /// in the database (case-insensitive comparison).
   Future<bool> journalTitleExists(String title) async {
     final db = await _dbHelper.database;
     final result = await db?.query(
       'field_journal',
       where: 'LOWER(title) = ?',
       whereArgs: [title.toLowerCase()],
     );
     return result!.isNotEmpty;
   }
}
