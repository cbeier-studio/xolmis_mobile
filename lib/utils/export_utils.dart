import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:geoxml/geoxml.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/inventory.dart';
import '../data/models/nest.dart';
import '../data/models/specimen.dart';
import '../providers/inventory_provider.dart';
import '../providers/nest_provider.dart';

import '../core/core_consts.dart';
import '../generated/l10n.dart';

Future<bool> requestStoragePermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }
  return status.isGranted;
}

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
        text: S.current.inventoryExported(2), 
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
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: Row(
    //         children: [
    //           const Icon(Icons.error_outlined, color: Colors.red),
    //           const SizedBox(width: 10),
    //           Text(S.current.errorTitle),
    //         ],
    //       ),
    //       content: SingleChildScrollView(
    //         child: Text(S.current.errorExportingInventory(1, error.toString())),
    //       ),
    //       actions: [
    //         TextButton(
    //           child: Text(S.of(context).ok),
    //           onPressed: () => Navigator.of(context).pop(),
    //         ),
    //       ],
    //     );
    //   },
    // );
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
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/json')],
          text: S.current.inventoryExported(1),
          subject: '${S.current.inventoryExported(1)} ${inventory.id}'
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
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: Row(
    //         children: [
    //           const Icon(Icons.error_outlined, color: Colors.red),
    //           const SizedBox(width: 10),
    //           Text(S.current.errorTitle),
    //         ],
    //       ),
    //       content: SingleChildScrollView(
    //         child: Text(S.current.errorExportingInventory(1, error.toString())),
    //       ),
    //       actions: [
    //         TextButton(
    //           child: Text(S.of(context).ok),
    //           onPressed: () => Navigator.of(context).pop(),
    //         ),
    //       ],
    //     );
    //   },
    // );
    }
    return;
  }
}

