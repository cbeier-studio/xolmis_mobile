import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/inventory.dart';
import '../../data/database/repositories/inventory_repository.dart';
import '../../data/database/repositories/species_repository.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/species_provider.dart';

import '../utils.dart';
import '../species_search_delegate.dart';
import 'species_list_item.dart';

class SpeciesTab extends StatefulWidget {
  final Inventory inventory;
  final GlobalKey<AnimatedListState> speciesListKey;
  final SpeciesRepository speciesRepository;
  final InventoryRepository inventoryRepository;

  const SpeciesTab({
    super.key,
    required this.inventory,
    required this.speciesListKey,
    required this.speciesRepository,
    required this.inventoryRepository
  });

  @override
  State<SpeciesTab> createState() => _SpeciesTabState();
}

class _SpeciesTabState extends State<SpeciesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildSpeciesList(widget.speciesRepository, widget.inventoryRepository);
  }

  void _addSpeciesToInventory(String speciesName, SpeciesRepository speciesRepository, InventoryRepository inventoryRepository) async {
    final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);

    if (speciesProvider.speciesExistsInInventory(widget.inventory.id, speciesName)) {
      _showSpeciesAlreadyExistsMessage();
      return;
    }

    final newSpecies = Species(
      inventoryId: widget.inventory.id,
      name: speciesName,
      isOutOfInventory: widget.inventory.isFinished,
      pois: [],
    );

    await speciesRepository.insertSpecies(widget.inventory.id, newSpecies);
    await inventoryRepository.updateInventory(widget.inventory);

    setState(() {
      _insertSpeciesListItem(newSpecies);
      checkMackinnonCompletion(context, widget.inventory, inventoryRepository);
    });

    if (!widget.inventory.isFinished && widget.inventory.type != InventoryType.invBanding) {
      _addSpeciesToOtherActiveInventories(speciesName, speciesProvider, inventoryProvider, speciesRepository, inventoryRepository);
    }

    // if (!widget.inventory.isFinished && widget.inventory.type == InventoryType.invCumulativeTime) {
    //   _restartInventoryTimer(inventoryProvider);
    // }

    _updateSpeciesList();

    inventoryProvider.notifyListeners();
  }

  void _showSpeciesAlreadyExistsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Espécie já adicionada à lista.'),
          ],
        ),
      ),
    );
  }

  void _insertSpeciesListItem(Species species) {
    final speciesList = Provider.of<SpeciesProvider>(context, listen: false).getSpeciesForInventory(widget.inventory.id);
    if (speciesList.isNotEmpty) {
      widget.speciesListKey.currentState?.insertItem(speciesList.length - 1, duration: const Duration(milliseconds: 300));
    }
    // final animatedListState = widget.speciesListKey.currentState;
    // if (animatedListState != null) {
    //   animatedListState.insertItem(speciesList.length - 1);
    // }
  }

  void _addSpeciesToOtherActiveInventories(String speciesName, SpeciesProvider speciesProvider, InventoryProvider inventoryProvider, SpeciesRepository speciesRepository, InventoryRepository inventoryRepository) {
    for (final inventory in inventoryProvider.activeInventories) {
      if (inventory.id != widget.inventory.id && !speciesProvider.speciesExistsInInventory(inventory.id, speciesName)) {
        final newSpeciesForOtherInventory = Species(
          inventoryId: inventory.id,
          name: speciesName,
          isOutOfInventory: inventory.isFinished,
          pois: [],
        );
        speciesRepository.insertSpecies(newSpeciesForOtherInventory.inventoryId, newSpeciesForOtherInventory);
      }
      if (inventory.type == InventoryType.invCumulativeTime) {
        _restartInventoryTimer(inventoryProvider, inventory, inventoryRepository);
      } else {
        inventoryProvider.updateInventory(inventory);
      }
    }
  }

  void _restartInventoryTimer(InventoryProvider inventoryProvider, Inventory inventory, InventoryRepository inventoryRepository) async {
    inventory.elapsedTime = 0;
    inventory.isPaused = false;
    inventory.isFinished = false;
    Inventory.startTimer(inventory, inventoryRepository);
    await inventoryRepository.updateInventory(inventory);
    // await inventoryProvider.updateInventoryElapsedTime(widget.inventory.id, widget.inventory.elapsedTime);

  }

  void _updateSpeciesList() async {
    final speciesProvider = Provider.of<SpeciesProvider>(
        context, listen: false);
    speciesProvider.loadSpeciesForInventory(widget.inventory.id);
  }

  // void _sortSpeciesList() {
  //   // widget.inventory.speciesList.sort((a, b) => a.name.compareTo(b.name));
  //   final speciesProvider = Provider.of<SpeciesProvider>(
  //       context, listen: false);
  //   speciesProvider.sortSpeciesForInventory(widget.inventory.id);
  // }

  void _showSpeciesSearch(SpeciesRepository speciesRepository, InventoryRepository inventoryRepository) async {
    final allSpecies = await loadSpeciesSearchData();
    allSpecies.sort((a, b) => a.compareTo(b));
    final selectedSpecies = await showSearch(
      context: context,
      delegate: SpeciesSearchDelegate(
          allSpecies, (speciesName) => _addSpeciesToInventory(speciesName, speciesRepository, inventoryRepository), _updateSpeciesList),
    );

    if (selectedSpecies != null) {
      _updateSpeciesList();
    }
  }

  Widget _buildSpeciesList(SpeciesRepository speciesRepository, InventoryRepository inventoryRepository) {
    final speciesList = Provider.of<SpeciesProvider>(context, listen: false).getSpeciesForInventory(
        widget.inventory.id);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar espécie...',
              prefixIcon: Icon(Icons.search_outlined),
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            onTap: () async {
              _showSpeciesSearch(speciesRepository, inventoryRepository);
            },
          ),
        ),
        Expanded(
          child: Selector<SpeciesProvider, List<Species>>(
            selector: (context, speciesProvider) => speciesProvider.getSpeciesForInventory(widget.inventory.id),
            builder: (context, speciesProvider, child) {
              if (speciesList.isEmpty) {
                return const Center(
                  child: Text('Nenhuma espécie registrada.'),
                );
              } else {
                return AnimatedList(
                  key: widget.speciesListKey,
                  initialItemCount: speciesList.length,
                  itemBuilder: (context, index, animation) {
                    // print('speciesList: ${speciesList.length} ; AnimatedList: $index');
                    if (index >= speciesList.length) {
                      return const SizedBox.shrink();
                    }
                    final species = speciesList[index];
                    return Dismissible(
                      key: Key(species.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16.0),
                        child: const Icon(Icons.delete_outlined, color: Colors.white),
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
                        Provider.of<SpeciesProvider>(context, listen: false).removeSpecies(context, widget.inventory.id, species.id!);
                        widget.speciesListKey.currentState?.removeItem(
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
              }
            },
          ),
        ),
      ],
    );
  }
}