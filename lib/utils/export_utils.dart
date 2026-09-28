import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:docx_creator/docx_creator.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:xml/xml.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/inventory.dart';
import '../data/models/journal.dart';
import '../data/models/nest.dart';
import '../data/models/specimen.dart';
import '../providers/inventory_provider.dart';
import '../providers/nest_provider.dart';

import '../core/core_consts.dart';
import '../generated/l10n.dart';

/// Marker written into every exported payload to identify the app source.
const String kExportSource = 'Xolmis Mobile';

/// Current version of the shared JSON export envelope schema.
const String kExportSchemaVersion = '1';

/// Ensures a single inventory has all child collections loaded before export.
Future<Inventory> _ensureInventoryLoadedForExport(
  BuildContext context,
  Inventory inventory, {
  InventoryProvider? inventoryProvider,
}) async {
  try {
    final provider = inventoryProvider ??
        Provider.of<InventoryProvider>(context, listen: false);
    await provider.loadInventoryDetails(inventory.id);
    return provider.getInventoryById(inventory.id) ?? inventory;
  } catch (error) {
    debugPrint('Error loading inventory details for export: $error');
    return inventory;
  }
}

/// Ensures a list of inventories has full details loaded before export.
Future<List<Inventory>> _ensureInventoriesLoadedForExport(
  BuildContext context,
  List<Inventory> inventories, {
  InventoryProvider? inventoryProvider,
}) async {
  if (inventories.isEmpty) return inventories;

  try {
    final provider = inventoryProvider ??
        Provider.of<InventoryProvider>(context, listen: false);
    final loaded =
        await provider.loadInventoriesDetails(inventories.map((i) => i.id).toList());

    if (loaded.length == inventories.length) {
      return loaded;
    }

    final loadedById = {for (final inventory in loaded) inventory.id: inventory};
    return inventories
        .map((inventory) => loadedById[inventory.id] ?? inventory)
        .toList();
  } catch (error) {
    debugPrint('Error loading inventories details for export: $error');
    return inventories;
  }
}

/// Ensures a single nest has revisions and eggs loaded before export.
Future<Nest> _ensureNestLoadedForExport(
  BuildContext context,
  Nest nest, {
  NestProvider? nestProvider,
}) async {
  if (nest.id == null) return nest;

  try {
    final provider = nestProvider ?? Provider.of<NestProvider>(context, listen: false);
    await provider.loadNestDetails(nest.id!);
    for (final loadedNest in provider.nests) {
      if (loadedNest.id == nest.id) {
        return loadedNest;
      }
    }
    return nest;
  } catch (error) {
    debugPrint('Error loading nest details for export: $error');
    return nest;
  }
}

/// Ensures a list of nests has full details loaded before export.
Future<List<Nest>> _ensureNestsLoadedForExport(
  BuildContext context,
  List<Nest> nests, {
  NestProvider? nestProvider,
}) async {
  if (nests.isEmpty) return nests;

  try {
    final provider = nestProvider ?? Provider.of<NestProvider>(context, listen: false);
    for (final nest in nests) {
      if (nest.id != null) {
        await provider.loadNestDetails(nest.id!);
      }
    }

    return nests.map((nest) {
      if (nest.id == null) return nest;
      for (final loadedNest in provider.nests) {
        if (loadedNest.id == nest.id) {
          return loadedNest;
        }
      }
      return nest;
    }).toList();
  } catch (error) {
    debugPrint('Error loading nests details for export: $error');
    return nests;
  }
}

/// A simple internal model for KML waypoints.
class _KmlWaypoint {
  final double? lat;
  final double? lon;
  final String name;
  final String description;
  final DateTime? time;

  _KmlWaypoint({
    required this.lat,
    required this.lon,
    required this.name,
    this.description = '',
    this.time,
  });
}

/// Generates a KML string with waypoints using the `xml` package.
String _buildKmlString({
  required String name,
  String? description,
  required List<_KmlWaypoint> waypoints,
}) {
  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element('kml', attributes: {'xmlns': 'http://www.opengis.net/kml/2.2'}, nest: () {
    builder.element('Document', nest: () {
      builder.element('name', nest: name);
      if (description != null && description.isNotEmpty) {
        builder.element('description', nest: description);
      }

      for (final wpt in waypoints) {
        if (wpt.lat == null || wpt.lon == null) continue;

        builder.element('Placemark', nest: () {
          builder.element('name', nest: wpt.name);
          if (wpt.description.isNotEmpty) {
            builder.element('description', nest: wpt.description);
          }
          if (wpt.time != null) {
            builder.element('TimeStamp', nest: () {
              builder.element('when', nest: wpt.time!.toIso8601String());
            });
          }
          builder.element('Point', nest: () {
            // KML coordinates are (longitude, latitude, [altitude])
            builder.element('coordinates', nest: '${wpt.lon},${wpt.lat},0');
          });
        });
      }
    });
  });

  return builder.buildDocument().toXmlString(pretty: true, indent: '  ');
}

/// Requests storage permission and returns `true` when access is granted.
Future<bool> requestStoragePermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }
  return status.isGranted;
}

/// Exports all finished inventories as a JSON envelope and opens the share sheet.
Future<void> exportAllInventoriesToJson(BuildContext context, InventoryProvider inventoryProvider) async {
  bool isDialogShown = false;

  try {
    // Show a loading dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(year2023: false,),
                  SizedBox(width: 16),
                  Text(S.current.exporting),
                ],
              ),
            ),
          );
        },
      );
      isDialogShown = true;

    final finishedInventories = await _ensureInventoriesLoadedForExport(
      context,
      inventoryProvider.finishedInventories,
      inventoryProvider: inventoryProvider,
    );
    final jsonData = {
      'source': kExportSource,
      'schema': 'inventories',
      'schemaVersion': kExportSchemaVersion,
      'records': finishedInventories.map((inventory) => inventory.toJson()).toList(),
    };
    var encoder = JsonEncoder.withIndent("  ");
    final jsonString = encoder.convert(jsonData);

    // Get the current date and time
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    // Create the file in a temporary folder
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/inventories_$formattedDate.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    if (isDialogShown) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        isDialogShown = false; // Dialog is now closed
      }

    // Share the file using share_plus
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/json')], 
        title: S.current.inventoryExported(2),
        subject: S.current.inventoryData(2)
      ),
    );
  } catch (error) {
    if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            persist: true,
                            showCloseIcon: true,
                            backgroundColor: Theme.of(context).colorScheme.error,
                            content: Text(S.of(context).errorExportingInventory(1, error.toString())),
                          ),
                        );
    }
    return;
  } finally {
    // Ensure the dialog is always closed if it was shown and an error occurred,
    // or if the function returned early while the dialog was up.
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Exports one inventory as JSON, ensuring lazy-loaded children are available.
Future<void> exportInventoryToJson(BuildContext context, Inventory inventory, bool shareIt) async {
  try {
    final inventoryToExport =
        await _ensureInventoryLoadedForExport(context, inventory);
    final jsonData = {
      'source': kExportSource,
      'schema': 'inventories',
      'schemaVersion': kExportSchemaVersion,
      'records': [inventoryToExport.toJson()],
    };
    
    var encoder = JsonEncoder.withIndent("  ");
    final jsonString = encoder.convert(jsonData);
    
    // Create the file in a temporary folder
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/inventory_${inventoryToExport.id}.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    // Share the file using share_plus
    if (shareIt) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/json')],
          title: S.current.inventoryExported(1),
          subject: '${S.current.inventoryExported(1)} ${inventoryToExport.id}'
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            persist: true,
                            showCloseIcon: true,
                            backgroundColor: Theme.of(context).colorScheme.error,
                            content: Text(S.of(context).errorExportingInventory(1, error.toString())),
                          ),
                        );
    }
    return;
  }
}

// --- Darwin Core Aligned Headers ---

/// Headers for Inventory species occurrences (Occurrences table/sheet).
const List<String> kInventoryOccurrencesHeaders = [
  'eventID',
  'samplingProtocol',
  'samplingEffort',
  'eventDate',
  'eventTime',
  'eventEndDate',
  'eventEndTime',
  'locality',
  'decimalLongitude',
  'decimalLatitude',
  'endLongitude',
  'endLatitude',
  'recordedBy',
  'totalObservers',
  'samplingIntervals',
  'pausedTimeSeconds',
  'eventRemarks',
  'isDiscarded',
  'scientificName',
  'individualCount',
  'occurrenceTime',
  'isOutOfSample',
  'distance',
  'flightHeight',
  'flightDirection',
  'occurrenceRemarks',
];

/// Headers for Vegetation measurements (Vegetation table/sheet).
const List<String> kInventoryVegetationHeaders = [
  'eventID',
  'samplingProtocol',
  'samplingEffort',
  'eventDate',
  'eventTime',
  'locality',
  'decimalLongitude',
  'decimalLatitude',
  'recordedBy',
  'eventRemarks',
  'measurementDate',
  'measurementLatitude',
  'measurementLongitude',
  'herbsProportion',
  'herbsDistribution',
  'herbsHeight',
  'shrubsProportion',
  'shrubsDistribution',
  'shrubsHeight',
  'treesProportion',
  'treesDistribution',
  'treesHeight',
  'measurementRemarks',
];

/// Headers for Weather measurements (Weather table/sheet).
const List<String> kInventoryWeatherHeaders = [
  'eventID',
  'samplingProtocol',
  'samplingEffort',
  'eventDate',
  'eventTime',
  'locality',
  'decimalLongitude',
  'decimalLatitude',
  'recordedBy',
  'eventRemarks',
  'measurementDate',
  'cloudCover',
  'precipitation',
  'temperature',
  'windSpeed',
  'windDirection',
  'atmosphericPressure',
  'relativeHumidity',
];

/// Headers for Points of Interest (POIs table/sheet).
const List<String> kInventoryPoiHeaders = [
  'eventID',
  'samplingProtocol',
  'eventDate',
  'locality',
  'recordedBy',
  'scientificName',
  'poiDate',
  'decimalLatitude',
  'decimalLongitude',
  'poiRemarks',
];

/// Headers for Inventory summary (Events table/sheet).
const List<String> kInventoryEventsHeaders = [
  'eventID',
  'samplingProtocol',
  'samplingEffort',
  'maxSpecies',
  'eventDate',
  'eventTime',
  'eventEndDate',
  'eventEndTime',
  'locality',
  'decimalLongitude',
  'decimalLatitude',
  'endLongitude',
  'endLatitude',
  'totalObservers',
  'recordedBy',
  'samplingIntervals',
  'pausedTimeSeconds',
  'eventRemarks',
  'isDiscarded',
];