// Add inventory data to list of rows
Future<List<List>> buildInventoryRows(Inventory inventory, Locale locale) async {
  const List<String> inventoryHeaders = ['ID','Type','Duration',
    'Max of species','Start date','Start time','End date','End time',
    'Locality','Start longitude','Start latitude','End longitude',
    'End latitude','Total of observers','Observer','Intervals','Paused time (seconds)','Notes','Discarded'];
  const List<String> speciesHeaders = ['SPECIES', 'Count', 'Time', 'Out of sample',
    'Distance', 'Flight height', 'Flight direction', 'Notes'];
  const List<String> vegetationHeaders = ['Date/Time','Latitude','Longitude',
    'Herbs Proportion','Herbs Distribution','Herbs Height',
    'Shrubs Proportion','Shrubs Distribution','Shrubs Height',
    'Trees Proportion','Trees Distribution','Trees Height','Notes'];
  const List<String> weatherHeaders = ['Date/Time','Cloud cover','Precipitation',
    'Temperature','Wind speed','Wind direction','Atmospheric pressure',
    'Relative humidity'];
  const List<String> poiHeaders = ['Species', 'Date/Time', 'Latitude', 'Longitude', 'Notes'];
  final List<List<dynamic>> rows = [];
  final numberFormat = NumberFormat.decimalPattern(locale.toString())..maximumFractionDigits = 7;
  final prefs = await SharedPreferences.getInstance();
  final formatNumbers = prefs.getBool('formatNumbers') ?? true;

  // Add inventory data
  rows.add(inventoryHeaders);
  rows.add([
    inventory.id,
    inventoryTypeFriendlyNames[inventory.type] ?? '',
    inventory.duration,
    inventory.maxSpecies,
    inventory.startTime != null ? DateFormat.yMd(locale.toString()).format(inventory.startTime!) : '',
    inventory.startTime != null ? DateFormat.Hms(locale.toString()).format(inventory.startTime!) : '',
    inventory.endTime != null ? DateFormat.yMd(locale.toString()).format(inventory.endTime!) : '',
    inventory.endTime != null ? DateFormat.Hms(locale.toString()).format(inventory.endTime!) : '',
    inventory.localityName ?? '',
    inventory.startLongitude != null ? formatNumbers ? numberFormat.format(inventory.startLongitude) : inventory.startLongitude : '',
    inventory.startLatitude != null ? formatNumbers ? numberFormat.format(inventory.startLatitude) : inventory.startLatitude : '',
    inventory.endLongitude != null ? formatNumbers ? numberFormat.format(inventory.endLongitude) : inventory.endLongitude : '',
    inventory.endLatitude != null ? formatNumbers ? numberFormat.format(inventory.endLatitude) : inventory.endLatitude : '',
    inventory.totalObservers == 0 ? '' : inventory.totalObservers,
    inventory.observer ?? '',
    inventory.currentInterval == 0 ? '' : inventory.currentInterval,
    inventory.totalPausedTimeInSeconds == 0 ? '' : inventory.totalPausedTimeInSeconds,
    inventory.notes ?? '',
    inventory.isDiscarded ? 'Yes' : 'No',
  ]);
  
  // Add species data
  rows.add(['']); // Empty line to separate the inventory of the species
  rows.add(speciesHeaders);
  for (var species in inventory.speciesList) {
    rows.add([
      species.name, 
      species.count,
      species.sampleTime != null ? DateFormat('dd/MM/yyyy HH:mm:ss').format(species.sampleTime!) : '',
      species.isOutOfInventory ? 'Yes' : 'No',
      species.distance != null ? formatNumbers ? numberFormat.format(species.distance) : species.distance : '',
      species.flightDirection != null ? formatNumbers ? numberFormat.format(species.flightHeight) : species.flightHeight : '',
      species.flightDirection,
      species.notes ?? '',
    ]);
  }
  
  // Add vegetation data
  rows.add(['']); // Empty line to separate vegetation data
  rows.add(['VEGETATION']);
  rows.add(vegetationHeaders);
  for (var vegetation in inventory.vegetationList) {
    rows.add([
      vegetation.sampleTime != null ? DateFormat('dd/MM/yyyy HH:mm:ss').format(vegetation.sampleTime!) : '',
      vegetation.latitude != null ? formatNumbers ? numberFormat.format(vegetation.latitude) : vegetation.latitude : '',
      vegetation.longitude != null ? formatNumbers ? numberFormat.format(vegetation.longitude) : vegetation.longitude : '',
      vegetation.herbsProportion,
      vegetation.herbsDistribution?.index ?? '',
      vegetation.herbsHeight,
      vegetation.shrubsProportion,
      vegetation.shrubsDistribution?.index ?? '',
      vegetation.shrubsHeight,
      vegetation.treesProportion,
      vegetation.treesDistribution?.index ?? '',
      vegetation.treesHeight,
      vegetation.notes ?? '',
    ]);
  }
  
  // Add weather data
  rows.add(['']); // Empty line to separate weather data
  rows.add(['WEATHER']);
  rows.add(weatherHeaders);
  for (var weather in inventory.weatherList) {
    rows.add([
      weather.sampleTime != null ? DateFormat('dd/MM/yyyy HH:mm:ss').format(weather.sampleTime!) : '',
      weather.cloudCover ?? '',
      precipitationTypeFriendlyNames[weather.precipitation] ?? '',
      weather.temperature != null ? formatNumbers ? NumberFormat.decimalPattern(locale.toString()).format(weather.temperature) : weather.temperature : '',
      weather.windSpeed ?? '',
      weather.windDirection,
      weather.atmosphericPressure ?? '',
      weather.relativeHumidity ?? '',
    ]);
  }
  
  // Add POIs data
  rows.add(['']); // Empty line to separate POI data
  rows.add(['POINTS OF INTEREST']);
  rows.add(poiHeaders);
  for (var species in inventory.speciesList) {
    if (species.pois.isNotEmpty) {
      for (var poi in species.pois) {
        rows.add([
          species.name,
          poi.sampleTime != null ? DateFormat('dd/MM/yyyy HH:mm:ss').format(poi.sampleTime!) : '',
          formatNumbers ? numberFormat.format(poi.latitude) : poi.latitude,
          formatNumbers ? numberFormat.format(poi.longitude) : poi.longitude,
          poi.notes ?? '',
        ]);
      }
    }
  }

  return rows;
}

