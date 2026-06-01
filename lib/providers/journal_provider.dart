import 'package:flutter/material.dart';

import '../data/models/journal.dart';
import '../data/daos/journal_dao.dart';

/// Manages field journal entries and exposes them to the widget tree.
class FieldJournalProvider with ChangeNotifier {
  final FieldJournalDao _journalDao;

  FieldJournalProvider(this._journalDao);

  List<FieldJournal> _journalEntries = [];

  /// The field journal entries currently loaded in memory.
  List<FieldJournal> get journalEntries => _journalEntries;

  /// The number of loaded journal entries.
  int get entriesCount => journalEntries.length;

  /// Notifies listeners without changing provider state.
  void refreshState() {
    notifyListeners();
  }

  /// Loads all field journal entries from persistent storage.
  Future<void> fetchJournalEntries() async {
    _journalEntries = await _journalDao.getJournalEntries();
    notifyListeners();
  }

  /// Returns a single journal entry identified by [entryId].
  Future<FieldJournal> getJournalEntryById(int entryId) async {
    return await _journalDao.getJournalEntryById(entryId);
  }

  /// Persists [journalEntry] and appends it to the in-memory list.
  Future<void> addJournalEntry(FieldJournal journalEntry) async {
    await _journalDao.insertJournalEntry(journalEntry);
    _journalEntries.add(journalEntry);
    notifyListeners();
  }

   /// Detects which journal entries have conflicting titles in the database.
   ///
   /// Returns a set of titles (in lowercase) that already exist locally.
   Future<Set<String>> _detectConflictingTitles(List<FieldJournal> journalEntries) async {
     final conflictingTitles = <String>{};
     for (final entry in journalEntries) {
       final exists = await _journalDao.journalTitleExists(entry.title);
       if (exists) {
         conflictingTitles.add(entry.title!.toLowerCase());
       }
     }
     return conflictingTitles;
   }

   /// Imports multiple journal entries with conflict resolution.
   ///
   /// This method checks for existing entries with matching titles and either
   /// updates or skips them based on the [updateExisting] flag. Each import
   /// transaction is handled via [FieldJournalDao.importJournal], which ensures
   /// consistency and assigns local auto-incremented IDs.
   ///
   /// Returns a map with counts for 'newCount', 'updatedCount', 'skippedCount',
   /// and a list of 'errors' for any failed imports.
   Future<Map<String, dynamic>> importJournalEntries(
     List<FieldJournal> journalEntries, {
     bool updateExisting = true,
   }) async {
     var newCount = 0;
     var updatedCount = 0;
     var skippedCount = 0;
     final errors = <String>[];

     // Detect conflicting titles first
     final conflictingTitles = await _detectConflictingTitles(journalEntries);

     for (final journalEntry in journalEntries) {
       try {
         final isExisting = conflictingTitles.contains(journalEntry.title?.toLowerCase());
         if (isExisting && !updateExisting) {
           skippedCount++;
           continue;
         }

          final success = await _journalDao.importJournal(
            journalEntry,
            updateExisting: updateExisting,
          );
          if (success) {
            if (isExisting) {
              updatedCount++;
            } else {
              newCount++;
            }
          } else {
            final identifier =
                journalEntry.title != null && journalEntry.title!.isNotEmpty
                    ? journalEntry.title
                    : (journalEntry.id?.toString() ?? 'unknown');
            errors.add('Failed to import field journal "$identifier": Unknown error');
          }
        } catch (error) {
          final identifier =
              journalEntry.title != null && journalEntry.title!.isNotEmpty
                  ? journalEntry.title
                  : (journalEntry.id?.toString() ?? 'unknown');
         final message = 'Failed to import field journal "$identifier": $error';
         debugPrint(message);
         errors.add(message);
       }
     }

     await fetchJournalEntries();
     return {
       'newCount': newCount,
       'updatedCount': updatedCount,
       'skippedCount': skippedCount,
       'errors': errors,
     };
   }

  /// Updates an existing journal entry in storage and in memory.
  Future<void> updateJournalEntry(FieldJournal journalEntry) async {
    await _journalDao.updateJournalEntry(journalEntry);

    final index = _journalEntries.indexWhere((n) => n.id == journalEntry.id);
    if (index != -1) {
      _journalEntries[index] = journalEntry;
      notifyListeners();
    } else {
      debugPrint('Field journal entry not found in the list');
    }
  }

  /// Deletes [journalEntry] from storage and removes it from the cache.
  ///
  /// Throws an [ArgumentError] when the entry has no valid identifier.
  Future<void> removeJournalEntry(FieldJournal journalEntry) async {
    if (journalEntry.id == null || journalEntry.id! <= 0) {
      throw ArgumentError('Invalid field journal entry ID: ${journalEntry.id}');
    }

    await _journalDao.deleteJournalEntry(journalEntry.id!);
    _journalEntries.removeWhere((item) => item.id == journalEntry.id);
    notifyListeners();
  }

   /// Returns `true` if a journal entry with the given [title] already exists
   /// in the database (case-insensitive comparison).
   Future<bool> journalTitleExists(String? title) async {
     if (title == null || title.trim().isEmpty) {
       return false;
     }
     return await _journalDao.journalTitleExists(title);
   }
}