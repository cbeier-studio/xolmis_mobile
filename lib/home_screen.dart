import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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
    _checkLocationPermissions();
    _loadActiveInventories().then((_) {
      for (var inventory in _activeInventories) {
        if (inventory.duration > 0 && !inventory.isFinished) {
          inventory.resumeTimer();
        }}
    });
  }

  Future<void> _checkLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions permanently denied
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions permanently denied
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Permissions granted, you can use the Geolocator here
  }

  Future<void> _loadActiveInventories() async {
    final inventories = await dbHelper.loadActiveInventories();
    setState(() {
      _activeInventories = inventories;
    });
  }

  void _onInventoryPausedOrResumed() {
    setState(() {
      _loadActiveInventories();
    });
  }

  void onInventoryUpdated() {
    setState(() {
      _loadActiveInventories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadActiveInventories,
        child: _activeInventories.isEmpty
            ? const Center(child: Text('Nenhum inventário ativo.'))
            : AnimatedList(
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
                    builder: (context) => InventoryDetailScreen(inventory: inventory,
                    onInventoryUpdated: onInventoryUpdated,
                    ),
                  ),
                );
              },
              onInventoryPausedOrResumed: _onInventoryPausedOrResumed,
            );
          },
        ),
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
        // Handle insertion error
      }
    });
  }
}

class InventoryListItem extends StatelessWidget {
  final Inventory inventory;
  final Animation<double> animation;
  final VoidCallback? onTap;
  final VoidCallback? onInventoryPausedOrResumed;

  const InventoryListItem({
    super.key,
    required this.inventory,
    required this.animation,
    this.onTap,
    this.onInventoryPausedOrResumed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell( // Ou GestureDetector
        onTap: onTap,
        child:SizeTransition(
          sizeFactor: animation,
          child: ListTile(
            // Use ValueListenableBuilder for update the CircularProgressIndicator
            leading: ValueListenableBuilder<double>(
              key: ValueKey(inventory.id),
              valueListenable: inventory.elapsedTimeNotifier,
              builder: (context, elapsedTime, child) {
                return CircularProgressIndicator(
                  value: inventory.duration == 0 ? 0 : (elapsedTime / (inventory.duration * 60)),
                );
              },
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
                      if (inventory.isPaused) {
                        inventory.resumeTimer();
                      } else {
                        inventory.pauseTimer();
                      }
                      onInventoryPausedOrResumed?.call();
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