import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database/database_helper.dart';
import '../data/models/nest.dart';
import '../data/models/specimen.dart';
import '../data/models/inventory.dart';
import '../providers/inventory_provider.dart';

import '../core/core_consts.dart';
import '../generated/l10n.dart';
import '../providers/nest_provider.dart';
import '../providers/specimen_provider.dart';

class MonthOccurrence {
  final int month;
  final int occurrences;

  MonthOccurrence({required this.month, required this.occurrences});
}

// Color mapping for each record type
final Map<String, Color> _recordTypeColors = {
  S.current.inventories: Colors.blue,
  S.current.nests: Colors.orange,
  S.current.egg(2): Colors.green,
  S.current.specimens(2): Colors.purple,
};

// Function to get the color for a given record type
Color getRecordColor(String recordType) {
  return _recordTypeColors[recordType] ??
      Colors.grey; // Default to grey if not found
}

// Color mapping for each specimen type
final Map<String, Color> _specimenTypeColors = {
  S.current.specimenWholeCarcass: Colors.blue,
  S.current.specimenPartialCarcass: Colors.orange,
  S.current.specimenNest: Colors.green,
  S.current.specimenBones: Colors.purple,
  S.current.specimenEgg: Colors.yellow,
  S.current.specimenParasites: Colors.cyan,
  S.current.specimenFeathers: Colors.deepPurple,
  S.current.specimenBlood: Colors.red,
  S.current.specimenClaw: Colors.teal,
  S.current.specimenSwab: Colors.amber,
  S.current.specimenTissues: Colors.lightGreen,
  S.current.specimenFeces: Colors.deepOrange,
  S.current.specimenRegurgite: Colors.pink,
};

// Function to get the color for a given record type
Color getSpecimenColor(String specimenType) {
  return _specimenTypeColors[specimenType] ??
      Colors.grey; // Default to grey if not found
}

// Color mapping for each nest fate type
final Map<String, Color> _nestFateTypeColors = {
  S.current.nestFateUnknown: Colors.grey,
  S.current.nestFateLost: Colors.red,
  S.current.nestFateSuccess: Colors.blue,
};

// Function to get the color for a given nest fate type
Color getNestFateColor(String fateType) {
  return _nestFateTypeColors[fateType] ??
      Colors.grey; // Default to grey if not found
}

// Helper function to get distinct species names from a table
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

// Get a list of recorded species
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

// Get the total number of species with records in any table
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

// Get the top 10 species with the most records
Future<List<MapEntry<String, int>>> getTopSpeciesWithMostRecords(int count) async {
  final speciesFromSpecies = await _getDistinctSpeciesFromTable('species');
  final speciesFromNests = await _getDistinctSpeciesFromTable('nests');
  final speciesFromEggs = await _getDistinctSpeciesFromTable('eggs');
  final speciesFromSpecimens = await _getDistinctSpeciesFromTable('specimens');

  final speciesCounts = <String, int>{};

  final allSpeciesSet = <String>{
    ...speciesFromSpecies,
    ...speciesFromNests,
    ...speciesFromEggs,
    ...speciesFromSpecimens,
  };
  List<String> allSpeciesList = allSpeciesSet.toList();

  // Count species from species list
  for (final species in allSpeciesList) {
    int countTotal = await getTotalsForSpecies(species);
    speciesCounts[species] = countTotal;
  }

  // Sort by count in descending order and take the top 10
  final sortedSpecies = speciesCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  if (count <= 0) {
    return sortedSpecies;
  } else {
    return sortedSpecies.take(count).toList();
  }
}

