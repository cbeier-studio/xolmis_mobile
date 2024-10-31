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
      version: 6, // Increase the version number
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
      onOpen: (db) {
        db.execute('PRAGMA foreign_keys = ON;');
      }
    );
  }

  void _createTables(Database db, int version) {
    db.execute(
      'CREATE TABLE inventories('
          'id TEXT PRIMARY KEY, '
          'type INTEGER, '
          'duration INTEGER, '
          'maxSpecies INTEGER, '
          'isPaused INTEGER, '
          'isFinished INTEGER, '
          'elapsedTime REAL, '
          'startTime TEXT, '
          'endTime TEXT, '
          'startLongitude REAL, '
          'startLatitude REAL, '
          'endLongitude REAL, '
          'endLatitude REAL)', // Add the new columns
    );
    db.execute(
      'CREATE TABLE species('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'inventoryId TEXT NOT NULL, '
          'name TEXT, '
          'isOutOfInventory INTEGER, '
          'count INTEGER, '
          'FOREIGN KEY (inventoryId) REFERENCES inventories(id) ON DELETE CASCADE )',
    );
    db.execute(
        'CREATE TABLE vegetation ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'inventoryId TEXT NOT NULL, '
            'sampleTime TEXT NOT NULL, '
            'longitude REAL, '
            'latitude REAL, '
            'herbsProportion INTEGER, '
            'herbsDistribution INTEGER, '
            'herbsHeight INTEGER, '
            'shrubsProportion INTEGER, '
            'shrubsDistribution INTEGER, '
            'shrubsHeight INTEGER, '
            'treesProportion INTEGER, '
            'treesDistribution INTEGER, '
            'treesHeight INTEGER, '
            'notes TEXT, '
            'FOREIGN KEY (inventoryId) REFERENCES inventories(id) ON DELETE CASCADE )'
    );
    db.execute(
        'CREATE TABLE pois ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'speciesId INTEGER NOT NULL, '
            'longitude REAL NOT NULL, '
            'latitude REAL NOT NULL, '
            'FOREIGN KEY (speciesId) REFERENCES species(id) ON DELETE CASCADE )'
    );
    db.execute(
        'CREATE TABLE weather ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'inventoryId INTEGER NOT NULL, '
            'sampleTime TEXT NOT NULL, '
            'cloudCover INTEGER, '
            'precipitation INTEGER, '
            'temperature REAL, '
            'windSpeed INTEGER, '
            'FOREIGN KEY (inventoryId) REFERENCES inventories(id) ON DELETE CASCADE )'
    );
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
  }

  void _upgradeTables(Database db, int oldVersion, int newVersion) {
    if (oldVersion < 2) {
      db.execute(
        'ALTER TABLE inventories ADD COLUMN maxSpecies INTEGER',
      );
    }
    if (oldVersion < 3) {
      db.execute(
          'CREATE TABLE weather ('
              'id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'inventoryId INTEGER NOT NULL, '
              'sampleTime TEXT NOT NULL, '
              'cloudCover INTEGER, '
              'precipitation INTEGER, '
              'temperature REAL, '
              'windSpeed INTEGER, '
              'FOREIGN KEY (inventoryId) REFERENCES inventories(id) ON DELETE CASCADE)'
      );
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
  }

  Future<void> closeDatabase() async {
    final db = await database;
    await db?.close();
  }

}
