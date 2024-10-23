import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/inventory.dart';
import '../providers/inventory_provider.dart';
import 'inventory_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    Provider.of<InventoryProvider>(context, listen: false).loadInventories();
  }

  void onInventoryUpdated(Inventory inventory) {
    Provider.of<InventoryProvider>(context, listen: false).updateInventory(
        inventory);
    Provider.of<InventoryProvider>(context, listen: false).loadInventories();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventários encerrados'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await inventoryProvider.loadInventories();
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
        : AnimatedList(
      key: _listKey,
      initialItemCount: inventoryProvider.finishedInventories.length,
      itemBuilder: (context, index, animation) {
        final inventory = inventoryProvider.finishedInventories[index];
        return Dismissible(
          key: Key(inventory.id),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            showDialog(
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
                        Navigator.of(context).pop();
                        setState(() {}); // Rebuild the list to restore the item
                      },
                    ),
                    TextButton(child: const Text('Excluir'),
                      onPressed: () {
                        final index = inventoryProvider
                            .finishedInventories.indexOf(
                            inventory);
                        inventoryProvider.removeInventory(
                            inventory.id);
                        Navigator.of(context).pop();
                        _listKey.currentState?.removeItem(
                            index, (context, animation) =>
                            SizedBox.shrink());
                      },
                    ),
                  ],
                );
              },
            );
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: InventoryListItem(
            inventory: inventory,
            animation: animation,
            onInventoryUpdated: onInventoryUpdated,
          ),
        );
      },
    );
  }
}

class InventoryListItem extends StatelessWidget {
  final Inventory inventory;
  final Animation<double> animation;
  final void Function(Inventory) onInventoryUpdated;

  const InventoryListItem({
    super.key,
    required this.inventory,
    required this.animation,
    required this.onInventoryUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
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
              icon: const Icon(Icons.file_download),
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
                  // onInventoryUpdated: onInventoryUpdated,
              ),
            ),
          ).then((_) => onInventoryUpdated(inventory));
        },
      ),
    );
  }

  Future<void> _exportInventoryToCsv(BuildContext context, Inventory inventory) async {
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

  }
}