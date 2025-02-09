import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/models/inventory.dart';
import '../data/models/nest.dart';
import '../data/models/specimen.dart';
import '../providers/inventory_provider.dart';
import '../providers/nest_provider.dart';
import '../providers/specimen_provider.dart';

import '../generated/l10n.dart';

Future<bool> requestStoragePermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }
  return status.isGranted;
}

Future<void> exportAllInventoriesToJson(BuildContext context, InventoryProvider inventoryProvider) async {
  try {
    final finishedInventories = inventoryProvider.finishedInventories;
    final jsonData = finishedInventories.map((inventory) => inventory.toJson()).toList();
    var encoder = JsonEncoder.withIndent("  ");
    final jsonString = encoder.convert(jsonData);
    // final jsonString = jsonEncode(jsonData);

    // Get the current date and time
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    // Create the file in a temporary folder
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/inventories_$formattedDate.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    // Share the file using share_plus
    await Share.shareXFiles([
      XFile(filePath, mimeType: 'application/json'),
    ], text: S.current.inventoryExported(2), subject: S.current.inventoryData(2));
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text(S.current.errorExportingInventory(2, error.toString())),
        ],
      ),
      ),
    );
  }
}

Future<void> exportInventoryToJson(BuildContext context, Inventory inventory, bool shareIt) async {
  try {
    final jsonData = inventory.toJson();
    var encoder = JsonEncoder.withIndent("  ");
    final jsonString = encoder.convert(jsonData);
    // final jsonString = jsonEncode(jsonData);
    
    // Create the file in a temporary folder
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/inventory_${inventory.id}.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    // Share the file using share_plus
    if (shareIt) {
      await Share.shareXFiles([
        XFile(filePath, mimeType: 'application/json'),
      ],
          text: S.current.inventoryExported(1),
          subject: '${S.current.inventoryExported(1)} ${inventory.id}');
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text(S.current.errorExportingInventory(1, error.toString())),
        ],
      ),
      ),
    );
  }
}

Future<void> exportInventoryToCsv(BuildContext context, Inventory inventory, bool shareIt) async {
  try {
    final locale = Localizations.localeOf(context);

    // 1. Create a list of data for the CSV
    List<List<dynamic>> rows = buildInventoryCsvRows(inventory, locale);

    // 2. Convert the list of data to CSV
    String csv = const ListToCsvConverter().convert(rows, fieldDelimiter: ';');

    // 3. Create the file in a temporary directory
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/inventory_${inventory.id}.csv';
    final file = File(filePath);
    await file.writeAsString(csv);

    // 4. Share the file using share_plus
    if (shareIt) {
      await Share.shareXFiles([
        XFile(filePath, mimeType: 'text/csv'),
      ],
          text: S.current.inventoryExported(1),
          subject: '${S.current.inventoryExported(1)} ${inventory.id}');
    } 
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text(S.current.errorExportingInventory(1, error.toString())),
        ],
      ),
      ),
    );
  }
}

