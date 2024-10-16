import 'package:flutter/material.dart';
import 'package:animated_list/animated_list.dart';
import 'inventory.dart';
import 'database_helper.dart';
import 'add_inventory_screen.dart';
import 'inventory_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Inventory> _activeInventories = [];
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadActiveInventories();
  }

  Future<void> _loadActiveInventories() async {final inventories = await dbHelper.loadActiveInventories();
  setState(() {
    _activeInventories = inventories;
  });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _activeInventories.length,
        itemBuilder: (context, index, animation) {
          final inventory = _activeInventories[index];
          return InventoryListItem(
            inventory: inventory,
            animation: animation,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InventoryDetailScreen(inventory: inventory),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddInventoryScreen()),
          ).then((newInventory) {
            if (newInventory != null && newInventory is Inventory) {
              setState(() {
                _activeInventories.add(newInventory);
                _listKey.currentState!.insertItem(_activeInventories.length - 1);
              });
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addInventory() {
    final newInventory = Inventory(
      id: 'Novo Inventário',
      type: InventoryType.invQualitative,
      duration: 0,
      speciesList: [],
      vegetationList: [],
    );

    newInventory.startTimer();

    dbHelper.insertInventory(newInventory).then((success) {
      if (success) {setState(() {
        _activeInventories.add(newInventory);
        _listKey.currentState!.insertItem(_activeInventories.length - 1);
      });
      } else {
        // Lidar com erro de inserção
      }
    });
  }
}

class InventoryListItem extends StatelessWidget {
  final Inventory inventory;
  final Animation<double> animation;
  final VoidCallback? onTap;

  const InventoryListItem({
    super.key,
    required this.inventory,
    required this.animation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell( // Ou GestureDetector
        onTap: onTap,
        child:SizeTransition(
          sizeFactor: animation,
          child: ListTile(
            leading: inventory.duration > 0
                ? CircularProgressIndicator(
              value: inventory.elapsedTime / inventory.duration,
            )
                : null,
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
                      if (inventory.isPaused) {
                        inventory.resumeTimer();
                      } else {
                        inventory.pauseTimer();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}