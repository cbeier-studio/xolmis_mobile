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

  /// Imports multiple journal entries and refreshes the cached list afterward.
  ///
  /// This method is intended for JSON import flows where entries may already
  /// carry an explicit [FieldJournal.id]. It relies on the DAO's replace-on-
  /// conflict behavior and then reloads the cache to keep the in-memory state
  /// aligned with SQLite.
  ///
  /// Returns the number of entries successfully persisted.
  Future<int> importJournalEntries(List<FieldJournal> journalEntries) async {
    var importedCount = 0;

    for (final journalEntry in journalEntries) {
      try {
        await _journalDao.insertJournalEntry(journalEntry);
        importedCount++;
      } catch (error) {
        debugPrint('Error importing field journal entry: $error');
      }
    }

    await fetchJournalEntries();
    return importedCount;
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

}