import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/inventory.dart';
import '../data/models/nest.dart';
import '../data/models/specimen.dart';
import '../providers/inventory_provider.dart';
import '../providers/nest_provider.dart';
import '../providers/specimen_provider.dart';

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
      nestFateTypeFriendlyNames[nest.nestFate],
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
        eggShapeTypeFriendlyNames[egg.eggShape],
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

Future<void> exportAllSpecimensToCsv(BuildContext context) async {
  try {
    final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
    final specimenList = specimenProvider.specimens;

    // 1. Create a list of data for the CSV
    List<List<dynamic>> rows = [];
    rows.add([
      'Data/Hora',
      'Nº de campo',
      'Espécie',
      'Tipo',
      'Localidade',
      'Longitude',
      'Latitude',
      'Observações',
    ]);
    for (var specimen in specimenList ?? []) {
      rows.add([
        specimen.sampleTime,
        specimen.fieldNumber,
        specimen.speciesName,
        specimenTypeFriendlyNames[specimen.type],
        specimen.locality,
        specimen.longitude,
        specimen.latitude,
        specimen.notes,
      ]);
    }

    // 2. Convert the list of data to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // 3. Create the file in a temporary directory
    Directory tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/specimens.csv';
    final file = File(filePath);
    await file.writeAsString(csv);

    // 4. Share the file using share_plus
    await Share.shareXFiles([
      XFile(filePath, mimeType: 'text/csv'),
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