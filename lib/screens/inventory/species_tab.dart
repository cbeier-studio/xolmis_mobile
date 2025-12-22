import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:xolmis/screens/inventory/edit_species_screen.dart';

import '../../data/models/inventory.dart';
import '../../data/daos/inventory_dao.dart';
import '../../data/daos/species_dao.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/species_provider.dart';
import '../../providers/poi_provider.dart';

import '../../core/core_consts.dart';
import '../../utils/utils.dart';
import '../statistics/species_chart_screen.dart';
import '../../widgets/species_list_item.dart';
import '../../generated/l10n.dart';

class SpeciesTab extends StatefulWidget {
  final Inventory inventory;
  final SpeciesDao speciesDao;
  final InventoryDao inventoryDao;

  const SpeciesTab({
    super.key,
    required this.inventory,
    required this.speciesDao,
    required this.inventoryDao
  });

  @override
  State<SpeciesTab> createState() => _SpeciesTabState();
}

class _SpeciesTabState extends State<SpeciesTab> with AutomaticKeepAliveClientMixin {

  late SpeciesSortField _sortOption = widget.inventory.type == InventoryType.invTransectDetection ||
      widget.inventory.type == InventoryType.invPointDetection ? SpeciesSortField.time : SpeciesSortField.name;
  late SortOrder _sortOrder = widget.inventory.type == InventoryType.invTransectDetection ||
      widget.inventory.type == InventoryType.invPointDetection ? SortOrder.descending : SortOrder.ascending;
  SearchController? _searchController;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildSpeciesList(
        widget.speciesDao, widget.inventoryDao);
  }

  // Add a species to the inventory
  Future<void> _addSpeciesToInventory(String speciesName,
      SpeciesDao speciesDao,
      InventoryDao inventoryDao) async {
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
    await speciesProvider.addSpecies(context, widget.inventory.id, newSpecies!);
    // await speciesDao.insertSpecies(widget.inventory.id, newSpecies!);

    if (!widget.inventory.isFinished) {
      // If the inventory is not finished, add the species to other active inventories
      await _addSpeciesToOtherActiveInventories(
          speciesName, speciesProvider, inventoryProvider, speciesDao,
          inventoryDao);

      if (widget.inventory.type == InventoryType.invIntervalQualitative) {
        // Increment the current interval species count for interval qualitative inventories
        widget.inventory.currentIntervalSpeciesCount++;
        await inventoryDao.updateInventoryCurrentIntervalSpeciesCount(widget.inventory.id, widget.inventory.currentIntervalSpeciesCount);
      } else if (widget.inventory.type == InventoryType.invTimedQualitative) {
        // Restart the inventory timer for timed qualitative inventories
        _restartInventoryTimer(inventoryProvider, widget.inventory, inventoryDao);
      }
    }

    // Check is Mackinnon list was completed and ask to start the next list
    // checkMackinnonCompletion(context, widget.inventory, inventoryDao);    

    // Update the inventory in the database
    // await inventoryRepository.updateInventory(widget.inventory);
    // Reload the species list for the current inventory
    await _updateSpeciesList(widget.inventory.id);
  }

  void _showSpeciesAlreadyExistsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outlined, color: Colors.blue),
            const SizedBox(width: 8),
            Text(S.of(context).errorSpeciesAlreadyExists),
          ],
        ),
      ),
    );
  }

  // Add species to other active inventories
  Future<void> _addSpeciesToOtherActiveInventories(String speciesName,
      SpeciesProvider speciesProvider, InventoryProvider inventoryProvider,
      SpeciesDao speciesDao,
      InventoryDao inventoryDao) async {
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
        await speciesDao.insertSpecies(
            newSpeciesForOtherInventory.inventoryId,
            newSpeciesForOtherInventory);

        if (inventory.type == InventoryType.invIntervalQualitative) {
          // Increment the current interval species count for interval qualitative inventories
          inventory.currentIntervalSpeciesCount++;
          await inventoryDao.updateInventoryCurrentIntervalSpeciesCount(inventory.id, inventory.currentIntervalSpeciesCount);
        } else if (inventory.type == InventoryType.invTimedQualitative) {
          // Restart the inventory timer for timed qualitative inventories
          _restartInventoryTimer(inventoryProvider, inventory, inventoryDao);
        } else {
          // Or just update the inventory in the database
          inventoryProvider.updateInventory(inventory);
        }
        // Reload the species list for the other inventory
        await speciesProvider.loadSpeciesForInventory(inventory.id);
        inventory.speciesList = speciesProvider.getSpeciesForInventory(inventory.id);
      }

    }
  }

  // Restart the inventory timer
  void _restartInventoryTimer(InventoryProvider inventoryProvider,
      Inventory inventory, InventoryDao inventoryDao) async {
    // Update the elapsed time to 0 and save it in the database
    inventory.updateElapsedTime(0);
    await inventoryProvider.updateInventoryElapsedTime(inventory.id, inventory.elapsedTime);
    // Update the paused state to false
    inventory.isPaused = false;
    // Update the isFinished state to false and save it in the database
    inventory.updateIsFinished(false);
    inventoryProvider.updateInventory(inventory);
    
    // Start the timer if it is not already running
    inventory.startTimer(context, inventoryDao);
  }

  // Reload the species list for the current inventory
  Future<void> _updateSpeciesList(String inventoryId) async {
    final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
    await speciesProvider.loadSpeciesForInventory(inventoryId);
    widget.inventory.speciesList = speciesProvider.getSpeciesForInventory(inventoryId);
    debugPrint('[SPECIES_TAB] Species list reloaded for inventory $inventoryId with ${widget.inventory.speciesList.length} species');
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
  Future<void> _showAddSpeciesDialog(BuildContext context, SpeciesDao speciesDao, InventoryDao inventoryDao) async {
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
      await _addSpeciesToInventory(newSpeciesName, speciesDao, inventoryDao);
    }
  }

  // Build the species list
  Widget _buildSpeciesList(SpeciesDao speciesDao,
      InventoryDao inventoryDao) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: SearchAnchor(
              isFullScreen: MediaQuery.of(context).size.width < 600,
              builder: (context, controller) {
                _searchController = controller;
                return TextField(
                  controller: controller,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    filled: true,
                    hintText: '${S.of(context).addSpecies}...',
                    prefixIcon: const Icon(Icons.add_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.sort_outlined),
                          tooltip: S.of(context).sortBy,
                          onPressed: () => _showSortOptionsBottomSheet(),
                        ),
                        MediaQuery.sizeOf(context).width < 600
                            ? IconButton(
                          icon: const Icon(Icons.more_vert_outlined),
                          onPressed: () {
                            _showMoreOptionsBottomSheet(context);
                          },
                        )
                            : MenuAnchor(
                          builder: (context, controller, child) {
                            return IconButton(
                              icon: const Icon(Icons.more_vert_outlined),
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
                                    widget.speciesDao,
                                    widget.inventoryDao);
                              },
                              leadingIcon: const Icon(Icons.add_box_outlined),
                              child: Text(S.current.addSpecies),
                            ),
                          ],
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
                        debugPrint('[SPECIES_TAB] Selected species from search suggestions: $species');
                        await _addSpeciesToInventory(species, speciesDao, inventoryDao);
                        controller.closeView(species);
                        controller.clear();
                        checkMackinnonCompletion(context, widget.inventory, inventoryDao);
                      },
                    );
                  }).toList();
                }
              },
              // viewOnSubmitted: (value) async {
              //   final query = value.trim();
              //   if (query.isEmpty) return;
              //   final matches = List<String>.from(allSpeciesNames)
              //       .where((species) => speciesMatchesQuery(
              //           species, query.toLowerCase()))
              //       .toList();
              //   if (matches.isEmpty) return;
              //   final first = matches.first;
              //   await _addSpeciesToInventory(first, speciesDao, inventoryDao);
              //   _searchController?.closeView(first);
              //   _searchController?.clear();
              //   checkMackinnonCompletion(context, widget.inventory, inventoryDao);
              // },
            ),
          ),
        ),
      ),
      Expanded(child: Consumer<SpeciesProvider>(builder: (context, speciesProvider, child) {
        final speciesList = speciesProvider.getSpeciesForInventory(widget.inventory.id);
        speciesList.sort((a, b) {
          int comparison;

          // Helper function to handle nulls. Null values are treated as "smaller".
          int compareNullables<T extends Comparable>(T? a, T? b) {
            if (a == null && b == null) return 0; // Both are equal
            if (a == null) return -1; // a is "smaller"
            if (b == null) return 1;  // b is "smaller"
            return a.compareTo(b);
          }

          switch (_sortOption) {
            case SpeciesSortField.name:
              comparison = compareNullables(a.name, b.name);
              break;
            case SpeciesSortField.time:
              comparison = compareNullables(a.sampleTime, b.sampleTime);
              break;
          }

          // Apply the sort order (ascending or descending)
          return _sortOrder == SortOrder.ascending ? comparison : -comparison;
        });

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
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(species.name,
                      style: TextTheme.of(context).bodyLarge?.copyWith(fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // ListTile(
                  //   title: Text(species.name, style: TextStyle(fontStyle: FontStyle.italic),),
                  // ),
                  const Divider(),
                  GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 4 : 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      buildGridMenuItem(
                          context, Icons.edit_outlined, S.current.details, () async {
                        Navigator.of(context).pop();
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
                      }),
                      if (species.isOutOfInventory)
                      buildGridMenuItem(context, Icons.inventory_outlined,
                          S.current.addSpeciesToSample, () {
                            Navigator.of(context).pop();
                            _addSpeciesToSample(context, species);
                          }),
                      if (!species.isOutOfInventory)
                        buildGridMenuItem(
                            context, Icons.content_paste_go_outlined, S.of(context).removeSpeciesFromSample,
                                () async {
                              Navigator.of(context).pop();
                              _removeSpeciesFromSample(context, species);
                            }),
                        buildGridMenuItem(context, Icons.add_location_outlined,
                            S.of(context).addPoi, () async {
                              Navigator.of(context).pop();
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
                                      persist: true,
                                      showCloseIcon: true,
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
                            }),
                      buildGridMenuItem(context, Icons.delete_outlined,
                          S.of(context).delete, () async {
                            Navigator.of(context).pop();
                            await _deleteSpecies(species);
                          }, color: Theme.of(context).colorScheme.error),
                    ],
                  ),
                ],
              ),
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
  void _removeSpeciesFromSample(BuildContext context, Species species) {
    final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);

    species.isOutOfInventory = true;
    speciesProvider.updateSpecies(species.inventoryId, species);
  }

  void _showSortOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.of(context).sortBy, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0, // Space between chips
                    children: <Widget>[
                      ChoiceChip(
                        label: Text(S.current.speciesName),
                        showCheckmark: false,
                        selected: _sortOption == SpeciesSortField.name,
                        onSelected: (bool selected) {
                          setModalState(() {
                            _sortOption = SpeciesSortField.name;
                          });
                          setState(() {
                            _sortOption = SpeciesSortField.name;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(S.current.sampleTime),
                        showCheckmark: false,
                        selected: _sortOption == SpeciesSortField.time,
                        onSelected: (bool selected) {
                          setModalState(() {
                            _sortOption = SpeciesSortField.time;
                          });
                          setState(() {
                            _sortOption = SpeciesSortField.time;
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(S.of(context).direction, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<SortOrder>(
                    segments: [
                      ButtonSegment(value: SortOrder.ascending, label: Text(S.of(context).ascending), icon: Icon(Icons.south_outlined)),
                      ButtonSegment(value: SortOrder.descending, label: Text(S.of(context).descending), icon: Icon(Icons.north_outlined)),
                    ],
                    selected: {_sortOrder},
                    showSelectedIcon: false,
                    onSelectionChanged: (Set<SortOrder> newSelection) {
                      setModalState(() {
                        _sortOrder = newSelection.first;
                      });
                      setState(() {
                        _sortOrder = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
              ),
            );
          },
          ),
        );
      },
    );
  }

  void _showMoreOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: BottomSheet(
            onClosing: () {},
            builder: (BuildContext context) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GridView.count(
                        crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 4 : 5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: <Widget>[
                          buildGridMenuItem(
                              context, Icons.show_chart_outlined, S.of(context).speciesAccumulationCurve,
                                  () async {
                                Navigator.of(context).pop();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SpeciesChartScreen(
                                        inventory: widget.inventory),
                                  ),
                                );
                              }),
                          // Action to import nests from JSON
                          buildGridMenuItem(
                              context, Icons.add_box_outlined, S.of(context).addSpecies,
                                  () async {
                                Navigator.of(context).pop();
                                _showAddSpeciesDialog(
                                    context,
                                    widget.speciesDao,
                                    widget.inventoryDao);
                              }),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
