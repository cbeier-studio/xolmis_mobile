import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'inventory_detail_screen.dart';
import 'inventory.dart';
import 'new_inventory_screen.dart';
import 'inventory_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventoryProvider>(context, listen: false).loadInventories();
      if (kDebugMode) {
        print('loadInventories chamado');
      }
    });
    Provider.of<InventoryProvider>(context, listen: false).startTimer();
  }

  @override
  void dispose() {
    // Stop timer when the widget is disposed
    Provider.of<InventoryProvider>(context, listen: false).stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventários ativos'),
        //backgroundColor: Colors.green,
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) { // Check if isLoading is true
            return const Center(child: CircularProgressIndicator());
          } else if (provider.inventories.isEmpty) {
            return const Center(child: Text('Nenhum inventário ativo.'));
          } else {
            return ListView.builder(
              itemCount: provider.inventories.length,
              itemBuilder: (context, index) {
                final inventory = provider.inventories[index];
                return ListTile(
                  leading: CircularProgressIndicator(
                    value: _calculateProgress(inventory),
                  ),
                  title: Text(inventory.id),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${inventoryTypeFriendlyNames[inventory.type]}'),
                      if (inventory.duration > 0) Text('${inventory.duration} minutos de duração'),
                      Text('${inventory.speciesList.length} espécies'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Visibility(
                        visible: inventory.duration > 0,
                        child: IconButton(
                          icon: Icon(inventory.isPaused ? Icons.play_arrow : Icons.pause),
                            onPressed: () {
                              Provider.of<InventoryProvider>(context, listen: false)
                                .updateInventoryIsPaused(inventory, !inventory.isPaused, context);
                            },
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            InventoryDetailScreen(
                              inventory: inventory,
                              allInventories: provider.inventories,
                            ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          bool? result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewInventoryScreen()),
          );

          if (result == true) {
            // Reload the inventories after add a new one
            Provider.of<InventoryProvider>(context, listen: false).loadInventories();
          }
        },
        tooltip: 'Criar novo inventário',
        child: const Icon(Icons.add),
      ),
    );
  }

  double _calculateProgress(Inventory inventory) {
    if (inventory.type == InventoryType.invCumulativeTime && inventory.duration > 0) {
      return (inventory.elapsedTime / inventory.duration);
    }
    return 0.0;
  }
}


