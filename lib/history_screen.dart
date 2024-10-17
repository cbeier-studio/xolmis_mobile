import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'inventory.dart';
import 'database_helper.dart';
import 'inventory_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Inventory> _closedInventories = [];
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadClosedInventories();
  }

  void onInventoryUpdated() {
    setState(() {
      _loadClosedInventories(); // Recarrega os inventários
    });
  }

  Future<void> _loadClosedInventories() async {
    final inventories = await dbHelper.getFinishedInventories();
    setState(() {
      _closedInventories = inventories;
    });
  }

  void _deleteInventory(Inventory inventory) async {
    // Remove o inventário do banco de dados
    await dbHelper.deleteInventory(inventory.id);

    // Remove o inventário da lista e atualiza a UI
    setState(() {
      final index = _closedInventories.indexOf(inventory);
      _closedInventories.removeAt(index);
      _listKey.currentState!.removeItem(index, (context, animation) {
        return InventoryListItem(
          inventory: inventory,
          animation: animation,
          onInventoryUpdated: onInventoryUpdated,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadClosedInventories,
        child: _closedInventories.isEmpty // Verifica se a lista está vazia
        ? const Center(child: Text('Nenhum inventário no histórico.')) // Mostra o texto se a lista estiver vazia
        : AnimatedList(
        key: _listKey,
        initialItemCount: _closedInventories.length,
          itemBuilder: (context, index, animation) {
            final inventory = _closedInventories[index];
            return Dismissible( // Adiciona o Dismissable
              key: Key(inventory.id), // Define uma chave única para o Dismissable
              onDismissed: (direction) {// Exibe um AlertDialog para confirmar a exclusão
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirmar Exclusão'),
                      content: const Text('Tem certeza que deseja excluir este inventário?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancelar'),
                          onPressed: () {
                            Navigator.of(context).pop(); // Fecha o AlertDialog
                            setState(() {}); // Reconstrói a lista para restaurar o item
                          },
                        ),
                        TextButton(child: const Text('Excluir'),
                          onPressed: () {
                            Navigator.of(context).pop(); // Fecha o AlertDialog
                            _deleteInventory(inventory); // Exclui o inventário
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              background: Container( // Widget exibido durante o arrasto
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: InventoryListItem( // Widget do item da lista
                inventory: inventory,
                animation: animation,
                onInventoryUpdated: onInventoryUpdated,
              ),
            );
          },
      ),
      ),
    );
  }
}

class InventoryListItem extends StatelessWidget {
  final Inventory inventory;
  final Animation<double> animation;
  final VoidCallback onInventoryUpdated;

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
            Text('${inventory.startTime}'),
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
                  onInventoryUpdated: onInventoryUpdated,
              ),
            ),
          ).then((_) => onInventoryUpdated());
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
    rows.add([]); // Empty line to separate the inventory of the species
    rows.add(['Espécie', 'Contagem', 'Fora da amostra']);
    for (var species in inventory.speciesList) {
      rows.add([species.name, species.count, species.isOutOfInventory]);
    }

    // Adicionar dados da vegetação
    rows.add([]); // Empty line to separate vegetation data
    rows.add(['Vegetação']);
    rows.add([
      'Data/Hora','Latitude',
      'Longitude',
      'Proporção de Ervas',
      'Distribuição de Ervas',
      'Altura de Ervas',
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

    // Adicionar dados dos POIs
    rows.add([]); // Empty line to separate POI data
    rows.add(['POIs das Espécies']);
    for (var species in inventory.speciesList) {
      rows.add(['Espécie: ${species.name}']);
      rows.add(['Latitude', 'Longitude']);
      for (var poi in species.pois) {
        rows.add([poi.latitude, poi.longitude]);
      }
      rows.add([]); // Empty line to separate species POIs
    }

    // 2. Convert the list of data to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // 3. Request save location from user
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      // 4. Create the file and save the data
      final filePath = '$selectedDirectory/inventory_${inventory.id}.csv';
      final file = File(filePath);
      await file.writeAsString(csv);

      // 5. Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inventário exportado para: $filePath')),
      );
    } else {
      // User canceled the save dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exportação de inventário cancelada')),
      );
    }
  }
}