// Add inventory data to CSV rows
List<List<dynamic>> buildInventoryCsvRows(Inventory inventory, Locale locale) {
  final List<List<dynamic>> rows = [];
  final numberFormat = NumberFormat.decimalPattern(locale.toString())..maximumFractionDigits = 7;
  rows.add([
    'ID',
    'Type',
    'Duration',
    'Max of species',
    'Start date',
    'Start time',
    'End date',
    'End time',
    'Start longitude',
    'Start latitude',
    'End longitude',
    'End latitude',
    'Intervals'
  ]);
  rows.add([
    inventory.id,
    inventoryTypeFriendlyNames[inventory.type],
    inventory.duration,
    inventory.maxSpecies,
    DateFormat.yMd(locale.toString()).format(inventory.startTime!),
    DateFormat.Hms(locale.toString()).format(inventory.startTime!),
    DateFormat.yMd(locale.toString()).format(inventory.endTime!),
    DateFormat.Hms(locale.toString()).format(inventory.endTime!),
    numberFormat.format(inventory.startLongitude),
    numberFormat.format(inventory.startLatitude),
    numberFormat.format(inventory.endLongitude),
    numberFormat.format(inventory.endLatitude),
    inventory.currentInterval,
  ]);
  
  // Add species data
  rows.add([]); // Empty line to separate the inventory of the species
  rows.add(['SPECIES', 'Count', 'Time', 'Out of sample', 'Notes']);
  for (var species in inventory.speciesList) {
    rows.add([
      species.name, 
      species.count, 
      DateFormat('dd/MM/yyyy HH:mm:ss').format(species.sampleTime!), 
      species.isOutOfInventory, 
      species.notes ?? '',
    ]);
  }
  
  // Add vegetation data
  rows.add([]); // Empty line to separate vegetation data
  rows.add(['VEGETATION']);
  rows.add([
    'Date/Time',
    'Latitude',
    'Longitude',
    'Herbs Proportion',
    'Herbs Distribution',
    'Herbs Height',
    'Shrubs Proportion',
    'Shrubs Distribution',
    'Shrubs Height',
    'Trees Proportion',
    'Trees Distribution',
    'Trees Height',
    'Notes'
  ]);
  for (var vegetation in inventory.vegetationList) {
    rows.add([
      DateFormat('dd/MM/yyyy HH:mm:ss').format(vegetation.sampleTime!),
      numberFormat.format(vegetation.latitude),
      numberFormat.format(vegetation.longitude),
      vegetation.herbsProportion,
      vegetation.herbsDistribution?.index,
      vegetation.herbsHeight,
      vegetation.shrubsProportion,
      vegetation.shrubsDistribution?.index,
      vegetation.shrubsHeight,
      vegetation.treesProportion,
      vegetation.treesDistribution?.index,
      vegetation.treesHeight,
      vegetation.notes ?? '',
    ]);
  }
  
  // Add weather data
  rows.add([]); // Empty line to separate weather data
  rows.add(['WEATHER']);
  rows.add([
    'Date/Time',
    'Cloud cover',
    'Precipitation',
    'Temperature',
    'Wind speed'
  ]);
  for (var weather in inventory.weatherList) {
    rows.add([
      DateFormat('dd/MM/yyyy HH:mm:ss').format(weather.sampleTime!),
      weather.cloudCover,
      precipitationTypeFriendlyNames[weather.precipitation],
      NumberFormat.decimalPattern(locale.toString()).format(weather.temperature),
      weather.windSpeed
    ]);
  }
  
  // Add POIs data
  rows.add([]); // Empty line to separate POI data
  rows.add(['POINTS OF INTEREST']);
  for (var species in inventory.speciesList) {
    if (species.pois.isNotEmpty) {
      rows.add(['Species: ${species.name}']);
      rows.add(['Latitude', 'Longitude']);
      for (var poi in species.pois) {
        rows.add([
          numberFormat.format(poi.latitude), 
          numberFormat.format(poi.longitude)
        ]);
      }
      rows.add([]); // Empty line to
    }// separate species POIs
  }

  return rows;
}

Future<void> exportAllInactiveNestsToJson(BuildContext context) async {
  try {
    final nestProvider = Provider.of<NestProvider>(context, listen: false);
    final inactiveNests = nestProvider.inactiveNests;
    final jsonData = inactiveNests.map((nest) => nest.toJson()).toList();
    final jsonString = jsonEncode(jsonData);

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/nests.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    await Share.shareXFiles([
      XFile(filePath, mimeType: 'application/json'),
    ], text: S.current.nestExported(2), subject: S.current.nestData(2));
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text(S.current.errorExportingNest(2, error.toString())),
        ],
      ),
      ),
    );
  }
}

Future<void> exportNestToJson(BuildContext context, Nest nest) async {
  try {
    // 1. Create a list of data
    final nestJson = nest.toJson();
    final jsonString = jsonEncode(nestJson);

    // 2. Create the file in a temporary directory
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/nest_${nest.fieldNumber}.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    // 3. Share the file using share_plus
    await Share.shareXFiles([
      XFile(filePath, mimeType: 'application/json'),
    ], text: S.current.nestExported(1), subject: '${S.current.nestData(1)} ${nest.fieldNumber}');
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text(S.current.errorExportingNest(1, error.toString())),
        ],
      ),
      ),
    );
  }
}

Future<void> exportNestToCsv(BuildContext context, Nest nest) async {
  try {
    final locale = Localizations.localeOf(context);
    // 1. Create a list of data for the CSV
    List<List<dynamic>> rows = buildNestCsvRows(nest, locale);

    // 2. Convert the list of data to CSV
    String csv = const ListToCsvConverter().convert(rows, fieldDelimiter: ';');

    // 3. Create the file in a temporary directory
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/nest_${nest.id}.csv';
    final file = File(filePath);
    await file.writeAsString(csv);

    // 4. Share the file using share_plus
    await Share.shareXFiles([
      XFile(filePath, mimeType: 'text/csv'),
    ], text: S.current.nestExported(1), subject: '${S.current.nestData(1)} ${nest.id}');
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text(S.current.errorExportingNest(1, error.toString())),
        ],
      ),
      ),
    );
  }
}

