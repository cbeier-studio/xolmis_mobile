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
  final SpeciesRepository speciesRepository;
  final InventoryRepository inventoryRepository;

  const SpeciesTab({
    super.key,
    required this.inventory,
    required this.speciesRepository,
    required this.inventoryRepository
  });

  @override
  State<SpeciesTab> createState() => _SpeciesTabState();
}

class _SpeciesTabState extends State<SpeciesTab> with AutomaticKeepAliveClientMixin {
  final _notesController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildSpeciesList(
        widget.speciesRepository, widget.inventoryRepository);
  }

  Future<void> _addSpeciesToInventory(String speciesName,
      SpeciesRepository speciesRepository,
      InventoryRepository inventoryRepository) async {
    final speciesProvider = Provider.of<SpeciesProvider>(
        context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(
        context, listen: false);

    if (speciesProvider.speciesExistsInInventory(
        widget.inventory.id, speciesName)) {
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
      checkMackinnonCompletion(context, widget.inventory, inventoryRepository);
    });

    if (!widget.inventory.isFinished) {
      _addSpeciesToOtherActiveInventories(
          speciesName, speciesProvider, inventoryProvider, speciesRepository,
          inventoryRepository);
    }

    // if (!widget.inventory.isFinished && widget.inventory.type == InventoryType.invCumulativeTime) {
    //   _restartInventoryTimer(inventoryProvider);
    // }

    _updateSpeciesList();

    speciesProvider.notifyListeners();
    // inventoryProvider.notifyListeners();
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

  Future<void> _addSpeciesToOtherActiveInventories(String speciesName,
      SpeciesProvider speciesProvider, InventoryProvider inventoryProvider,
      SpeciesRepository speciesRepository,
      InventoryRepository inventoryRepository) async {
    for (final inventory in inventoryProvider.activeInventories) {
      if (inventory.id != widget.inventory.id &&
          !speciesProvider.speciesExistsInInventory(
              inventory.id, speciesName) &&
          widget.inventory.type != InventoryType.invBanding) {
        final newSpeciesForOtherInventory = Species(
          inventoryId: inventory.id,
          name: speciesName,
          isOutOfInventory: inventory.isFinished,
          pois: [],
        );
        await speciesRepository.insertSpecies(
            newSpeciesForOtherInventory.inventoryId,
            newSpeciesForOtherInventory);
      }
      if (inventory.type == InventoryType.invTimedQualitative) {
        _restartInventoryTimer(inventoryProvider, inventory, inventoryRepository);
      } else {
        inventoryProvider.updateInventory(inventory);
      }
      speciesProvider.loadSpeciesForInventory(inventory.id);
      speciesProvider.notifyListeners();
      // inventoryProvider.notifyListeners();
    }
  }

  void _restartInventoryTimer(InventoryProvider inventoryProvider,
      Inventory inventory, InventoryRepository inventoryRepository) async {
    inventory.updateElapsedTime(0);
    inventory.isPaused = false;
    inventory.updateIsFinished(false);
    await inventoryProvider.updateInventoryElapsedTime(
        inventory.id, inventory.elapsedTime);
    // await inventoryProvider.fetchInventories();
    inventory.startTimer(inventoryRepository);
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

  void _showSpeciesSearch(SpeciesRepository speciesRepository,
      InventoryRepository inventoryRepository) async {
    final allSpecies = await loadSpeciesSearchData();
    allSpecies.sort((a, b) => a.compareTo(b));

    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    final selectedSpecies = await showSearch(
      context: context,
      delegate: SpeciesSearchDelegate(
          allSpecies, (speciesName) =>
          _addSpeciesToInventory(
              speciesName, speciesRepository, inventoryRepository),
          _updateSpeciesList),
      useRootNavigator: !isLargeScreen,
    );

    if (selectedSpecies != null) {
      _updateSpeciesList();
    }
  }

  Future<void> _deleteSpecies(Species species) async {
    final confirmed = await _showDeleteConfirmationDialog(context);
    if (confirmed) {
      Provider.of<SpeciesProvider>(context, listen: false)
          .removeSpecies(context, widget.inventory.id, species.id!);
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Tem certeza que deseja excluir esta espécie?'),
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
    ) ?? false;
  }

  Future<void> _showAddSpeciesDialog(BuildContext context, SpeciesRepository speciesRepository, InventoryRepository inventoryRepository) async {
    String? newSpeciesName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String speciesName = '';
        return AlertDialog(
          title: const Text('Adicionar espécie'),
          content: TextField(
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              speciesName = value;
            },
            decoration: const InputDecoration(
              labelText: 'Nome da espécie',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(speciesName),
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );

    if (newSpeciesName != null && newSpeciesName.isNotEmpty) {
      _addSpeciesToInventory(newSpeciesName, speciesRepository, inventoryRepository);
    }
  }

  Widget _buildSpeciesList(SpeciesRepository speciesRepository,
      InventoryRepository inventoryRepository) {
    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: 840),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Adicionar espécie...',
                    prefixIcon: const Icon(Icons.search_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_box_outlined),
                      onPressed: () {
                        _showAddSpeciesDialog(context, widget.speciesRepository, widget.inventoryRepository);
                      },
                    ),
                  ),
                  readOnly: true,
                  onTap: () async {
                    _showSpeciesSearch(speciesRepository, inventoryRepository);
                  },
                ),
              ),
            ),
          ),
          Expanded(
              child: Consumer<SpeciesProvider>(
                  builder: (context, speciesProvider, child) {
                    final speciesList = speciesProvider
                        .getSpeciesForInventory(widget.inventory.id);
                    speciesList.sort((a, b) => a.name.compareTo(b.name));
                    if (speciesList.isEmpty) {
                      return const Center(
                        child: Text('Nenhuma espécie registrada.'),
                      );
                    } else {
                      return LayoutBuilder(
                        builder: (BuildContext context,
                            BoxConstraints constraints) {
                          final screenWidth = constraints.maxWidth;
                          final isLargeScreen = screenWidth > 600;

                          if (isLargeScreen) {
                            return Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                    maxWidth: 840),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: speciesList.length,
                                  itemBuilder: (context, index) {
                                    // print('speciesList: ${speciesList.length} ; AnimatedList: $index');
                                    // if (index >= speciesList.length) {
                                    //   return const SizedBox.shrink();
                                    // }
                                    final species = speciesList[index];
                                    return SpeciesListItem(
                                      species: species,
                                      onLongPress: () =>
                                          _showBottomSheet(context, species),
                                    );
                                  },
                                ),
                              ),
                            );
                          } else {
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: speciesList.length,
                              itemBuilder: (context, index) {
                                // if (index >= speciesList.length) {
                                //   return const SizedBox.shrink();
                                // }
                                final species = speciesList[index];
                                return SpeciesListItem(
                                  species: species,
                                  onLongPress: () =>
                                      _showBottomSheet(context, species),
                                );
                              },
                            );
                          }
                        },
                      );
                    }
                  }
              )

          ),
        ]
    );
  }

  void _showBottomSheet(BuildContext context, Species species) {
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
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Anotações da espécie'),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditNotesDialog(context, species);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outlined, color: Colors.red,),
                    title: const Text(
                      'Apagar espécie', style: TextStyle(color: Colors.red),),
                    onTap: () {
                      _deleteSpecies(species);
                      Navigator.pop(context);
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

  void _showEditNotesDialog(BuildContext context, Species species) {
    final _notesController = TextEditingController(text: species.notes);
    final speciesProvider = Provider.of<SpeciesProvider>(
        context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar notas'),
          content: TextField(
            controller: _notesController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notas',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Salvar'),
              onPressed: () async {
                species.notes = _notesController.text;
                final updatedSpecies = Species(
                  id: species.id,
                  inventoryId: species.inventoryId,
                  notes: _notesController.text,
                  isOutOfInventory: species.isOutOfInventory,
                  count: species.count,
                  name: species.name,
                );
                await speciesProvider.updateSpecies(species.inventoryId, updatedSpecies);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }
}