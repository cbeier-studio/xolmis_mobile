import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:xolmis/utils/themes.dart';

import '../data/database/database_helper.dart';
import '../data/models/nest.dart';
import '../data/models/specimen.dart';
import '../data/models/inventory.dart';
import '../providers/inventory_provider.dart';

import '../core/core_consts.dart';
import '../generated/l10n.dart';
import '../providers/nest_provider.dart';
import '../providers/specimen_provider.dart';

/// Stores the number of occurrences recorded for a given month.
class MonthOccurrence {
  final int month;
  final int occurrences;

  MonthOccurrence({required this.month, required this.occurrences});
}

S get _activeL10n {
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  for (final locale in dispatcher.locales) {
    if (S.delegate.isSupported(locale)) {
      return lookupS(locale);
    }
    final fallbackLocale = Locale(locale.languageCode);
    if (S.delegate.isSupported(fallbackLocale)) {
      return lookupS(fallbackLocale);
    }
  }
  return lookupS(const Locale('en'));
}

// Color mapping for each record type
Map<String, Color> get _recordTypeColors {
  final l10n = _activeL10n;
  return {
    l10n.inventories: XolmisColors.primary,
    l10n.nests: XolmisColors.success,
    l10n.egg(2): XolmisColors.warning,
    l10n.specimens(2): XolmisColors.error,
  };
}

/// Returns the chart color associated with a localized record type label.
///
/// Falls back to [Colors.grey] when [recordType] is not present in the
/// configured color map.
Color getRecordColor(String recordType) {
  return _recordTypeColors[recordType] ??
      Colors.grey; // Default to grey if not found
}

// Color mapping for each specimen type
Map<String, Color> get _specimenTypeColors {
  final l10n = _activeL10n;
  return {
    l10n.specimenWholeCarcass: Colors.blue,
    l10n.specimenPartialCarcass: Colors.orange,
    l10n.specimenNest: Colors.green,
    l10n.specimenBones: Colors.purple,
    l10n.specimenEgg: Colors.yellow,
    l10n.specimenParasites: Colors.cyan,
    l10n.specimenFeathers: Colors.deepPurple,
    l10n.specimenBlood: Colors.red,
    l10n.specimenClaw: Colors.teal,
    l10n.specimenSwab: Colors.amber,
    l10n.specimenTissues: Colors.lightGreen,
    l10n.specimenFeces: Colors.deepOrange,
    l10n.specimenRegurgite: Colors.pink,
  };
}

/// Returns the chart color associated with a localized specimen type label.
///
/// Falls back to [Colors.grey] when [specimenType] is not present in the
/// configured color map.
Color getSpecimenColor(String specimenType) {
  return _specimenTypeColors[specimenType] ??
      Colors.grey; // Default to grey if not found
}

// Color mapping for each nest fate type
Map<String, Color> get _nestFateTypeColors {
  final l10n = _activeL10n;
  return {
    l10n.nestFateUnknown: Colors.grey,
    l10n.nestFateLost: Colors.red,
    l10n.nestFateSuccess: Colors.blue,
  };
}

/// Returns the chart color associated with a localized nest fate label.
///
/// Falls back to [Colors.grey] when [fateType] is not present in the
/// configured color map.
Color getNestFateColor(String fateType) {
  return _nestFateTypeColors[fateType] ??
      Colors.grey; // Default to grey if not found
}

/// Returns distinct species names stored in [tableName].
///
/// The helper reads from the `name` column for the `species` table and from
/// `speciesName` for the remaining supported tables. It returns an empty list
/// when the database is unavailable or when the query fails.
Future<List<String>> _getDistinctSpeciesFromTable(String tableName) async {
  final DatabaseHelper dbHelper;
  dbHelper = DatabaseHelper();
  final db = await dbHelper.database;
  final String columnName = tableName == 'species' ? 'name' : 'speciesName';
  if (db == null) {
    debugPrint('Error: Unable to access the database. It is null. Please ensure the database is initialized properly.');
    return [];
  }
  try {
    final List<Map<String, dynamic>> results = await db.query(
      tableName,
      columns: [columnName],
      distinct: true,
    );

    // Extract the species names from the results.
    final List<String> speciesNames =
        results.map((row) => row[columnName] as String).toList();

    return speciesNames;
  } catch (e) {
    debugPrint('Error querying database: $e');
    return []; // Return an empty list in case of an error.
  }
}

/// Returns all distinct species names recorded anywhere in the local database.
///
/// Species names are collected from the `species`, `nests`, `eggs`, and
/// `specimens` tables, deduplicated, and sorted alphabetically.
Future<List<String>> getRecordedSpeciesList() async {
  final speciesFromSpecies = await _getDistinctSpeciesFromTable('species');
  final speciesFromNests = await _getDistinctSpeciesFromTable('nests');
  final speciesFromEggs = await _getDistinctSpeciesFromTable('eggs');
  final speciesFromSpecimens = await _getDistinctSpeciesFromTable('specimens');

  final allSpecies = <String>{
    ...speciesFromSpecies,
    ...speciesFromNests,
    ...speciesFromEggs,
    ...speciesFromSpecimens,
  };

  List<String> sortedSpecies = allSpecies.toList();
  sortedSpecies.sort((a, b) => a.compareTo(b));

  return sortedSpecies;
}

