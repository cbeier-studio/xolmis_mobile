import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:xolmis/screens/inventory/edit_species_screen.dart';

import '../../data/models/inventory.dart';
import '../../data/database/repositories/inventory_repository.dart';
import '../../data/database/repositories/species_repository.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/species_provider.dart';
import '../../providers/poi_provider.dart';

import '../../utils/utils.dart';
// import '../../utils/species_search_delegate.dart';
// import '../../utils/species_search_dialog.dart';
import '../statistics/species_chart_screen.dart';
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

  // Add a species to the inventory
  Future<void> _addSpeciesToInventory(String speciesName,
      SpeciesRepository speciesRepository,
      InventoryRepository inventoryRepository) async {
    final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);

    // If the species is already in the inventory, show a message and return
    if (widget.inventory.type != InventoryType.invTransectDetection &&
      widget.inventory.type != InventoryType.invPointDetection) {
      if (speciesProvider.speciesExistsInInventory(
        widget.inventory.id, speciesName)) {
        _showSpeciesAlreadyExistsMessage();
        return;
      }
    }

    // Set the initial count to 1 for transect and point count inventories
    final initialCount = widget.inventory.type == InventoryType.invTransectCount ||
        widget.inventory.type == InventoryType.invPointCount ||
        widget.inventory.type == InventoryType.invTransectDetection ||
        widget.inventory.type == InventoryType.invPointDetection ? 1 : 0;

    // Create the new species
    Species? newSpecies = Species(
      inventoryId: widget.inventory.id,
      name: speciesName,
      sampleTime: DateTime.now(),
      isOutOfInventory: widget.inventory.isFinished,
      count: initialCount,
      pois: [],
    );

    // Add species details
    if (widget.inventory.type == InventoryType.invTransectDetection ||
        widget.inventory.type == InventoryType.invPointDetection) {
      newSpecies = await Navigator.push<Species>(
        context,
        MaterialPageRoute(
          builder: (context) => EditSpeciesScreen(species: newSpecies!),
        ),
      );
    }

    // Insert the new species in the database
    await speciesRepository.insertSpecies(widget.inventory.id, newSpecies!);
    
    // Check is Mackinnon list was completed and ask to start the next list
    setState(() {
      checkMackinnonCompletion(context, widget.inventory, inventoryRepository);
    });

    if (!widget.inventory.isFinished) {
      // If the inventory is not finished, add the species to other active inventories
      await _addSpeciesToOtherActiveInventories(
          speciesName, speciesProvider, inventoryProvider, speciesRepository,
          inventoryRepository);

      if (widget.inventory.type == InventoryType.invIntervalQualitative) {
        // Increment the current interval species count for interval qualitative inventories
        widget.inventory.currentIntervalSpeciesCount++;
        await inventoryRepository.updateInventoryCurrentIntervalSpeciesCount(widget.inventory.id, widget.inventory.currentIntervalSpeciesCount);
      } else if (widget.inventory.type == InventoryType.invTimedQualitative) {
        // Restart the inventory timer for timed qualitative inventories
        _restartInventoryTimer(inventoryProvider, widget.inventory, inventoryRepository);
      }
    }

    // Update the inventory in the database
    // await inventoryRepository.updateInventory(widget.inventory);
    // Reload the species list for the current inventory
    await _updateSpeciesList(widget.inventory.id);

    // speciesProvider.notifyListeners();
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

  // Add species to other active inventories
  Future<void> _addSpeciesToOtherActiveInventories(String speciesName,
      SpeciesProvider speciesProvider, InventoryProvider inventoryProvider,
      SpeciesRepository speciesRepository,
      InventoryRepository inventoryRepository) async {
    for (final inventory in inventoryProvider.activeInventories) {
      if (inventory.id != widget.inventory.id &&
          !speciesProvider.speciesExistsInInventory(inventory.id, speciesName) &&
          (inventory.type != InventoryType.invBanding ||
              inventory.type != InventoryType.invTransectDetection ||
              inventory.type != InventoryType.invPointDetection)) {
        // Set the initial count to 1 for transect and point count inventories
        final initialCount = inventory.type == InventoryType.invTransectCount ||
            inventory.type == InventoryType.invPointCount ? 1 : 0;
        // Create the new species
        final newSpeciesForOtherInventory = Species(
          inventoryId: inventory.id,
          name: speciesName,
          sampleTime: DateTime.now(),
          isOutOfInventory: inventory.isFinished,
          count: initialCount,
          pois: [],
        );
        // Insert the new species in the database
        await speciesRepository.insertSpecies(
            newSpeciesForOtherInventory.inventoryId,
            newSpeciesForOtherInventory);

        if (inventory.type == InventoryType.invIntervalQualitative) {
          // Increment the current interval species count for interval qualitative inventories
          inventory.currentIntervalSpeciesCount++;
          await inventoryRepository.updateInventoryCurrentIntervalSpeciesCount(inventory.id, inventory.currentIntervalSpeciesCount);
        } else if (inventory.type == InventoryType.invTimedQualitative) {
          // Restart the inventory timer for timed qualitative inventories
          _restartInventoryTimer(inventoryProvider, inventory, inventoryRepository);
        } else {
          // Or just update the inventory in the database
          inventoryProvider.updateInventory(inventory);
        }
        // Reload the species list for the other inventory
        await speciesProvider.loadSpeciesForInventory(inventory.id);
        inventory.speciesList = speciesProvider.getSpeciesForInventory(inventory.id);
        // speciesProvider.notifyListeners();
      }

    }
  }

  // Restart the inventory timer
  void _restartInventoryTimer(InventoryProvider inventoryProvider,
      Inventory inventory, InventoryRepository inventoryRepository) async {
    // Update the elapsed time to 0 and save it in the database
    inventory.updateElapsedTime(0);
    await inventoryProvider.updateInventoryElapsedTime(inventory.id, inventory.elapsedTime);
    // Update the paused state to false
    inventory.isPaused = false;
    // Update the isFinished state to false and save it in the database
    inventory.updateIsFinished(false);
    inventoryProvider.updateInventory(inventory);
    
    // Start the timer if it is not already running
    inventory.startTimer(context, inventoryRepository);
  }

  // Reload the species list for the current inventory
  Future<void> _updateSpeciesList(String inventoryId) async {
    final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
    await speciesProvider.loadSpeciesForInventory(inventoryId);
    widget.inventory.speciesList = speciesProvider.getSpeciesForInventory(inventoryId);
  }

  // Delete the selected species from the list
  Future<void> _deleteSpecies(Species species) async {
    final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final confirmed = await _showDeleteConfirmationDialog(context);

    if (!confirmed) return;

    if (mounted) {
      await speciesProvider.removeSpecies(context, widget.inventory.id, species.id!);
      widget.inventory.speciesList.remove(species);
    }

    // Ask to delete the species from other active inventories
    final shouldAskAboutOtherInventories = !widget.inventory.isFinished &&
        inventoryProvider.activeInventories.length > 1 &&
        widget.inventory.type != InventoryType.invTransectDetection &&
        widget.inventory.type != InventoryType.invPointDetection;

    if (shouldAskAboutOtherInventories) {
      if (mounted) {
        bool confirmDeleteFromOthers = await _showDeleteFromOtherListsConfirmationDialog(context, species.name);
        if (confirmDeleteFromOthers) {
          await _deleteSpeciesFromOtherActiveInventories(species, speciesProvider); 
        } 
      }          
    }
  }

  // Delete species from other active inventories
  Future<void> _deleteSpeciesFromOtherActiveInventories(Species species,
      SpeciesProvider speciesProvider) async {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    for (final inventory in inventoryProvider.activeInventories) {
      if (inventory.id != species.inventoryId &&
          speciesProvider.speciesExistsInInventory(inventory.id, species.name) &&
          (inventory.type != InventoryType.invBanding &&
              inventory.type != InventoryType.invTransectDetection &&
              inventory.type != InventoryType.invPointDetection)) {
        
        await speciesProvider.removeSpeciesFromInventory(
          context,
          inventory.id,
          species.name);
        
        inventoryProvider.updateInventory(inventory);
        
        speciesProvider.loadSpeciesForInventory(inventory.id);
        inventory.speciesList = speciesProvider.getSpeciesForInventory(inventory.id);
        // speciesProvider.notifyListeners();
      }

    }
  }

  // Show dialog to confirm species deletion
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog.adaptive(
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

  // Show dialog to confirm deletion of species from other active inventories
  Future<bool> _showDeleteFromOtherListsConfirmationDialog(
      BuildContext context, String speciesName) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog.adaptive(
              title: Text(S.of(context).confirmDeleteSpecies),
              content: Text(S.of(context).confirmDeleteSpeciesMessage(speciesName)),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).no),
                  onPressed: () {
                    Navigator.of(context).pop(false); 
                  },
                ),
                TextButton(
                  child: Text(S.of(context).yes),
                  onPressed: () {
                    Navigator.of(context).pop(true); 
                  },
                ),
              ],
            );
          },
        ) ?? false; // Return false if the dialog was closed without a selection
  }

  // Show dialog to add a personalized species name
  Future<void> _showAddSpeciesDialog(BuildContext context, SpeciesRepository speciesRepository, InventoryRepository inventoryRepository) async {
    String? newSpeciesName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String speciesName = '';
        return AlertDialog.adaptive(
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
      await _addSpeciesToInventory(newSpeciesName, speciesRepository, inventoryRepository);
    }
  }

  // Build the species list
  Widget _buildSpeciesList(SpeciesRepository speciesRepository,
      InventoryRepository inventoryRepository) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: SearchAnchor(
              isFullScreen: MediaQuery.of(context).size.width < 600,
              builder: (context, controller) {
                return TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: '${S.of(context).addSpecies}...',
                    prefixIcon: const Icon(Icons.search_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: MenuAnchor(
                      builder: (context, controller, child) {
                        return IconButton(
                          icon: Icon(Icons.more_vert_outlined),
                          // tooltip: S.of(context).exportWhat(S.of(context).inventory(1)),
                          onPressed: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                        );
                      },
                      menuChildren: [
                        MenuItemButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SpeciesChartScreen(
                                    inventory: widget.inventory),
                              ),
                            );
                          },
                          leadingIcon: const Icon(Icons.show_chart_outlined),
                          child: Text(
                            S.current.speciesAccumulationCurve,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        MenuItemButton(
                          onPressed: () {
                            _showAddSpeciesDialog(
                                context,
                                widget.speciesRepository,
                                widget.inventoryRepository);
                          },
                          leadingIcon: const Icon(Icons.add_box_outlined),
                          child: Text(S.current.addSpecies),
                        ),
                      ],
                    ),
                  ),
                  readOnly: true,
                  onTap: () {
                    controller.openView();
                  },
                );
              },
              suggestionsBuilder: (context, controller) {
                if (controller.text.isEmpty) {
                  return [];
                } else {
                  return List<String>.from(allSpeciesNames)
                    .where((species) => speciesMatchesQuery(
                        species, controller.text.toLowerCase()))
                    .map((species) {
                    return ListTile(
                      title: Text(species),
                      onTap: () async {
                        await _addSpeciesToInventory(species, speciesRepository, inventoryRepository);
                        controller.closeView(species);
                        controller.clear();
                      },
                    );
                  }).toList();
                }
              },
            ),
          ),
        ),
      ),
      Expanded(child: Consumer<SpeciesProvider>(builder: (context, speciesProvider, child) {
        final speciesList = speciesProvider.getSpeciesForInventory(widget.inventory.id);
        if (widget.inventory.type == InventoryType.invTransectDetection ||
            widget.inventory.type == InventoryType.invPointDetection) {
          speciesList.sort((a, b) {
            if (a.sampleTime == null && b.sampleTime == null) {
              return 0; // Both are null, considered the same
            }
            if (a.sampleTime == null) {
              return -1; // 'a' is null, then goes to the end of list
            }
            if (b.sampleTime == null) {
              return 1; // 'b' is null, then goes to the end of list (and 'a' goes first)
            }
            // None is null, compare the times
            return b.sampleTime!.compareTo(a.sampleTime!);
          });
        } else {
          speciesList.sort((a, b) => a.name.compareTo(b.name));
        }

        if (speciesList.isEmpty) {
          return Center(
            child: Text(S.of(context).noSpeciesFound),
          );
        } else {
          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final screenWidth = constraints.maxWidth;
              final isLargeScreen = screenWidth > 600;

              if (isLargeScreen) {
                // If the screen is large, use a ListView with a maximum width
                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 840),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: speciesList.length,
                      itemBuilder: (context, index) {
                        final species = speciesList[index];
                        return SpeciesListItem(
                          species: species,
                          onLongPress: () => _showBottomSheet(context, species),
                        );
                      },
                    ),
                  ),
                );
              } else {
                // If the screen is small, use a ListView with no maximum width
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: speciesList.length,
                  itemBuilder: (context, index) {
                    final species = speciesList[index];
                    return SpeciesListItem(
                      species: species,
                      onLongPress: () => _showBottomSheet(context, species),
                    );
                  },
                );
              }
            },
          );
        }
      })),
    ]);
  }

  void _showBottomSheet(BuildContext context, Species species) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: BottomSheet(
          onClosing: () {},
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    title: Text(species.name, style: TextStyle(fontStyle: FontStyle.italic),),
                  ),
                  Divider(),
                  // Option to edit the species notes
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(S.of(context).speciesNotes),
                    onTap: () async {
                      Navigator.pop(context);
                      // _showEditNotesDialog(context, species);
                      final speciesProvider = Provider.of<SpeciesProvider>(
                          context, listen: false);
                      final editedSpecies = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditSpeciesScreen(species: species),
                        ),
                      );
                      if (editedSpecies != null && editedSpecies is Species) {
                        await speciesProvider.updateSpecies(widget.inventory.id, editedSpecies);
                      }
                    },
                  ),
                  // Option to add the species to the sample
                  if (species.isOutOfInventory)
                    ListTile(
                      leading: const Icon(Icons.inventory_outlined),
                      title: Text(S.of(context).addSpeciesToSample),
                      onTap: () {
                        Navigator.pop(context);
                        _addSpeciesToSample(context, species);
                      },
                    ),
                  // Option to remove the species from the sample                  
                  if (!species.isOutOfInventory)
                    ListTile(
                      leading: const Icon(Icons.content_paste_go_outlined),
                      title: Text(S.of(context).removeSpeciesFromSample),
                      onTap: () {
                        Navigator.pop(context);
                        _removeSpeciesToSample(context, species);
                      },
                    ),
                  // Divider(),
                  // Option to add a POI
                  ListTile(
                    leading: const Icon(Icons.add_location_outlined),
                    title: Text(S.of(context).addPoi),
                    onTap: () async {
                      final poiProvider =
                          Provider.of<PoiProvider>(context, listen: false);
                      // Get the current location
                      Position? position = await getPosition(context);

                      if (position != null) {
                        // Create a new POI
                        final poi = Poi(
                          speciesId: species.id!,
                          sampleTime: DateTime.now(),
                          longitude: position.longitude,
                          latitude: position.latitude,
                        );

                        // Insert the POI in the database
                        if (context.mounted) {
                          poiProvider.addPoi(context, species.id!, poi);
                          // poiProvider.notifyListeners();
                        }                        
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.error_outlined,
                                      color: Colors.red),
                                  const SizedBox(width: 8),
                                  Text(S.of(context).errorGettingLocation),
                                ],
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  // Divider(),
                  // Option to delete the species
                  ListTile(
                    leading: Icon(
                      Icons.delete_outlined, color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red
                        : Colors.redAccent,),
                    title: Text(
                      S.of(context).deleteSpecies, style: TextStyle(color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red
                        : Colors.redAccent,),),
                    onTap: () async {
                      await _deleteSpecies(species);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  )
                ],
              ),
            );
          },
          ),
        );
      },
    );
  }

  // Add the species to the sample
  void _addSpeciesToSample(BuildContext context, Species species) {
    final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);

    species.isOutOfInventory = false;
    speciesProvider.updateSpecies(species.inventoryId, species);
  }

  // Remove the species from the sample
  void _removeSpeciesToSample(BuildContext context, Species species) {
    final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);

    species.isOutOfInventory = true;
    speciesProvider.updateSpecies(species.inventoryId, species);
  }

  // Show the dialog to edit species notes
  void _showEditNotesDialog(BuildContext context, Species species) {
    final notesController = TextEditingController(text: species.notes);
    final speciesProvider = Provider.of<SpeciesProvider>(
        context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog.adaptive(
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
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }
}