List<dynamic> _buildInventoryPrefix(
  Inventory inventory,
  NumberFormat numberFormat,
  bool formatNumbers,
) {
  return [
    inventory.id,
    inventoryTypeFriendlyNames[inventory.type] ?? '',
    inventory.duration,
    inventory.startTime != null
        ? DateFormat('yyyy-MM-dd').format(inventory.startTime!)
        : '',
    inventory.startTime != null
        ? DateFormat('HH:mm:ss').format(inventory.startTime!)
        : '',
    inventory.endTime != null
        ? DateFormat('yyyy-MM-dd').format(inventory.endTime!)
        : '',
    inventory.endTime != null
        ? DateFormat('HH:mm:ss').format(inventory.endTime!)
        : '',
    inventory.localityName ?? '',
    inventory.startLongitude != null
        ? (formatNumbers
            ? numberFormat.format(inventory.startLongitude)
            : inventory.startLongitude)
        : '',
    inventory.startLatitude != null
        ? (formatNumbers
            ? numberFormat.format(inventory.startLatitude)
            : inventory.startLatitude)
        : '',
    inventory.endLongitude != null
        ? (formatNumbers
            ? numberFormat.format(inventory.endLongitude)
            : inventory.endLongitude)
        : '',
    inventory.endLatitude != null
        ? (formatNumbers
            ? numberFormat.format(inventory.endLatitude)
            : inventory.endLatitude)
        : '',
    inventory.observer ?? '',
    inventory.totalObservers == 0 ? '' : inventory.totalObservers,
    inventory.currentInterval == 0 ? '' : inventory.currentInterval,
    inventory.totalPausedTimeInSeconds == 0
        ? ''
        : inventory.totalPausedTimeInSeconds,
    inventory.notes ?? '',
    inventory.isDiscarded ? 'Yes' : 'No',
  ];
}

/// Builds flat denormalized species occurrences rows for a list of inventories.
Future<List<List<dynamic>>> buildInventoriesSpeciesRows(
  List<Inventory> inventories,
  Locale locale,
) async {
  final List<List<dynamic>> rows = [kInventoryOccurrencesHeaders];
  final numberFormat = NumberFormat.decimalPattern(locale.toString())
    ..maximumFractionDigits = 7;
  final prefs = await SharedPreferences.getInstance();
  final formatNumbers = prefs.getBool('formatNumbers') ?? true;

  for (var inventory in inventories) {
    final prefix = _buildInventoryPrefix(inventory, numberFormat, formatNumbers);
    if (inventory.speciesList.isNotEmpty) {
      for (var species in inventory.speciesList) {
        rows.add([
          ...prefix,
          species.name,
          species.count,
          species.sampleTime != null
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format(species.sampleTime!)
              : '',
          species.isOutOfInventory ? 'Yes' : 'No',
          species.distance != null
              ? (formatNumbers
                  ? numberFormat.format(species.distance)
                  : species.distance)
              : '',
          species.flightHeight != null
              ? (formatNumbers
                  ? numberFormat.format(species.flightHeight)
                  : species.flightHeight)
              : '',
          species.flightDirection ?? '',
          species.notes ?? '',
        ]);
      }
    } else {
      rows.add([
        ...prefix,
        '', '', '', '', '', '', '', ''
      ]);
    }
  }

  return rows;
}

/// Builds flat denormalized vegetation measurement rows for a list of inventories.
Future<List<List<dynamic>>> buildInventoriesVegetationRows(
  List<Inventory> inventories,
  Locale locale,
) async {
  final List<List<dynamic>> rows = [kInventoryVegetationHeaders];
  final numberFormat = NumberFormat.decimalPattern(locale.toString())
    ..maximumFractionDigits = 7;
  final prefs = await SharedPreferences.getInstance();
  final formatNumbers = prefs.getBool('formatNumbers') ?? true;

  for (var inventory in inventories) {
    if (inventory.vegetationList.isEmpty) continue;
    final prefix = [
      inventory.id,
      inventoryTypeFriendlyNames[inventory.type] ?? '',
      inventory.duration,
      inventory.startTime != null
          ? DateFormat('yyyy-MM-dd').format(inventory.startTime!)
          : '',
      inventory.startTime != null
          ? DateFormat('HH:mm:ss').format(inventory.startTime!)
          : '',
      inventory.localityName ?? '',
      inventory.startLongitude != null
          ? (formatNumbers
              ? numberFormat.format(inventory.startLongitude)
              : inventory.startLongitude)
          : '',
      inventory.startLatitude != null
          ? (formatNumbers
              ? numberFormat.format(inventory.startLatitude)
              : inventory.startLatitude)
          : '',
      inventory.observer ?? '',
      inventory.notes ?? '',
    ];

    for (var veg in inventory.vegetationList) {
      rows.add([
        ...prefix,
        veg.sampleTime != null
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(veg.sampleTime!)
            : '',
        veg.latitude != null
            ? (formatNumbers
                ? numberFormat.format(veg.latitude)
                : veg.latitude)
            : '',
        veg.longitude != null
            ? (formatNumbers
                ? numberFormat.format(veg.longitude)
                : veg.longitude)
            : '',
        veg.herbsProportion ?? '',
        veg.herbsDistribution?.index ?? '',
        veg.herbsHeight ?? '',
        veg.shrubsProportion ?? '',
        veg.shrubsDistribution?.index ?? '',
        veg.shrubsHeight ?? '',
        veg.treesProportion ?? '',
        veg.treesDistribution?.index ?? '',
        veg.treesHeight ?? '',
        veg.notes ?? '',
      ]);
    }
  }

  return rows;
}

/// Builds flat denormalized weather log rows for a list of inventories.
Future<List<List<dynamic>>> buildInventoriesWeatherRows(
  List<Inventory> inventories,
  Locale locale,
) async {
  final List<List<dynamic>> rows = [kInventoryWeatherHeaders];
  final numberFormat = NumberFormat.decimalPattern(locale.toString())
    ..maximumFractionDigits = 7;
  final prefs = await SharedPreferences.getInstance();
  final formatNumbers = prefs.getBool('formatNumbers') ?? true;

  for (var inventory in inventories) {
    if (inventory.weatherList.isEmpty) continue;
    final prefix = [
      inventory.id,
      inventoryTypeFriendlyNames[inventory.type] ?? '',
      inventory.duration,
      inventory.startTime != null
          ? DateFormat('yyyy-MM-dd').format(inventory.startTime!)
          : '',
      inventory.startTime != null
          ? DateFormat('HH:mm:ss').format(inventory.startTime!)
          : '',
      inventory.localityName ?? '',
      inventory.startLongitude != null
          ? (formatNumbers
              ? numberFormat.format(inventory.startLongitude)
              : inventory.startLongitude)
          : '',
      inventory.startLatitude != null
          ? (formatNumbers
              ? numberFormat.format(inventory.startLatitude)
              : inventory.startLatitude)
          : '',
      inventory.observer ?? '',
      inventory.notes ?? '',
    ];

    for (var weather in inventory.weatherList) {
      rows.add([
        ...prefix,
        weather.sampleTime != null
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(weather.sampleTime!)
            : '',
        weather.cloudCover ?? '',
        precipitationTypeFriendlyNames[weather.precipitation] ?? '',
        weather.temperature != null
            ? (formatNumbers
                ? numberFormat.format(weather.temperature)
                : weather.temperature)
            : '',
        weather.windSpeed ?? '',
        weather.windDirection ?? '',
        weather.atmosphericPressure ?? '',
        weather.relativeHumidity ?? '',
      ]);
    }
  }

  return rows;
}

/// Builds flat denormalized POI rows for a list of inventories.
Future<List<List<dynamic>>> buildInventoriesPoiRows(
  List<Inventory> inventories,
  Locale locale,
) async {
  final List<List<dynamic>> rows = [kInventoryPoiHeaders];
  final numberFormat = NumberFormat.decimalPattern(locale.toString())
    ..maximumFractionDigits = 7;
  final prefs = await SharedPreferences.getInstance();
  final formatNumbers = prefs.getBool('formatNumbers') ?? true;

  for (var inventory in inventories) {
    final prefix = [
      inventory.id,
      inventoryTypeFriendlyNames[inventory.type] ?? '',
      inventory.startTime != null
          ? DateFormat('yyyy-MM-dd').format(inventory.startTime!)
          : '',
      inventory.localityName ?? '',
      inventory.observer ?? '',
    ];

    for (var species in inventory.speciesList) {
      if (species.pois.isEmpty) continue;
      for (var poi in species.pois) {
        rows.add([
          ...prefix,
          species.name,
          poi.sampleTime != null
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format(poi.sampleTime!)
              : '',
          formatNumbers ? numberFormat.format(poi.latitude) : poi.latitude,
          formatNumbers ? numberFormat.format(poi.longitude) : poi.longitude,
          poi.notes ?? '',
        ]);
      }
    }
  }

  return rows;
}

/// Builds inventory summary rows for a list of inventories.
Future<List<List<dynamic>>> buildInventoriesSummaryRows(
  List<Inventory> inventories,
  Locale locale,
) async {
  final List<List<dynamic>> rows = [kInventoryEventsHeaders];
  final numberFormat = NumberFormat.decimalPattern(locale.toString())
    ..maximumFractionDigits = 7;
  final prefs = await SharedPreferences.getInstance();
  final formatNumbers = prefs.getBool('formatNumbers') ?? true;

  for (var inventory in inventories) {
    rows.add([
      inventory.id,
      inventoryTypeFriendlyNames[inventory.type] ?? '',
      inventory.duration,
      inventory.maxSpecies,
      inventory.startTime != null
          ? DateFormat('yyyy-MM-dd').format(inventory.startTime!)
          : '',
      inventory.startTime != null
          ? DateFormat('HH:mm:ss').format(inventory.startTime!)
          : '',
      inventory.endTime != null
          ? DateFormat('yyyy-MM-dd').format(inventory.endTime!)
          : '',
      inventory.endTime != null
          ? DateFormat('HH:mm:ss').format(inventory.endTime!)
          : '',
      inventory.localityName ?? '',
      inventory.startLongitude != null
          ? (formatNumbers
              ? numberFormat.format(inventory.startLongitude)
              : inventory.startLongitude)
          : '',
      inventory.startLatitude != null
          ? (formatNumbers
              ? numberFormat.format(inventory.startLatitude)
              : inventory.startLatitude)
          : '',
      inventory.endLongitude != null
          ? (formatNumbers
              ? numberFormat.format(inventory.endLongitude)
              : inventory.endLongitude)
          : '',
      inventory.endLatitude != null
          ? (formatNumbers
              ? numberFormat.format(inventory.endLatitude)
              : inventory.endLatitude)
          : '',
      inventory.totalObservers == 0 ? '' : inventory.totalObservers,
      inventory.observer ?? '',
      inventory.currentInterval == 0 ? '' : inventory.currentInterval,
      inventory.totalPausedTimeInSeconds == 0
          ? ''
          : inventory.totalPausedTimeInSeconds,
      inventory.notes ?? '',
      inventory.isDiscarded ? 'Yes' : 'No',
    ]);
  }

  return rows;
}

