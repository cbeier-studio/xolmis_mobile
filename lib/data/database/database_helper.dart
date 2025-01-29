import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;

    _database = await initDatabase();
    return _database;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'xolmis_database.db');
    return await openDatabase(
      path,
      version: 12, // Increase the version number
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
      onOpen: (db) {
        // Turn on SQLite foreign keys (disabled by default)
        db.execute('PRAGMA foreign_keys = ON;');
      }
    );
  }

  // Create SQLite database file and structure
  void _createTables(Database db, int version) {
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
          currentIntervalSpeciesCount INTEGER
        )
      ''');
    db.execute('''
        CREATE TABLE species(
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          inventoryId TEXT NOT NULL, 
          name TEXT, 
          isOutOfInventory INTEGER, 
          count INTEGER, 
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
          notes TEXT
        )
      ''');
    db.execute('''
        CREATE TABLE pois (
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            speciesId INTEGER NOT NULL, 
            longitude REAL NOT NULL, 
            latitude REAL NOT NULL, 
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
        title TEXT NOT NULL,
        notes TEXT,
        creationDate TEXT,
        lastModifiedDate TEXT
      )
    ''');
  }

  // Update SQLite database structure based on DB version
  void _upgradeTables(Database db, int oldVersion, int newVersion) {
    if (oldVersion < 2) {
      db.execute(
        'ALTER TABLE inventories ADD COLUMN maxSpecies INTEGER',
      );
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
      db.execute(
        'ALTER TABLE nests ADD COLUMN isActive INTEGER',
      );
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
      db.execute(
        'ALTER TABLE species ADD COLUMN notes TEXT',
      );
    }
    if (oldVersion < 9) {
      db.execute(
        'ALTER TABLE inventories ADD COLUMN currentInterval INTEGER',
      );
    }
    if (oldVersion < 10) {
      db.execute(
        'ALTER TABLE inventories ADD COLUMN intervalsWithoutNewSpecies INTEGER',
      );
      db.execute(
        'ALTER TABLE inventories ADD COLUMN currentIntervalSpeciesCount INTEGER',
      );
    }
    if (oldVersion < 11) {
      db.execute(
        'ALTER TABLE species ADD COLUMN sampleTime TEXT',
      );
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
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db?.close();
  }

}

