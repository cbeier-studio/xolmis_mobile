import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
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

  Future<void> _loadClosedInventories() async {
    final inventories = await dbHelper.getFinishedInventories();
    setState(() {
      _closedInventories = inventories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _closedInventories.length,
        itemBuilder: (context, index, animation) {
          final inventory = _closedInventories[index];
          return InventoryListItem(
            inventory: inventory,
            animation: animation,
          );
        },
      ),
    );
  }
}

class InventoryListItem extends StatelessWidget {
  final Inventory inventory;
  final Animation<double> animation;

  const InventoryListItem({
    super.key,
    required this.inventory,
    required this.animation,
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
              builder: (context) => InventoryDetailScreen(inventory: inventory),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportInventoryToCsv(BuildContext context, Inventory inventory) async {
    // 1. Create a list of data for the CSV
    List<List<dynamic>> rows = [];
    rows.add(['ID do Inventário', 'Tipo', 'Duração', 'Pausado', 'Finalizado', 'Tempo Restante', 'Tempo Decorrido']);
    rows.add([inventory.id, inventory.type.toString(), inventory.duration, inventory.isPaused, inventory.isFinished, inventory.elapsedTime]);
    rows.add([]); // Empty line to separate the inventory of the species
    rows.add(['Espécie', 'Contagem']);
    for (var species in inventory.speciesList) {
      rows.add([species.name, species.count]);
    }

    // 2. Convert the list of data to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // 3. Get the documents folder of the device
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/inventory_${inventory.id}.csv';

    // 4. Create the file and save the data
    final file = File(path);
    await file.writeAsString(csv);

    // 5. (Optional) Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inventário exportado para: $path')),
    );
  }
}