/// Builds tabular rows for an inventory export.
Future<List<List<dynamic>>> buildInventoryRows(
  Inventory inventory,
  Locale locale,
) async {
  return buildInventoriesSpeciesRows([inventory], locale);
}

/// Converts a dynamic value into an Excel [CellValue] preserving basic types.
CellValue _convertToCellValue(dynamic val) {
  if (val == null) {
    return TextCellValue('');
  }
  if (val is String) {
    return TextCellValue(val);
  }
  if (val is int) {
    return IntCellValue(val);
  }
  if (val is double) {
    return DoubleCellValue(val);
  }
  if (val is bool) {
    return BoolCellValue(val);
  }

  return TextCellValue(val.toString());
}

/// Converts matrix rows into Excel-compatible [CellValue] rows.
List<List<CellValue>> convertRowsToCellValues(List<List<dynamic>> dynamicRows) {
  List<List<CellValue>> cellValueRows = [];
  for (var dynamicRow in dynamicRows) {
    List<CellValue> cellValueRow = [];
    for (var val in dynamicRow) {
      cellValueRow.add(_convertToCellValue(val));
    }
    cellValueRows.add(cellValueRow);
  }
  return cellValueRows;
}

/// Builds an Excel workbook with sheets for Occurrences, Vegetation, Weather, POIs, and Events.
Future<Excel> _createInventoriesExcel(
  List<Inventory> inventories,
  Locale locale,
) async {
  final excel = Excel.createExcel();

  final speciesRows = await buildInventoriesSpeciesRows(inventories, locale);
  final occSheet = excel['Occurrences'];
  for (var row in convertRowsToCellValues(speciesRows)) {
    occSheet.appendRow(row);
  }
  if (excel.sheets.containsKey('Sheet1')) {
    excel.delete('Sheet1');
  }

  final vegRows = await buildInventoriesVegetationRows(inventories, locale);
  if (vegRows.length > 1) {
    final vegSheet = excel['Vegetation'];
    for (var row in convertRowsToCellValues(vegRows)) {
      vegSheet.appendRow(row);
    }
  }

  final weatherRows = await buildInventoriesWeatherRows(inventories, locale);
  if (weatherRows.length > 1) {
    final weatherSheet = excel['Weather'];
    for (var row in convertRowsToCellValues(weatherRows)) {
      weatherSheet.appendRow(row);
    }
  }

  final poiRows = await buildInventoriesPoiRows(inventories, locale);
  if (poiRows.length > 1) {
    final poiSheet = excel['POIs'];
    for (var row in convertRowsToCellValues(poiRows)) {
      poiSheet.appendRow(row);
    }
  }

  final eventsRows = await buildInventoriesSummaryRows(inventories, locale);
  final eventsSheet = excel['Events'];
  for (var row in convertRowsToCellValues(eventsRows)) {
    eventsSheet.appendRow(row);
  }

  return excel;
}

/// Exports one inventory to an Excel file and returns the generated path.
Future<String> exportInventoryToExcel(
  BuildContext context,
  Inventory inventory,
  Locale locale,
) async {
  try {
    final inventoryToExport =
        await _ensureInventoryLoadedForExport(context, inventory);
    final excel = await _createInventoriesExcel([inventoryToExport], locale);

    var fileBytes = excel.save();
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/inventory_${inventoryToExport.id}.xlsx';
    if (fileBytes != null) {
      File(filePath)
        ..create(recursive: true)
        ..writeAsBytes(fileBytes);
      return filePath;
    } else {
      throw Exception('Failed to generate Excel file.');
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: true,
          showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            S.of(context).errorExportingInventory(1, error.toString()),
          ),
        ),
      );
    }
    return '';
  }
}

/// Exports one inventory to CSV files (species, vegetation, weather, pois) and returns the list of generated paths.
Future<List<String>> exportInventoryToCsv(
  BuildContext context,
  Inventory inventory,
  Locale locale,
) async {
  try {
    final inventoryToExport =
        await _ensureInventoryLoadedForExport(context, inventory);
    final filePaths = <String>[];

    // Export species data
    List<List<dynamic>> speciesRows =
        await buildInventoriesSpeciesRows([inventoryToExport], locale);
    if (speciesRows.isNotEmpty) {
      String speciesCsv = Csv(fieldDelimiter: ';').encode(speciesRows);
      Directory tempDir = await getTemporaryDirectory();
      final speciesFilePath = '${tempDir.path}/inventory_${inventoryToExport.id}_species.csv';
      if (speciesCsv.isNotEmpty) {
        final file = File(speciesFilePath);
        await file.writeAsString(speciesCsv);
        filePaths.add(speciesFilePath);
      }
    }

    // Export POI data
    List<List<dynamic>> poiRows =
        await buildInventoriesPoiRows([inventoryToExport], locale);
    if (poiRows.length > 1) {
      String poiCsv = Csv(fieldDelimiter: ';').encode(poiRows);
      Directory tempDir = await getTemporaryDirectory();
      final poiFilePath = '${tempDir.path}/inventory_${inventoryToExport.id}_pois.csv';
      if (poiCsv.isNotEmpty) {
        final file = File(poiFilePath);
        await file.writeAsString(poiCsv);
        filePaths.add(poiFilePath);
      }
    }

    // Export vegetation data
    List<List<dynamic>> vegRows =
        await buildInventoriesVegetationRows([inventoryToExport], locale);
    if (vegRows.length > 1) {
      String vegCsv = Csv(fieldDelimiter: ';').encode(vegRows);
      Directory tempDir = await getTemporaryDirectory();
      final vegFilePath = '${tempDir.path}/inventory_${inventoryToExport.id}_vegetation.csv';
      if (vegCsv.isNotEmpty) {
        final file = File(vegFilePath);
        await file.writeAsString(vegCsv);
        filePaths.add(vegFilePath);
      }
    }

    // Export weather data
    List<List<dynamic>> weatherRows =
        await buildInventoriesWeatherRows([inventoryToExport], locale);
    if (weatherRows.length > 1) {
      String weatherCsv = Csv(fieldDelimiter: ';').encode(weatherRows);
      Directory tempDir = await getTemporaryDirectory();
      final weatherFilePath = '${tempDir.path}/inventory_${inventoryToExport.id}_weather.csv';
      if (weatherCsv.isNotEmpty) {
        final file = File(weatherFilePath);
        await file.writeAsString(weatherCsv);
        filePaths.add(weatherFilePath);
      }
    }

    if (filePaths.isEmpty) {
      throw Exception('Failed to generate CSV files.');
    }
    return filePaths;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: true,
          showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            S.of(context).errorExportingInventory(1, error.toString()),
          ),
        ),
      );
    }
    return [];
  }
}

/// Exports one inventory POI dataset to KML and opens the share sheet.
Future<void> exportInventoryToKml(
  BuildContext context,
  Inventory inventory,
) async {
  try {
    final inventoryToExport =
        await _ensureInventoryLoadedForExport(context, inventory);
    final List<_KmlWaypoint> waypoints = [];

    if (inventoryToExport.startLatitude != null &&
        inventoryToExport.startLongitude != null) {
      waypoints.add(_KmlWaypoint(
        lat: inventoryToExport.startLatitude,
        lon: inventoryToExport.startLongitude,
        name: '${inventoryToExport.id} - Start',
        description: inventoryTypeFriendlyNames[inventoryToExport.type] ?? '',
        time: inventoryToExport.startTime,
      ));
    }

    if (inventoryToExport.endLatitude != null &&
        inventoryToExport.endLongitude != null) {
      waypoints.add(_KmlWaypoint(
        lat: inventoryToExport.endLatitude,
        lon: inventoryToExport.endLongitude,
        name: '${inventoryToExport.id} - End',
        description: inventoryTypeFriendlyNames[inventoryToExport.type] ?? '',
        time: inventoryToExport.endTime,
      ));
    }

    for (var species in inventoryToExport.speciesList) {
      for (var poi in species.pois) {
        waypoints.add(_KmlWaypoint(
          lat: poi.latitude,
          lon: poi.longitude,
          name: '${species.name} - POI #${poi.id}',
          description: poi.notes ?? '',
          time: poi.sampleTime,
        ));
      }
    }

    if (waypoints.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text(S.of(context).noPoisToExport),
          ),
        );
      }
      return;
    }

    final kmlString = _buildKmlString(
      name: 'Inventory ${inventoryToExport.id}',
      description: 'Points of Interest for Inventory ${inventoryToExport.id}',
      waypoints: waypoints,
    );

    Directory tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/inventory_${inventoryToExport.id}_pois.kml';
    final file = File(filePath);
    await file.writeAsString(kmlString);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(filePath, mimeType: 'application/vnd.google-earth.kml+xml')
        ],
        title: S.current.inventoryExported(1),
        subject: '${S.current.inventoryExported(1)} ${inventoryToExport.id}',
      ),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: true,
          showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            S.of(context).errorExportingInventory(1, error.toString()),
          ),
        ),
      );
    }
    return;
  }
}

/// Exports selected inventories to a single JSON envelope.
Future<void> exportSelectedInventoriesToJson(
  BuildContext context,
  List<Inventory> inventories,
) async {
  try {
    final inventoriesToExport =
        await _ensureInventoriesLoadedForExport(context, inventories);
    final jsonData = {
      'source': kExportSource,
      'schema': 'inventories',
      'schemaVersion': kExportSchemaVersion,
      'records':
          inventoriesToExport.map((inventory) => inventory.toJson()).toList(),
    };
    var encoder = JsonEncoder.withIndent("  ");
    final jsonString = encoder.convert(jsonData);

    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/selected_inventories_$formattedDate.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/json')],
        title: S.current.inventoryExported(inventories.length),
        subject: S.current.inventoryData(inventories.length),
      ),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: true,
          showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            S.of(context).errorExportingInventory(
              inventories.length,
              error.toString(),
            ),
          ),
        ),
      );
    }
  }
}

