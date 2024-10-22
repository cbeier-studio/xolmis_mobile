import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory.dart';
import '../data/database_helper.dart';
import 'add_vegetation_screen.dart';
import '../providers/species_provider.dart';
import '../providers/poi_provider.dart';
import '../providers/vegetation_provider.dart';
import 'species_list_item.dart';
import 'vegetation_list_item.dart';
import 'species_search_delegate.dart';
import 'inventory_detail_helpers.dart';

class InventoryDetailScreen extends StatefulWidget {
  final Inventory inventory;

  const InventoryDetailScreen({
    super.key,
    required this.inventory,
  });

  @override
  InventoryDetailScreenState createState() => InventoryDetailScreenState();
}

class InventoryDetailScreenState extends State<InventoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<AnimatedListState> _speciesListKey = GlobalKey<
      AnimatedListState>();
  final GlobalKey<AnimatedListState> _vegetationListKey = GlobalKey<
      AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Access the providers
    final speciesProvider = Provider.of<SpeciesProvider>(
        context, listen: true);
    final poiProvider = Provider.of<PoiProvider>(context, listen: false);
    final vegetationProvider = Provider.of<VegetationProvider>(
        context, listen: false);
    vegetationProvider.vegetationListKey = _vegetationListKey;

    // Load the species for the current inventory
    speciesProvider.loadSpeciesForInventory(widget.inventory.id);
    // Load the vegetation for the current inventory
    vegetationProvider.loadVegetationForInventory(widget.inventory.id);

    // Load the POIs for each species of the inventory
    for (var species in widget.inventory.speciesList) {
      poiProvider.loadPoisForSpecies(species.id ?? 0);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addSpeciesToInventory(String speciesName) async {
    // Check if species already exists in current inventory
    bool speciesExistsInCurrentInventory = widget.inventory.speciesList.any((
        species) => species.name == speciesName);

    if (!speciesExistsInCurrentInventory) {
      // Add the species to the current inventory
      final newSpecies = Species(
        inventoryId: widget.inventory.id,
        name: speciesName,
        isOutOfInventory: widget.inventory.isFinished,
        pois: [],
      );
      final inventoryProvider = Provider.of<InventoryProvider>(
          context, listen: false);
      final activeInventories = inventoryProvider.activeInventories;
      final speciesProvider = Provider.of<SpeciesProvider>(
          context, listen: false);
      speciesProvider.addSpecies(widget.inventory.id, newSpecies);
      await Future.microtask(() {}); // Wait the next microtask

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final speciesList = speciesProvider.getSpeciesForInventory(widget.inventory.id);
        _speciesListKey.currentState?.insertItem(speciesList.length -1, duration: const Duration(milliseconds: 300));
      });

      // If not finished, add species to other active inventories
      if (!widget.inventory.isFinished) {
        for (final inventory in activeInventories) {
          // Check if the inventory is different from the current and if species exists in it
          if (inventory.id != widget.inventory.id &&
              !inventory.speciesList.any((species) =>
              species.name == speciesName)) {
            final newSpeciesForOtherInventory = Species(
              inventoryId: inventory.id,
              name: speciesName,
              isOutOfInventory: inventory.isFinished,
              pois: [],
            );

            // Update the species list of the active inventory
            speciesProvider.addSpecies(newSpeciesForOtherInventory.inventoryId,
                newSpeciesForOtherInventory);

            inventoryProvider.updateInventory(inventory);
          }
        }
      }

      // Check if Mackinnon list reached the maximum number of species per list
      checkMackinnonCompletion(context, widget.inventory);

      // Restart the timer if the inventory is of type invCumulativeTime
      if (widget.inventory.type == InventoryType.invCumulativeTime) {
        widget.inventory.elapsedTime = 0;
        widget.inventory.isPaused = false;
        widget.inventory.isFinished = false;
        await DatabaseHelper().updateInventoryElapsedTime(
            widget.inventory.id, widget.inventory.elapsedTime);
        widget.inventory.startTimer();
      }

      inventoryProvider.notifyListeners();
    } else {
      // Show message informing that species already exists
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Espécie já adicionada à lista.'),
              ],
            ),
        ),
      );
    }
  }

  void _updateSpeciesList() async {
    final speciesProvider = Provider.of<SpeciesProvider>(
        context, listen: false);
    speciesProvider.loadSpeciesForInventory(widget.inventory.id);
  }

  void _sortSpeciesList() {
    // widget.inventory.speciesList.sort((a, b) => a.name.compareTo(b.name));
    final speciesProvider = Provider.of<SpeciesProvider>(
        context, listen: false);
    speciesProvider.sortSpeciesForInventory(widget.inventory.id);
  }

  void _showSpeciesSearch() async {
    final allSpecies = await loadSpeciesData();
    final selectedSpecies = await showSearch(
      context: context,
      delegate: SpeciesSearchDelegate(
          allSpecies, _addSpeciesToInventory, _updateSpeciesList),
    );

    if (selectedSpecies != null) {
      _updateSpeciesList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final speciesProvider = Provider.of<SpeciesProvider>(
        context, listen: false);
    final speciesList = speciesProvider.getSpeciesForInventory(
        widget.inventory.id!);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inventory.id),
        actions: [
          !widget.inventory.isFinished && widget.inventory.duration > 0
              ? Consumer<InventoryProvider>(
            builder: (context, inventoryProvider, child) {
              final inventory = widget.inventory;
              return IconButton(
                icon: Icon(inventory.isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: () {
                  if (inventory.isPaused) {
                    inventoryProvider.resumeInventoryTimer(inventory);
                  } else {
                    inventoryProvider.pauseInventoryTimer(inventory);
                  }
                  Provider.of<InventoryProvider>(context, listen: false)
                      .updateInventory(inventory);
                },
              );
            },
          ) : const SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.grass),
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddVegetationDataScreen(
                        inventory: widget.inventory,
                      ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Consumer<SpeciesProvider>(
              builder: (context, speciesProvider, child) {
                final speciesList = speciesProvider.getSpeciesForInventory(
                    widget.inventory.id);
                return speciesList.isNotEmpty
                    ? Badge.count(
                  backgroundColor: Colors.deepPurple,
                  alignment: AlignmentDirectional.centerEnd,
                  offset: const Offset(24, -8),
                  count: speciesList.length,
                  child: const Tab(text: 'Espécies'),
                )
                    : const Tab(text: 'Espécies');
              },
            ),
            Consumer<VegetationProvider>(
              builder: (context, vegetationProvider, child) {
                final vegetationList = vegetationProvider
                    .getVegetationForInventory(widget.inventory.id);
                return vegetationList.isNotEmpty
                    ? Badge.count(
                  backgroundColor: Colors.deepPurple,
                  alignment: AlignmentDirectional.centerEnd,
                  offset: const Offset(24, -8),
                  count: vegetationList.length,
                  child: const Tab(text: 'Vegetação'),
                )
                    : const Tab(text: 'Vegetação');
              },
            ),
          ],
        ),
        flexibleSpace: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: widget.inventory.duration > 0 && !widget.inventory.isFinished
              ? ValueListenableBuilder<double>(
            valueListenable: widget.inventory.elapsedTimeNotifier,
            builder: (context, elapsedTime, child) {
              return LinearProgressIndicator(
                value: widget.inventory.isPaused
                    ? null
                    : elapsedTime / (widget.inventory.duration * 60),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.inventory.isPaused
                      ? Colors.amber
                      : Colors.deepPurple,
                ),
              );
            },
          )
              : const SizedBox.shrink(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSpeciesList(),
          _buildVegetationList(),
        ],
      ),
      floatingActionButton: !widget.inventory.isFinished ? FloatingActionButton(
        onPressed: () async {
          // Finishing the inventory
          await widget.inventory.stopTimer();
          // widget.onInventoryUpdated(widget.inventory);
          Navigator.pop(context, true);
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.flag, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildSpeciesList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar espécie...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            onTap: () async {
              _showSpeciesSearch();
            },
          ),
        ),
        Expanded(
          child: Consumer<SpeciesProvider>(
            builder: (context, speciesProvider, child) {
              final speciesList = speciesProvider.getSpeciesForInventory(
                  widget.inventory.id);
              return AnimatedList(
                key: _speciesListKey,
                initialItemCount: speciesList.length,
                itemBuilder: (context, index, animation) {
                  if (index >= speciesList.length) {
                    return const SizedBox.shrink();
                  }
                  final species = speciesList[index];
                  return Dismissible(
                    key: Key(species.id.toString()),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar exclusão'),
                            content: const Text(
                                'Tem certeza que deseja excluir esta espécie?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Excluir'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) {
                      final indexToRemove = speciesList.indexOf(species);
                      speciesProvider.removeSpecies(widget.inventory.id, species.id!);
                      _speciesListKey.currentState?.removeItem(
                        indexToRemove,
                            (context, animation) => SpeciesListItem(
                          species: species,
                          animation: animation,
                        ),
                      );
                      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
                      inventoryProvider.updateInventory(widget.inventory);
                    },
                    child: SpeciesListItem(
                      species: species,
                      animation: animation,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVegetationList() {
    return Consumer<VegetationProvider>(
      builder: (context, vegetationProvider, child) {
        final vegetationList = vegetationProvider.getVegetationForInventory(
            widget.inventory.id);
        return AnimatedList(
          key: _vegetationListKey,
          initialItemCount: vegetationList.length,
          itemBuilder: (context, index, animation) {
            final vegetation = vegetationList[index];
            return Dismissible(
              key: ValueKey(vegetation),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirmar exclusão'),
                      content: const Text(
                          'Tem certeza que deseja excluir esta vegetação?'),
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
              },
              onDismissed: (direction) {
                final indexToRemove = vegetationList.indexOf(
                    vegetation); // Obter o índice antes da remoção
                vegetationProvider.removeVegetation(
                    widget.inventory.id, vegetation.id!).then((_) {
                  // Remover o item do AnimatedList após a atualização do Provider
                  _vegetationListKey.currentState?.removeItem(
                    indexToRemove,
                        (context, animation) =>
                        VegetationListItem(
                          vegetation: vegetation,
                          animation: animation,
                        ),
                  );
                });
              },
              child: VegetationListItem(
                vegetation: vegetation,
                animation: animation,
              ),
            );
          },
        );
      },
    );
  }
}