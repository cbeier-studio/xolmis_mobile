import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/inventory.dart';
import '../data/database_helper.dart';
import 'add_inventory_screen.dart';
import 'inventory_detail_screen.dart';
import '../providers/inventory_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  // List<Inventory> _activeInventories = [];
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
    Provider.of<InventoryProvider>(context, listen: false).loadInventories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      Future.delayed(Duration.zero, ()
      { // Adiciona um Future.delayed
        for (var inventory in inventoryProvider.activeInventories) {
          if (inventory.duration != 0 && !inventory.isPaused) {
            inventory.startTimer();
          }
        }
      });
    });
    // _loadActiveInventories().then((_) {
    //   for (var inventory in _activeInventories) {
    //     if (inventory.duration > 0 && !inventory.isFinished) {
    //       inventory.resumeTimer();
    //     }}
    // });
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

  // Future<void> _loadActiveInventories() async {
  //   final inventories = await dbHelper.loadActiveInventories();
  //   setState(() {
  //     _activeInventories = inventories;
  //     Provider.of<InventoryCountNotifier>(context, listen: false).updateCount();
  //   });
  // }

  void _onInventoryPausedOrResumed(Inventory inventory) {
    Provider.of<InventoryProvider>(context, listen: false).updateInventory(inventory);
  }

  void onInventoryUpdated(Inventory inventory) {
    Provider.of<InventoryProvider>(context, listen: false).updateInventory(inventory);
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await inventoryProvider.loadInventories();
        },
        child: inventoryProvider.isLoading // Verifica o estado de carregamento
            ? const Center(child: CircularProgressIndicator()) // Exibe o indicador de progresso
            : inventoryProvider.activeInventories.isEmpty
            ? const Center(child: Text('Nenhum inventário ativo.'))
            : AnimatedList(
          key: _listKey,
          initialItemCount: inventoryProvider.activeInventories.length,
          itemBuilder: (context, index, animation) {
            final inventory = inventoryProvider.activeInventories[index];
            return ValueListenableBuilder<bool>(
                valueListenable: inventory.isFinishedNotifier,
                builder: (context, isFinished, child) {
                  if (isFinished) {
                    inventoryProvider.loadInventories();
                  }
                  return child!; // Retorna o widget filho (InventoryListItem)
                },
                child: InventoryListItem(
                  inventory: inventory,
                  animation: animation,
                  onTap: (inventory) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InventoryDetailScreen(
                          inventory: inventory,
                          onInventoryUpdated: (inventory) => onInventoryUpdated(inventory),
                        ),
                      ),
                    ).then((result) {
                      if (result == true) {
                        inventoryProvider.loadInventories();
                      }
                    });
                  },
                  onInventoryPausedOrResumed: (inventory) => _onInventoryPausedOrResumed(inventory),
                )
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
              inventoryProvider.addInventory(newInventory);
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class InventoryListItem extends StatelessWidget {
  final Inventory inventory;
  final Animation<double> animation;
  final void Function(Inventory)? onTap;
  final void Function(Inventory)? onInventoryPausedOrResumed;

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
        onTap: () {
          onTap?.call(inventory);
        },
        child:SizeTransition(
          sizeFactor: animation,
          child: ListTile(
            // Use ValueListenableBuilder for update the CircularProgressIndicator
            leading: Consumer<InventoryProvider>(
              builder: (context, inventoryProvider, child) {
                final activeInventory = inventoryProvider.getActiveInventoryById(inventory.id);
                final progress = (activeInventory.isPaused && activeInventory.duration > 0)
                    ? null
                    : (activeInventory.elapsedTime / (activeInventory.duration * 60)).toDouble();

                // Verifica se o progress é um número válido entre 0 e 1
                if (progress != null && (progress.isNaN || progress.isInfinite || progress < 0 || progress > 1)) {
                  return const SizedBox.shrink(); // Ou qualquer outro widget que você queira exibir em caso de erro
                }

                return CircularProgressIndicator(
                  value: progress,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    activeInventory.isPaused ? Colors.amber : Theme.of(context).primaryColor,
                  ),
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
                      inventory.isPaused = !inventory.isPaused;
                      inventory.isPaused
                          ? inventory.resumeTimer()
                          : inventory.pauseTimer();
                      // inventoryProvider.updateInventory(inventory);
                      onInventoryPausedOrResumed?.call(inventory);
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