/// Exports selected inventories to a single CSV file and shares it.
Future<void> exportSelectedInventoriesToCsv(
  BuildContext context,
  List<Inventory> inventories,
) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(year2023: false),
              SizedBox(width: 16),
              Text(S.current.exportingPleaseWait),
            ],
          ),
        ),
      );
    },
  );
  try {
    final locale = Localizations.localeOf(context);
    final inventoriesToExport =
        await _ensureInventoriesLoadedForExport(context, inventories);

    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    final filePaths = <String>[];

    // Export species data
    List<List<dynamic>> speciesRows =
        await buildInventoriesSpeciesRows(inventoriesToExport, locale);
    if (speciesRows.isNotEmpty) {
      String speciesCsv = Csv(fieldDelimiter: ';').encode(speciesRows);
      Directory tempDir = await getTemporaryDirectory();
      final speciesFilePath = '${tempDir.path}/selected_inventories_${formattedDate}_species.csv';
      if (speciesCsv.isNotEmpty) {
        final file = File(speciesFilePath);
        await file.writeAsString(speciesCsv);
        filePaths.add(speciesFilePath);
      }
    }

    // Export POI data
    List<List<dynamic>> poiRows =
        await buildInventoriesPoiRows(inventoriesToExport, locale);
    if (poiRows.length > 1) {
      String poiCsv = Csv(fieldDelimiter: ';').encode(poiRows);
      Directory tempDir = await getTemporaryDirectory();
      final poiFilePath = '${tempDir.path}/selected_inventories_${formattedDate}_pois.csv';
      if (poiCsv.isNotEmpty) {
        final file = File(poiFilePath);
        await file.writeAsString(poiCsv);
        filePaths.add(poiFilePath);
      }
    }

    // Export vegetation data
    List<List<dynamic>> vegRows =
        await buildInventoriesVegetationRows(inventoriesToExport, locale);
    if (vegRows.length > 1) {
      String vegCsv = Csv(fieldDelimiter: ';').encode(vegRows);
      Directory tempDir = await getTemporaryDirectory();
      final vegFilePath = '${tempDir.path}/selected_inventories_${formattedDate}_vegetation.csv';
      if (vegCsv.isNotEmpty) {
        final file = File(vegFilePath);
        await file.writeAsString(vegCsv);
        filePaths.add(vegFilePath);
      }
    }

    // Export weather data
    List<List<dynamic>> weatherRows =
        await buildInventoriesWeatherRows(inventoriesToExport, locale);
    if (weatherRows.length > 1) {
      String weatherCsv = Csv(fieldDelimiter: ';').encode(weatherRows);
      Directory tempDir = await getTemporaryDirectory();
      final weatherFilePath = '${tempDir.path}/selected_inventories_${formattedDate}_weather.csv';
      if (weatherCsv.isNotEmpty) {
        final file = File(weatherFilePath);
        await file.writeAsString(weatherCsv);
        filePaths.add(weatherFilePath);
      }
    }

    if (filePaths.isNotEmpty) {
      await SharePlus.instance.share(
        ShareParams(
          files: filePaths.map((f) => XFile(f, mimeType: 'text/csv')).toList(),
          title: S.current.inventoryExported(inventories.length),
          subject: S.current.inventoryData(inventories.length),
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: true,
          showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            S.of(context).errorExportingInventory(
              inventories.length,
              error.toString(),
            ),
          ),
        ),
      );
    }
  } finally {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Exports selected inventories to a single Excel file and shares it.
Future<void> exportSelectedInventoriesToExcel(
  BuildContext context,
  List<Inventory> inventories,
) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(year2023: false),
              SizedBox(width: 16),
              Text(S.current.exportingPleaseWait),
            ],
          ),
        ),
      );
    },
  );
  try {
    final locale = Localizations.localeOf(context);
    final inventoriesToExport =
        await _ensureInventoriesLoadedForExport(context, inventories);
    final excel = await _createInventoriesExcel(inventoriesToExport, locale);

    var fileBytes = excel.save();
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    Directory tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/selected_inventories_$formattedDate.xlsx';
    if (fileBytes != null) {
      File(filePath)
        ..create(recursive: true)
        ..writeAsBytes(fileBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              filePath,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            )
          ],
          title: S.current.inventoryExported(inventories.length),
          subject: S.current.inventoryData(inventories.length),
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: true,
          showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(
            S.of(context).errorExportingInventory(
              inventories.length,
              error.toString(),
            ),
          ),
        ),
      );
    }
  } finally {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Exports selected inventories to one KML file and opens the share sheet.
Future<void> exportSelectedInventoriesToKml(BuildContext context, List<Inventory> inventories) async {
  try {
    final inventoriesToExport =
        await _ensureInventoriesLoadedForExport(context, inventories);
    final List<_KmlWaypoint> waypoints = [];

    for (final inventory in inventoriesToExport) {
      if (inventory.startLatitude != null && inventory.startLongitude != null) {
        waypoints.add(
          _KmlWaypoint(
            lat: inventory.startLatitude,
            lon: inventory.startLongitude,
            name: '${inventory.id} - Start',
            description: inventoryTypeFriendlyNames[inventory.type] ?? '',
            time: inventory.startTime,
          ),
        );
      }

      if (inventory.endLatitude != null && inventory.endLongitude != null) {
        waypoints.add(
          _KmlWaypoint(
            lat: inventory.endLatitude,
            lon: inventory.endLongitude,
            name: '${inventory.id} - End',
            description: inventoryTypeFriendlyNames[inventory.type] ?? '',
            time: inventory.endTime,
          ),
        );
      }

      for (final species in inventory.speciesList) {
        for (final poi in species.pois) {
          waypoints.add(
            _KmlWaypoint(
              lat: poi.latitude,
              lon: poi.longitude,
              name: '${inventory.id} - ${species.name} - POI #${poi.id}',
              description: poi.notes ?? '',
              time: poi.sampleTime,
            ),
          );
        }
      }
    }

    if (waypoints.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(S.of(context).noPoisToExport),
        ),
      );
      return;
    }

    final kmlString = _buildKmlString(
      name: 'Selected inventories',
      description: 'Points of Interest for selected inventories',
      waypoints: waypoints,
    );

    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/selected_inventories_$formattedDate.kml';
    final file = File(filePath);
    await file.writeAsString(kmlString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/vnd.google-earth.kml+xml')],
        title: S.current.inventoryExported(inventoriesToExport.length),
        subject: S.current.inventoryData(inventoriesToExport.length),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          S.of(context).errorExportingInventory(inventories.length, error.toString()),
        ),
      ),
    );
  }
}

List<dynamic>? _parseJournalDeltaOps(String? notes) {
  if (notes == null || notes.trim().isEmpty) {
    return null;
  }

  try {
    final decoded = jsonDecode(notes);
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic> && decoded['ops'] is List) {
      return decoded['ops'] as List<dynamic>;
    }
  } catch (_) {
    return null;
  }

  return null;
}

String _extractJournalEmbedPlaceholder(dynamic insert) {
  if (insert is! Map) {
    return '[Embedded content]';
  }

  final type = insert['_type'] as String?;
  if (type == 'image') {
    final source = insert['source'] as String? ?? '';
    return '[Image: ${source.isNotEmpty ? source : 'attached'}]';
  }
  if (type == 'hr') {
    return '---';
  }

  return '[Embedded ${type ?? 'content'}]';
}

String? _extractJournalImageSource(Map<dynamic, dynamic> insert) {
  final directCandidates = <dynamic>[
    insert['source'],
    insert['src'],
    insert['url'],
    insert['path'],
  ];

  for (final candidate in directCandidates) {
    if (candidate is String && candidate.trim().isNotEmpty) {
      return candidate.trim();
    }
  }

  final nested = insert['data'];
  if (nested is Map) {
    final nestedCandidates = <dynamic>[
      nested['source'],
      nested['src'],
      nested['url'],
      nested['path'],
    ];

    for (final candidate in nestedCandidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
  }

  return null;
}

/// Builds Markdown representation for Fleather embeds used by DOCX export.
String _extractJournalEmbedMarkdown(dynamic insert) {
  if (insert is! Map) {
    return '[Embedded content]';
  }

  final type = insert['_type'] as String?;
  if (type == 'image') {
    final source = _extractJournalImageSource(insert);
    final alt = (insert['alt'] as String? ?? 'Image').trim();
    if (source == null || source.isEmpty) {
      return '[Image: attached]';
    }
    // Keep Markdown syntax so regular Markdown export and DOCX conversion can embed images.
    return '![${alt.isEmpty ? 'Image' : alt}]($source)';
  }
  if (type == 'hr') {
    return '---';
  }

  return '[Embedded ${type ?? 'content'}]';
}

String _journalDeltaToPlainText(String? notes) {
  final ops = _parseJournalDeltaOps(notes);
  if (ops == null) {
    return notes ?? '';
  }

  final output = StringBuffer();
  final currentLine = StringBuffer();
  var orderedIndex = 1;
  var hasWrittenElements = false;
  String? lastBlockType;
  bool? currentLineChecked;

  bool isBlockType(String? blockType) {
    return blockType == 'ul' ||
        blockType == 'ol' ||
        blockType == 'cl' ||
        blockType == 'quote' ||
        blockType == 'code';
  }

  void writeElement(String line, {String? blockType}) {
    final isBlock = isBlockType(blockType);
    final sameBlockRun =
        isBlock && hasWrittenElements && lastBlockType == blockType;

    if (hasWrittenElements && !sameBlockRun) {
      output.writeln();
    }

    output.writeln(line);
    hasWrittenElements = true;
    lastBlockType = isBlock ? blockType : null;
  }

  String applyInlinePlainText(String text, Map<dynamic, dynamic>? attributes) {
    if (text.isEmpty) {
      return text;
    }

    final link = attributes?['a'];
    if (link is String && link.isNotEmpty) {
      return '$text ($link)';
    }
    return text;
  }

  void flushLine([Map<dynamic, dynamic>? lineAttributes]) {
    final raw = currentLine.toString().trimRight();
    if (raw.isEmpty) {
      currentLine.clear();
      currentLineChecked = null;
      return;
    }

    final blockType = lineAttributes?['block'] as String?;
    final headingLevel = lineAttributes?['heading'];
    if (blockType != 'ol') orderedIndex = 1;

    final lineChecked = lineAttributes?['checked'] as bool?;
    final effectiveChecked = lineChecked ?? currentLineChecked;

    String line;
    if (effectiveChecked != null) {
      // Treat as a checklist item regardless of blockType.
      line = effectiveChecked ? '- [x] ${raw.trim()}' : '- [ ] ${raw.trim()}';
    } else if (blockType == 'cl') {
      // Block is checklist but no checked state → assume unchecked.
      line = '- [ ] ${raw.trim()}';
    } else if (headingLevel is int) {
      line = '${'#' * headingLevel.clamp(1, 6)} ${raw.trim()}';
    } else if (blockType == 'ul') {
      line = '- ${raw.trim()}';
    } else if (blockType == 'ol') {
      line = '${orderedIndex++}. ${raw.trim()}';
    } else if (blockType == 'quote') {
      line = '> ${raw.trim()}';
    } else if (blockType == 'code') {
      line = '    $raw';
    } else {
      line = raw;
    }

    writeElement(line, blockType: blockType);
    currentLine.clear();
    currentLineChecked = null;
  }

  for (final op in ops) {
    if (op is! Map) {
      continue;
    }

    final insert = op['insert'];
    final attributes = op['attributes'] as Map<dynamic, dynamic>?;

    if (insert is String) {
      final parts = insert.split('\n');
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (part.isNotEmpty) {
          // Update checked state for the segment being written to the current line.
          if (attributes?['checked'] is bool) {
            currentLineChecked = attributes!['checked'] as bool;
          }
          currentLine.write(applyInlinePlainText(part, attributes));
        }
        if (i < parts.length - 1) {
          // A \n inside a text op with block/heading attributes terminates a
          // styled paragraph; a \n without those attributes is a plain separator.
          final hasLineAttrs = attributes != null &&
              (attributes.containsKey('block') ||
                  attributes.containsKey('heading'));
          flushLine(hasLineAttrs ? attributes : null);
        }
      }
      continue;
    }

    if (insert is Map) {
      final type = insert['_type'] as String?;
      if (type == 'hr') {
        // Horizontal rule gets its own output line.
        if (currentLine.isNotEmpty) flushLine();
        writeElement('---');
      } else {
        currentLine.write(_extractJournalEmbedPlaceholder(insert));
      }
    }
  }

  if (currentLine.isNotEmpty) {
    flushLine();
  }

  return output.toString().trimRight();
}

