import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/inventory.dart';
import '../providers/inventory_provider.dart';
import '../providers/species_provider.dart';

import 'history_screen.dart';
import 'add_inventory_screen.dart';
import 'inventory_detail_screen.dart';
import 'settings_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
    // Load the inventories
    Provider.of<InventoryProvider>(context, listen: false).loadInventories();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      Future.delayed(Duration.zero, ()
      {
        for (var inventory in inventoryProvider.activeInventories) {
          if (inventory.duration != 0 && !inventory.isPaused) {
            inventory.startTimer();
          }
        }
      });
      inventoryProvider.inventoryListKey = _listKey;
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
      appBar: AppBar(
        title: const Text('Inventários ativos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Inventários encerrados',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await inventoryProvider.loadInventories();
        },
        child: inventoryProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Consumer<InventoryProvider>(
          builder: (context, inventoryProvider, child) {
            return inventoryProvider.activeInventories.isEmpty
                ? const Center(child: Text('Nenhum inventário ativo.'))
                : AnimatedList(
              key: _listKey,
              initialItemCount: inventoryProvider.activeInventories.length,
              itemBuilder: (context, index, animation) {
                final inventory = inventoryProvider.activeInventories[index];
                return Dismissible(
                    key: ValueKey(inventory.id),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      color: Colors.green,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20.0),
                      child: const Icon(Icons.flag, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      // Drag to left
                      if (direction == DismissDirection.endToStart) {
                        // Show confirmation dialog for deleting
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirmar exclusão'),
                              content: const Text('Tem certeza que deseja excluir este inventário?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Excluir'),
                                ),
                              ],
                            );
                          },
                        );
                        // Drag to right
                      } else if (direction == DismissDirection.startToEnd) {
                        // Show confirmation dialog for finishing
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirmar Encerramento'),
                              content: const Text('Tem certeza que deseja encerrar este inventário?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text('Encerrar'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                      return false; // Default to not dismissing
                    },
                    onDismissed: (direction) {
                      // Drag to left
                      if (direction == DismissDirection.endToStart) {
                        // Remove the inventory from list
                        final indexToRemove = inventoryProvider.activeInventories.indexOf(inventory);
                        inventoryProvider.removeInventory(inventory.id);
                        _listKey.currentState?.removeItem(
                          indexToRemove,
                              (context, animation) => InventoryListItem(
                            inventory: inventory,
                            animation: animation,
                          ),
                        );
                        // Drag to right
                      } else if (direction == DismissDirection.startToEnd) {
                        // Finish the inventory
                        inventory.stopTimer();
                        inventoryProvider.updateInventory(inventory);
                        inventoryProvider.loadInventories();
                      }
                    },
                    child: ValueListenableBuilder<bool>(
                        valueListenable: inventory.isFinishedNotifier,
                        builder: (context, isFinished, child) {
                          if (isFinished) {
                            inventoryProvider.loadInventories();
                          }
                          return child!;
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
                    )
                );
              },
            );
          },
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   tooltip: 'Novo inventário',
      //   onPressed: () {
      //     showDialog(
      //       context: context,
      //       builder: (context) {
      //         const dialogContent = AddInventoryScreen();
      //         final showFullScreenDialog = MediaQuery.sizeOf(context).width < 600;
      //         if (showFullScreenDialog) {
      //           return const Dialog.fullscreen(
      //             child: dialogContent,
      //           );
      //         } else {
      //           return Dialog(
      //             child: ConstrainedBox(
      //               constraints: BoxConstraints(maxWidth: 400),
      //               child: dialogContent,
      //             )
      //           );
      //         }
      //       },
      //     ).then((newInventory) {
      //       // Reload the inventory list
      //       if (newInventory != null) {
      //         inventoryProvider.loadInventories();
      //       }
      //     });
      //   },
      //   child: const Icon(Icons.add),
      // ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo inventário',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddInventoryScreen()),
          ).then((newInventory) {
            // Reload the inventory list
            if (newInventory != null) {
              inventoryProvider.loadInventories();
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
            leading: ValueListenableBuilder<double>(
              valueListenable: inventory.elapsedTimeNotifier,
              builder: (context, elapsedTime, child) {
                if (inventory == null) {
                  return const Icon(Icons.error);
                }

                var progress = (inventory.isPaused || inventory.duration < 0)
                    ? null
                    : (elapsedTime / (inventory.duration * 60)).toDouble();

                if (progress != null && (progress.isNaN || progress.isInfinite || progress < 0 || progress > 1)) {
                  progress = 0;
                }

                return CircularProgressIndicator(
                  value: progress,
                  backgroundColor: inventory.duration > 0 ? Colors.grey[200] : null,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    inventory.isPaused ? Colors.amber : Theme.of(context).primaryColor,
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
                Selector<SpeciesProvider, List<Species>>(
                  selector: (context, speciesProvider) => speciesProvider.getSpeciesForInventory(inventory.id),
                  builder: (context, speciesList, child) {
                    return Text('${speciesList.length} espécies');
                  },
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Visibility(
                  visible: inventory.duration > 0,
                  child: IconButton(
                    icon: Icon(inventory.isPaused ? Icons.play_arrow : Icons.pause),
                    tooltip: inventory.isPaused ? 'Retomar' : 'Pausa',
                    onPressed: () {
                      if (inventory.isPaused) {
                        Provider.of<InventoryProvider>(context, listen: false).resumeInventoryTimer(inventory);
                      } else {
                        Provider.of<InventoryProvider>(context, listen: false).pauseInventoryTimer(inventory);
                      }
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