/// Returns all distinct locality names currently available through the feature
/// providers.
///
/// Localities are gathered from inventories, nests, and specimens, then
/// deduplicated and sorted alphabetically.
Future<List<String>> getRecordedLocalitiesList(BuildContext context) async {
  final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
  final nestProvider = Provider.of<NestProvider>(context, listen: false);
  final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);

  final localitiesFromInventories = await inventoryProvider.getDistinctLocalities();
  final localitiesFromNests = await nestProvider.getDistinctLocalities();
  final localitiesFromSpecimens = await specimenProvider.getDistinctLocalities();

  final allLocalities = <String>{
    ...localitiesFromInventories,
    ...localitiesFromNests,
    ...localitiesFromSpecimens,
  };

  List<String> sortedLocalities = allLocalities.toList();
  sortedLocalities.sort((a, b) => a.compareTo(b));

  return sortedLocalities;
}

/// Returns the total number of distinct species that have records in any table.
///
/// This count is built from unique species names present in the `species`,
/// `nests`, `eggs`, and `specimens` tables.
Future<int> getTotalSpeciesWithRecords() async {
  final speciesFromSpecies = await _getDistinctSpeciesFromTable('species');
  final speciesFromNests = await _getDistinctSpeciesFromTable('nests');
  final speciesFromEggs = await _getDistinctSpeciesFromTable('eggs');
  final speciesFromSpecimens = await _getDistinctSpeciesFromTable('specimens');

  final allSpecies = <String>{
    ...speciesFromSpecies,
    ...speciesFromNests,
    ...speciesFromEggs,
    ...speciesFromSpecimens,
  };

  return allSpecies.length;
}

/// Returns the species with the highest total number of records across all
/// supported tables.
///
/// Counts are aggregated from the `species`, `nests`, `eggs`, and `specimens`
/// tables and sorted by descending total count, then alphabetically by species
/// name. When [count] is greater than zero, the result is limited to that many
/// entries; otherwise all ranked species are returned.
Future<List<MapEntry<String, int>>> getTopSpeciesWithMostRecords(int count) async {
  final dbHelper = DatabaseHelper();
  final db = await dbHelper.database;
  if (db == null) {
    debugPrint('Error: Database is null.');
    return [];
  }

  final shouldLimit = count > 0;
  final limitClause = shouldLimit ? 'LIMIT $count' : '';

  // Single query: aggregate counts across all sources, then rank globally.
  final result = await db.rawQuery('''
    SELECT species_name, SUM(total_count) AS total_count
    FROM (
      SELECT name AS species_name, COUNT(*) AS total_count
      FROM species
      WHERE name IS NOT NULL AND TRIM(name) != ''
      GROUP BY name

      UNION ALL

      SELECT speciesName AS species_name, COUNT(*) AS total_count
      FROM nests
      WHERE speciesName IS NOT NULL AND TRIM(speciesName) != ''
      GROUP BY speciesName

      UNION ALL

      SELECT speciesName AS species_name, COUNT(*) AS total_count
      FROM eggs
      WHERE speciesName IS NOT NULL AND TRIM(speciesName) != ''
      GROUP BY speciesName

      UNION ALL

      SELECT speciesName AS species_name, COUNT(*) AS total_count
      FROM specimens
      WHERE speciesName IS NOT NULL AND TRIM(speciesName) != ''
      GROUP BY speciesName
    ) grouped
    GROUP BY species_name
    ORDER BY total_count DESC, species_name ASC
    $limitClause
  ''');

  return result.map((row) {
    final species = row['species_name'] as String;
    final total = row['total_count'] as int;
    return MapEntry(species, total);
  }).toList();
}

