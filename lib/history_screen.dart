import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'inventory_detail_screen.dart';
import 'inventory_provider.dart';
import 'inventory.dart';

class HistoryScreen extends StatefulWidget {const HistoryScreen({super.key});

@override
_HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false)
          .loadFinishedInventories();
    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingFinished) {
            return const Center(child: CircularProgressIndicator());
          } else if (provider.finishedInventories.isEmpty) {
            return const Center(child: Text('Nenhum inventário encontrado.'));
          } else {
            return AnimatedList(
              key: _listKey,
              initialItemCount: provider.finishedInventories.length,
              itemBuilder: (context, index, animation) {
                final inventory = provider.finishedInventories[index];
                return HistoryListItem(
                  key: ValueKey(inventory.id),
                  inventory: inventory,
                  animation: animation,
                  onDelete: () => _removeInventory(provider, inventory, index),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _removeInventory(InventoryProvider provider, Inventory inventory, int index) {
    _listKey.currentState!.removeItem(
      index,
          (context, animation) => SizeTransition(
        sizeFactor: animation,
        child: DismissedHistoryListItem(
          key: ValueKey(inventory.id),
          inventory: inventory,
          animation: animation,
        ),
      ),
    );
    provider.removeFinishedInventory(inventory);
  }
}

class HistoryListItem extends StatelessWidget {
  final Inventory inventory;
  final Animation<double> animation;
  final VoidCallback onDelete;

  const HistoryListItem({
    super.key,
    required this.inventory,
    required this.animation,
    required this.onDelete,
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
          children: [
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: () {
                Provider.of<InventoryProvider>(context, listen: false)
                    .exportInventory(inventory);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InventoryDetailScreen(
                inventory: inventory,
                allInventories: const [],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DismissedHistoryListItem extends StatelessWidget {
  final Inventory inventory;
  final Animation<double> animation;

  const DismissedHistoryListItem({
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
        // Remove trailing here as it contains the delete button
      ),
    );
  }
}