String _applyInlineMarkdown(String text, Map<dynamic, dynamic>? attributes) {
  if (text.isEmpty) {
    return text;
  }

  var value = text;
  final link = attributes?['a'];
  if (attributes?['c'] == true) {
    value = '`$value`';
  }
  if (attributes?['b'] == true) {
    value = '**$value**';
  }
  if (attributes?['i'] == true) {
    value = '*$value*';
  }
  if (attributes?['s'] == true) {
    value = '~~$value~~';
  }
  if (attributes?['u'] == true) {
    value = '$value'; // Markdown doesn't have native underline, so we can choose to ignore or use a custom syntax
  }
  if (link is String && link.isNotEmpty) {
    value = '[$value]($link)';
  }

  return value;
}

String _journalDeltaToMarkdown(String? notes) {
  final ops = _parseJournalDeltaOps(notes);
  if (ops == null) {
    return notes ?? '';
  }

  final output = StringBuffer();
  final currentLine = StringBuffer();
  var orderedIndex = 1;
  var hasWrittenElements = false;
  String? lastBlockType;

  bool _isBlockType(String? blockType) {
    return blockType == 'ul' ||
        blockType == 'ol' ||
        blockType == 'cl' ||
        blockType == 'quote' ||
        blockType == 'code';
  }

  void writeElement(String line, {String? blockType}) {
    final isBlock = _isBlockType(blockType);
    final sameBlockRun =
        isBlock && hasWrittenElements && lastBlockType == blockType;

    // Markdown expects a blank line between elements, except while we are in
    // the same contiguous block run (lists, quotes, code blocks, checklists).
    if (hasWrittenElements && !sameBlockRun) {
      output.writeln();
    }

    output.writeln(line);
    hasWrittenElements = true;
    lastBlockType = isBlock ? blockType : null;
  }
  // Tracks whether the current line's text had the `checked` inline attribute,
  // which is how Fleather marks checklist item state on text runs.
  bool? currentLineChecked;

  void flushLine([Map<dynamic, dynamic>? lineAttributes]) {
    final raw = currentLine.toString().trimRight();
    // Skip empty lines that carry block styles (e.g. blank trailing list items).
    if (raw.isEmpty) {
      currentLine.clear();
      currentLineChecked = null;
      return;
    }

    final blockType = lineAttributes?['block'] as String?;
    final headingLevel = lineAttributes?['heading'];
    if (blockType != 'ol') orderedIndex = 1;

    String line;
    // `checked` can appear on the block-terminating `\n` op (standard Fleather
    // format) or as an inline attribute on text runs. Prefer the block attr, then
    // fall back to what was tracked from the text runs.
    final lineChecked = lineAttributes?['checked'] as bool?;
    final effectiveChecked = lineChecked ?? currentLineChecked;

    if (effectiveChecked != null) {
      // Treat as a checklist item regardless of blockType.
      line = effectiveChecked ? '- [x] ${raw.trim()}' : '- [ ] ${raw.trim()}';
    } else if (blockType == 'cl') {
      // Block is checklist but no checked state → assume unchecked.
      line = '- [ ] ${raw.trim()}';
    } else if (headingLevel is int) {
      line = '${'#' * headingLevel.clamp(1, 6)} ${raw.trim()}';
    } else if (blockType == 'ul') {
      line = '- ${raw.trim()}';
    } else if (blockType == 'ol') {
      line = '${orderedIndex++}. ${raw.trim()}';
    } else if (blockType == 'quote') {
      line = '> ${raw.trim()}';
    } else if (blockType == 'code') {
      line = '    $raw';
    } else {
      line = raw;
    }

    writeElement(line, blockType: blockType);
    currentLine.clear();
    currentLineChecked = null;
  }

  for (final op in ops) {
    if (op is! Map) {
      continue;
    }

    final insert = op['insert'];
    final attributes = op['attributes'] as Map<dynamic, dynamic>?;

    if (insert is String) {
      final parts = insert.split('\n');
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        if (part.isNotEmpty) {
          // Update checked state for the segment being written to the current line.
          if (attributes?['checked'] is bool) {
            currentLineChecked = attributes!['checked'] as bool;
          }
          currentLine.write(_applyInlineMarkdown(part, attributes));
        }
        if (i < parts.length - 1) {
          // A \n inside a text op with block/heading attributes terminates a
          // styled paragraph; a \n without those attributes is a plain separator.
          final hasLineAttrs = attributes != null &&
              (attributes.containsKey('block') ||
                  attributes.containsKey('heading'));
          flushLine(hasLineAttrs ? attributes : null);
        }
      }
      continue;
    }

    if (insert is Map) {
      final type = insert['_type'] as String?;
      if (type == 'hr') {
        // Horizontal rule gets its own output line.
        if (currentLine.isNotEmpty) flushLine();
        writeElement('---');
      } else {
        currentLine.write(_extractJournalEmbedMarkdown(insert));
      }
    }
  }

  if (currentLine.isNotEmpty) {
    flushLine();
  }

  return output.toString().trimRight();
}

String _buildJournalTxtExportContent(List<FieldJournal> journals) {
  final content = StringBuffer();

  for (var i = 0; i < journals.length; i++) {
    final journal = journals[i];
    // content.writeln('Title: ${journal.title}');
    if (journal.observer != null && journal.observer!.isNotEmpty) {
      content.writeln('Observer: ${journal.observer}');
    }
    if (journal.tags.isNotEmpty) {
      content.writeln('Tags: ${journal.tags.join(', ')}');
    }
    if (journal.creationDate != null) {
      content.writeln('Created: ${journal.creationDate!.toIso8601String()}');
    }
    if (journal.lastModifiedDate != null) {
      content.writeln('Last modified: ${journal.lastModifiedDate!.toIso8601String()}');
    }
    content.writeln('');
    content.writeln(_journalDeltaToPlainText(journal.notes));

    if (i < journals.length - 1) {
      content.writeln('\n${'-' * 40}\n');
    }
  }

  return content.toString().trimRight();
}

String _toYamlStringValue(String value) {
  final escaped = value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  return '"$escaped"';
}

String _buildJournalMarkdownExportContent(List<FieldJournal> journals) {
  final content = StringBuffer();

  for (var i = 0; i < journals.length; i++) {
    final journal = journals[i];
    content.writeln('---');
    // content.writeln('title: ${_toYamlStringValue(journal.title)}');
    if (journal.observer != null && journal.observer!.isNotEmpty) {
      content.writeln('observer: ${_toYamlStringValue(journal.observer!)}');
    }
    if (journal.tags.isNotEmpty) {
      content.writeln('tags: [${_toYamlStringValue(journal.tags.join(', '))}]');
    }
    if (journal.creationDate != null) {
      content.writeln('created: ${journal.creationDate!.toIso8601String()}');
    }
    if (journal.lastModifiedDate != null) {
      content.writeln('lastModified: ${journal.lastModifiedDate!.toIso8601String()}');
    }
    content.writeln('---');
    content.writeln('');
    content.writeln('# ${journal.title}');
    content.writeln('');
    content.writeln(_journalDeltaToMarkdown(journal.notes));

    if (i < journals.length - 1) {
      content.writeln('\n---\n');
    }
  }

  return content.toString().trimRight();
}

/// Exports selected field journal notes to TXT files.
Future<void> exportSelectedJournalsToTxt(
  BuildContext context,
  List<FieldJournal> journals,
) async {
  try {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    final txtContent = _buildJournalTxtExportContent(journals);
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/selected_journals_$formattedDate.txt';
    final file = File(filePath);
    await file.writeAsString(txtContent);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'text/plain')],
        title: S.current.journalEntries(journals.length),
        subject: S.current.journalEntries(journals.length),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text('${S.current.errorSavingJournalEntry}: $error'),
      ),
    );
  }
}

/// Exports selected field journal notes to Markdown files.
Future<void> exportSelectedJournalsToMarkdown(
  BuildContext context,
  List<FieldJournal> journals,
) async {
  try {
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    final markdownContent = _buildJournalMarkdownExportContent(journals);
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/selected_journals_$formattedDate.md';
    final file = File(filePath);
    await file.writeAsString(markdownContent);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'text/markdown')],
        title: S.current.journalEntries(journals.length),
        subject: S.current.journalEntries(journals.length),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text('${S.current.errorSavingJournalEntry}: $error'),
      ),
    );
  }
}