/// Returns the number of occurrences of [selectedSpecies] grouped by month (1–12),
/// querying the database directly instead of relying on in-memory lists.
///
/// For [Species] records, [sampleTime] is used when available; otherwise the
/// parent [Inventory.startTime] is used as a fallback via a LEFT JOIN.
/// Records from [Nest], [Egg] and [Specimen] tables are also included when
/// [selectedSpecies] is not null.
///
/// Returns a map with all 12 months pre-initialised to zero.
Future<Map<int, int>> getOccurrencesByMonth(String? selectedSpecies) async {
  // Initialize the occurrences map with zero for each month
  final Map<int, int> occurrences = {for (var i = 1; i <= 12; i++) i: 0};

  final db = await DatabaseHelper().database;
  if (db == null) {
    debugPrint('getOccurrencesByMonth: database is null.');
    return occurrences;
  }

  /// Adds row results (columns: month INTEGER, count INTEGER) to [occurrences].
  void addRows(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      final month = row['month'] as int?;
      final count = (row['count'] as int?) ?? 0;
      if (month != null && month >= 1 && month <= 12) {
        occurrences[month] = (occurrences[month] ?? 0) + count;
      }
    }
  }

  try {
    // Species: use sampleTime, fallback to parent inventory startTime
    final speciesFilter = selectedSpecies != null ? 'AND s.name = ?' : '';
    final speciesArgs = selectedSpecies != null ? [selectedSpecies] : <dynamic>[];
    final speciesRows = await db.rawQuery('''
      SELECT
        CAST(strftime('%m', COALESCE(s.sampleTime, i.startTime)) AS INTEGER) AS month,
        COUNT(*) AS count
      FROM species s
      LEFT JOIN inventories i ON s.inventoryId = i.id
      WHERE (s.sampleTime IS NOT NULL OR i.startTime IS NOT NULL)
        $speciesFilter
      GROUP BY month
    ''', speciesArgs);
    addRows(speciesRows);

    if (selectedSpecies != null) {
      // Nests: use foundTime
      final nestRows = await db.rawQuery('''
        SELECT
          CAST(strftime('%m', foundTime) AS INTEGER) AS month,
          COUNT(*) AS count
        FROM nests
        WHERE foundTime IS NOT NULL AND speciesName = ?
        GROUP BY month
      ''', [selectedSpecies]);
      addRows(nestRows);

      // Eggs: use sampleTime
      final eggRows = await db.rawQuery('''
        SELECT
          CAST(strftime('%m', sampleTime) AS INTEGER) AS month,
          COUNT(*) AS count
        FROM eggs
        WHERE sampleTime IS NOT NULL AND speciesName = ?
        GROUP BY month
      ''', [selectedSpecies]);
      addRows(eggRows);

      // Specimens: use sampleTime
      final specimenRows = await db.rawQuery('''
        SELECT
          CAST(strftime('%m', sampleTime) AS INTEGER) AS month,
          COUNT(*) AS count
        FROM specimens
        WHERE sampleTime IS NOT NULL AND speciesName = ?
        GROUP BY month
      ''', [selectedSpecies]);
      addRows(specimenRows);
    }
  } catch (e) {
    debugPrint('Error in getOccurrencesByMonth: $e');
  }

  return occurrences;
}

/// Returns the number of occurrences of [selectedSpecies] grouped by year,
/// querying the database directly instead of relying on in-memory lists.
///
/// For [Species] records, [sampleTime] is used when available; otherwise the
/// parent [Inventory.startTime] is used as a fallback via a LEFT JOIN.
/// Records from [Nest], [Egg] and [Specimen] tables are also included when
/// [selectedSpecies] is not null.
///
/// Returns an empty map when no records are found (years are not pre-initialised
/// since the year range is dynamic).
Future<Map<int, int>> getOccurrencesByYear(String? selectedSpecies) async {
  final Map<int, int> occurrences = {};

  final db = await DatabaseHelper().database;
  if (db == null) {
    debugPrint('getOccurrencesByYear: database is null.');
    return occurrences;
  }

  /// Adds row results (columns: year INTEGER, count INTEGER) to [occurrences].
  void addRows(List<Map<String, dynamic>> rows) {
    for (final row in rows) {
      final year = row['year'] as int?;
      final count = (row['count'] as int?) ?? 0;
      if (year != null) {
        occurrences[year] = (occurrences[year] ?? 0) + count;
      }
    }
  }

  try {
    // Species: use sampleTime, fallback to parent inventory startTime
    final speciesFilter = selectedSpecies != null ? 'AND s.name = ?' : '';
    final speciesArgs = selectedSpecies != null ? [selectedSpecies] : <dynamic>[];
    final speciesRows = await db.rawQuery('''
      SELECT
        CAST(strftime('%Y', COALESCE(s.sampleTime, i.startTime)) AS INTEGER) AS year,
        COUNT(*) AS count
      FROM species s
      LEFT JOIN inventories i ON s.inventoryId = i.id
      WHERE (s.sampleTime IS NOT NULL OR i.startTime IS NOT NULL)
        $speciesFilter
      GROUP BY year
    ''', speciesArgs);
    addRows(speciesRows);

    if (selectedSpecies != null) {
      // Nests: use foundTime
      final nestRows = await db.rawQuery('''
        SELECT
          CAST(strftime('%Y', foundTime) AS INTEGER) AS year,
          COUNT(*) AS count
        FROM nests
        WHERE foundTime IS NOT NULL AND speciesName = ?
        GROUP BY year
      ''', [selectedSpecies]);
      addRows(nestRows);

      // Eggs: use sampleTime
      final eggRows = await db.rawQuery('''
        SELECT
          CAST(strftime('%Y', sampleTime) AS INTEGER) AS year,
          COUNT(*) AS count
        FROM eggs
        WHERE sampleTime IS NOT NULL AND speciesName = ?
        GROUP BY year
      ''', [selectedSpecies]);
      addRows(eggRows);

      // Specimens: use sampleTime
      final specimenRows = await db.rawQuery('''
        SELECT
          CAST(strftime('%Y', sampleTime) AS INTEGER) AS year,
          COUNT(*) AS count
        FROM specimens
        WHERE sampleTime IS NOT NULL AND speciesName = ?
        GROUP BY year
      ''', [selectedSpecies]);
      addRows(specimenRows);
    }
  } catch (e) {
    debugPrint('Error in getOccurrencesByYear: $e');
  }

  return occurrences;
}

