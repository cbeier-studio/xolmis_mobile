import '../daos/journal_dao.dart';
import '../../models/journal.dart';

class FieldJournalRepository {
  final FieldJournalDao _journalDao;

  FieldJournalRepository(this._journalDao);

  Future<int> insertJournalEntry(FieldJournal journalEntry) {
    return _journalDao.insertJournalEntry(journalEntry);
  }

  Future<List<FieldJournal>> getJournalEntries() {
    return _journalDao.getJournalEntries();
  }

  Future<FieldJournal> getJournalEntryById(int entryId) {
    return _journalDao.getJournalEntryById(entryId);
  }

  Future<int?> updateJournalEntry(FieldJournal journalEntry) {
    return _journalDao.updateJournalEntry(journalEntry);
  }

  Future<void> deleteJournalEntry(int entryId) {
    return _journalDao.deleteJournalEntry(entryId);
  }

}