/// Exports selected field journal entries to a single DOCX file.
///
/// Each journal entry is rendered as a section starting with an H1 title,
/// followed by metadata lines (observer, dates) and the rich-text body
/// converted from Fleather Delta JSON via Markdown. Multiple entries are
/// separated by a horizontal rule. The resulting file is shared through the
/// platform share sheet.
Future<void> exportSelectedJournalsToWord(
  BuildContext context,
  List<FieldJournal> journals,
) async {
  bool isDialogShown = false;

  try {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(year2023: false),
                SizedBox(width: 16),
                Text(S.current.exporting),
              ],
            ),
          ),
        );
      },
    );
    isDialogShown = true;

    final builder = docx();

    for (var i = 0; i < journals.length; i++) {
      final journal = journals[i];

      // Title as Heading 1
      // builder.h1(journal.title);

      // Metadata lines as plain paragraphs
      if (journal.observer != null && journal.observer!.isNotEmpty) {
        builder.p('Observer: ${journal.observer}');
      }
      if (journal.tags.isNotEmpty) {
        builder.p('Tags: ${journal.tags.join(', ')}');
      }
      if (journal.creationDate != null) {
        builder.p('Created: ${journal.creationDate!.toIso8601String()}');
      }
      if (journal.lastModifiedDate != null) {
        builder.p('Last modified: ${journal.lastModifiedDate!.toIso8601String()}');
      }

      // Convert Fleather Delta → Markdown → DocxNodes
      final markdownContent = _journalDeltaToMarkdown(journal.notes);
      if (markdownContent.isNotEmpty) {
        final nodes = await MarkdownParser.parse(markdownContent);
        for (final node in nodes) {
          builder.add(node);
        }
      }

      // Horizontal rule separator between entries (not after the last one)
      if (i < journals.length - 1) {
        builder.hr();
      }
    }

    final doc = builder.build();
    final bytes = await DocxExporter().exportToBytes(doc);

    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/selected_journals_$formattedDate.docx';
    await File(filePath).writeAsBytes(bytes);

    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
      isDialogShown = false;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            filePath,
            mimeType:
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          ),
        ],
        title: S.current.journalEntries(journals.length),
        subject: S.current.journalEntries(journals.length),
      ),
    );
  } catch (error) {
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
      isDialogShown = false;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text('${S.current.errorSavingJournalEntry}: $error'),
      ),
    );
  } finally {
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Exports selected field journal entries to a single JSON envelope.
Future<void> exportSelectedJournalsToJson(
  BuildContext context,
  List<FieldJournal> journals,
) async {
  try {
    final jsonData = {
      'source': kExportSource,
      'schema': 'journals',
      'schemaVersion': kExportSchemaVersion,
      'records': journals.map((journal) => journal.toJson()).toList(),
    };
    final jsonString = JsonEncoder.withIndent('  ').convert(jsonData);

    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/selected_journals_$formattedDate.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/json')],
        title: S.current.journalEntries(journals.length),
        subject: S.current.journalEntries(journals.length),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text('${S.current.errorSavingJournalEntry}: $error'),
      ),
    );
  }
}

/// Exports selected nests to a single JSON envelope.
Future<void> exportSelectedNestsToJson(BuildContext context, List<Nest> nests) async {
  try {
    final nestsToExport = await _ensureNestsLoadedForExport(context, nests);
    final jsonData = {
      'source': kExportSource,
      'schema': 'nests',
      'schemaVersion': kExportSchemaVersion,
      'records': nestsToExport.map((nest) => nest.toJson()).toList(),
    };
    var encoder = JsonEncoder.withIndent("  ");
    final jsonString = encoder.convert(jsonData);

    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/selected_nests_$formattedDate.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/json')],
        title: S.current.nestExported(nests.length),
        subject: S.current.nestData(nests.length),
      ),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: true,
          showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(S.of(context).errorExportingNest(nests.length, error.toString())),
        ),
      );
    }
  }
}

/// Exports selected nests to a single CSV file and shares it.
Future<void> exportSelectedNestsToCsv(BuildContext context, List<Nest> nests) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(year2023: false),
              SizedBox(width: 16),
              Text(S.current.exportingPleaseWait),
            ],
          ),
        ),
      );
    },
  );
  try {
    final locale = Localizations.localeOf(context);
    final nestsToExport = await _ensureNestsLoadedForExport(context, nests);

    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    final filePaths = <String>[];

    // Export revisions data
    List<List<dynamic>> revRows = await buildNestsRevisionsRows(nestsToExport, locale);
    if (revRows.isNotEmpty) {
      String revCsv = Csv(fieldDelimiter: ';').encode(revRows);
      Directory tempDir = await getTemporaryDirectory();
      final revFilePath = '${tempDir.path}/selected_nests_${formattedDate}_revisions.csv';
      if (revCsv.isNotEmpty) {
        final file = File(revFilePath);
        await file.writeAsString(revCsv);
        filePaths.add(revFilePath);
      }
    }

    // Export eggs data
    List<List<dynamic>> eggRows = await buildNestsEggsRows(nestsToExport, locale);
    if (eggRows.length > 1) {
      String eggCsv = Csv(fieldDelimiter: ';').encode(eggRows);
      Directory tempDir = await getTemporaryDirectory();
      final eggFilePath = '${tempDir.path}/selected_nests_${formattedDate}_eggs.csv';
      if (eggCsv.isNotEmpty) {
        final file = File(eggFilePath);
        await file.writeAsString(eggCsv);
        filePaths.add(eggFilePath);
      }
    }

    if (filePaths.isNotEmpty) {
      await SharePlus.instance.share(
        ShareParams(
          files: filePaths.map((f) => XFile(f, mimeType: 'text/csv')).toList(),
          title: S.current.nestExported(nests.length),
          subject: S.current.nestData(nests.length),
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: true,
          showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(S.of(context).errorExportingNest(nests.length, error.toString())),
        ),
      );
    }
  } finally {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Exports selected nests to a single Excel file and shares it.
Future<void> exportSelectedNestsToExcel(BuildContext context, List<Nest> nests) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(year2023: false),
              SizedBox(width: 16),
              Text(S.current.exportingPleaseWait),
            ],
          ),
        ),
      );
    },
  );
  try {
    final locale = Localizations.localeOf(context);
    final nestsToExport = await _ensureNestsLoadedForExport(context, nests);
    final excel = await _createNestsExcel(nestsToExport, locale);

    var fileBytes = excel.save();
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/selected_nests_$formattedDate.xlsx';
    if (fileBytes != null) {
      File(filePath)
        ..create(recursive: true)
        ..writeAsBytes(fileBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              filePath,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            )
          ],
          title: S.current.nestExported(nests.length),
          subject: S.current.nestData(nests.length),
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: true,
          showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(S.of(context).errorExportingNest(nests.length, error.toString())),
        ),
      );
    }
  } finally {
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Exports selected nests to one KML file and opens the share sheet.
Future<void> exportSelectedNestsToKml(BuildContext context, List<Nest> nests) async {
  try {
    final nestsToExport = await _ensureNestsLoadedForExport(context, nests);
    final List<_KmlWaypoint> waypoints = [];

    for (final nest in nestsToExport) {
      if (nest.latitude == null || nest.longitude == null) {
        continue;
      }

      waypoints.add(
        _KmlWaypoint(
          lat: nest.latitude,
          lon: nest.longitude,
          name: '${nest.fieldNumber} - ${nest.speciesName ?? ''}',
          description: nest.localityName ?? '',
          time: nest.foundTime,
        ),
      );
    }

    if (waypoints.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(S.of(context).noPoisToExport),
        ),
      );
      return;
    }

    final kmlString = _buildKmlString(
      name: 'Selected nests',
      description: 'Coordinates for selected nests',
      waypoints: waypoints,
    );

    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/selected_nests_$formattedDate.kml';
    final file = File(filePath);
    await file.writeAsString(kmlString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/vnd.google-earth.kml+xml')],
        title: S.current.nestExported(waypoints.length),
        subject: S.current.nestData(waypoints.length),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          S.of(context).errorExportingNest(nests.length, error.toString()),
        ),
      ),
    );
  }
}

/// Exports all inactive nests to a JSON envelope and opens the share sheet.
Future<void> exportAllInactiveNestsToJson(BuildContext context) async {
  bool isDialogShown = false;

  try {
    // Show a loading dialog
      if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(year2023: false,),
                  SizedBox(width: 16),
                  Text(S.current.exporting),
                ],
              ),
            ),
          );
        },
      );
      isDialogShown = true;
      }

    final nestProvider = Provider.of<NestProvider>(context, listen: false);
    final inactiveNests = await _ensureNestsLoadedForExport(
      context,
      nestProvider.inactiveNests,
      nestProvider: nestProvider,
    );
    final jsonData = {
      'source': kExportSource,
      'schema': 'nests',
      'schemaVersion': kExportSchemaVersion,
      'records': inactiveNests.map((nest) => nest.toJson()).toList(),
    };
    final jsonString = jsonEncode(jsonData);

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/nests.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    if (isDialogShown) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        isDialogShown = false; // Dialog is now closed
      }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/json')], 
        title: S.current.nestExported(2),
        subject: S.current.nestData(2)
      ),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            persist: true,
                            showCloseIcon: true,
                            backgroundColor: Theme.of(context).colorScheme.error,
                            content: Text(S.of(context).errorExportingInventory(1, error.toString())),
                          ),
                        );
    }
    return;
  } finally {
    // Ensure the dialog is always closed if it was shown and an error occurred,
    // or if the function returned early while the dialog was up.
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Exports one nest as JSON, including revisions and eggs when available.
Future<void> exportNestToJson(BuildContext context, Nest nest) async {
  try {
    final nestToExport = await _ensureNestLoadedForExport(context, nest);
    // 1. Create a list of data
    final jsonData = {
      'source': kExportSource,
      'schema': 'nests',
      'schemaVersion': kExportSchemaVersion,
      'records': [nestToExport.toJson()],
    };
    final jsonString = jsonEncode(jsonData);

    // 2. Create the file in a temporary directory
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/nest_${nestToExport.fieldNumber}.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    // 3. Share the file using share_plus
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/json')], 
        title: S.current.nestExported(1),
        subject: '${S.current.nestData(1)} ${nestToExport.fieldNumber}'
      ),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            persist: true,
                            showCloseIcon: true,
                            backgroundColor: Theme.of(context).colorScheme.error,
                            content: Text(S.of(context).errorExportingNest(1, error.toString())),
                          ),
                        );
    }
    return;
  }
}

/// Headers for Nest records (Nests table/sheet).
const List<String> kNestHeaders = [
  'occurrenceID',
  'scientificName',
  'locality',
  'decimalLongitude',
  'decimalLatitude',
  'verbatimEventDate',
  'support',
  'heightAboveGround',
  'male',
  'female',
  'helpers',
  'lastEventDate',
  'recordedBy',
  'nestFate',
];

/// Headers for Nest revisions (Revisions table/sheet).
const List<String> kNestRevisionHeaders = [
  'occurrenceID',
  'scientificName',
  'locality',
  'decimalLongitude',
  'decimalLatitude',
  'recordedBy',
  'eventTime',
  'nestStatus',
  'nestStage',
  'eggsHost',
  'nestlingsHost',
  'eggsParasite',
  'nestlingsParasite',
  'hasPhilornisLarvae',
  'revisionRemarks',
];