Map<int, int> getOccurrencesByMonth(
    BuildContext context,
    List<Species> speciesList,
    List<Nest> nestList,
    List<Egg> eggList,
    List<Specimen> specimenList,
    String? selectedSpecies) {
  Map<int, int> occurrences = {};

  // Initialize the occurrences map with zero for each month
  for (int month = 1; month <= 12; month++) {
    occurrences[month] = 0;
  }

  void addOccurrence(DateTime date) {
    occurrences[date.month] = (occurrences[date.month] ?? 0) + 1;
  }

  // Check the list of species
  for (var specie in speciesList) {
    // if (specie.id == species.id) {
    DateTime? speciesDate = specie.sampleTime;

    if (speciesDate == null) {
      Inventory? inventory =
          Provider.of<InventoryProvider>(context, listen: false)
              .getInventoryById(specie.inventoryId);
      speciesDate = inventory?.startTime;
    }

    if (speciesDate != null) {
      addOccurrence(speciesDate);
    }
    // }
  }

  // Check the list of nests
  for (var nest in nestList) {
    if (nest.speciesName == selectedSpecies) {
      addOccurrence(nest.foundTime!);
    }
  }

  // Check the list of eggs
  for (var egg in eggList) {
    if (egg.speciesName == selectedSpecies) {
      addOccurrence(egg.sampleTime!);
    }
  }

  // Check the list of specimens
  for (var specimen in specimenList) {
    if (specimen.speciesName == selectedSpecies) {
      addOccurrence(specimen.sampleTime!);
    }
  }

  return occurrences;
}

Map<int, int> getOccurrencesByYear(
    BuildContext context,
    List<Species> speciesList,
    List<Nest> nestList,
    List<Egg> eggList,
    List<Specimen> specimenList,
    String? selectedSpecies) {
  Map<int, int> occurrences = {};

  void addOccurrence(DateTime date) {
    occurrences[date.year] = (occurrences[date.year] ?? 0) + 1;
  }

  // Check the list of species
  for (var specie in speciesList) {
    DateTime? speciesDate = specie.sampleTime;

    if (speciesDate == null) {
      Inventory? inventory =
          Provider.of<InventoryProvider>(context, listen: false)
              .getInventoryById(specie.inventoryId);
      speciesDate = inventory?.startTime;
    }

    if (speciesDate != null) {
      addOccurrence(speciesDate);
    }
  }

  // Check the list of nests
  for (var nest in nestList) {
    if (nest.speciesName == selectedSpecies) {
      addOccurrence(nest.foundTime!);
    }
  }

  // Check the list of eggs
  for (var egg in eggList) {
    if (egg.speciesName == selectedSpecies) {
      addOccurrence(egg.sampleTime!);
    }
  }

  // Check the list of specimens
  for (var specimen in specimenList) {
    if (specimen.speciesName == selectedSpecies) {
      addOccurrence(specimen.sampleTime!);
    }
  }

  return occurrences;
}

Map<String, int> getTotalsByRecordType(List<Species> inventories,
    List<Nest> nests, List<Egg> eggs, List<Specimen> specimens) {
  return {
    S.current.inventories: inventories.length,
    S.current.nests: nests.length,
    S.current.egg(2): eggs.length,
    S.current.specimens(2): specimens.length,
  };
}

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

    // Get a list of specimen types and the number of records per type
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

List<FlSpot> prepareAccumulatedSpeciesData(List<Inventory> selectedInventories) {
  final speciesSet = <String>{};
  final accumulatedSpeciesData = <FlSpot>[];

  for (var i = 0; i < selectedInventories.length; i++) {
    final inventory = selectedInventories[i];
    // inventory.speciesList.where((species) => speciesSet.add(species.name));
    for (final species in inventory.speciesList) {
      speciesSet.add(species.name);
    }
    accumulatedSpeciesData.add(FlSpot(i.toDouble(), speciesSet.length.toDouble()));
  }

  return accumulatedSpeciesData;
}

List<FlSpot> prepareAccumulatedSpeciesWithinSample(List<Inventory> selectedInventories) {
  final speciesSet = <String>{};
  final accumulatedSpeciesData = <FlSpot>[];

  for (var i = 0; i < selectedInventories.length; i++) {
    final inventory = selectedInventories[i];
    // inventory.speciesList.where((species) => speciesSet.add(species.name));
    for (final species in inventory.speciesList) {
      if (!species.isOutOfInventory) {
        speciesSet.add(species.name);
      }
    }
    accumulatedSpeciesData.add(FlSpot(i.toDouble(), speciesSet.length.toDouble()));
  }

  return accumulatedSpeciesData;
}
