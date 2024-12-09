import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/inventory.dart';
import '../../data/database/repositories/inventory_repository.dart';
import '../../data/database/repositories/species_repository.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/species_provider.dart';

import '../../utils/utils.dart';
import '../../utils/species_search_delegate.dart';
import 'species_list_item.dart';
import '../../generated/l10n.dart';

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
    
    setState(() {
      checkMackinnonCompletion(context, widget.inventory, inventoryRepository);
    });

    if (!widget.inventory.isFinished) {
      _addSpeciesToOtherActiveInventories(
          speciesName, speciesProvider, inventoryProvider, speciesRepository,
          inventoryRepository);

      if (widget.inventory.type == InventoryType.invIntervaledQualitative) {
        widget.inventory.currentIntervalSpeciesCount++;
      }
    }

    await inventoryRepository.updateInventory(widget.inventory);
    _updateSpeciesList();

    speciesProvider.notifyListeners();
  }

  void _showSpeciesAlreadyExistsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text(S.of(context).errorSpeciesAlreadyExists),
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
          !speciesProvider.speciesExistsInInventory(inventory.id, speciesName) &&
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

        if (inventory.type == InventoryType.invIntervaledQualitative) {
          inventory.currentIntervalSpeciesCount++;
          inventoryRepository.updateInventoryCurrentIntervalSpeciesCount(inventory.id, inventory.currentIntervalSpeciesCount);
        } else if (inventory.type == InventoryType.invTimedQualitative) {
          _restartInventoryTimer(inventoryProvider, inventory, inventoryRepository);
        } else {
          inventoryProvider.updateInventory(inventory);
        }
        speciesProvider.loadSpeciesForInventory(inventory.id);
        speciesProvider.notifyListeners();
      }

    }
  }

  void _restartInventoryTimer(InventoryProvider inventoryProvider,
      Inventory inventory, InventoryRepository inventoryRepository) async {
    inventory.updateElapsedTime(0);
    await inventoryProvider.updateInventoryElapsedTime(inventory.id, inventory.elapsedTime);
    inventory.isPaused = false;
    inventory.updateIsFinished(false);
    inventoryProvider.updateInventory(inventory);
    
    inventory.startTimer(inventoryRepository);
  }

  void _updateSpeciesList() async {
    final speciesProvider = Provider.of<SpeciesProvider>(
        context, listen: false);
    speciesProvider.loadSpeciesForInventory(widget.inventory.id);
  }

  void _showSpeciesSearch(SpeciesRepository speciesRepository,
      InventoryRepository inventoryRepository) async {

    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    final selectedSpecies = await showSearch(
      context: context,
      delegate: SpeciesSearchDelegate(
          allSpeciesNames, (speciesName) =>
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
    final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
    final confirmed = await _showDeleteConfirmationDialog(context);
    if (confirmed) {
      await speciesProvider.removeSpecies(context, widget.inventory.id, species.id!);
    }

    if (!widget.inventory.isFinished) {
      bool confirm = await _showDeleteFromOtherListsConfirmationDialog(context, species.name);
      if (confirm) {
        await _deleteSpeciesFromOtherActiveInventories(species, speciesProvider); 
      }     
    }
  }

  Future<void> _deleteSpeciesFromOtherActiveInventories(Species species,
      SpeciesProvider speciesProvider) async {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    for (final inventory in inventoryProvider.activeInventories) {
      if (inventory.id != species.inventoryId &&
          speciesProvider.speciesExistsInInventory(inventory.id, species.name) &&
          inventory.type != InventoryType.invBanding) {
        
        await speciesProvider.removeSpeciesFromInventory(
          context,
          inventory.id,
          species.name);
        
        inventoryProvider.updateInventory(inventory);
        
        speciesProvider.loadSpeciesForInventory(inventory.id);
        speciesProvider.notifyListeners();
      }

    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirmDelete),
          content: Text(S.of(context).confirmDeleteMessage(1, 'female', S.of(context).species(1).toLowerCase())),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).delete),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _showDeleteFromOtherListsConfirmationDialog(
      BuildContext context, String speciesName) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Remover espécie'),
              content: Text(
                  'Deseja remover a espécie "$speciesName" dos outros inventários ativos?'),
              actions: <Widget>[
                TextButton(
                  child: Text('Não'),
                  onPressed: () {
                    Navigator.of(context).pop(false); 
                  },
                ),
                TextButton(
                  child: Text('Sim'),
                  onPressed: () {
                    Navigator.of(context).pop(true); 
                  },
                ),
              ],
            );
          },
        ) ?? false; // Retorna false por padrão se o diálogo for fechado sem uma resposta
  }

  Future<void> _showAddSpeciesDialog(BuildContext context, SpeciesRepository speciesRepository, InventoryRepository inventoryRepository) async {
    String? newSpeciesName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String speciesName = '';
        return AlertDialog(
          title: Text(S.of(context).addSpecies),
          content: TextField(
            textCapitalization: TextCapitalization.sentences,
            onChanged: (value) {
              speciesName = value;
            },
            decoration: InputDecoration(
              labelText: S.of(context).speciesName,
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(speciesName),
              child: Text(S.of(context).save),
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
                    hintText: '${S.of(context).addSpecies}...',
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
                      return Center(
                        child: Text(S.of(context).noSpeciesFound),
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
                  if (species.isOutOfInventory)
                    ListTile(
                      leading: const Icon(Icons.inventory_outlined),
                      title: Text(S.of(context).addSpeciesToSample),
                      onTap: () {
                        Navigator.pop(context);
                        _addSpeciesToSample(context, species);
                      },
                    ),
                  if (!species.isOutOfInventory)
                    ListTile(
                      leading: const Icon(Icons.content_paste_go_outlined),
                      title: Text(S.of(context).removeSpeciesFromSample),
                      onTap: () {
                        Navigator.pop(context);
                        _removeSpeciesToSample(context, species);
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(S.of(context).speciesNotes),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditNotesDialog(context, species);
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outlined, color: Colors.red,),
                    title: Text(
                      S.of(context).deleteSpecies, style: TextStyle(color: Colors.red),),
                    onTap: () async {
                      await _deleteSpecies(species);
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

  void _addSpeciesToSample(BuildContext context, Species species) {
    final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);

    species.isOutOfInventory = false;
    speciesProvider.updateSpecies(species.inventoryId, species);
  }

  void _removeSpeciesToSample(BuildContext context, Species species) {
    final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);

    species.isOutOfInventory = true;
    speciesProvider.updateSpecies(species.inventoryId, species);
  }

  void _showEditNotesDialog(BuildContext context, Species species) {
    final notesController = TextEditingController(text: species.notes);
    final speciesProvider = Provider.of<SpeciesProvider>(
        context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).editNotes),
          content: TextField(
            controller: notesController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: S.of(context).notes,
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(S.of(context).save),
              onPressed: () async {
                species.notes = notesController.text;
                final updatedSpecies = Species(
                  id: species.id,
                  inventoryId: species.inventoryId,
                  notes: notesController.text,
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