/// Headers for Nest eggs (Eggs table/sheet).
const List<String> kNestEggHeaders = [
  'occurrenceID',
  'scientificName',
  'locality',
  'eventTime',
  'eggFieldNumber',
  'eggSpeciesName',
  'eggShape',
  'width',
  'length',
  'mass',
];

/// Builds flat summary rows for a list of nests.
Future<List<List<dynamic>>> buildNestsSummaryRows(
  List<Nest> nests,
  Locale locale,
) async {
  final List<List<dynamic>> rows = [kNestHeaders];
  final numberFormat = NumberFormat.decimalPattern(locale.toString())
    ..maximumFractionDigits = 7;
  final prefs = await SharedPreferences.getInstance();
  final formatNumbers = prefs.getBool('formatNumbers') ?? true;

  for (var nest in nests) {
    rows.add([
      nest.fieldNumber ?? '',
      nest.speciesName ?? '',
      nest.localityName ?? '',
      nest.longitude != null
          ? (formatNumbers ? numberFormat.format(nest.longitude) : nest.longitude)
          : '',
      nest.latitude != null
          ? (formatNumbers ? numberFormat.format(nest.latitude) : nest.latitude)
          : '',
      nest.foundTime != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(nest.foundTime!)
          : '',
      nest.support ?? '',
      nest.heightAboveGround != null
          ? (formatNumbers
              ? numberFormat.format(nest.heightAboveGround)
              : nest.heightAboveGround)
          : '',
      nest.male ?? '',
      nest.female ?? '',
      nest.helpers ?? '',
      nest.lastTime != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(nest.lastTime!)
          : '',
      nest.observer ?? '',
      nestFateTypeFriendlyNames[nest.nestFate] ?? '',
    ]);
  }

  return rows;
}

/// Builds flat denormalized revision rows for a list of nests.
Future<List<List<dynamic>>> buildNestsRevisionsRows(
  List<Nest> nests,
  Locale locale,
) async {
  final List<List<dynamic>> rows = [kNestRevisionHeaders];
  final numberFormat = NumberFormat.decimalPattern(locale.toString())
    ..maximumFractionDigits = 7;
  final prefs = await SharedPreferences.getInstance();
  final formatNumbers = prefs.getBool('formatNumbers') ?? true;

  for (var nest in nests) {
    final prefix = [
      nest.fieldNumber ?? '',
      nest.speciesName ?? '',
      nest.localityName ?? '',
      nest.longitude != null
          ? (formatNumbers ? numberFormat.format(nest.longitude) : nest.longitude)
          : '',
      nest.latitude != null
          ? (formatNumbers ? numberFormat.format(nest.latitude) : nest.latitude)
          : '',
      nest.observer ?? '',
    ];

    final revisions = nest.revisionsList ?? [];
    if (revisions.isNotEmpty) {
      for (var rev in revisions) {
        rows.add([
          ...prefix,
          rev.sampleTime != null
              ? DateFormat('yyyy-MM-dd HH:mm:ss').format(rev.sampleTime!)
              : '',
          nestStatusTypeFriendlyNames[rev.nestStatus] ?? '',
          nestStageTypeFriendlyNames[rev.nestStage] ?? '',
          rev.eggsHost ?? '',
          rev.nestlingsHost ?? '',
          rev.eggsParasite ?? '',
          rev.nestlingsParasite ?? '',
          rev.hasPhilornisLarvae == true ? 'Yes' : 'No',
          rev.notes ?? '',
        ]);
      }
    } else {
      rows.add([
        ...prefix,
        '', '', '', '', '', '', '', '', ''
      ]);
    }
  }

  return rows;
}

/// Builds flat egg rows for a list of nests.
Future<List<List<dynamic>>> buildNestsEggsRows(
  List<Nest> nests,
  Locale locale,
) async {
  final List<List<dynamic>> rows = [kNestEggHeaders];
  final numberFormat = NumberFormat.decimalPattern(locale.toString())
    ..maximumFractionDigits = 7;
  final prefs = await SharedPreferences.getInstance();
  final formatNumbers = prefs.getBool('formatNumbers') ?? true;

  for (var nest in nests) {
    final eggs = nest.eggsList ?? [];
    if (eggs.isEmpty) continue;

    for (var egg in eggs) {
      rows.add([
        nest.fieldNumber ?? '',
        nest.speciesName ?? '',
        nest.localityName ?? '',
        egg.sampleTime != null
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(egg.sampleTime!)
            : '',
        egg.fieldNumber ?? '',
        egg.speciesName ?? '',
        eggShapeTypeFriendlyNames[egg.eggShape] ?? '',
        egg.width != null
            ? (formatNumbers ? numberFormat.format(egg.width) : egg.width)
            : '',
        egg.length != null
            ? (formatNumbers ? numberFormat.format(egg.length) : egg.length)
            : '',
        egg.mass != null
            ? (formatNumbers ? numberFormat.format(egg.mass) : egg.mass)
            : '',
      ]);
    }
  }

  return rows;
}

/// Builds tabular rows for nest export.
Future<List<List<dynamic>>> buildNestRows(Nest nest, Locale locale) async {
  return buildNestsRevisionsRows([nest], locale);
}

/// Builds an Excel workbook with sheets for Revisions, Nests, and Eggs.
Future<Excel> _createNestsExcel(List<Nest> nests, Locale locale) async {
  final excel = Excel.createExcel();

  final revRows = await buildNestsRevisionsRows(nests, locale);
  final revSheet = excel['Revisions'];
  for (var row in convertRowsToCellValues(revRows)) {
    revSheet.appendRow(row);
  }
  if (excel.sheets.containsKey('Sheet1')) {
    excel.delete('Sheet1');
  }

  final nestRows = await buildNestsSummaryRows(nests, locale);
  final nestSheet = excel['Nests'];
  for (var row in convertRowsToCellValues(nestRows)) {
    nestSheet.appendRow(row);
  }

  final eggRows = await buildNestsEggsRows(nests, locale);
  if (eggRows.length > 1) {
    final eggSheet = excel['Eggs'];
    for (var row in convertRowsToCellValues(eggRows)) {
      eggSheet.appendRow(row);
    }
  }

  return excel;
}

/// Exports one nest to CSV files (revisions and eggs) and returns the list of generated file paths.
Future<List<String>> exportNestToCsv(BuildContext context, Nest nest, Locale locale) async {
  try {
    final nestToExport = await _ensureNestLoadedForExport(context, nest);
    final filePaths = <String>[];

    // Export revisions data
    List<List<dynamic>> revRows = await buildNestsRevisionsRows([nestToExport], locale);
    if (revRows.isNotEmpty) {
      String revCsv = Csv(fieldDelimiter: ';').encode(revRows);
      Directory tempDir = await getTemporaryDirectory();
      final revFilePath = '${tempDir.path}/nest_${nestToExport.fieldNumber}_revisions.csv';
      if (revCsv.isNotEmpty) {
        final file = File(revFilePath);
        await file.writeAsString(revCsv);
        filePaths.add(revFilePath);
      }
    }

    // Export eggs data
    List<List<dynamic>> eggRows = await buildNestsEggsRows([nestToExport], locale);
    if (eggRows.length > 1) {
      String eggCsv = Csv(fieldDelimiter: ';').encode(eggRows);
      Directory tempDir = await getTemporaryDirectory();
      final eggFilePath = '${tempDir.path}/nest_${nestToExport.fieldNumber}_eggs.csv';
      if (eggCsv.isNotEmpty) {
        final file = File(eggFilePath);
        await file.writeAsString(eggCsv);
        filePaths.add(eggFilePath);
      }
    }

    if (filePaths.isEmpty) {
      throw Exception('Failed to generate CSV files.');
    }
    return filePaths;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: true,
          showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(S.of(context).errorExportingNest(1, error.toString())),
        ),
      );
    }
    return [];
  }
}

/// Exports one nest to Excel and returns the generated file path.
Future<String> exportNestToExcel(BuildContext context, Nest nest, Locale locale) async {
  try {
    final nestToExport = await _ensureNestLoadedForExport(context, nest);
    final excel = await _createNestsExcel([nestToExport], locale);

    var fileBytes = excel.save();
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/nest_${nestToExport.fieldNumber}.xlsx';
    if (fileBytes != null) {
      File(filePath)
        ..create(recursive: true)
        ..writeAsBytes(fileBytes);
      return filePath;
    } else {
      throw Exception('Failed to generate Excel file.');
    }
  } catch (error) {
    if (!context.mounted) return '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(S.of(context).errorExportingNest(1, error.toString())),
      ),
    );
    return '';
  }
}

/// Exports one nest location dataset to KML and opens the share sheet.
Future<void> exportNestToKml(BuildContext context, Nest nest) async {
  try {
    final nestToExport = await _ensureNestLoadedForExport(context, nest);
    final List<_KmlWaypoint> waypoints = [];
    if (nestToExport.latitude != null && nestToExport.longitude != null) {
      waypoints.add(_KmlWaypoint(
        lat: nestToExport.latitude,
        lon: nestToExport.longitude,
        name: '${nestToExport.fieldNumber} - ${nestToExport.speciesName}',
        description: nestToExport.localityName ?? '',
        time: nestToExport.foundTime,
      ));
    }

    if (waypoints.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(S.of(context).noPoisToExport),
        ),
      );
      return;
    }

    final kmlString = _buildKmlString(
      name: 'Nest ${nestToExport.fieldNumber}',
      description: 'Coordinates for Nest ${nestToExport.fieldNumber}',
      waypoints: waypoints,
    );

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/nest_${nestToExport.fieldNumber}.kml';
    final file = File(filePath);
    await file.writeAsString(kmlString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/vnd.google-earth.kml+xml')],
        title: S.current.nestExported(1),
        subject: '${S.current.nestExported(1)} ${nestToExport.fieldNumber}',
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            persist: true,
                            showCloseIcon: true,
                            backgroundColor: Theme.of(context).colorScheme.error,
                            content: Text(S.of(context).errorExportingNest(1, error.toString())),
                          ),
                        );
    return;
  }
}

