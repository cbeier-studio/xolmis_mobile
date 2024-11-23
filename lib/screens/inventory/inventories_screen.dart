import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/inventory.dart';
import '../../data/database/repositories/inventory_repository.dart';
import '../../data/database/repositories/species_repository.dart';
import '../../data/database/repositories/poi_repository.dart';
import '../../data/database/repositories/vegetation_repository.dart';
import '../../data/database/repositories/weather_repository.dart';

import '../../providers/inventory_provider.dart';
import '../../providers/species_provider.dart';

import 'add_inventory_screen.dart';
import 'inventory_detail_screen.dart';

import '../utils.dart';
import '../export_utils.dart';


class InventoriesScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const InventoriesScreen({
    super.key,
    required this.scaffoldKey,
  });

  @override
  State<InventoriesScreen> createState() => _InventoriesScreenState();
}

class _InventoriesScreenState extends State<InventoriesScreen> {
  late InventoryProvider inventoryProvider;
  late InventoryRepository inventoryRepository;
  late SpeciesRepository speciesRepository;
  late PoiRepository poiRepository;
  late VegetationRepository vegetationRepository;
  late WeatherRepository weatherRepository;
  // bool _inventoriesLoaded = false;
  final _searchController = TextEditingController();
  bool _showActive = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    inventoryProvider = context.read<InventoryProvider>();
    inventoryRepository = context.read<InventoryRepository>();
    speciesRepository = context.read<SpeciesRepository>();
    poiRepository = context.read<PoiRepository>();
    vegetationRepository = context.read<VegetationRepository>();
    weatherRepository = context.read<WeatherRepository>();
    // Load the inventories
    // if (!_inventoriesLoaded) {
    //   Provider.of<InventoryProvider>(context, listen: false).fetchInventories();
    //   _inventoriesLoaded = true;
    // }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      Future.delayed(Duration.zero, ()
      {
        for (var inventory in inventoryProvider.activeInventories) {
          if (inventory.duration != 0 && !inventory.isPaused) {
            inventory.startTimer(inventoryRepository);
          }
        }
      });
    });
    onInventoryStopped = (inventoryId) {
      inventoryProvider.fetchInventories();
    };
  }

  @override
  void dispose() {
    onInventoryStopped = null;
    super.dispose();
  }

  void _onInventoryPausedOrResumed(Inventory inventory) {
    inventoryProvider.updateInventory(inventory);
  }

  void onInventoryUpdated(Inventory inventory) {
    inventoryProvider.updateInventory(inventory);
  }

  List<Inventory> _filterInventories(List<Inventory> inventories) {
    if (_searchQuery.isEmpty) {
      return inventories;
    }
    return inventories.where((inventory) =>
        inventory.id.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
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
          inventoryProvider.notifyListeners();
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddInventoryScreen()),
      ).then((newInventory) {
        // Reload the inventory list
        if (newInventory != null) {
          inventoryProvider.notifyListeners();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventários'),
        leading: MediaQuery.sizeOf(context).width < 600 ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_outlined),
            onPressed: () {
              widget.scaffoldKey.currentState?.openDrawer();
            },
          ),
        ) : SizedBox.shrink(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Procurar inventários...',
              // backgroundColor: Theme.of(context).brightness == Brightness.light
              //     ? WidgetStateProperty.all<Color>(Colors.deepPurple[50]!)
              //     : WidgetStateProperty.all<Color>(Colors.grey[800]!),
              leading: const Icon(Icons.search_outlined),
              trailing: [
                _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_outlined),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
                    : SizedBox.shrink(),
              ],
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final screenWidth = constraints.maxWidth;
                final buttonWidth = screenWidth < 600 ? screenWidth : 400.0;

                return SizedBox(
                  width: buttonWidth,
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('Ativos')),
                      ButtonSegment(value: false, label: Text('Encerrados')),
                    ],
                    selected: {_showActive},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _showActive = newSelection.first;
                      });
                      inventoryProvider.notifyListeners();
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
    child: RefreshIndicator(
            onRefresh: () async {
              await inventoryProvider.fetchInventories();
            },
            child: Consumer<InventoryProvider>(
                builder: (context, inventoryProvider, child) {
                  if (inventoryProvider.isLoading) {
                    return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator()
                      ),
                    );
                  } else if (_showActive && inventoryProvider.activeInventories.isEmpty ||
                      !_showActive && inventoryProvider.finishedInventories.isEmpty) {
                    return const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Nenhum inventário encontrado.')
                      ),
                    );
                  } else {
                    final filteredInventories = _filterInventories(_showActive
                        ? inventoryProvider.activeInventories
                        : inventoryProvider.finishedInventories);
                    return LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          final screenWidth = constraints.maxWidth;
                          final isLargeScreen = screenWidth > 600;

                          if (isLargeScreen) {
                            return Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 840),
                                  child: GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 3.5,
                                    ),
                                  shrinkWrap: true,
                                  itemCount: filteredInventories.length,
                                  itemBuilder: (context, index) {
                                    final inventory = filteredInventories[index];
                                    return GridTile(
                                      child: InkWell(
                                          onLongPress: () => _showBottomSheet(context, inventory),
                                          onTap: () {
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
                                              if (result == true) {
                                                inventoryProvider.notifyListeners();
                                              }
                                            });
                                          },
                                          child: Card.filled(
                                    child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.fromLTRB(0.0, 16.0, 16.0, 16.0),
                                                  child: ValueListenableBuilder<double>(
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
                                                        backgroundColor: _showActive && inventory.duration > 0 ? Theme.of(context).brightness == Brightness.light
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
                                                ),
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      inventory.id,
                                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                                    ),
                                                    Text('${inventoryTypeFriendlyNames[inventory.type]}'),
                                                    if (_showActive && inventory.duration > 0) Text('${inventory.duration} minutos de duração'),
                                                    Selector<SpeciesProvider, int>(
                                                      selector: (context, speciesProvider) => speciesProvider.getSpeciesForInventory(inventory.id).length,
                                                      shouldRebuild: (previous, next) => previous != next,
                                                      builder: (context, speciesCount, child) {
                                                        return Text('$speciesCount espécies');
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                Visibility(
                                                  visible: _showActive && inventory.duration > 0,
                                                  child: IconButton(
                                                    icon: Icon(inventory.isPaused ? Theme.of(context).brightness == Brightness.light
                                                        ? Icons.play_arrow_outlined
                                                        : Icons.play_arrow : Theme.of(context).brightness == Brightness.light
                                                        ? Icons.pause_outlined
                                                        : Icons.pause),
                                                    tooltip: inventory.isPaused ? 'Retomar' : 'Pausa',
                                                    onPressed: () {
                                                      if (inventory.isPaused) {
                                                        inventoryProvider.resumeInventoryTimer(inventory, inventoryRepository);
                                                      } else {
                                                        inventoryProvider.pauseInventoryTimer(inventory, inventoryRepository);
                                                      }
                                                      inventoryProvider.updateInventory(inventory);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ),
                                        ),
                                    );
                                  },
                                ),
                                ),
                            );
                          } else {
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredInventories.length,
                              itemBuilder: (context, index) {
                                final inventory = filteredInventories[index];
                                return Dismissible(
                                    key: ValueKey(inventory.id),
                                    direction: DismissDirection.horizontal,
                                    background: _showActive ? Container(
                                      color: Colors.green,
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 20.0),
                                      child: const Icon(Icons.flag_outlined, color: Colors.white),
                                    ) : Container(color: Colors.transparent),
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
                                      } else if (_showActive && direction == DismissDirection.startToEnd) {
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
                                      } else if (_showActive && direction == DismissDirection.startToEnd) {
                                        // Finish the inventory
                                        inventory.stopTimer(inventoryRepository);
                                        inventoryProvider.updateInventory(inventory);
                                        inventoryProvider.notifyListeners();
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
                                              if (result == true) {
                                                inventoryProvider.notifyListeners();
                                              }
                                            });
                                          },
                                          onInventoryPausedOrResumed: (inventory) => _onInventoryPausedOrResumed(inventory),
                                          isHistory: !_showActive,
                                        )
                                    )
                                );
                              },
                            );
                          }
                        }
                    );
                  }
                }
            ),
          )
          )
        ],
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
                  _showActive ? ListTile(
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
                                  inventory.stopTimer(inventoryRepository);
                                  inventoryProvider.updateInventory(inventory);
                                  inventoryProvider.notifyListeners();
                                },
                                child: const Text('Encerrar'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ) : const SizedBox.shrink(),
                  !_showActive ? ExpansionTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text('Exportar inventário'),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.table_chart_outlined),
                          title: const Text('CSV'),
                          onTap: () {
                            Navigator.of(context).pop();
                            exportInventoryToCsv(context, inventory);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.code_outlined),
                          title: const Text('JSON'),
                          onTap: () {
                            Navigator.of(context).pop();
                            exportInventoryToJson(context, inventory);
                          },
                        ),
                      ]
                  ) : const SizedBox.shrink(),
                  !_showActive ? ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('Exportar todos os inventários'),
                    onTap: () {
                      Navigator.of(context).pop();
                      exportAllInventoriesToJson(context, inventoryProvider);
                    },
                  ) : const SizedBox.shrink(),
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
                                  inventoryProvider.removeInventory(inventory.id);
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
  final bool isHistory;

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
    required this.isHistory,
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
                  backgroundColor: !isHistory && inventory.duration > 0 ? Theme.of(context).brightness == Brightness.light
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
                if (!isHistory && inventory.duration > 0) Text('${inventory.duration} ${Intl.plural(inventory.duration, one: 'minuto', other: 'minutos')} de duração'),
                Selector<SpeciesProvider, int>(
                  selector: (context, speciesProvider) => speciesProvider.getSpeciesForInventory(inventory.id).length,
                  shouldRebuild: (previous, next) => previous != next,
                  builder: (context, speciesCount, child) {
                    return Text('$speciesCount ${Intl.plural(speciesCount, one: 'espécie', other: 'espécies')}');
                  },
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Visibility(
                  visible: !isHistory && inventory.duration > 0,
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