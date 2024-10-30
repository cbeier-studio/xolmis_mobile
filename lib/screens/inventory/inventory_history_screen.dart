import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../data/models/inventory.dart';
import '../../data/database/repositories/inventory_repository.dart';
import '../../data/database/repositories/species_repository.dart';
import '../../data/database/repositories/poi_repository.dart';
import '../../data/database/repositories/vegetation_repository.dart';
import '../../data/database/repositories/weather_repository.dart';
import '../../providers/inventory_provider.dart';

import 'inventory_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final InventoryRepository inventoryRepository;
  final SpeciesRepository speciesRepository;
  final PoiRepository poiRepository;
  final VegetationRepository vegetationRepository;
  final WeatherRepository weatherRepository;

  const HistoryScreen({
    super.key,
    required this.inventoryRepository,
    required this.speciesRepository,
    required this.poiRepository,
    required this.vegetationRepository,
    required this.weatherRepository,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {

  @override
  void initState() {
    super.initState();
    Provider.of<InventoryProvider>(context, listen: false).fetchInventories();
  }

  void onInventoryUpdated(Inventory inventory) {
    Provider.of<InventoryProvider>(context, listen: false).updateInventory(
        inventory);
    Provider.of<InventoryProvider>(context, listen: false).fetchInventories();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventários encerrados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _exportAllInventoriesToJson(inventoryProvider),
            tooltip: 'Exportar todos os inventários',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await inventoryProvider.fetchInventories();
        },
        child: inventoryProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildInventoryList(inventoryProvider),
      ),
    );

  }

  Widget _buildInventoryList(InventoryProvider inventoryProvider) {
    return inventoryProvider.finishedInventories.isEmpty
        ? const Center(child: Text('Nenhum inventário encontrado.'))
        : ListView.builder(
      itemCount: inventoryProvider.finishedInventories.length,
      itemBuilder: (context, index) {
        final inventory = inventoryProvider.finishedInventories[index];
        return Dismissible(
          key: Key(inventory.id),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirmar Exclusão'),
                    content: const Text(
                        'Tem certeza que deseja excluir este inventário?'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(child: const Text('Excluir'),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  );
                }
            );
          },
          onDismissed: (direction) {
            inventoryProvider.removeInventory(inventory.id);
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete_outlined, color: Colors.white),
          ),
          child: InventoryListItem(
            inventory: inventory,
            onInventoryUpdated: onInventoryUpdated,
            speciesRepository: widget.speciesRepository,
            inventoryRepository: widget.inventoryRepository,
            poiRepository: widget.poiRepository,
            vegetationRepository: widget.vegetationRepository,
            weatherRepository: widget.weatherRepository,
          ),
        );
      },
    );
  }

  Future<void> _exportAllInventoriesToJson(InventoryProvider inventoryProvider) async {
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
}

class InventoryListItem extends StatelessWidget {
  final Inventory inventory;
  final void Function(Inventory) onInventoryUpdated;
  final InventoryRepository inventoryRepository;
  final SpeciesRepository speciesRepository;
  final PoiRepository poiRepository;
  final VegetationRepository vegetationRepository;
  final WeatherRepository weatherRepository;

  const InventoryListItem({
    super.key,
    required this.inventory,
    required this.onInventoryUpdated,
    required this.inventoryRepository,
    required this.speciesRepository,
    required this.poiRepository,
    required this.vegetationRepository,
    required this.weatherRepository,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(inventory.id),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${inventoryTypeFriendlyNames[inventory.type]}'),
            Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(inventory.startTime!)),
            Text('${inventory.speciesList.length} espécies registradas'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children:[
            IconButton(
              icon: const Icon(Icons.file_download_outlined),
              tooltip: 'Exportar inventário',
              onPressed: () {
                _exportInventoryToCsv(context, inventory);
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InventoryDetailScreen(
                inventory: inventory,
                speciesRepository: speciesRepository,
                inventoryRepository: inventoryRepository,
                poiRepository: poiRepository,
                vegetationRepository: vegetationRepository,
                weatherRepository: weatherRepository,
              ),
            ),
          ).then((_) => onInventoryUpdated(inventory));
        },
    );
  }

  Future<void> _exportInventoryToCsv(BuildContext context, Inventory inventory) async {
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
}