// Convert to CellValue based on value type
CellValue _convertToCellValue(dynamic val) {
  if (val == null) {
    return TextCellValue('');
  }
  if (val is String) {
    // if (val.startsWith('=')) {
    //   return FormulaCellValue(val);
    // }
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
  // if (val is DateTime) {
  //   return TextCellValue(DateFormat('dd/MM/yyyy HH:mm:ss').format(val));
  // }

  return TextCellValue(val.toString());
}

// Convert lists of dynamic to lists of CellValue to use in Excel
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

// Export an inventory to a Excel file, returns the file path
Future<String> exportInventoryToExcel(BuildContext context, Inventory inventory, Locale locale) async {
  try {
    // 1. Create a list of data
    List<List<dynamic>> rows = await buildInventoryRows(inventory, locale);
    List<List<CellValue>> cellRows = convertRowsToCellValues(rows);

    // 2. Convert the list of data to Excel
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];

    for (List<CellValue> row in cellRows) {
      sheet.appendRow(row);
    }

    // 3. Create the file in a temporary directory
    var fileBytes = excel.save();
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/inventory_${inventory.id}.xlsx';
    // if (sheet.rows.isNotEmpty) {
      File(filePath)
        ..create(recursive: true)
        ..writeAsBytes(fileBytes!);
      return filePath; // Return the file path for further use
    // } else {
      // throw Exception('Failed to generate Excel file.');
    // }
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
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: Row(
    //         children: [
    //           const Icon(Icons.error_outlined, color: Colors.red),
    //           const SizedBox(width: 10),
    //           Text(S.current.errorTitle),
    //         ],
    //       ),
    //       content: SingleChildScrollView(
    //         child: Text(S.current.errorExportingInventory(1, error.toString())),
    //       ),
    //       actions: [
    //         TextButton(
    //           child: Text(S.of(context).ok),
    //           onPressed: () => Navigator.of(context).pop(),
    //         ),
    //       ],
    //     );
    //   },
    // );
    return '';
  }
}

// Export an inventory to a CSV file
Future<String> exportInventoryToCsv(BuildContext context, Inventory inventory, Locale locale) async {
  try {
    // 1. Create a list of data 
    List<List<dynamic>> rows = await buildInventoryRows(inventory, locale);

    // 2. Convert the list of data to CSV
    String csv = const ListToCsvConverter().convert(rows, fieldDelimiter: ';', convertNullTo: '');

    // 3. Create the file in a temporary directory
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/inventory_${inventory.id}.csv';
    if (csv.isNotEmpty) {
      final file = File(filePath);
      await file.writeAsString(csv);
      return filePath;
    } else {
      throw Exception('Failed to generate CSV file.');
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
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: Row(
    //         children: [
    //           const Icon(Icons.error_outlined, color: Colors.red),
    //           const SizedBox(width: 10),
    //           Text(S.current.errorTitle),
    //         ],
    //       ),
    //       content: SingleChildScrollView(
    //         child: Text(S.current.errorExportingInventory(1, error.toString())),
    //       ),
    //       actions: [
    //         TextButton(
    //           child: Text(S.of(context).ok),
    //           onPressed: () => Navigator.of(context).pop(),
    //         ),
    //       ],
    //     );
    //   },
    // );
    return '';
  }
}

Future<void> exportInventoryToKml(BuildContext context, Inventory inventory) async {
  try {
    final gpx = GeoXml();
    gpx.creator = 'Xolmis Mobile';
    gpx.metadata = Metadata(
      name: 'Inventory ${inventory.id}',
      desc: 'Points of Interest for Inventory ${inventory.id}',
      time: inventory.startTime ?? DateTime.now(),
    );

    gpx.wpts.add(Wpt(
      lat: inventory.startLatitude,
      lon: inventory.startLongitude,
      name: '${inventory.id} - Start',
      desc: inventoryTypeFriendlyNames[inventory.type] ?? '',
      time: inventory.startTime ?? DateTime.now(),
    ));
    gpx.wpts.add(Wpt(
      lat: inventory.endLatitude,
      lon: inventory.endLongitude,
      name: '${inventory.id} - End',
      desc: inventoryTypeFriendlyNames[inventory.type] ?? '',
      time: inventory.endTime ?? DateTime.now(),
    ));

    for (var species in inventory.speciesList) {
      if (species.pois.isNotEmpty) {
        for (var poi in species.pois) {
          gpx.wpts.add(Wpt(
            lat: poi.latitude,
            lon: poi.longitude,
            name: '${species.name} - POI #${poi.id}',
            desc: poi.notes ?? '',
            time: poi.sampleTime ?? DateTime.now(),
          ));
        }
      }
    }

    if (gpx.wpts.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            showCloseIcon: true,
                            content: Text(S.of(context).noPoisToExport),
                          ),
                        );
      }
      // showDialog(
      //   context: context,
      //   builder: (context) => AlertDialog(
      //     title: Text(S.current.warningTitle),
      //     content: Text(S.current.noPoisToExport),
      //     actions: [
      //       TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(S.current.ok)),
      //     ],
      //   ),
      // );
      return;
    }

    final kmlString = KmlWriter(altitudeMode: AltitudeMode.clampToGround).asString(gpx, pretty: true);

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/inventory_${inventory.id}_pois.kml';
    final file = File(filePath);
    await file.writeAsString(kmlString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/vnd.google-earth.kml+xml')],
        text: S.current.inventoryExported(1),
        subject: '${S.current.inventoryExported(1)} ${inventory.id}',
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
    // showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: Text(S.current.errorTitle),
    //     content: Text(S.current.errorExportingInventory(1, error.toString())),
    //     actions: [
    //       TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(S.current.ok)),
    //     ],
    //   ),
    // );
    return;
  }
}

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
    final inactiveNests = nestProvider.inactiveNests;
    final jsonData = inactiveNests.map((nest) => nest.toJson()).toList();
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
        text: S.current.nestExported(2), 
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
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: Row(
    //         children: [
    //           const Icon(Icons.error_outlined, color: Colors.red),
    //           const SizedBox(width: 10),
    //           Text(S.current.errorTitle),
    //         ],
    //       ),
    //       content: SingleChildScrollView(
    //         child: Text(S.current.errorExportingNest(1, error.toString())),
    //       ),
    //       actions: [
    //         TextButton(
    //           child: Text(S.of(context).ok),
    //           onPressed: () => Navigator.of(context).pop(),
    //         ),
    //       ],
    //     );
    //   },
    // );
    return;
  } finally {
    // Ensure the dialog is always closed if it was shown and an error occurred,
    // or if the function returned early while the dialog was up.
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
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
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/json')], 
        text: S.current.nestExported(1), 
        subject: '${S.current.nestData(1)} ${nest.fieldNumber}'
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
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: Row(
    //         children: [
    //           const Icon(Icons.error_outlined, color: Colors.red),
    //           const SizedBox(width: 10),
    //           Text(S.current.errorTitle),
    //         ],
    //       ),
    //       content: SingleChildScrollView(
    //         child: Text(S.current.errorExportingNest(1, error.toString())),
    //       ),
    //       actions: [
    //         TextButton(
    //           child: Text(S.of(context).ok),
    //           onPressed: () => Navigator.of(context).pop(),
    //         ),
    //       ],
    //     );
    //   },
    // );
    return;
  }
}

Future<String> exportNestToCsv(BuildContext context, Nest nest, Locale locale) async {
  try {
    // 1. Create a list of data for the CSV
    List<List<dynamic>> rows = await buildNestRows(nest, locale);

    // 2. Convert the list of data to CSV
    String csv = const ListToCsvConverter().convert(rows, fieldDelimiter: ';', convertNullTo: '');

    // 3. Create the file in a temporary directory
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/nest_${nest.fieldNumber}.csv';
    if (csv.isNotEmpty) {
      final file = File(filePath);
      await file.writeAsString(csv);
      return filePath;
    } else {
      throw Exception('Failed to generate CSV file.');
    }    
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
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: Row(
    //         children: [
    //           const Icon(Icons.error_outlined, color: Colors.red),
    //           const SizedBox(width: 10),
    //           Text(S.current.errorTitle),
    //         ],
    //       ),
    //       content: SingleChildScrollView(
    //         child: Text(S.current.errorExportingNest(1, error.toString())),
    //       ),
    //       actions: [
    //         TextButton(
    //           child: Text(S.of(context).ok),
    //           onPressed: () => Navigator.of(context).pop(),
    //         ),
    //       ],
    //     );
    //   },
    // );
    return '';
  }
}

// Export a nest to an Excel file, returns the file path
Future<String> exportNestToExcel(BuildContext context, Nest nest, Locale locale) async {
  try {
    // 1. Create a list of data
    List<List<dynamic>> rows = await buildNestRows(nest, locale);
    List<List<CellValue>> cellRows = convertRowsToCellValues(rows);

    // 2. Convert the list of data to Excel
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Sheet1'];

    for (List<CellValue> row in cellRows) {
      sheet.appendRow(row);
    }

    // 3. Create the file in a temporary directory
    var fileBytes = excel.save();
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/nest_${nest.fieldNumber}.xlsx';
    if (fileBytes != null) {
      File(filePath)
        ..create(recursive: true)
        ..writeAsBytes(fileBytes);
      return filePath; // Return the file path for further use
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
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: Row(
    //         children: [
    //           const Icon(Icons.error_outlined, color: Colors.red),
    //           const SizedBox(width: 10),
    //           Text(S.current.errorTitle),
    //         ],
    //       ),
    //       content: SingleChildScrollView(
    //         child: Text(S.current.errorExportingNest(1, error.toString())),
    //       ),
    //       actions: [
    //         TextButton(
    //           child: Text(S.of(context).ok),
    //           onPressed: () => Navigator.of(context).pop(),
    //         ),
    //       ],
    //     );
    //   },
    // );
    return '';
  }
}

// Add nest data to CSV rows
Future<List<List>> buildNestRows(Nest nest, Locale locale) async {
  const nestHeaders = ['Field number','Species','Locality','Longitude','Latitude',
    'Date found','Support','Height above ground','Male','Female','Helpers',
    'Last date','Observer','Fate'];
  const revisionHeaders = ['Date/Time','Status','Phase','Host eggs','Host nestlings',
    'Nidoparasite eggs','Nidoparasite nestlings','Has Philornis larvae','Notes'];
  const eggHeaders = ['Date/Time','Field number','Species','Egg shape',
    'Width','Length','Weight'];
  final numberFormat = NumberFormat.decimalPattern(locale.toString())..maximumFractionDigits = 7;
  List<List<dynamic>> rows = [];
  final prefs = await SharedPreferences.getInstance();
  final formatNumbers = prefs.getBool('formatNumbers') ?? true;
  rows.add(nestHeaders);
  rows.add([
    nest.fieldNumber,
    nest.speciesName,
    nest.localityName,
    formatNumbers ? numberFormat.format(nest.longitude) : nest.longitude,
    formatNumbers ? numberFormat.format(nest.latitude) : nest.latitude,
    nest.foundTime != null ? DateFormat('dd/MM/yyyy HH:mm:ss').format(nest.foundTime!) : '',
    nest.support,
    formatNumbers ? NumberFormat.decimalPattern(locale.toString()).format(nest.heightAboveGround) : nest.heightAboveGround,
    nest.male,
    nest.female,
    nest.helpers,
    nest.lastTime != null ? DateFormat('dd/MM/yyyy HH:mm:ss').format(nest.lastTime!) : '',
    nest.observer,
    nestFateTypeFriendlyNames[nest.nestFate] ?? '',
  ]);
  
  // Add nest revision data
  rows.add(['']); // Empty line as separator
  rows.add(['REVISIONS']);
  rows.add(revisionHeaders);
  for (var revision in nest.revisionsList ?? []) {
    rows.add([
      revision.sampleTime != null ? DateFormat('dd/MM/yyyy HH:mm:ss').format(revision.sampleTime!) : '',
      nestStatusTypeFriendlyNames[revision.nestStatus] ?? '',
      nestStageTypeFriendlyNames[revision.nestStage] ?? '',
      revision.eggsHost,
      revision.nestlingsHost,
      revision.eggsParasite,
      revision.nestlingsParasite,
      revision.hasPhilornisLarvae,
      revision.notes,
    ]);
  }
  
  // Add egg data
  rows.add(['']);
  rows.add(['EGGS']);
  rows.add(eggHeaders);
  for (var egg in nest.eggsList ?? []) {
    rows.add([
      egg.sampleTime != null ? DateFormat('dd/MM/yyyy HH:mm:ss').format(egg.sampleTime!) : '',
      egg.fieldNumber,
      egg.speciesName,
      eggShapeTypeFriendlyNames[egg.eggShape] ?? '',
      formatNumbers ? NumberFormat.decimalPattern(locale.toString()).format(egg.width) : egg.width,
      formatNumbers ? NumberFormat.decimalPattern(locale.toString()).format(egg.length) : egg.length,
      formatNumbers ? NumberFormat.decimalPattern(locale.toString()).format(egg.mass) : egg.mass,
    ]);
  }

  return rows;
}

Future<void> exportNestToKml(BuildContext context, Nest nest) async {
  try {
    final gpx = GeoXml();
    gpx.creator = 'Xolmis Mobile';
    gpx.metadata = Metadata(
      name: 'Nest ${nest.fieldNumber}',
      desc: 'Coordinates for Nest ${nest.fieldNumber}',
      time: nest.foundTime ?? DateTime.now(),
    );

          gpx.wpts.add(Wpt(
            lat: nest.latitude,
            lon: nest.longitude,
            name: '${nest.fieldNumber} - ${nest.speciesName}',
            desc: nest.localityName ?? '',
            time: nest.foundTime ?? DateTime.now(),
          ));

    if (gpx.wpts.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            showCloseIcon: true,
                            content: Text(S.of(context).noPoisToExport),
                          ),
                        );
      // showDialog(
      //   context: context,
      //   builder: (context) => AlertDialog(
      //     title: Text(S.current.warningTitle),
      //     content: Text(S.current.noPoisToExport),
      //     actions: [
      //       TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(S.current.ok)),
      //     ],
      //   ),
      // );
      return;
    }

    final kmlString = KmlWriter(altitudeMode: AltitudeMode.clampToGround).asString(gpx, pretty: true);

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/nest_${nest.fieldNumber}.kml';
    final file = File(filePath);
    await file.writeAsString(kmlString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/vnd.google-earth.kml+xml')],
        text: S.current.nestExported(1),
        subject: '${S.current.nestExported(1)} ${nest.fieldNumber}',
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
    // showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: Text(S.current.errorTitle),
    //     content: Text(S.current.errorExportingNest(1, error.toString())),
    //     actions: [
    //       TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(S.current.ok)),
    //     ],
    //   ),
    // );
    return;
  }
}

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

    // final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
    // final specimenList = specimenProvider.specimens;
    final jsonData = specimenList.map((specimen) => specimen.toJson()).toList();
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
        text: S.current.specimenExported(2), 
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
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: Row(
    //         children: [
    //           const Icon(Icons.error_outlined, color: Colors.red),
    //           const SizedBox(width: 10),
    //           Text(S.current.errorTitle),
    //         ],
    //       ),
    //       content: SingleChildScrollView(
    //         child: Text(S.current.errorExportingSpecimen(1, error.toString())),
    //       ),
    //       actions: [
    //         TextButton(
    //           child: Text(S.of(context).ok),
    //           onPressed: () => Navigator.of(context).pop(),
    //         ),
    //       ],
    //     );
    //   },
    // );
  } finally {
    // Ensure the dialog is always closed if it was shown and an error occurred,
    // or if the function returned early while the dialog was up.
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

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

    // final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
    // final specimenList = specimenProvider.specimens;
    final locale = Localizations.localeOf(context);

    // 1. Create a list of data for the CSV
    List<List<dynamic>> rows = await buildSpecimensRows(specimenList, locale);

    // 2. Convert the list of data to CSV
    String csv = const ListToCsvConverter().convert(rows, fieldDelimiter: ';', convertNullTo: '');

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
        text: S.current.specimenExported(2), 
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
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: Row(
    //         children: [
    //           const Icon(Icons.error_outlined, color: Colors.red),
    //           const SizedBox(width: 10),
    //           Text(S.current.errorTitle),
    //         ],
    //       ),
    //       content: SingleChildScrollView(
    //         child: Text(S.current.errorExportingSpecimen(1, error.toString())),
    //       ),
    //       actions: [
    //         TextButton(
    //           child: Text(S.of(context).ok),
    //           onPressed: () => Navigator.of(context).pop(),
    //         ),
    //       ],
    //     );
    //   },
    // );
  } finally {
    // Ensure the dialog is always closed if it was shown and an error occurred,
    // or if the function returned early while the dialog was up.
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

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
        files: [XFile(filePath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')], 
        text: S.current.specimenExported(2), 
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
    // showDialog(
    //   context: context,
    //   builder: (context) {
    //     return AlertDialog(
    //       title: Row(
    //         children: [
    //           const Icon(Icons.error_outlined, color: Colors.red),
    //           const SizedBox(width: 10),
    //           Text(S.current.errorTitle),
    //         ],
    //       ),
    //       content: SingleChildScrollView(
    //         child: Text(S.current.errorExportingSpecimen(1, error.toString())),
    //       ),
    //       actions: [
    //         TextButton(
    //           child: Text(S.of(context).ok),
    //           onPressed: () => Navigator.of(context).pop(),
    //         ),
    //       ],
    //     );
    //   },
    // );
  } finally {
    // Ensure the dialog is always closed if it was shown and an error occurred,
    // or if the function returned early while the dialog was up.
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

// Add specimens data to CSV rows
Future<List<List>> buildSpecimensRows(List<Specimen> specimenList, Locale locale) async {
  const specimenHeaders = ['Date/Time','Field number','Observer','Species','Type','Locality',
    'Longitude','Latitude','Notes'];
  final numberFormat = NumberFormat.decimalPattern(locale.toString())..maximumFractionDigits = 7;
  List<List<dynamic>> rows = [];
  final prefs = await SharedPreferences.getInstance();
  final formatNumbers = prefs.getBool('formatNumbers') ?? true;

  rows.add(specimenHeaders);
  for (var specimen in specimenList) {
    rows.add([
      specimen.sampleTime != null ? DateFormat('dd/MM/yyyy HH:mm:ss').format(specimen.sampleTime!) : '',
      specimen.fieldNumber,
      specimen.observer,
      specimen.speciesName,
      specimenTypeFriendlyNames[specimen.type] ?? '',
      specimen.locality,
      formatNumbers ? numberFormat.format(specimen.longitude) : specimen.longitude,
      formatNumbers ? numberFormat.format(specimen.latitude) : specimen.latitude,
      specimen.notes,
    ]);
  }

  return rows;
}

Future<void> exportSpecimenToKml(BuildContext context, Specimen specimen) async {
  try {
    final gpx = GeoXml();
    gpx.creator = 'Xolmis Mobile';
    gpx.metadata = Metadata(
      name: 'Specimen ${specimen.fieldNumber}',
      desc: 'Coordinates for Specimen ${specimen.fieldNumber}',
      time: specimen.sampleTime ?? DateTime.now(),
    );

    gpx.wpts.add(Wpt(
      lat: specimen.latitude,
      lon: specimen.longitude,
      name: '${specimen.fieldNumber} - ${specimen.speciesName}',
      desc: specimen.locality ?? '',
      time: specimen.sampleTime ?? DateTime.now(),
    ));

    if (gpx.wpts.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            showCloseIcon: true,
                            content: Text(S.of(context).noPoisToExport),
                          ),
                        );
      // showDialog(
      //   context: context,
      //   builder: (context) => AlertDialog(
      //     title: Text(S.current.warningTitle),
      //     content: Text(S.current.noPoisToExport),
      //     actions: [
      //       TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(S.current.ok)),
      //     ],
      //   ),
      // );
      return;
    }

    final kmlString = KmlWriter(altitudeMode: AltitudeMode.clampToGround).asString(gpx, pretty: true);

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/specimen_${specimen.fieldNumber}.kml';
    final file = File(filePath);
    await file.writeAsString(kmlString);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath, mimeType: 'application/vnd.google-earth.kml+xml')],
        text: S.current.specimenExported(1),
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
    // showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: Text(S.current.errorTitle),
    //     content: Text(S.current.errorExportingSpecimen(1, error.toString())),
    //     actions: [
    //       TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(S.current.ok)),
    //     ],
    //   ),
    // );
  }
}