// Add nest data to CSV rows
List<List<dynamic>> buildNestCsvRows(Nest nest, Locale locale) {
  final numberFormat = NumberFormat.decimalPattern(locale.toString())..maximumFractionDigits = 7;
  List<List<dynamic>> rows = [];
  rows.add([
    'Field number',
    'Species',
    'Locality',
    'Longitude',
    'Latitude',
    'Date found',
    'Support',
    'Height above ground',
    'Male',
    'Female',
    'Helpers',
    'Last date',
    'Fate',
  ]);
  rows.add([
    nest.fieldNumber,
    nest.speciesName,
    nest.localityName,
    numberFormat.format(nest.longitude),
    numberFormat.format(nest.latitude),
    nest.foundTime != null ? DateFormat('dd/MM/yyyy HH:mm:ss').format(nest.foundTime!) : '',
    nest.support,
    NumberFormat.decimalPattern(locale.toString()).format(nest.heightAboveGround),
    nest.male,
    nest.female,
    nest.helpers,
    nest.lastTime != null ? DateFormat('dd/MM/yyyy HH:mm:ss').format(nest.lastTime!) : '',
    nestFateTypeFriendlyNames[nest.nestFate],
  ]);
  
  // Add nest revision data
  rows.add([]); // Empty line as separator
  rows.add(['REVISIONS']);
  rows.add([
    'Date/Time',
    'Status',
    'Phase',
    'Host eggs',
    'Host nestlings',
    'Nidoparasite eggs',
    'Nidoparasite nestlings',
    'Has Philornis larvae',
    'Notes',
  ]);
  for (var revision in nest.revisionsList ?? []) {
    rows.add([
      DateFormat('dd/MM/yyyy HH:mm:ss').format(revision.sampleTime!),
      nestStatusTypeFriendlyNames[revision.nestStatus],
      nestStageTypeFriendlyNames[revision.nestStage],
      revision.eggsHost,
      revision.nestlingsHost,
      revision.eggsParasite,
      revision.nestlingsParasite,
      revision.hasPhilornisLarvae,
      revision.notes,
    ]);
  }
  
  // Add egg data
  rows.add([]);
  rows.add(['EGGS']);
  rows.add([
    'Date/Time',
    'Field number',
    'Species',
    'Egg shape',
    'Width',
    'Length',
    'Weight',
  ]);
  for (var egg in nest.eggsList ?? []) {
    rows.add([
      DateFormat('dd/MM/yyyy HH:mm:ss').format(egg.sampleTime!),
      egg.fieldNumber,
      egg.speciesName,
      eggShapeTypeFriendlyNames[egg.eggShape],
      NumberFormat.decimalPattern(locale.toString()).format(egg.width),
      NumberFormat.decimalPattern(locale.toString()).format(egg.length),
      NumberFormat.decimalPattern(locale.toString()).format(egg.mass),
    ]);
  }

  return rows;
}

Future<void> exportAllSpecimensToJson(BuildContext context) async {
  try {
    final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
    final specimenList = specimenProvider.specimens;
    final jsonData = specimenList.map((specimen) => specimen.toJson()).toList();
    final jsonString = jsonEncode(jsonData);

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/specimens.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    await Share.shareXFiles([
      XFile(filePath, mimeType: 'application/json'),
    ], text: S.current.specimenExported(2), subject: S.current.specimenData(2));
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text(S.current.errorExportingSpecimen(2, error.toString())),
        ],
      ),
      ),
    );
  }
}

Future<void> exportAllSpecimensToCsv(BuildContext context) async {
  try {
    final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
    final specimenList = specimenProvider.specimens;
    final locale = Localizations.localeOf(context);

    // 1. Create a list of data for the CSV
    List<List<dynamic>> rows = buildSpecimensCsvRows(specimenList, locale);

    // 2. Convert the list of data to CSV
    String csv = const ListToCsvConverter().convert(rows, fieldDelimiter: ';');

    // 3. Create the file in a temporary directory
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/specimens.csv';
    final file = File(filePath);
    await file.writeAsString(csv);

    // 4. Share the file using share_plus
    await Share.shareXFiles([
      XFile(filePath, mimeType: 'text/csv'),
    ], text: S.current.specimenExported(2), subject: S.current.specimenData(2));
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text(S.current.errorExportingSpecimen(2, error.toString())),
        ],
      ),
      ),
    );
  }
}

// Add specimens data to CSV rows
List<List<dynamic>> buildSpecimensCsvRows(List<Specimen> specimenList, Locale locale) {
  final numberFormat = NumberFormat.decimalPattern(locale.toString())..maximumFractionDigits = 7;
  List<List<dynamic>> rows = [];
  rows.add([
    'Date/Time',
    'Field number',
    'Species',
    'Type',
    'Locality',
    'Longitude',
    'Latitude',
    'Notes',
  ]);
  for (var specimen in specimenList) {
    rows.add([
      DateFormat('dd/MM/yyyy HH:mm:ss').format(specimen.sampleTime!),
      specimen.fieldNumber,
      specimen.speciesName,
      specimenTypeFriendlyNames[specimen.type],
      specimen.locality,
      numberFormat.format(specimen.longitude),
      numberFormat.format(specimen.latitude),
      specimen.notes,
    ]);
  }

  return rows;
}