/// Returns record totals grouped by localized record type label.
///
/// The resulting map contains counts for inventory species records, nests,
/// eggs, and specimens using the translated labels expected by the charts.
Map<String, int> getTotalsByRecordType(BuildContext context, List<Species> inventories,
    List<Nest> nests, List<Egg> eggs, List<Specimen> specimens) {
  return {
    S.of(context).inventories: inventories.length,
    S.of(context).nests: nests.length,
    S.of(context).egg(2): eggs.length,
    S.of(context).specimens(2): specimens.length,
  };
}

/// Returns the total number of records associated with [speciesName].
///
/// The total is computed by summing matches found in the `species`, `nests`,
/// `eggs`, and `specimens` tables. Returns `0` if the database is unavailable
/// or if any query fails.
Future<int> getTotalsForSpecies(String speciesName) async {
      final DatabaseHelper _dbHelper;
  _dbHelper = DatabaseHelper();
  final db = await _dbHelper.database;
  
  if (db == null) {
    debugPrint('Error: Database is null.');
    return 0;
  }
  try {
    final List<Map<String, dynamic>> resultSpecies = await db.query(
      'species',
      columns: ['count(*) as count'],
      where: 'name = ?',
      whereArgs: [speciesName],
    );
    int inventoryCount = resultSpecies[0]['count'] as int;

    final List<Map<String, dynamic>> resultNests = await db.query(
      'nests',
      columns: ['count(*) as count'],
      where: 'speciesName = ?',
      whereArgs: [speciesName],
    );
    int nestCount = resultNests[0]['count'] as int;

    final List<Map<String, dynamic>> resultEggs = await db.query(
      'eggs',
      columns: ['count(*) as count'],
      where: 'speciesName = ?',
      whereArgs: [speciesName],
    );
    int eggCount = resultEggs[0]['count'] as int;

    final List<Map<String, dynamic>> resultSpecimens = await db.query(
      'specimens',
      columns: ['count(*) as count'],
      where: 'speciesName = ?',
      whereArgs: [speciesName],
        );
        int specimenCount = resultSpecimens[0]['count'] as int;

        return inventoryCount + nestCount + eggCount + specimenCount;
      } catch (e) {
        debugPrint('Error querying database: $e');
        return 0; 
      }
}

/// Returns the number of distinct nests with evidence of nidoparasitism.
///
/// A nest is counted when at least one related `nest_revisions` row reports
/// `eggsParasite > 0` or `nestlingsParasite > 0`.
Future<int> getTotalNestsWithNidoparasitism() async {
      final DatabaseHelper dbHelper;
  dbHelper = DatabaseHelper();
  final db = await dbHelper.database;
  if (db == null) {
    debugPrint('Error: Database is null.');
    return 0;
  }
  try {
    final List<Map<String, dynamic>> results = await db.query(
      'nest_revisions',
      columns: ['COUNT(DISTINCT nestId) AS count'],
      where: 'eggsParasite > 0 OR nestlingsParasite > 0',
    );
    return results[0]['count'] as int;
  } catch (e) {
    debugPrint('Error querying database: $e');
    return 0; 
  }
}

    /// Returns specimen counts grouped by localized specimen type name.
    ///
    /// Values are read from the `specimens` table, grouped by the stored enum
    /// index, and converted to user-facing labels via
    /// [specimenTypeFriendlyNames].
    Future<Map<String, int>> getSpecimenTypeCounts() async {
      final DatabaseHelper dbHelper;
      dbHelper = DatabaseHelper();
      final db = await dbHelper.database;
      List<MapEntry<String, int>?> specimenTypeCounts = [];
      Map<String, int> specimenTypeCountsMap = {};

      if (db == null) {
        debugPrint('Error: Database is null.');
        return {};
      }

      try {
        final List<Map<String, dynamic>> results = await db.query(
          'specimens',
          columns: ['type', 'COUNT(*) as count'],
          where: 'type IS NOT NULL',
          groupBy: 'type',
        );

        specimenTypeCounts = results.map((row) {
          final specimenType = row['type'];
          final count = row['count'];
          if (specimenType != null && count != null) {
            return MapEntry(specimenTypeFriendlyNames[SpecimenType.values[specimenType as int]] as String, count as int);
          }
        }).toList();

        specimenTypeCountsMap = Map.fromEntries(specimenTypeCounts.whereType<MapEntry<String, int>>());

        return specimenTypeCountsMap;
      } catch (e) {
        debugPrint('Error querying database: $e');
        return {}; // Return an empty map in case of an error.
      }
    }

