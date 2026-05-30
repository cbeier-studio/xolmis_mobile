import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../core/core_consts.dart';
import '../../utils/predefined_tags.dart';

/// Centralized SQLite access point responsible for opening, creating,
/// upgrading, and maintaining the local database.
class DatabaseHelper {
  /// Singleton instance used across the app.
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _kLastVacuumRunAtKey = 'lastVacuumRunAt';
  static const Duration _vacuumInterval = Duration(days: 30);
  static final Random _random = Random();

  factory DatabaseHelper() => instance;

  DatabaseHelper._internal();

  static Database? _database;

  /// Returns the initialized database, creating it on first access.
  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await initDatabase();
    return _database;
  }

  /// Opens the app database file and wires creation, migration, and setup hooks.
  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'xolmis_database.db');
    return await openDatabase(
      path,
      version: 27,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
      onConfigure: (db) {
        // Turn on SQLite foreign keys (disabled by default)
        db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  }

  /// Creates all tables and indexes for a fresh database.
  Future<void> _createTables(Database db, int version) async {
    db.execute('''
        CREATE TABLE inventories(
          id TEXT PRIMARY KEY, 
          type INTEGER, 
          duration INTEGER, 
          maxSpecies INTEGER, 
          isPaused INTEGER, 
          isFinished INTEGER, 
          elapsedTime REAL, 
          startTime TEXT, 
          endTime TEXT, 
          startLongitude REAL, 
          startLatitude REAL, 
          endLongitude REAL, 
          endLatitude REAL,
          currentInterval INTEGER,
          intervalsWithoutNewSpecies INTEGER,
          currentIntervalSpeciesCount INTEGER,
          totalPausedTimeInSeconds REAL,
          pauseStartTime TEXT,
          localityName TEXT,
          totalObservers INTEGER,
          observer TEXT,
          notes TEXT,
          isDiscarded INTEGER
        )
      ''');
    db.execute('''
        CREATE TABLE species(
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          inventoryId TEXT NOT NULL, 
          name TEXT, 
          isOutOfInventory INTEGER, 
          count INTEGER, 
          distance REAL,
          flightHeight REAL,
          flightDirection TEXT,
          notes TEXT, 
          sampleTime TEXT,
          FOREIGN KEY (inventoryId) REFERENCES inventories(id) ON DELETE CASCADE 
        )
      ''');
    db.execute('''
        CREATE TABLE vegetation (
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            inventoryId TEXT NOT NULL, 
            sampleTime TEXT NOT NULL, 
            longitude REAL, 
            latitude REAL, 
            herbsProportion INTEGER, 
            herbsDistribution INTEGER, 
            herbsHeight INTEGER, 
            shrubsProportion INTEGER, 
            shrubsDistribution INTEGER, 
            shrubsHeight INTEGER, 
            treesProportion INTEGER, 
            treesDistribution INTEGER, 
            treesHeight INTEGER, 
            notes TEXT, 
            FOREIGN KEY (inventoryId) REFERENCES inventories(id) ON DELETE CASCADE 
        )
      ''');
    db.execute('''
        CREATE TABLE weather (
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            inventoryId INTEGER NOT NULL, 
            sampleTime TEXT NOT NULL, 
            cloudCover INTEGER, 
            precipitation INTEGER, 
            temperature REAL, 
            windSpeed INTEGER, 
            windDirection TEXT,
            atmosphericPressure REAL,
            relativeHumidity REAL,
            FOREIGN KEY (inventoryId) REFERENCES inventories(id) ON DELETE CASCADE 
        )
      ''');
    db.execute('''
        CREATE TABLE nests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fieldNumber TEXT,
          speciesName TEXT,
          localityName TEXT,
          longitude REAL,
          latitude REAL,
          support TEXT,
          heightAboveGround REAL,
          foundTime TEXT,
          lastTime TEXT,
          observer TEXT,
          nestFate INTEGER,
          male TEXT,
          female TEXT,
          helpers TEXT,
          isActive INTEGER
        )
      ''');
    db.execute('''
        CREATE TABLE eggs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nestId INTEGER,
          sampleTime TEXT,
          fieldNumber TEXT,
          eggShape INTEGER,
          width REAL,
          length REAL,
          mass REAL,
          speciesName TEXT,
          FOREIGN KEY (nestId) REFERENCES nests(id) ON DELETE CASCADE
        )
      ''');
    db.execute('''
        CREATE TABLE nest_revisions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nestId INTEGER,
          sampleTime TEXT,
          nestStatus INTEGER,
          nestStage INTEGER,
          eggsHost INTEGER,
          nestlingsHost INTEGER,
          eggsParasite INTEGER,
          nestlingsParasite INTEGER,
          hasPhilornisLarvae INTEGER,
          notes TEXT,
          FOREIGN KEY (nestId) REFERENCES nests(id) ON DELETE CASCADE
        )
      ''');
    db.execute('''
        CREATE TABLE specimens (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sampleTime TEXT,
          fieldNumber TEXT,
          type INTEGER,
          longitude REAL,
          latitude REAL,
          locality TEXT,
          speciesName TEXT,
          observer TEXT,
          notes TEXT,
          isPending INTEGER DEFAULT 1
        )
      ''');
    db.execute('''
        CREATE TABLE pois (
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            speciesId INTEGER NOT NULL, 
            sampleTime TEXT, 
            longitude REAL NOT NULL, 
            latitude REAL NOT NULL, 
            notes TEXT, 
            FOREIGN KEY (speciesId) REFERENCES species(id) ON DELETE CASCADE 
        )
      ''');
    db.execute('''
      CREATE TABLE images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        imagePath TEXT NOT NULL,
        notes TEXT,
        vegetationId INTEGER,
        eggId INTEGER,
        specimenId INTEGER,
        nestRevisionId INTEGER,
        FOREIGN KEY (vegetationId) REFERENCES vegetation(id) ON DELETE CASCADE,
        FOREIGN KEY (eggId) REFERENCES eggs(id) ON DELETE CASCADE,
        FOREIGN KEY (specimenId) REFERENCES specimens(id) ON DELETE CASCADE,
        FOREIGN KEY (nestRevisionId) REFERENCES nest_revisions(id) ON DELETE CASCADE
      )
    ''');
    db.execute('''
      CREATE TABLE field_journal (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        notes TEXT,
        creationDate TEXT,
        lastModifiedDate TEXT,
        observer TEXT
      )
    ''');
    db.execute('''
      CREATE TABLE predefined_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        colorIndex INTEGER NOT NULL,
        isCustom INTEGER DEFAULT 0
      )
    ''');
    db.execute('''
      CREATE TABLE journal_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        journalId INTEGER NOT NULL,
        tagId INTEGER NOT NULL,
        FOREIGN KEY (journalId) REFERENCES field_journal(id) ON DELETE CASCADE,
        FOREIGN KEY (tagId) REFERENCES predefined_tags(id) ON DELETE CASCADE,
        UNIQUE(journalId, tagId)
      )
    ''');

    await _seedPredefinedTags(db);
    _createPerformanceIndexes(db);
    _createTagIndexes(db);

    debugPrint('Database created with version $version');
  }

  /// Inserts the app's default predefined tags without duplicating existing rows.
  Future<void> _seedPredefinedTags(Database db) async {
    final batch = db.batch();
    final languageCode = ui.PlatformDispatcher.instance.locale.languageCode;
    final availableColorIndices = List<int>.generate(kJournalTagColors.length, (index) => index)..shuffle(_random);

    final tagNames = localizedPredefinedTagNames(languageCode);
    for (var i = 0; i < tagNames.length; i++) {
      batch.insert('predefined_tags', {
        'name': tagNames[i],
        'colorIndex': availableColorIndices[i % availableColorIndices.length],
        'isCustom': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch.commit(noResult: true);
  }

  Future<void> _migrateTagsToReferenceModel(Database db) async {
    // Add metadata columns to predefined_tags if they do not exist.
    final predefinedColumns = await db.rawQuery('PRAGMA table_info(predefined_tags)');
    final predefinedColumnNames = predefinedColumns.map((c) => c['name'] as String).toSet();

    if (!predefinedColumnNames.contains('colorIndex')) {
      await db.execute('ALTER TABLE predefined_tags ADD COLUMN colorIndex INTEGER');
    }
    if (!predefinedColumnNames.contains('isCustom')) {
      await db.execute('ALTER TABLE predefined_tags ADD COLUMN isCustom INTEGER DEFAULT 0');
    }

    // Fill missing colors/custom flags for predefined tags.
    final predefinedRows = await db.query('predefined_tags', columns: ['id', 'colorIndex', 'isCustom']);
    for (final row in predefinedRows) {
      if (row['colorIndex'] == null) {
        await db.update(
          'predefined_tags',
          {'colorIndex': _random.nextInt(kJournalTagColors.length), 'isCustom': (row['isCustom'] as int?) ?? 0},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }

    final journalColumns = await db.rawQuery('PRAGMA table_info(journal_tags)');
    final journalColumnNames = journalColumns.map((c) => c['name'] as String).toSet();

    if (!journalColumnNames.contains('tagId')) {
      await db.execute('ALTER TABLE journal_tags ADD COLUMN tagId INTEGER');
    }

    // Nothing else to migrate if journal_tags already stores only tag references.
    if (!journalColumnNames.contains('name') && journalColumnNames.contains('tagId')) {
      _createTagIndexes(db);
      return;
    }

    // Ensure each journal tag name exists in predefined_tags and capture the tag ID.
    final journalRows = await db.rawQuery('SELECT id, name, colorIndex, isCustom FROM journal_tags');

    for (final row in journalRows) {
      final rawName = row['name'] as String?;
      if (rawName == null || rawName.trim().isEmpty) {
        continue;
      }

      final normalizedName = rawName.trim();
      final existing = await db.query(
        'predefined_tags',
        columns: ['id'],
        where: 'LOWER(name) = ?',
        whereArgs: [normalizedName.toLowerCase()],
        limit: 1,
      );

      final tagId =
          existing.isNotEmpty
              ? existing.first['id'] as int
              : await db.insert('predefined_tags', {
                'name': normalizedName,
                'colorIndex': (row['colorIndex'] as int?) ?? _random.nextInt(kJournalTagColors.length),
                'isCustom': (row['isCustom'] as int?) ?? 1,
              });

      await db.update('journal_tags', {'tagId': tagId}, where: 'id = ?', whereArgs: [row['id']]);
    }

    // Recreate journal_tags to enforce the new FK/reference model.
    await db.execute('ALTER TABLE journal_tags RENAME TO journal_tags_old');
    await db.execute('''
      CREATE TABLE journal_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        journalId INTEGER NOT NULL,
        tagId INTEGER NOT NULL,
        FOREIGN KEY (journalId) REFERENCES field_journal(id) ON DELETE CASCADE,
        FOREIGN KEY (tagId) REFERENCES predefined_tags(id) ON DELETE CASCADE,
        UNIQUE(journalId, tagId)
      )
    ''');
    await db.execute('''
      INSERT INTO journal_tags (id, journalId, tagId)
      SELECT id, journalId, tagId
      FROM journal_tags_old
      WHERE tagId IS NOT NULL
    ''');
    await db.execute('DROP TABLE journal_tags_old');
    _createTagIndexes(db);
  }

  /// Creates indexes that speed up common filters, joins, and sorting.
  void _createPerformanceIndexes(Database db) {
    db.execute('CREATE INDEX IF NOT EXISTS idx_species_name ON species(name)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_inventories_is_finished ON inventories(isFinished)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_species_is_out_of_inventory ON species(isOutOfInventory)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_nests_found_time ON nests(foundTime DESC)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_nests_species_name ON nests(speciesName)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_nests_field_number ON nests(fieldNumber)');
  }

  /// Creates indexes specific to journal tag tables.
  void _createTagIndexes(Database db) {
    db.execute('CREATE INDEX IF NOT EXISTS idx_journal_tags_journal_id ON journal_tags(journalId)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_journal_tags_tag_id ON journal_tags(tagId)');
    db.execute('CREATE INDEX IF NOT EXISTS idx_predefined_tags_name ON predefined_tags(name)');
  }

  /// Applies incremental schema migrations between database versions.
  void _upgradeTables(Database db, int oldVersion, int newVersion) async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
    if (oldVersion < 2) {
      db.execute('ALTER TABLE inventories ADD COLUMN maxSpecies INTEGER');
    }
    if (oldVersion < 3) {
      db.execute('''
          CREATE TABLE weather (
              id INTEGER PRIMARY KEY AUTOINCREMENT, 
              inventoryId INTEGER NOT NULL, 
              sampleTime TEXT NOT NULL, 
              cloudCover INTEGER, 
              precipitation INTEGER, 
              temperature REAL, 
              windSpeed INTEGER, 
              FOREIGN KEY (inventoryId) REFERENCES inventories(id) ON DELETE CASCADE
          )
      ''');
    }
    if (oldVersion < 4) {
      db.execute('''
        CREATE TABLE nests (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fieldNumber TEXT,
          speciesName TEXT,
          localityName TEXT,
          longitude REAL,
          latitude REAL,
          support TEXT,
          heightAboveGround REAL,
          foundTime TEXT,
          lastTime TEXT,
          nestFate INTEGER,
          male TEXT,
          female TEXT,
          helpers TEXT
        )
      ''');
      db.execute('''
        CREATE TABLE eggs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nestId INTEGER,
          sampleTime TEXT,
          fieldNumber TEXT,
          eggShape INTEGER,
          width REAL,
          length REAL,
          mass REAL,
          speciesName TEXT,
          FOREIGN KEY (nestId) REFERENCES nests(id) ON DELETE CASCADE
        )
      ''');
      db.execute('''
        CREATE TABLE nest_revisions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nestId INTEGER,
          sampleTime TEXT,
          nestStatus INTEGER,
          nestStage INTEGER,
          eggsHost INTEGER,
          nestlingsHost INTEGER,
          eggsParasite INTEGER,
          nestlingsParasite INTEGER,
          hasPhilornisLarvae INTEGER,
          notes TEXT,
          FOREIGN KEY (nestId) REFERENCES nests(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 5) {
      db.execute('ALTER TABLE nests ADD COLUMN isActive INTEGER');
    }
    if (oldVersion < 6) {
      db.execute('''
        CREATE TABLE specimens (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sampleTime TEXT,
          fieldNumber TEXT,
          type INTEGER,
          longitude REAL,
          latitude REAL,
          locality TEXT,
          speciesName TEXT,
          notes TEXT
        )
      ''');
    }
    if (oldVersion < 7) {
      db.execute('''
        CREATE TABLE images (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          imagePath TEXT NOT NULL,
          notes TEXT,
          vegetationId INTEGER,
          eggId INTEGER,
          specimenId INTEGER,
          nestRevisionId INTEGER,
          FOREIGN KEY (vegetationId) REFERENCES vegetation(id) ON DELETE CASCADE,
          FOREIGN KEY (eggId) REFERENCES eggs(id) ON DELETE CASCADE,
          FOREIGN KEY (specimenId) REFERENCES specimens(id) ON DELETE CASCADE,
          FOREIGN KEY (nestRevisionId) REFERENCES nest_revisions(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 8) {
      db.execute('ALTER TABLE species ADD COLUMN notes TEXT');
    }
    if (oldVersion < 9) {
      db.execute('ALTER TABLE inventories ADD COLUMN currentInterval INTEGER');
    }
    if (oldVersion < 10) {
      db.execute('ALTER TABLE inventories ADD COLUMN intervalsWithoutNewSpecies INTEGER');
      db.execute('ALTER TABLE inventories ADD COLUMN currentIntervalSpeciesCount INTEGER');
    }
    if (oldVersion < 11) {
      db.execute('ALTER TABLE species ADD COLUMN sampleTime TEXT');
    }
    if (oldVersion < 12) {
      db.execute('''
        CREATE TABLE field_journal (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          notes TEXT,
          creationDate TEXT,
          lastModifiedDate TEXT
        )
      ''');
    }
    if (oldVersion < 13) {
      db.execute('ALTER TABLE pois ADD COLUMN sampleTime TEXT');
    }
    if (oldVersion < 14) {
      db.execute('ALTER TABLE specimens ADD COLUMN isPending INTEGER DEFAULT 1');
    }
    if (oldVersion < 15) {
      db.execute('ALTER TABLE inventories ADD COLUMN localityName TEXT');
    }
    if (oldVersion < 16) {
      db.execute('ALTER TABLE pois ADD COLUMN notes TEXT');
    }
    if (oldVersion < 17) {
      db.execute('ALTER TABLE inventories ADD COLUMN notes TEXT');
      db.execute('ALTER TABLE inventories ADD COLUMN isDiscarded INTEGER');
    }
    if (oldVersion < 18) {
      db.execute('ALTER TABLE inventories ADD COLUMN totalObservers INTEGER');
      db.execute('ALTER TABLE weather ADD COLUMN atmosphericPressure REAL');
      db.execute('ALTER TABLE weather ADD COLUMN relativeHumidity REAL');
    }
    if (oldVersion < 19) {
      db.execute('ALTER TABLE species ADD COLUMN distance REAL');
      db.execute('ALTER TABLE species ADD COLUMN flightHeight REAL');
      db.execute('ALTER TABLE species ADD COLUMN flightDirection TEXT');
    }
    if (oldVersion < 20) {
      db.execute('ALTER TABLE weather ADD COLUMN windDirection TEXT');
    }
    if (oldVersion < 21) {
      db.execute('ALTER TABLE inventories ADD COLUMN totalPausedTimeInSeconds REAL');
      db.execute('ALTER TABLE inventories ADD COLUMN pauseStartTime TEXT');
    }
    if (oldVersion < 22) {
      db.execute('ALTER TABLE inventories ADD COLUMN observer TEXT');
      final observerAbbrev = prefs.getString('observerAcronym') ?? '';
      db.update('inventories', {'observer': observerAbbrev}, where: 'observer IS NULL');
      db.execute('ALTER TABLE nests ADD COLUMN observer TEXT');
      db.update('nests', {'observer': observerAbbrev}, where: 'observer IS NULL');
      db.execute('ALTER TABLE specimens ADD COLUMN observer TEXT');
      db.update('specimens', {'observer': observerAbbrev}, where: 'observer IS NULL');
      db.execute('ALTER TABLE field_journal ADD COLUMN observer TEXT');
      db.update('field_journal', {'observer': observerAbbrev}, where: 'observer IS NULL');
    }
    if (oldVersion < 23) {
      _createPerformanceIndexes(db);
    }
    if (oldVersion < 24) {
      // SQLite cannot drop NOT NULL constraints in-place, so recreate table.
      db.execute('ALTER TABLE field_journal RENAME TO field_journal_old');
      db.execute('''
        CREATE TABLE field_journal (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          notes TEXT,
          creationDate TEXT,
          lastModifiedDate TEXT,
          observer TEXT
        )
      ''');
      db.execute('''
        INSERT INTO field_journal (id, title, notes, creationDate, lastModifiedDate, observer)
        SELECT id, title, notes, creationDate, lastModifiedDate, observer
        FROM field_journal_old
      ''');
      db.execute('DROP TABLE field_journal_old');
    }
    if (oldVersion < 25) {
      db.execute('''
        CREATE TABLE predefined_tags (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          colorIndex INTEGER NOT NULL,
          isCustom INTEGER DEFAULT 0
        )
      ''');
      db.execute('''
        CREATE TABLE journal_tags (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          journalId INTEGER NOT NULL,
          tagId INTEGER NOT NULL,
          FOREIGN KEY (journalId) REFERENCES field_journal(id) ON DELETE CASCADE,
          FOREIGN KEY (tagId) REFERENCES predefined_tags(id) ON DELETE CASCADE,
          UNIQUE(journalId, tagId)
        )
      ''');
      _createTagIndexes(db);
    }
    if (oldVersion < 26) {
      await _seedPredefinedTags(db);
    }
    if (oldVersion < 27) {
      await _migrateTagsToReferenceModel(db);
      await _seedPredefinedTags(db);
    }
  }

  /// Runs `VACUUM` at most once per month to keep database file size healthy.
  Future<void> runMonthlyVacuumIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRunAtRaw = prefs.getString(_kLastVacuumRunAtKey);
      final now = DateTime.now();

      if (lastRunAtRaw != null) {
        final lastRunAt = DateTime.tryParse(lastRunAtRaw);
        if (lastRunAt != null && now.difference(lastRunAt) < _vacuumInterval) {
          debugPrint('[DB_MAINTENANCE] VACUUM skipped. Last run at: $lastRunAtRaw');
          return;
        }
      }

      final db = await database;
      if (db == null) {
        debugPrint('[DB_MAINTENANCE] VACUUM skipped. Database is not available.');
        return;
      }

      debugPrint('[DB_MAINTENANCE] Starting VACUUM...');
      await db.execute('VACUUM');
      await prefs.setString(_kLastVacuumRunAtKey, now.toIso8601String());
      debugPrint('[DB_MAINTENANCE] VACUUM finished successfully.');
    } catch (e, s) {
      debugPrint('[DB_MAINTENANCE] VACUUM failed: $e\n$s');
    }
  }

  /// Closes the opened database connection if available.
  Future<void> closeDatabase() async {
    final db = await database;
    await db?.close();
  }
}
