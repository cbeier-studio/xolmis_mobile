import 'package:flutter/foundation.dart';

import '../data/models/journal.dart';
import '../data/database/repositories/journal_repository.dart';
// import '../generated/l10n.dart';

class FieldJournalProvider with ChangeNotifier {
  final FieldJournalRepository _journalRepository;

  FieldJournalProvider(this._journalRepository);

  List<FieldJournal> _journalEntries = [];
  List<FieldJournal> get journalEntries => _journalEntries;

  int get entriesCount => journalEntries.length;

  // Load list of all field journal entries
  Future<void> fetchJournalEntries() async {
    _journalEntries = await _journalRepository.getJournalEntries();
    notifyListeners();
  }

  // Get field journal entry by ID
  Future<FieldJournal> getJournalEntryById(int entryId) async {
    return await _journalRepository.getJournalEntryById(entryId);
  }

  // Add field journal entry to the database and the list
  Future<void> addJournalEntry(FieldJournal journalEntry) async {
    await _journalRepository.insertJournalEntry(journalEntry);
    _journalEntries.add(journalEntry);
    notifyListeners();
  }

  // Update field journal entry in the database and the list
  Future<void> updateJournalEntry(FieldJournal journalEntry) async {
    await _journalRepository.updateJournalEntry(journalEntry);

    final index = _journalEntries.indexWhere((n) => n.id == journalEntry.id);
    if (index != -1) {
      _journalEntries[index] = journalEntry;
      notifyListeners();
    } else {
      if (kDebugMode) {
        print('Field journal entry not found in the list');
      }
    }
  }

  // Remove field journal entry from database and from list
  Future<void> removeJournalEntry(FieldJournal journalEntry) async {
    if (journalEntry.id == null || journalEntry.id! <= 0) {
      throw ArgumentError('Invalid field journal entry ID: ${journalEntry.id}');
    }

    await _journalRepository.deleteJournalEntry(journalEntry.id!);
    _journalEntries.remove(journalEntry);
    notifyListeners();
  }

}