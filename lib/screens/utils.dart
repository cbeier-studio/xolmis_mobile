import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/inventory.dart';
import '../data/models/nest.dart';
import '../data/database/repositories/inventory_repository.dart';
import '../providers/inventory_provider.dart';
import '../providers/species_provider.dart';
import '../providers/nest_provider.dart';
import '../providers/specimen_provider.dart';

import 'inventory/add_inventory_screen.dart';

Future<List<String>> loadSpeciesSearchData() async {
  final jsonString = await rootBundle.loadString('assets/species_data.json');
  final jsonData = json.decode(jsonString) as List<dynamic>;
  return jsonData.map((species) => species['scientificName'].toString())
      .toList();
}

String getNextInventoryId(String currentId) {
  final parts = currentId.split('-');
  final lastPart = parts.last;
  final prefix = lastPart.substring(0, 1); // Get the letter prefix (e.g., "L")
  final number = int.parse(lastPart.substring(1)); // Get the numeric part (e.g., "01")
  final nextNumber = number + 1;
  final nextId = '${parts[0]}-${prefix}${nextNumber.toString().padLeft(2, '0')}'; // Pad with leading zeros if needed
  return nextId;
}

void checkMackinnonCompletion(BuildContext context, Inventory inventory, InventoryRepository inventoryRepository) {
  final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
  final speciesList = speciesProvider.getSpeciesForInventory(inventory.id);
  // print('speciesList: ${speciesList.length} ; maxSpecies: ${inventory.maxSpecies}');
  if (inventory.type == InventoryType.invMackinnonList &&
      speciesList.length == inventory.maxSpecies) {
    _showMackinnonDialog(context, inventory, inventoryRepository);
  }
}

void _showMackinnonDialog(BuildContext context, Inventory inventory, InventoryRepository inventoryRepository) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Inventário Concluído'),
        content: Text(
            'O inventário atingiu o número máximo de espécies. Deseja iniciar a próxima lista ou encerrar as listas?'),
        actions: [
          TextButton(
            child: Text('Iniciar Próxima Lista'),
            onPressed: () async {
              // Finish the inventory and open the screen to add inventory
              await Inventory.stopTimer(inventory, inventoryRepository);
              // onInventoryUpdated(inventory);
              Navigator.pop(context, true);
              Navigator.of(context).pop();
              final nextInventoryId = getNextInventoryId(inventory.id);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddInventoryScreen(
                  initialInventoryId: nextInventoryId,
                  initialInventoryType: InventoryType.invMackinnonList,
                  initialMaxSpecies: inventory.maxSpecies,
                )
                ),
              );
            },
          ),
          TextButton(
            child: Text('Encerrar'),
            onPressed: () async {
              // Finish the inventory and go back to the Home screen
              await Inventory.stopTimer(inventory, inventoryRepository);
              // onInventoryUpdated(inventory);
              Navigator.pop(context, true);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<ThemeMode> getThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final themeModeIndex = prefs.getInt('themeMode') ?? 0; // 0 is the default value for ThemeMode.system
  return ThemeMode.values[themeModeIndex];
}

/// Determine the current position of the device.
///
/// When the location services are not enabled or permissions
/// are denied the `Future` will return an error.
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

Future<Position?> getPosition() async {
  try {
    return await _determinePosition();
  } catch (e) {
    return null;
  }
}

Future<void> exportAllInventoriesToJson(BuildContext context, InventoryProvider inventoryProvider) async {
  try {
    final finishedInventories = inventoryProvider.finishedInventories;
    final jsonData = finishedInventories.map((inventory) => inventory.toJson()).toList();
    final jsonString = jsonEncode(jsonData);

    // Create the file in a temporary folder
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/inventories.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    // Share the file using share_plus
    await Share.shareXFiles([
      XFile(filePath, mimeType: 'application/json'),
    ], text: 'Inventários exportados!', subject: 'Dados dos Inventários');
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text('Erro ao exportar os inventários: $error'),
        ],
      ),
      ),
    );
  }
}

