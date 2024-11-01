import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/inventory.dart';
import '../../data/database/repositories/inventory_repository.dart';
import '../../data/database/repositories/species_repository.dart';
import '../../data/database/repositories/poi_repository.dart';
import '../../data/database/repositories/vegetation_repository.dart';
import '../../data/database/repositories/weather_repository.dart';

import '../../providers/inventory_provider.dart';
import '../../providers/species_provider.dart';

import 'inventory_history_screen.dart';
import 'add_inventory_screen.dart';
import 'inventory_detail_screen.dart';

import '../settings_screen.dart';


class InventoriesScreen extends StatefulWidget {

  const InventoriesScreen({
    super.key,
  });

  @override
  State<InventoriesScreen> createState() => _InventoriesScreenState();
}

class _InventoriesScreenState extends State<InventoriesScreen> {
  late InventoryRepository inventoryRepository;
  // bool _inventoriesLoaded = false;

  @override
  void initState() {
    super.initState();
    inventoryRepository = Provider.of<InventoryRepository>(context, listen: false);
    // Load the inventories
    // if (!_inventoriesLoaded) {
    //   Provider.of<InventoryProvider>(context, listen: false).fetchInventories();
    //   _inventoriesLoaded = true;
    // }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      Future.delayed(Duration.zero, ()
      {
        for (var inventory in inventoryProvider.activeInventories) {
          if (inventory.duration != 0 && !inventory.isPaused) {
            Inventory.startTimer(inventory, inventoryRepository);
          }
        }
      });
    });
  }

  void _onInventoryPausedOrResumed(Inventory inventory) {
    Provider.of<InventoryProvider>(context, listen: false).updateInventory(inventory);
  }

  void onInventoryUpdated(Inventory inventory) {
    Provider.of<InventoryProvider>(context, listen: false).updateInventory(inventory);
  }

  void _showAddInventoryScreen(BuildContext context) {
    if (MediaQuery.sizeOf(context).width > 600) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: const AddInventoryScreen(),
            ),
          );
        },
      ).then((newInventory) {
        // Reload the inventory list
        if (newInventory != null) {
          Provider.of<InventoryProvider>(context, listen: false).fetchInventories();
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddInventoryScreen()),
      ).then((newInventory) {
        // Reload the inventory list
        if (newInventory != null) {
          Provider.of<InventoryProvider>(context, listen: false).fetchInventories();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final inventoryRepository = Provider.of<InventoryRepository>(context, listen: false);
    final speciesRepository = Provider.of<SpeciesRepository>(context, listen: false);
    final poiRepository = Provider.of<PoiRepository>(context, listen: false);
    final vegetationRepository = Provider.of<VegetationRepository>(context, listen: false);
    final weatherRepository = Provider.of<WeatherRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventários ativos'),
        actions: [
          IconButton(
            icon: Theme.of(context).brightness == Brightness.light
                ? const Icon(Icons.history_outlined)
                : const Icon(Icons.history),
            tooltip: 'Inventários encerrados',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InventoryHistoryScreen(
                  inventoryRepository: inventoryRepository,
                  speciesRepository: speciesRepository,
                  poiRepository: poiRepository,
                  vegetationRepository: vegetationRepository,
                  weatherRepository: weatherRepository,
                )),
              );
            },
          ),
          IconButton(
            icon: Theme.of(context).brightness == Brightness.light
                ? const Icon(Icons.settings_outlined)
                : const Icon(Icons.settings),
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
          await inventoryProvider.fetchInventories();
        },
        child: Consumer<InventoryProvider>(
          builder: (context, inventoryProvider, child) {
            if (inventoryProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (inventoryProvider.activeInventories.isEmpty) {
              return const Center(child: Text('Nenhum inventário ativo.'));
            } else {
              return ListView.builder(
                itemCount: inventoryProvider.activeInventories.length,
                itemBuilder: (context, index) {
                final inventory = inventoryProvider.activeInventories[index];
                return Dismissible(
                    key: ValueKey(inventory.id),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      color: Colors.green,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20.0),
                      child: const Icon(Icons.flag_outlined, color: Colors.white),
                    ),
                    secondaryBackground: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      child: const Icon(Icons.delete_outlined, color: Colors.white),
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
                        inventoryProvider.removeInventory(inventory.id);

                        // Drag to right
                      } else if (direction == DismissDirection.startToEnd) {
                        // Finish the inventory
                        Inventory.stopTimer(inventory, inventoryRepository);
                        inventoryProvider.updateInventory(inventory);
                        inventoryProvider.fetchInventories();
                      }
                    },
                    child: ValueListenableBuilder<bool>(
                        valueListenable: inventory.isFinishedNotifier,
                        builder: (context, isFinished, child) {
                          if (isFinished) {
                            inventoryProvider.fetchInventories();
                          }
                          return child!;
                        },
                        child: InventoryListItem(
                          inventory: inventory,
                          speciesRepository: speciesRepository,
                          inventoryRepository: inventoryRepository,
                          poiRepository: poiRepository,
                          vegetationRepository: vegetationRepository,
                          weatherRepository: weatherRepository,
                          onLongPress: () => _showBottomSheet(context, inventory),
                          onTap: (inventory) {
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
                            ).then((result) {
                              // if (result == true) {
                                inventoryProvider.fetchInventories();
                              // }
                            });
                          },
                          onInventoryPausedOrResumed: (inventory) => _onInventoryPausedOrResumed(inventory),
                        )
                    )
                );
              },
            );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo inventário',
        onPressed: () {
          _showAddInventoryScreen(context);
        },
        child: const Icon(Icons.add_outlined),
      ),
    );
  }

  void _showBottomSheet(BuildContext context, Inventory inventory) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return BottomSheet(
          onClosing: () {},
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.flag_outlined),
                    title: const Text('Encerrar inventário'),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar Encerramento'),
                            content: const Text('Tem certeza que deseja encerrar este inventário?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                  Navigator.of(context).pop();
                                  // Call the function to delete species
                                  Inventory.stopTimer(inventory, inventoryRepository);
                                  Provider.of<InventoryProvider>(context, listen: false).updateInventory(inventory);
                                  Provider.of<InventoryProvider>(context, listen: false).fetchInventories();
                                },
                                child: const Text('Encerrar'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outlined, color: Colors.red,),
                    title: const Text('Apagar inventário', style: TextStyle(color: Colors.red),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar exclusão'),
                            content: const Text('Tem certeza que deseja excluir este inventário?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                  Navigator.of(context).pop();
                                  // Call the function to delete species
                                  Provider.of<InventoryProvider>(context, listen: false)
                                      .removeInventory(inventory.id);
                                },
                                child: const Text('Excluir'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class InventoryListItem extends StatelessWidget {
  final Inventory inventory;
  final InventoryRepository inventoryRepository;
  final SpeciesRepository speciesRepository;
  final PoiRepository poiRepository;
  final VegetationRepository vegetationRepository;
  final WeatherRepository weatherRepository;
  final VoidCallback onLongPress;
  final void Function(Inventory)? onTap;
  final void Function(Inventory)? onInventoryPausedOrResumed;

  const InventoryListItem({
    super.key,
    required this.inventory,
    required this.inventoryRepository,
    required this.speciesRepository,
    required this.poiRepository,
    required this.vegetationRepository,
    required this.weatherRepository,
    required this.onLongPress,
    this.onTap,
    this.onInventoryPausedOrResumed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell( // Or GestureDetector
        onLongPress: onLongPress,
        onTap: () {
          onTap?.call(inventory);
        },
        child: ListTile(
            // Use ValueListenableBuilder for update the CircularProgressIndicator
            leading: ValueListenableBuilder<double>(
              valueListenable: inventory.elapsedTimeNotifier,
              builder: (context, elapsedTime, child) {
                // if (inventory == null) {
                //   return const Icon(Icons.error_outlined);
                // }

                var progress = (inventory.isPaused || inventory.duration < 0)
                    ? null
                    : (elapsedTime / (inventory.duration * 60)).toDouble();

                if (progress != null && (progress.isNaN || progress.isInfinite || progress < 0 || progress > 1)) {
                  progress = 0;
                }

                return CircularProgressIndicator(
                  value: progress,
                  backgroundColor: inventory.duration > 0 ? Theme.of(context).brightness == Brightness.light
                      ? Colors.grey[200]
                      : Colors.grey[800] : null,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    inventory.isPaused ? Colors.amber : Theme.of(context).brightness == Brightness.light
                        ? Colors.deepPurple
                        : Colors.deepPurpleAccent,
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
                Selector<SpeciesProvider, int>(
                  selector: (context, speciesProvider) => speciesProvider.getSpeciesForInventory(inventory.id).length,
                  shouldRebuild: (previous, next) => previous != next,
                  builder: (context, speciesCount, child) {
                    return Text('$speciesCount espécies');
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
                    icon: Icon(inventory.isPaused ? Theme.of(context).brightness == Brightness.light
                        ? Icons.play_arrow_outlined
                        : Icons.play_arrow : Theme.of(context).brightness == Brightness.light
                        ? Icons.pause_outlined
                        : Icons.pause),
                    tooltip: inventory.isPaused ? 'Retomar' : 'Pausa',
                    onPressed: () {
                      if (inventory.isPaused) {
                        Provider.of<InventoryProvider>(context, listen: false).resumeInventoryTimer(inventory, inventoryRepository);
                      } else {
                        Provider.of<InventoryProvider>(context, listen: false).pauseInventoryTimer(inventory, inventoryRepository);
                      }
                      onInventoryPausedOrResumed?.call(inventory);
                    },
                  ),
                ),
              ],
            ),
          ),

    );
  }
}