/// Returns nest counts grouped by localized nest fate label.
Map<String, int> getNestFateCounts(List<Nest> nests) {
  Map<String, int> nestFateCounts = {};

  for (var nest in nests) {
    String fate = (nestFateTypeFriendlyNames[nest.nestFate] ?? nestFateTypeFriendlyNames[NestFateType.fatUnknown]) as String;
    if (nestFateCounts.containsKey(fate)) {
      nestFateCounts[fate] = (nestFateCounts[fate] ?? 0) + 1;
    } else {
      nestFateCounts[fate] = 1;
    }
  }

  return nestFateCounts;
}

/// Builds an accumulated species-richness series for the provided inventories.
///
/// Each returned [FlSpot] uses the inventory index as the x-axis value and the
/// cumulative number of distinct species observed up to that inventory as the
/// y-axis value.
List<FlSpot> prepareAccumulatedSpeciesData(List<Inventory> selectedInventories) {
  final speciesSet = <String>{};
  final accumulatedSpeciesData = <FlSpot>[const FlSpot(0, 0)];

  for (var i = 0; i < selectedInventories.length; i++) {
    final inventory = selectedInventories[i];
    for (final species in inventory.speciesList) {
      speciesSet.add(species.name);
    }
    accumulatedSpeciesData.add(FlSpot((i + 1).toDouble(), speciesSet.length.toDouble()));
  }

  return accumulatedSpeciesData;
}

/// Builds an accumulated species-richness series using only in-sample records.
///
/// Species flagged as out of inventory are ignored. Each returned [FlSpot]
/// uses the inventory index as the x-axis value and the cumulative number of
/// distinct in-sample species as the y-axis value.
List<FlSpot> prepareAccumulatedSpeciesWithinSample(List<Inventory> selectedInventories) {
  final speciesSet = <String>{};
  final accumulatedSpeciesData = <FlSpot>[const FlSpot(0, 0)];

  for (var i = 0; i < selectedInventories.length; i++) {
    final inventory = selectedInventories[i];
    for (final species in inventory.speciesList) {
      if (!species.isOutOfInventory) {
        speciesSet.add(species.name);
      }
    }
    accumulatedSpeciesData.add(FlSpot((i + 1).toDouble(), speciesSet.length.toDouble()));
  }

  return accumulatedSpeciesData;
}

/// Returns the total number of records grouped by hour of day (0–23) across
/// all record types ([Species], [Nest], [Egg], [Specimen]), querying the
/// database directly via a single `UNION ALL` query.
///
/// Only records with a non-null timestamp are counted. All 24 hours are
/// pre-initialised to zero.
Future<Map<int, int>> getAllOccurrencesByHourOfDay() async {
  final Map<int, int> occurrences = {for (var i = 0; i < 24; i++) i: 0};

  final db = await DatabaseHelper().database;
  if (db == null) {
    debugPrint('getAllOccurrencesByHourOfDay: database is null.');
    return occurrences;
  }

  try {
    final rows = await db.rawQuery('''
      SELECT hour, COUNT(*) AS count
      FROM (
        SELECT CAST(strftime('%H', sampleTime) AS INTEGER) AS hour
        FROM species
        WHERE sampleTime IS NOT NULL

        UNION ALL

        SELECT CAST(strftime('%H', foundTime) AS INTEGER) AS hour
        FROM nests
        WHERE foundTime IS NOT NULL

        UNION ALL

        SELECT CAST(strftime('%H', sampleTime) AS INTEGER) AS hour
        FROM eggs
        WHERE sampleTime IS NOT NULL

        UNION ALL

        SELECT CAST(strftime('%H', sampleTime) AS INTEGER) AS hour
        FROM specimens
        WHERE sampleTime IS NOT NULL
      ) grouped
      GROUP BY hour
      ORDER BY hour
    ''');

    for (final row in rows) {
      final hour = row['hour'] as int?;
      final count = (row['count'] as int?) ?? 0;
      if (hour != null && hour >= 0 && hour < 24) {
        occurrences[hour] = (occurrences[hour] ?? 0) + count;
      }
    }
  } catch (e) {
    debugPrint('Error in getAllOccurrencesByHourOfDay: $e');
  }

  return occurrences;
}

/// Returns species record counts grouped by hour of day (0–23).
///
/// Only [Species.sampleTime] values that are not null are counted. All 24
/// hours are pre-initialised to zero.
Map<int, int> getOccurrencesByHourOfDay(
    List<Species> speciesList,
    ) {
  // Cria um mapa para armazenar a contagem de cada hora, inicializando todas com 0.
  final Map<int, int> occurrences = { for (var i = 0; i < 24; i++) i: 0 };

  // Combina todos os registros que têm um 'sampleTime' em uma única lista.
  final allRecordsWithTime = [
    ...speciesList.where((s) => s.sampleTime != null).map((s) => s.sampleTime!),
  ];

  // Para cada registro, incrementa a contagem para a hora correspondente.
  for (final time in allRecordsWithTime) {
    final hour = time.hour;
    occurrences[hour] = (occurrences[hour] ?? 0) + 1;
  }

  return occurrences;
}

