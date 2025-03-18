import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/database/database_helper.dart';
import '../data/models/nest.dart';
import '../data/models/specimen.dart';
import '../data/models/inventory.dart';
import '../providers/inventory_provider.dart';

import '../generated/l10n.dart';

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
Color getColor(String recordType) {
  return _recordTypeColors[recordType] ??
      Colors.grey; // Default to grey if not found
}

// Helper function to get distinct species names from a table
Future<List<String>> _getDistinctSpeciesFromTable(String tableName) async {
  final DatabaseHelper _dbHelper;
  _dbHelper = DatabaseHelper();
  final db = await _dbHelper.database;
  final String columnName = tableName == 'species' ? 'name' : 'speciesName';
  if (db == null) {
    debugPrint('Error: Database is null.');
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
Future<List<MapEntry<String, int>>> getTop10SpeciesWithMostRecords(
  List<Species> inventories,
    List<Nest> nests,
    List<Egg> eggs,
    List<Specimen> specimens
) async {
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
    int countTotal = await getTotalsForSpecies(species, inventories, nests, eggs, specimens);
    speciesCounts[species] = countTotal;
  }

  // Sort by count in descending order and take the top 10
  final sortedSpecies = speciesCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sortedSpecies.take(10).toList();
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

Future<int> getTotalsForSpecies(
    String speciesName,
    List<Species> inventories,
    List<Nest> nests,
    List<Egg> eggs,
    List<Specimen> specimens) async {
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