Future<void> exportInventoryToJson(BuildContext context, Inventory inventory) async {
  try {
    final jsonData = inventory.toJson();
    final jsonString = jsonEncode(jsonData);

    // Create the file in a temporary folder
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/inventory_${inventory.id}.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    // Share the file using share_plus
    await Share.shareXFiles([
      XFile(filePath, mimeType: 'application/json'),
    ], text: 'Inventário exportado!', subject: 'Dados do Inventário ${inventory.id}');
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text('Erro ao exportar o inventário: $error'),
        ],
      ),
      ),
    );
  }
}

Future<void> exportInventoryToCsv(BuildContext context, Inventory inventory) async {
  try {
    // 1. Create a list of data for the CSV
    List<List<dynamic>> rows = [];
    rows.add([
      'ID do Inventário',
      'Tipo',
      'Duração',
      'Pausado',
      'Finalizado',
      'Tempo Restante',
      'Tempo Decorrido'
    ]);
    rows.add([
      inventory.id,
      inventoryTypeFriendlyNames[inventory.type],
      inventory.duration,
      inventory.isPaused,
      inventory.isFinished,
      inventory.elapsedTime
    ]);

    // Add species data
    rows.add([]); // Empty line to separate the inventory of the species
    rows.add(['Espécie', 'Contagem', 'Fora da amostra']);
    for (var species in inventory.speciesList) {
      rows.add([species.name, species.count, species.isOutOfInventory]);
    }

    // Add vegetation data
    rows.add([]); // Empty line to separate vegetation data
    rows.add(['Vegetação']);
    rows.add([
      'Data/Hora',
      'Latitude',
      'Longitude',
      'Proporção de Herbáceas',
      'Distribuição de Herbáceas',
      'Altura de Herbáceas',
      'Proporção de Arbustos',
      'Distribuição de Arbustos',
      'Altura de Arbustos',
      'Proporção de Árvores',
      'Distribuição de Árvores',
      'Altura de Árvores',
      'Observações'
    ]);
    for (var vegetation in inventory.vegetationList) {
      rows.add([
        vegetation.sampleTime,
        vegetation.latitude,
        vegetation.longitude,
        vegetation.herbsProportion,
        vegetation.herbsDistribution,
        vegetation.herbsHeight,
        vegetation.shrubsProportion,
        vegetation.shrubsDistribution,
        vegetation.shrubsHeight,
        vegetation.treesProportion,
        vegetation.treesDistribution,
        vegetation.treesHeight,
        vegetation.notes
      ]);
    }

    // Add weather data
    rows.add([]); // Empty line to separate weather data
    rows.add(['Tempo']);
    rows.add([
      'Data/Hora',
      'Nebulosidade',
      'Precipitação',
      'Temperatura',
      'Vento'
    ]);
    for (var weather in inventory.weatherList) {
      rows.add([
        weather.sampleTime,
        weather.cloudCover,
        precipitationTypeFriendlyNames[weather.precipitation],
        weather.temperature,
        weather.windSpeed
      ]);
    }

    // Add POIs data
    rows.add([]); // Empty line to separate POI data
    rows.add(['POIs das Espécies']);
    for (var species in inventory.speciesList) {
      if (species.pois.isNotEmpty) {
        rows.add(['Espécie: ${species.name}']);
        rows.add(['Latitude', 'Longitude']);
        for (var poi in species.pois) {
          rows.add([poi.latitude, poi.longitude]);
        }
        rows.add([]); // Empty line to
      }// separate species POIs
    }

    // 2. Convert the list of data to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // 3. Create the file in a temporary directory
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/inventory_${inventory.id}.csv';
    final file = File(filePath);
    await file.writeAsString(csv);

    // 4. Share the file using share_plus
    await Share.shareXFiles([
      XFile(filePath, mimeType: 'text/csv'),
    ], text: 'Inventário exportado!', subject: 'Dados do Inventário ${inventory.id}');
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text('Erro ao exportar o inventário: $error'),
        ],
      ),
      ),
    );
  }
}