/// Exports all specimens as a JSON envelope and opens the share sheet.
Future<void> exportAllSpecimensToJson(BuildContext context, List<Specimen> specimenList) async {
  bool isDialogShown = false;

  try {
    // Show a loading dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(year2023: false,),
                  SizedBox(width: 16),
                  Text(S.current.exporting),
                ],
              ),
            ),
          );
        },
      );
      isDialogShown = true;

    final jsonData = {
      'source': kExportSource,
      'schema': 'specimens',
      'schemaVersion': kExportSchemaVersion,
      'records': specimenList.map((specimen) => specimen.toJson()).toList(),
    };
    final jsonString = jsonEncode(jsonData);

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/specimens.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    if (isDialogShown) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        isDialogShown = false; // Dialog is now closed
      }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/json')], 
        title: S.current.specimenExported(2),
        subject: S.current.specimenData(2)
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            persist: true,
                            showCloseIcon: true,
                            backgroundColor: Theme.of(context).colorScheme.error,
                            content: Text(S.of(context).errorExportingSpecimen(1, error.toString())),
                          ),
                        );
  } finally {
    // Ensure the dialog is always closed if it was shown and an error occurred,
    // or if the function returned early while the dialog was up.
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Exports selected specimens to a single JSON envelope.
Future<void> exportSelectedSpecimensToJson(BuildContext context, List<Specimen> specimenList) async {
  try {
    final jsonData = {
      'source': kExportSource,
      'schema': 'specimens',
      'schemaVersion': kExportSchemaVersion,
      'records': specimenList.map((specimen) => specimen.toJson()).toList(),
    };
    var encoder = JsonEncoder.withIndent("  ");
    final jsonString = encoder.convert(jsonData);

    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/selected_specimens_$formattedDate.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/json')],
        title: S.current.specimenExported(specimenList.length),
        subject: S.current.specimenData(specimenList.length),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(S.of(context).errorExportingSpecimen(specimenList.length, error.toString())),
      ),
    );
  }
}

/// Exports selected specimens to one CSV file and opens the share sheet.
Future<void> exportSelectedSpecimensToCsv(BuildContext context, List<Specimen> specimenList) async {
  bool isDialogShown = false;

  try {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(year2023: false),
                SizedBox(width: 16),
                Text(S.current.exporting),
              ],
            ),
          ),
        );
      },
    );
    isDialogShown = true;

    final locale = Localizations.localeOf(context);
    List<List<dynamic>> rows = await buildSpecimensRows(specimenList, locale);
    String csv = Csv(fieldDelimiter: ';').encode(rows);

    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/selected_specimens_$formattedDate.csv';
    final file = File(filePath);
    await file.writeAsString(csv);

    if (isDialogShown) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      isDialogShown = false;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'text/csv')],
        title: S.current.specimenExported(specimenList.length),
        subject: S.current.specimenData(specimenList.length),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(S.of(context).errorExportingSpecimen(specimenList.length, error.toString())),
      ),
    );
  } finally {
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Exports selected specimens to one Excel file and opens the share sheet.
Future<void> exportSelectedSpecimensToExcel(BuildContext context, List<Specimen> specimenList) async {
  bool isDialogShown = false;

  try {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(year2023: false),
                SizedBox(width: 16),
                Text(S.current.exporting),
              ],
            ),
          ),
        );
      },
    );
    isDialogShown = true;

    final locale = Localizations.localeOf(context);
    List<List<dynamic>> rows = await buildSpecimensRows(specimenList, locale);
    List<List<CellValue>> cellRows = convertRowsToCellValues(rows);

    final excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];

    for (List<CellValue> row in cellRows) {
      sheet.appendRow(row);
    }

    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    var fileBytes = excel.save();
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/selected_specimens_$formattedDate.xlsx';
    if (fileBytes != null) {
      File(filePath)
        ..create(recursive: true)
        ..writeAsBytes(fileBytes);

      if (isDialogShown) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        isDialogShown = false;
      }
    } else {
      throw Exception('Failed to generate Excel file.');
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            filePath,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        title: S.current.specimenExported(specimenList.length),
        subject: S.current.specimenData(specimenList.length),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(S.of(context).errorExportingSpecimen(1, error.toString())),
      ),
    );
  } finally {
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Exports selected specimens to one KML file and opens the share sheet.
Future<void> exportSelectedSpecimensToKml(BuildContext context, List<Specimen> specimenList) async {
  try {
    final List<_KmlWaypoint> waypoints = [];

    for (final specimen in specimenList) {
      if (specimen.latitude == null || specimen.longitude == null) {
        continue;
      }

      waypoints.add(
        _KmlWaypoint(
          lat: specimen.latitude,
          lon: specimen.longitude,
          name: '${specimen.fieldNumber} - ${specimen.speciesName ?? ''}',
          description: specimen.locality ?? '',
          time: specimen.sampleTime,
        ),
      );
    }

    if (waypoints.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(S.of(context).noPoisToExport),
        ),
      );
      return;
    }

    final kmlString = _buildKmlString(
      name: 'Selected specimens',
      description: 'Coordinates for selected specimens',
      waypoints: waypoints,
    );

    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/selected_specimens_$formattedDate.kml';
    final file = File(filePath);
    await file.writeAsString(kmlString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/vnd.google-earth.kml+xml')],
        title: S.current.specimenExported(waypoints.length),
        subject: S.current.specimenData(waypoints.length),
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          S.of(context).errorExportingSpecimen(specimenList.length, error.toString()),
        ),
      ),
    );
  }
}

/// Exports all specimens to one CSV file and opens the share sheet.
Future<void> exportAllSpecimensToCsv(BuildContext context, List<Specimen> specimenList) async {
  bool isDialogShown = false;

  try {
    // Show a loading dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(year2023: false,),
                  SizedBox(width: 16),
                  Text(S.current.exporting),
                ],
              ),
            ),
          );
        },
      );
      isDialogShown = true;

    final locale = Localizations.localeOf(context);

    // 1. Create a list of data for the CSV
    List<List<dynamic>> rows = await buildSpecimensRows(specimenList, locale);

    // 2. Convert the list of data to CSV
    String csv = Csv(fieldDelimiter: ';').encode(rows);

    // 3. Create the file in a temporary directory
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/specimens.csv';
    final file = File(filePath);
    await file.writeAsString(csv);

    if (isDialogShown) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        isDialogShown = false; // Dialog is now closed
      }

    // 4. Share the file using share_plus
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'text/csv')], 
        title: S.current.specimenExported(2),
        subject: S.current.specimenData(2)
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            persist: true,
                            showCloseIcon: true,
                            backgroundColor: Theme.of(context).colorScheme.error,
                            content: Text(S.of(context).errorExportingSpecimen(1, error.toString())),
                          ),
                        );
  } finally {
    // Ensure the dialog is always closed if it was shown and an error occurred,
    // or if the function returned early while the dialog was up.
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Exports all specimens to one Excel file and opens the share sheet.
Future<void> exportAllSpecimensToExcel(BuildContext context, List<Specimen> specimenList) async {
  bool isDialogShown = false;

  try {
    // Show a loading dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(year2023: false,),
                  SizedBox(width: 16),
                  Text(S.current.exporting),
                ],
              ),
            ),
          );
        },
      );
      isDialogShown = true;

      final locale = Localizations.localeOf(context);

    // 1. Create a list of data
    List<List<dynamic>> rows = await buildSpecimensRows(specimenList, locale);
    List<List<CellValue>> cellRows = convertRowsToCellValues(rows);

    // 2. Convert the list of data to Excel
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];

    for (List<CellValue> row in cellRows) {
      sheet.appendRow(row);
    }

    // 3. Create the file in a temporary directory
    final now = DateTime.now();
    final formatter = DateFormat('yyyyMMdd_HHmmss');
    final formattedDate = formatter.format(now);
    
    var fileBytes = excel.save();
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/specimens_$formattedDate.xlsx';
    if (fileBytes != null) {
      File(filePath)
        ..create(recursive: true)
        ..writeAsBytes(fileBytes);

      if (isDialogShown) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        isDialogShown = false; // Dialog is now closed
      }
    } else {
      throw Exception('Failed to generate Excel file.');
    }

    // 4. Share the file using share_plus
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            filePath,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        title: S.current.specimenExported(2),
        subject: S.current.specimenData(2)
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(S.of(context).errorExportingSpecimen(1, error.toString())),
      ),
    );
  } finally {
    // Ensure the dialog is always closed if it was shown and an error occurred,
    // or if the function returned early while the dialog was up.
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Headers for Specimen records.
const List<String> kSpecimenHeaders = [
  'verbatimEventDate',
  'occurrenceID',
  'recordedBy',
  'scientificName',
  'basisOfRecord',
  'locality',
  'decimalLongitude',
  'decimalLatitude',
  'occurrenceRemarks',
];

/// Builds tabular rows for specimen exports.
Future<List<List<dynamic>>> buildSpecimensRows(List<Specimen> specimenList, Locale locale) async {
  final numberFormat = NumberFormat.decimalPattern(locale.toString())..maximumFractionDigits = 7;
  List<List<dynamic>> rows = [kSpecimenHeaders];
  final prefs = await SharedPreferences.getInstance();
  final formatNumbers = prefs.getBool('formatNumbers') ?? true;

  for (var specimen in specimenList) {
    rows.add([
      specimen.sampleTime != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(specimen.sampleTime!) : '',
      specimen.fieldNumber,
      specimen.observer ?? '',
      specimen.speciesName ?? '',
      specimenTypeFriendlyNames[specimen.type] ?? '',
      specimen.locality ?? '',
      specimen.longitude != null
          ? (formatNumbers ? numberFormat.format(specimen.longitude) : specimen.longitude)
          : '',
      specimen.latitude != null
          ? (formatNumbers ? numberFormat.format(specimen.latitude) : specimen.latitude)
          : '',
      specimen.notes ?? '',
    ]);
  }

  return rows;
}

/// Exports one specimen location dataset to KML and opens the share sheet.
Future<void> exportSpecimenToKml(BuildContext context, Specimen specimen) async {
  try {
    final List<_KmlWaypoint> waypoints = [];
    if (specimen.latitude != null && specimen.longitude != null) {
      waypoints.add(_KmlWaypoint(
        lat: specimen.latitude,
        lon: specimen.longitude,
        name: '${specimen.fieldNumber} - ${specimen.speciesName}',
        description: specimen.locality ?? '',
        time: specimen.sampleTime,
      ));
    }

    if (waypoints.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          showCloseIcon: true,
          content: Text(S.of(context).noPoisToExport),
        ),
      );
      return;
    }

    final kmlString = _buildKmlString(
      name: 'Specimen ${specimen.fieldNumber}',
      description: 'Coordinates for Specimen ${specimen.fieldNumber}',
      waypoints: waypoints,
    );

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/specimen_${specimen.fieldNumber}.kml';
    final file = File(filePath);
    await file.writeAsString(kmlString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/vnd.google-earth.kml+xml')],
        title: S.current.specimenExported(1),
        subject: '${S.current.specimenExported(1)} ${specimen.fieldNumber}',
      ),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            persist: true,
                            showCloseIcon: true,
                            backgroundColor: Theme.of(context).colorScheme.error,
                            content: Text(S.of(context).errorExportingSpecimen(1, error.toString())),
                          ),
                        );
  }
}