/// Returns specimen counts grouped by [SpecimenType] for a given specimen list.
Map<SpecimenType, int> getSpecimenTypeCountsFromList(List<Specimen> specimens) {
  final Map<SpecimenType, int> counts = {};
  for (final specimen in specimens) {
    counts[specimen.type] = (counts[specimen.type] ?? 0) + 1;
  }
  return counts;
}

/// Returns specimen counts per species name, sorted descending by count.
List<MapEntry<String, int>> getSpecimensBySpecies(List<Specimen> specimens) {
  final Map<String, int> counts = {};
  for (final specimen in specimens) {
    final name = specimen.speciesName ?? '';
    if (name.isNotEmpty) {
      counts[name] = (counts[name] ?? 0) + 1;
    }
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted;
}

/// Returns specimen counts per locality name, sorted descending by count.
List<MapEntry<String, int>> getSpecimensByLocality(List<Specimen> specimens) {
  final Map<String, int> counts = {};
  for (final specimen in specimens) {
    final locality = specimen.locality ?? '';
    if (locality.isNotEmpty) {
      counts[locality] = (counts[locality] ?? 0) + 1;
    }
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return sorted;
}

/// Returns specimen counts grouped by hour of day (0-23).
Map<int, int> getSpecimensByHourOfDay(List<Specimen> specimens) {
  final Map<int, int> occurrences = { for (var i = 0; i < 24; i++) i: 0 };
  for (final specimen in specimens) {
    if (specimen.sampleTime != null) {
      final hour = specimen.sampleTime!.hour;
      occurrences[hour] = (occurrences[hour] ?? 0) + 1;
    }
  }
  return occurrences;
}

/// Returns distinct species richness grouped by month of year (1–12), querying
/// the database directly across all record types ([Species], [Nest], [Egg],
/// [Specimen]).
///
/// For [Species] records, [sampleTime] is used when available; otherwise the
/// parent [Inventory.startTime] is used as a fallback via a LEFT JOIN.
/// All 12 months are pre-initialised to zero.
Future<Map<int, int>> getSpeciesRichnessPerMonthGlobal() async {
  final Map<int, int> richnessByMonth = {for (var i = 1; i <= 12; i++) i: 0};

  final db = await DatabaseHelper().database;
  if (db == null) {
    debugPrint('getSpeciesRichnessPerMonthGlobal: database is null.');
    return richnessByMonth;
  }

  try {
    final rows = await db.rawQuery('''
      SELECT month, COUNT(DISTINCT species_name) AS count
      FROM (
        SELECT
          CAST(strftime('%m', COALESCE(s.sampleTime, i.startTime)) AS INTEGER) AS month,
          s.name AS species_name
        FROM species s
        LEFT JOIN inventories i ON s.inventoryId = i.id
        WHERE (s.sampleTime IS NOT NULL OR i.startTime IS NOT NULL)
          AND s.name IS NOT NULL AND TRIM(s.name) != ''

        UNION ALL

        SELECT
          CAST(strftime('%m', foundTime) AS INTEGER) AS month,
          speciesName AS species_name
        FROM nests
        WHERE foundTime IS NOT NULL
          AND speciesName IS NOT NULL AND TRIM(speciesName) != ''

        UNION ALL

        SELECT
          CAST(strftime('%m', sampleTime) AS INTEGER) AS month,
          speciesName AS species_name
        FROM eggs
        WHERE sampleTime IS NOT NULL
          AND speciesName IS NOT NULL AND TRIM(speciesName) != ''

        UNION ALL

        SELECT
          CAST(strftime('%m', sampleTime) AS INTEGER) AS month,
          speciesName AS species_name
        FROM specimens
        WHERE sampleTime IS NOT NULL
          AND speciesName IS NOT NULL AND TRIM(speciesName) != ''
      ) combined
      WHERE month >= 1 AND month <= 12
      GROUP BY month
      ORDER BY month
    ''');

    for (final row in rows) {
      final month = row['month'] as int?;
      final count = (row['count'] as int?) ?? 0;
      if (month != null && month >= 1 && month <= 12) {
        richnessByMonth[month] = count;
      }
    }
  } catch (e) {
    debugPrint('Error in getSpeciesRichnessPerMonthGlobal: $e');
  }

  return richnessByMonth;
}

/// Returns distinct species richness grouped by year, querying the database
/// directly across all record types ([Species], [Nest], [Egg], [Specimen]).
///
/// For [Species] records, [sampleTime] is used when available; otherwise the
/// parent [Inventory.startTime] is used as a fallback via a LEFT JOIN.
/// Years are not pre-initialised since the range is dynamic.
Future<Map<int, int>> getSpeciesRichnessPerYearGlobal() async {
  final Map<int, int> richnessByYear = {};

  final db = await DatabaseHelper().database;
  if (db == null) {
    debugPrint('getSpeciesRichnessPerYearGlobal: database is null.');
    return richnessByYear;
  }

  try {
    final rows = await db.rawQuery('''
      SELECT year, COUNT(DISTINCT species_name) AS count
      FROM (
        SELECT
          CAST(strftime('%Y', COALESCE(s.sampleTime, i.startTime)) AS INTEGER) AS year,
          s.name AS species_name
        FROM species s
        LEFT JOIN inventories i ON s.inventoryId = i.id
        WHERE (s.sampleTime IS NOT NULL OR i.startTime IS NOT NULL)
          AND s.name IS NOT NULL AND TRIM(s.name) != ''

        UNION ALL

        SELECT
          CAST(strftime('%Y', foundTime) AS INTEGER) AS year,
          speciesName AS species_name
        FROM nests
        WHERE foundTime IS NOT NULL
          AND speciesName IS NOT NULL AND TRIM(speciesName) != ''

        UNION ALL

        SELECT
          CAST(strftime('%Y', sampleTime) AS INTEGER) AS year,
          speciesName AS species_name
        FROM eggs
        WHERE sampleTime IS NOT NULL
          AND speciesName IS NOT NULL AND TRIM(speciesName) != ''

        UNION ALL

        SELECT
          CAST(strftime('%Y', sampleTime) AS INTEGER) AS year,
          speciesName AS species_name
        FROM specimens
        WHERE sampleTime IS NOT NULL
          AND speciesName IS NOT NULL AND TRIM(speciesName) != ''
      ) combined
      WHERE year IS NOT NULL
      GROUP BY year
      ORDER BY year
    ''');

    for (final row in rows) {
      final year = row['year'] as int?;
      final count = (row['count'] as int?) ?? 0;
      if (year != null) {
        richnessByYear[year] = count;
      }
    }
  } catch (e) {
    debugPrint('Error in getSpeciesRichnessPerYearGlobal: $e');
  }

  return richnessByYear;
}

/// Returns total inventory species records grouped by month of year (1–12).
///
/// For each species entry, [Species.sampleTime] is used when available;
/// otherwise the parent [Inventory.startTime] is used as a fallback. Years are
/// intentionally ignored so all records for the same month are merged.
Map<int, int> getRecordsByMonthFromInventories(List<Inventory> inventories) {
  final Map<int, int> recordsByMonth = { for (var i = 1; i <= 12; i++) i: 0 };

  for (final inventory in inventories) {
    // Add species records
    for (final species in inventory.speciesList) {
      final DateTime? recordTime = species.sampleTime ?? inventory.startTime;
      if (recordTime != null) {
        final month = recordTime.month;
        recordsByMonth[month] = (recordsByMonth[month] ?? 0) + 1;
      }
    }
  }

  return recordsByMonth;
}

/// Returns distinct inventory species richness grouped by month of year (1–12).
///
/// For each species entry, [Species.sampleTime] is used when available;
/// otherwise the parent [Inventory.startTime] is used as a fallback. Years are
/// intentionally ignored so all records for the same month are merged.
Map<int, int> getSpeciesRichnessPerMonth(List<Inventory> inventories) {
  final Map<int, Set<String>> speciesByMonth = { for (var i = 1; i <= 12; i++) i: <String>{} };

  for (final inventory in inventories) {
    // Add species records
    for (final species in inventory.speciesList) {
      final DateTime? recordTime = species.sampleTime ?? inventory.startTime;
      if (recordTime != null) {
        final month = recordTime.month;
        if (species.name.isNotEmpty) {
          speciesByMonth[month]?.add(species.name);
        }
      }
    }
  }

  // Convert sets to counts
  return speciesByMonth.map((month, species) => MapEntry(month, species.length));
}

/// Stores biodiversity diversity indices and richness estimates for an inventory or set of inventories.
class InventoryDiversityMetrics {
  final String label;
  final int richness; // S
  final int totalIndividuals; // N
  final double shannonWiener; // H'
  final double simpsonDiversity; // 1 - D
  final double pielouEvenness; // J'
  final double hillQ0; // Hill number q=0 (richness)
  final double hillQ1; // Hill number q=1 (exp(H'))
  final double hillQ2; // Hill number q=2 (1 / D)
  final double chao1; // Chao1 richness estimate

  InventoryDiversityMetrics({
    required this.label,
    required this.richness,
    required this.totalIndividuals,
    required this.shannonWiener,
    required this.simpsonDiversity,
    required this.pielouEvenness,
    required this.hillQ0,
    required this.hillQ1,
    required this.hillQ2,
    required this.chao1,
  });
}

/// Computes Shannon-Wiener (H'), Simpson (1-D), Pielou (J'), Hill numbers
/// (q0, q1, q2), species richness (S), total individuals (N), and Chao1
/// estimate for a collection of species.
///
/// When [ignoreZeroCountSpeciesInChao1] is true, species records with
/// `count <= 0` still contribute presence data to richness, N, Shannon, and
/// Pielou, but they are excluded from Chao1 singleton/doubleton frequencies.
/// This avoids inflating the estimator in inventories that mix true abundance
/// counts with qualitative presence-only records stored as zero.
InventoryDiversityMetrics computeDiversityMetrics(
  String label,
  List<Species> allSpecies, {
  bool ignoreZeroCountSpeciesInChao1 = false,
}) {
  final Map<String, int> abundances = {};
  final Map<String, int> chao1Abundances = {};
  for (final species in allSpecies) {
    final name = species.name;
    final count = species.count > 0 ? species.count : 1;
    abundances[name] = (abundances[name] ?? 0) + count;

    if (!ignoreZeroCountSpeciesInChao1 || species.count > 0) {
      chao1Abundances[name] = (chao1Abundances[name] ?? 0) + species.count;
    }
  }

  final int S = abundances.length;
  final int N = abundances.values.fold(0, (sum, c) => sum + c);

  double hPrime = 0.0;
  double simpsonDominance = 0.0;
  if (N > 0) {
    for (final count in abundances.values) {
      if (count > 0) {
        final double p = count / N;
        hPrime -= p * log(p);
        simpsonDominance += p * p;
      }
    }
  }

  final simpsonDiversity = N > 0 ? (1.0 - simpsonDominance) : 0.0;

  double jPrime = 0.0;
  if (S > 1) {
    jPrime = hPrime / log(S.toDouble());
  } else if (S == 1 && hPrime == 0.0) {
    jPrime = 1.0;
  }

  final chao1Source = ignoreZeroCountSpeciesInChao1 ? chao1Abundances : abundances;
  int a1 = chao1Source.values.where((c) => c == 1).length;
  int a2 = chao1Source.values.where((c) => c == 2).length;
  double chao1 = S.toDouble();
  if (a2 > 0) {
    chao1 = S + (a1 * a1) / (2.0 * a2);
  } else if (a1 > 1) {
    chao1 = S + (a1 * (a1 - 1)) / (2.0);
  }

  final hillQ0 = S.toDouble();
  final hillQ1 = N > 0 ? exp(hPrime) : 0.0;
  final hillQ2 = (N > 0 && simpsonDominance > 0) ? (1.0 / simpsonDominance) : 0.0;

  return InventoryDiversityMetrics(
    label: label,
    richness: S,
    totalIndividuals: N,
    shannonWiener: hPrime,
    simpsonDiversity: simpsonDiversity,
    pielouEvenness: jPrime,
    hillQ0: hillQ0,
    hillQ1: hillQ1,
    hillQ2: hillQ2,
    chao1: chao1,
  );
}

/// Prepares cumulative observed richness and sample-based rarefaction richness
/// across inventories.
///
/// The expected curve follows the analytical Mao Tau estimator over incidence
/// (presence/absence) data, avoiding expensive random permutations.
({List<FlSpot> sampled, List<FlSpot> expected}) prepareRarefactionCurveSpots(
  List<Inventory> inventories,
) {
  final sampledSpots = <FlSpot>[const FlSpot(0, 0)];
  final expectedSpots = <FlSpot>[const FlSpot(0, 0)];

  if (inventories.isEmpty) {
    return (sampled: sampledSpots, expected: expectedSpots);
  }

  final inventorySpeciesSets = inventories
      .map((inventory) => inventory.speciesList.map((s) => s.name.trim()).where((name) => name.isNotEmpty).toSet())
      .toList();

  final observedAccumulated = <String>{};
  for (var i = 0; i < inventorySpeciesSets.length; i++) {
    observedAccumulated.addAll(inventorySpeciesSets[i]);
    sampledSpots.add(FlSpot((i + 1).toDouble(), observedAccumulated.length.toDouble()));
  }

  final H = inventorySpeciesSets.length;
  final speciesIncidence = <String, int>{};
  for (final speciesSet in inventorySpeciesSets) {
    for (final speciesName in speciesSet) {
      speciesIncidence[speciesName] = (speciesIncidence[speciesName] ?? 0) + 1;
    }
  }

  final observedRichness = speciesIncidence.length.toDouble();
  final logFactorials = List<double>.filled(H + 1, 0.0);
  for (var i = 2; i <= H; i++) {
    logFactorials[i] = logFactorials[i - 1] + log(i.toDouble());
  }
  final logCombHh = List<double>.filled(H + 1, 0.0);
  for (var h = 0; h <= H; h++) {
    logCombHh[h] = _logCombination(H, h, logFactorials);
  }

  for (var h = 1; h <= H; h++) {
    var absentProbabilitySum = 0.0;

    for (final xi in speciesIncidence.values) {
      final n = H - xi;
      if (h > n) {
        continue;
      }

      final absentProbability = exp(_logCombination(n, h, logFactorials) - logCombHh[h]);
      absentProbabilitySum += absentProbability.clamp(0.0, 1.0);
    }

    final expectedRichness = (observedRichness - absentProbabilitySum).clamp(0.0, observedRichness);
    expectedSpots.add(FlSpot(h.toDouble(), expectedRichness));
  }

  return (sampled: sampledSpots, expected: expectedSpots);
}

double _logCombination(int n, int k, List<double> logFactorials) {
  if (k < 0 || k > n) {
    return double.negativeInfinity;
  }
  return logFactorials[n] - logFactorials[k] - logFactorials[n - k];
}