Future<void> exportAllInactiveNestsToJson(BuildContext context) async {
  try {
    final nestProvider = Provider.of<NestProvider>(context, listen: false);
    final inactiveNests = nestProvider.inactiveNests;
    final jsonData = inactiveNests.map((nest) => nest.toJson()).toList();
    final jsonString = jsonEncode(jsonData);

    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/inactive_nests.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);

    await Share.shareXFiles([
      XFile(filePath, mimeType: 'application/json'),
    ], text: 'Ninhos inativos exportados!', subject: 'Dados dos Ninhos Inativos');
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text('Erro ao exportar os ninhos inativos: $error'),
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
    ], text: 'Ninho exportado!', subject: 'Dados do Ninho ${nest.fieldNumber}');
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text('Erro ao exportar o ninho: $error'),
        ],
      ),
      ),
    );
  }
}

Future<void> exportNestToCsv(BuildContext context, Nest nest) async {
  try {
    // 1. Create a list of data for the CSV
    List<List<dynamic>> rows = [];
    rows.add([
      'Nº de campo',
      'Espécie',
      'Localidade',
      'Longitude',
      'Latitude',
      'Data de encontro',
      'Suporte',
      'Altura acima do solo',
      'Macho',
      'Fêmea',
      'Ajudantes de ninho',
      'Última data',
      'Destino do ninho',
    ]);
    rows.add([
      nest.fieldNumber,
      nest.speciesName,
      nest.localityName,
      nest.longitude,
      nest.latitude,
      nest.foundTime,
      nest.support,
      nest.heightAboveGround,
      nest.male,
      nest.female,
      nest.helpers,
      nest.lastTime,
      NestFateType.values[nest.nestFate!.index],
    ]);

    // Add nest revision data
    rows.add([]); // Empty line as separator
    rows.add(['Revisões']);
    rows.add([
      'Data/Hora',
      'Status',
      'Estágio',
      'Ovos do hospedeiro',
      'Ninhegos do hospedeiro',
      'Ovos do nidoparasita',
      'Ninhegos do nidoparasita',
      'Tem larvas de Philornis',
      'Observações',
    ]);
    for (var revision in nest.revisionsList ?? []) {
      rows.add([
        revision.sampleTime,
        revision.nestStatus,
        revision.nestStage,
        revision.eggsHost,
        revision.nestlingsHost,
        revision.eggsParasite,
        revision.nestlingsParasite,
        revision.hasPhilornisLarvae,
        revision.notes,
      ]);
    }

    // Add egg data
    rows.add([]); // Empty line to separate vegetation data
    rows.add(['Ovos']);
    rows.add([
      'Data/Hora',
      'Nº de campo',
      'Espécie',
      'Forma do ovo',
      'Largura',
      'Comprimento',
      'Peso',
    ]);
    for (var egg in nest.eggsList ?? []) {
      rows.add([
        egg.sampleTime,
        egg.fieldNumber,
        egg.speciesName,
        egg.eggShape,
        egg.width,
        egg.length,
        egg.mass,
      ]);
    }

    // 2. Convert the list of data to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // 3. Create the file in a temporary directory
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/nest_${nest.id}.csv';
    final file = File(filePath);
    await file.writeAsString(csv);

    // 4. Share the file using share_plus
    await Share.shareXFiles([
      XFile(filePath, mimeType: 'text/csv'),
    ], text: 'Ninho exportado!', subject: 'Dados do Ninho ${nest.id}');
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text('Erro ao exportar o ninho: $error'),
        ],
      ),
      ),
    );
  }
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
    ], text: 'Espécimes exportados!', subject: 'Dados dos Espécimes');
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text('Erro ao exportar os espécimes: $error'),
        ],
      ),
      ),
    );
  }
}

