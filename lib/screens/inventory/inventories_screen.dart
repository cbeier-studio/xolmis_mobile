import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

import '../../utils/utils.dart';
import '../../utils/export_utils.dart';
import '../../generated/l10n.dart';


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
  final _searchController = TextEditingController();
  bool _isShowingActiveInventories = true;
  bool _isAscendingOrder = false;
  String _sortField = 'startTime';
  bool _isSearchBarVisible = false;
  String _searchQuery = '';
  Set<String> selectedInventories = {};

  @override
  void initState() {
    super.initState();
    inventoryProvider = context.read<InventoryProvider>();
    inventoryRepository = context.read<InventoryRepository>();
    speciesRepository = context.read<SpeciesRepository>();
    poiRepository = context.read<PoiRepository>();
    vegetationRepository = context.read<VegetationRepository>();
    weatherRepository = context.read<WeatherRepository>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  void _toggleSearchBarVisibility() {
    setState(() {
      _isSearchBarVisible = !_isSearchBarVisible;
    });
  }

  void _toggleSortOrder(String order) {
    setState(() {
      _isAscendingOrder = order == 'ascending';
    });
  }

  void _changeSortField(String field) {
    setState(() {
      _sortField = field;
    });
  }

  List<Inventory> _sortInventories(List<Inventory> inventories) {
  inventories.sort((a, b) {
    int comparison;
    if (_sortField == 'id') {
      comparison = a.id.compareTo(b.id);
    } else {
      comparison = a.startTime!.compareTo(b.startTime!);
    }
    return _isAscendingOrder ? comparison : -comparison;
  });
  return inventories;
}

  List<Inventory> _filterInventories(List<Inventory> inventories) {
    if (_searchQuery.isEmpty) {
      return _sortInventories(inventories);
    }
    List<Inventory> filteredInventories = inventories.where((inventory) =>
      inventory.id.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return _sortInventories(filteredInventories);
  }

  Future<void> _showAddInventoryScreen(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (inventoryProvider.activeInventories.length ==
        (prefs.getInt('maxSimultaneousInventories') ?? 2)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text(S.of(context).simultaneousLimitReached),
              ],
            ),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
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
          // Update the inventory list
          if (newInventory != null) {
            inventoryProvider.notifyListeners();
          }
        });
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddInventoryScreen()),
        ).then((newInventory) {
          // Update the inventory list
          if (newInventory != null) {
            inventoryProvider.notifyListeners();
          }
        });
      }
    }
  }

  void _deleteSelectedInventories() async {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirmDelete),
          content: Text(S
              .of(context)
              .confirmDeleteMessage(selectedInventories.length, "male", S.of(context).inventory(selectedInventories.length))),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                // Navigator.of(context).pop();
              },
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                // Call the function to delete species
                for (final id in selectedInventories) {
                  inventoryProvider.removeInventory(id);
                }
                setState(() {
                  selectedInventories.clear();
                });
                Navigator.of(context).pop(true);
                // Navigator.of(context).pop();
              },
              child: Text(S.of(context).delete),
            ),
          ],
        );
      },
    );
  }

  void _exportSelectedInventoriesToJson() async {
    try {
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      final inventories = selectedInventories.map((id) => inventoryProvider.getInventoryById(id)).toList();

      final jsonString = jsonEncode(inventories.map((inventory) => inventory?.toJson()).toList());

      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final formattedDate = formatter.format(now);

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/selected_inventories_$formattedDate.json';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      // Share the file using share_plus
      await Share.shareXFiles([
        XFile(filePath, mimeType: 'application/json'),
      ], text: S.current.inventoryExported(2), subject: S.current.inventoryData(2));

      setState(() {
        selectedInventories.clear();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text(S.current.errorExportingInventory(2, error.toString())),
            ],
          ),
        ),
      );
    }
  }

  void _exportSelectedInventoriesToCsv() async {
    try {
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      final inventories = selectedInventories.map((id) => inventoryProvider.getInventoryById(id)).toList();
      List<XFile> csvFiles = [];

      for (final inventory in inventories) {
        // 1. Create a list of data for the CSV
        List<List<dynamic>> rows = [];
        rows.add([
          'ID',
          'Type',
          'Duration',
          'Max of species',
          'Start time',
          'End time',
          'Start longitude',
          'Start latitude',
          'End longitude',
          'End latitude',
          'Intervals'
        ]);
        rows.add([
          inventory!.id,
          inventoryTypeFriendlyNames[inventory.type],
          inventory.duration,
          inventory.maxSpecies,
          inventory.startTime,
          inventory.endTime,
          inventory.startLongitude,
          inventory.startLatitude,
          inventory.endLongitude,
          inventory.endLatitude,
          inventory.currentInterval
        ]);

        // Add species data
        rows.add([]); // Empty line to separate the inventory of the species
        rows.add(['SPECIES', 'Count', 'Time', 'Out of sample', 'Notes']);
        for (var species in inventory.speciesList) {
          rows.add([
            species.name,
            species.count,
            species.sampleTime,
            species.isOutOfInventory,
            species.notes
          ]);
        }

        // Add vegetation data
        rows.add([]); // Empty line to separate vegetation data
        rows.add(['VEGETATION']);
        rows.add([
          'Date/Time',
          'Latitude',
          'Longitude',
          'Herbs Proportion',
          'Herbs Distribution',
          'Herbs Height',
          'Shrubs Proportion',
          'Shrubs Distribution',
          'Shrubs Height',
          'Trees Proportion',
          'Trees Distribution',
          'Trees Height',
          'Notes'
        ]);
        for (var vegetation in inventory.vegetationList) {
          rows.add([
            vegetation.sampleTime,
            vegetation.latitude,
            vegetation.longitude,
            vegetation.herbsProportion,
            vegetation.herbsDistribution?.index,
            vegetation.herbsHeight,
            vegetation.shrubsProportion,
            vegetation.shrubsDistribution?.index,
            vegetation.shrubsHeight,
            vegetation.treesProportion,
            vegetation.treesDistribution?.index,
            vegetation.treesHeight,
            vegetation.notes
          ]);
        }

        // Add weather data
        rows.add([]); // Empty line to separate weather data
        rows.add(['WEATHER']);
        rows.add([
          'Date/Time',
          'Cloud cover',
          'Precipitation',
          'Temperature',
          'Wind speed'
        ]);
        for (var weather in inventory.weatherList) {
          rows.add([
            weather.sampleTime,
            weather.cloudCover,
            precipitationTypeFriendlyNames[weather.precipitation],
            weather.temperature,
            weather.windSpeed
          ]);
        }

        // Add POIs data
        rows.add([]); // Empty line to separate POI data
        rows.add(['POINTS OF INTEREST']);
        for (var species in inventory.speciesList) {
          if (species.pois.isNotEmpty) {
            rows.add(['Species: ${species.name}']);
            rows.add(['Latitude', 'Longitude']);
            for (var poi in species.pois) {
              rows.add([poi.latitude, poi.longitude]);
            }
            rows.add([]); // Empty line to
          } // separate species POIs
        }

        // 2. Convert the list of data to CSV
        String csv = const ListToCsvConverter().convert(rows, fieldDelimiter: ';');

        // 3. Create the file in a temporary directory
        Directory tempDir = await getApplicationDocumentsDirectory();
        final filePath = '${tempDir.path}/inventory_${inventory.id}.csv';
        final file = File(filePath);
        await file.writeAsString(csv);

        csvFiles.add(XFile(filePath, mimeType: 'text/csv'));
      }

      // Share the file using share_plus
      await Share.shareXFiles(csvFiles, text: S.current.inventoryExported(2), subject: S.current.inventoryData(2));

      setState(() {
        selectedInventories.clear();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text(S.current.errorExportingInventory(2, error.toString())),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).inventories),
        leading: MediaQuery.sizeOf(context).width < 600 ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_outlined),
            onPressed: () {
              widget.scaffoldKey.currentState?.openDrawer();
            },
          ),
        ) : SizedBox.shrink(),
        actions: [
          IconButton(
            icon: Icon(Icons.search_outlined),
            onPressed: _toggleSearchBarVisibility,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.sort_outlined),
            position: PopupMenuPosition.under,
            onSelected: (value) {
              if (value == 'ascending' || value == 'descending') {
                _toggleSortOrder(value);
              } else {
                _changeSortField(value);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'startTime',
                  child: Row(
                    children: [
                      Icon(Icons.schedule_outlined),
                      SizedBox(width: 8),
                      Text(S.of(context).sortByTime),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'id',
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha_outlined),
                      SizedBox(width: 8),
                      Text(S.of(context).sortByName),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'ascending',
                  child: Row(
                    children: [
                      Icon(Icons.south_outlined),
                      SizedBox(width: 8),
                      Text(S.of(context).sortAscending),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'descending',
                  child: Row(
                    children: [
                      Icon(Icons.north_outlined),
                      SizedBox(width: 8),
                      Text(S.of(context).sortDescending),
                    ],
                  ),
                ),
              ];
            },
          ),
          // if (selectedInventories.isNotEmpty)
          //   IconButton(
          //     icon: Icon(Icons.delete_outlined),
          //     onPressed: _deleteSelectedInventories,
          //   ),
          // if (selectedInventories.isNotEmpty)
          //   IconButton(
          //     icon: Icon(Icons.download_outlined),
          //     onPressed: _exportSelectedInventories,
          //   ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchBarVisible) Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: SearchBar(
              controller: _searchController,
              hintText: S.of(context).findInventories,
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
                    segments: [
                      ButtonSegment(value: true, label: Text(S.of(context).active)),
                      ButtonSegment(value: false, label: Text(S.of(context).finished)),
                    ],
                    selected: {_isShowingActiveInventories},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isShowingActiveInventories = newSelection.first;
                      });
                      // inventoryProvider.notifyListeners();
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
                  } else if (_isShowingActiveInventories && inventoryProvider.activeInventories.isEmpty ||
                      !_isShowingActiveInventories && inventoryProvider.finishedInventories.isEmpty) {
                    return Center(
                      child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(S.of(context).noInventoriesFound)
                      ),
                    );
                  } else {
                    final filteredInventories = _filterInventories(_isShowingActiveInventories
                        ? inventoryProvider.activeInventories
                        : inventoryProvider.finishedInventories);
                    return LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          final screenWidth = constraints.maxWidth;
                          final isLargeScreen = screenWidth > 600;

                          if (isLargeScreen) {
                            return SingleChildScrollView(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 840),
                                  child: GridView.builder(
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 3.2,
                                    ),
                                    physics: const NeverScrollableScrollPhysics(),
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
                                          child: InventoryGridItem(
                                              inventory: inventory,
                                              isShowingActiveInventories: _isShowingActiveInventories,
                                              inventoryRepository: inventoryRepository
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredInventories.length,
                              itemBuilder: (context, index) {
                                final inventory = filteredInventories[index];
                                final isSelected = selectedInventories.contains(inventory.id);
                                return ListTile(
                                  // Use ValueListenableBuilder for update the CircularProgressIndicator
                                  leading: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        ValueListenableBuilder<double>(
                                          valueListenable:
                                              inventory.elapsedTimeNotifier,
                                          builder:
                                              (context, elapsedTime, child) {
                                            var progress = (inventory
                                                        .isPaused ||
                                                    inventory.duration < 0)
                                                ? null
                                                : (elapsedTime /
                                                        (inventory.duration *
                                                            60))
                                                    .toDouble();

                                            if (progress != null &&
                                                (progress.isNaN ||
                                                    progress.isInfinite ||
                                                    progress < 0 ||
                                                    progress > 1)) {
                                              progress = 0;
                                            }

                                            return CircularProgressIndicator(
                                              value: progress,
                                              backgroundColor:
                                                  _isShowingActiveInventories &&
                                                          inventory.duration > 0
                                                      ? Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.light
                                                          ? Colors.grey[200]
                                                          : Colors.black
                                                      : null,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                inventory.isPaused
                                                    ? Colors.amber
                                                    : Theme.of(context)
                                                                .brightness ==
                                                            Brightness.light
                                                        ? Colors.deepPurple
                                                        : Colors
                                                            .deepPurpleAccent,
                                              ),
                                            );
                                          },
                                        ),
                                        if (_isShowingActiveInventories &&
                                            inventory.type ==
                                                InventoryType
                                                    .invIntervalQualitative)
                                          ValueListenableBuilder<int>(
                                              valueListenable: inventory
                                                  .currentIntervalNotifier,
                                              builder: (context,
                                                  currentInterval, child) {
                                                return Text(
                                                    currentInterval.toString());
                                              }),
                                        Visibility(
                                          visible: !_isShowingActiveInventories,
                                          child: Checkbox(
                                            value: isSelected,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (value == true) {
                                                  selectedInventories
                                                      .add(inventory.id);
                                                } else {
                                                  selectedInventories
                                                      .remove(inventory.id);
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ]),
                                  title: Text(inventory.id),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          '${inventoryTypeFriendlyNames[inventory.type]}'),
                                      if (_isShowingActiveInventories && inventory.duration > 0)
                                        Text(S.of(context).inventoryDuration(
                                            inventory.duration)),
                                      if (!_isShowingActiveInventories)
                                        Text(
                                            '${DateFormat('dd/MM/yyyy HH:mm:ss').format(inventory.startTime!)} - ${DateFormat('HH:mm:ss').format(inventory.endTime!)}'),
                                      Selector<SpeciesProvider, int>(
                                        selector: (context, speciesProvider) =>
                                            speciesProvider
                                                .getSpeciesForInventory(
                                                    inventory.id)
                                                .length,
                                        shouldRebuild: (previous, next) =>
                                            previous != next,
                                        builder:
                                            (context, speciesCount, child) {
                                          return Text(
                                              '$speciesCount ${S.of(context).speciesCount(speciesCount)}');
                                        },
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Visibility(
                                        visible: inventory.type ==
                                            InventoryType
                                                .invIntervalQualitative,
                                        child: ValueListenableBuilder<int>(
                                            valueListenable: inventory
                                                .intervalWithoutSpeciesNotifier,
                                            builder: (context,
                                                intervalWithoutSpecies, child) {
                                              return intervalWithoutSpecies > 0
                                                  ? Badge.count(
                                                      count:
                                                          intervalWithoutSpecies)
                                                  : SizedBox.shrink();
                                            }),
                                      ),
                                      Visibility(
                                        visible: _isShowingActiveInventories &&
                                            inventory.duration > 0,
                                        child: IconButton(
                                          icon: Icon(inventory.isPaused
                                              ? Theme.of(context).brightness ==
                                                      Brightness.light
                                                  ? Icons.play_arrow_outlined
                                                  : Icons.play_arrow
                                              : Theme.of(context).brightness ==
                                                      Brightness.light
                                                  ? Icons.pause_outlined
                                                  : Icons.pause),
                                          tooltip: inventory.isPaused
                                              ? S.of(context).resume
                                              : S.of(context).pause,
                                          onPressed: () {
                                            if (inventory.isPaused) {
                                              Provider.of<InventoryProvider>(
                                                      context,
                                                      listen: false)
                                                  .resumeInventoryTimer(
                                                      inventory,
                                                      inventoryRepository);
                                            } else {
                                              Provider.of<InventoryProvider>(
                                                      context,
                                                      listen: false)
                                                  .pauseInventoryTimer(
                                                      inventory,
                                                      inventoryRepository);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            InventoryDetailScreen(
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
                                  onLongPress: () =>
                                      _showBottomSheet(context, inventory),
                                );
                            
                                        
                                        // InventoryListItem(
                                        //   inventory: inventory,
                                        //   speciesRepository: speciesRepository,
                                        //   inventoryRepository: inventoryRepository,
                                        //   poiRepository: poiRepository,
                                        //   vegetationRepository: vegetationRepository,
                                        //   weatherRepository: weatherRepository,
                                        //   onLongPress: () => _showBottomSheet(context, inventory),
                                        //   onTap: (inventory) {
                                        //     Navigator.push(
                                        //       context,
                                        //       MaterialPageRoute(
                                        //         builder: (context) => InventoryDetailScreen(
                                        //           inventory: inventory,
                                        //           speciesRepository: speciesRepository,
                                        //           inventoryRepository: inventoryRepository,
                                        //           poiRepository: poiRepository,
                                        //           vegetationRepository: vegetationRepository,
                                        //           weatherRepository: weatherRepository,
                                        //         ),
                                        //       ),
                                        //     ).then((result) {
                                        //       if (result == true) {
                                        //         inventoryProvider.notifyListeners();
                                        //       }
                                        //     });
                                        //   },
                                        //   onInventoryPausedOrResumed: (inventory) => _onInventoryPausedOrResumed(inventory),
                                        //   isHistory: !_isShowingActiveInventories,
                                        // )
                                    
                                
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
      floatingActionButtonLocation: selectedInventories.isNotEmpty && !_isShowingActiveInventories 
        ? FloatingActionButtonLocation.endContained 
        : FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).newInventory,
        onPressed: () {
          _showAddInventoryScreen(context);
        },
        child: const Icon(Icons.add_outlined),
      ),
      bottomNavigationBar: selectedInventories.isNotEmpty && !_isShowingActiveInventories
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete_outlined),
                    tooltip: S.of(context).delete,
                    color: Colors.red,
                    onPressed: _deleteSelectedInventories,
                  ),
                  VerticalDivider(),
                  PopupMenuButton<String>(
                    position: PopupMenuPosition.over,
                    onSelected: (String item) {
                      switch (item) {
                        case 'csv':
                          _exportSelectedInventoriesToCsv();
                          break;
                        case 'json':
                          _exportSelectedInventoriesToJson();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        const PopupMenuItem<String>(
                          value: 'csv',
                          child: Text('CSV'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'json',
                          child: Text('JSON'),
                        ),
                      ];
                    },
                    icon: const Icon(Icons.file_download_outlined),
                    tooltip: S.of(context).export(S.of(context).inventory(2)),
                  ),
                ],
              ),
            )
          : null,
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
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(S.of(context).editInventoryId),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showEditIdDialog(context, inventory);
                      },
                    ),
                  if (_isShowingActiveInventories)
                    ListTile(
                      leading: const Icon(Icons.flag_outlined),
                      title: Text(S.of(context).finishInventory),
                      onTap: () {
                        // Ask for user confirmation
                        showFinishDialog(context, inventory);
                      },
                    ),
                  if (!_isShowingActiveInventories)
                    ListTile(
                      leading: const Icon(Icons.undo_outlined),
                      title: Text(S.of(context).reactivateInventory),
                      onTap: () {
                        Navigator.of(context).pop();
                        inventory.updateElapsedTime(0);
                        inventory.updateCurrentInterval(inventory.currentInterval + 1);
                        inventory.currentIntervalSpeciesCount = 0;
                        inventory.intervalsWithoutNewSpecies = 0;
                        inventory.intervalWithoutSpeciesNotifier.value = inventory.intervalsWithoutNewSpecies;
                        inventory.updateIsFinished(false);
                        inventoryProvider.updateInventory(inventory);
                        inventoryProvider.startInventoryTimer(inventory, inventoryRepository);
                        // inventoryProvider.notifyListeners();
                      },
                    ),
                  if (!_isShowingActiveInventories) 
                    Divider(),
                  if (!_isShowingActiveInventories)
                    ExpansionTile(
                        leading: const Icon(Icons.file_download_outlined),
                        title: Text(S.of(context).export(S.of(context).inventory(1))),
                        children: [
                          ListTile(
                            leading: const Icon(Icons.table_chart_outlined),
                            title: const Text('CSV'),
                            onTap: () {
                              Navigator.of(context).pop();
                              exportInventoryToCsv(context, inventory, true);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.data_object_outlined),
                            title: const Text('JSON'),
                            onTap: () {
                              Navigator.of(context).pop();
                              exportInventoryToJson(context, inventory, true);
                            },
                          ),
                        ]
                    ),
                  if (!_isShowingActiveInventories)
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: Text(S.of(context).exportAll(S.of(context).inventory(2))),
                      onTap: () {
                        Navigator.of(context).pop();
                        exportAllInventoriesToJson(context, inventoryProvider);
                      },
                    ),
                  Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outlined, color: Colors.red,),
                    title: Text(S.of(context).deleteInventory, style: TextStyle(color: Colors.red),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(S.of(context).confirmDelete),
                            content: Text(S.of(context).confirmDeleteMessage(1, "male", S.of(context).inventory(1))),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                  Navigator.of(context).pop();
                                },
                                child: Text(S.of(context).cancel),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                  Navigator.of(context).pop();
                                  // Call the function to delete species
                                  inventoryProvider.removeInventory(inventory.id);
                                },
                                child: Text(S.of(context).delete),
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

  void _showEditIdDialog(BuildContext context, Inventory inventory) {
    final idController = TextEditingController(text: inventory.id);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final oldId = inventory.id;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar ID'),
          content: TextField(
            controller: idController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'ID',
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
                var newId = idController.text;
                // Check if the ID already exists in the database
                // final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
                final idExists = await inventoryProvider.inventoryIdExists(newId);

                if (idExists) {
                  // ID already exists, show a SnackBar
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.info_outlined, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(S.of(context).inventoryIdAlreadyExists),
                          ],
                        ),
                      ),
                    );
                  }
                  return; // Prevent adding inventory
                }
                inventoryProvider.changeInventoryId(oldId, newId);
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

  Future<dynamic> showFinishDialog(BuildContext context, Inventory inventory) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirmFinish),
          content: Text(S.of(context).confirmFinishMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                Navigator.of(context).pop();
                // Call the function to delete species
                inventory.stopTimer(inventoryRepository);
                inventoryProvider.updateInventory(inventory);
                // inventoryProvider.notifyListeners();
              },
              child: Text(S.of(context).finish),
            ),
          ],
        );
      },
    );
  }
}

class InventoryGridItem extends StatelessWidget {
  const InventoryGridItem({
    super.key,
    required this.inventory,
    required bool isShowingActiveInventories,
    required this.inventoryRepository,
  }) : _isShowingActiveInventories = isShowingActiveInventories;

  final Inventory inventory;
  final bool _isShowingActiveInventories;
  final InventoryRepository inventoryRepository;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Padding(
                //   padding: const EdgeInsets.fromLTRB(0.0, 16.0, 16.0, 16.0),
                //   child: 
                  if (_isShowingActiveInventories &&
                    inventory.duration > 0) Stack(
                    alignment: Alignment.center,
                    children: [
                      ValueListenableBuilder<double>(
                        valueListenable: inventory.elapsedTimeNotifier,
                        builder: (context, elapsedTime, child) {
                          // if (inventory == null) {
                          //   return const Icon(Icons.error_outlined);
                          // }

                          var progress =
                              (inventory.isPaused || inventory.duration < 0)
                                  ? null
                                  : (elapsedTime / (inventory.duration * 60))
                                      .toDouble();

                          if (progress != null &&
                              (progress.isNaN ||
                                  progress.isInfinite ||
                                  progress < 0 ||
                                  progress > 1)) {
                            progress = 0;
                          }

                          return CircularProgressIndicator(
                            value: progress,
                            backgroundColor: _isShowingActiveInventories &&
                                    inventory.duration > 0
                                ? Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.grey[200]
                                    : Colors.black
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              inventory.isPaused
                                  ? Colors.amber
                                  : Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.deepPurple
                                      : Colors.deepPurpleAccent,
                            ),
                          );
                        },
                      ),
                      if (_isShowingActiveInventories &&
                          inventory.type ==
                              InventoryType.invIntervalQualitative)
                        ValueListenableBuilder<int>(
                            valueListenable: inventory.currentIntervalNotifier,
                            builder: (context, currentInterval, child) {
                              return Text(currentInterval.toString());
                            }),
                    ],
                  ),
                // ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inventory.id,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${inventoryTypeFriendlyNames[inventory.type]}'),
                    if (_isShowingActiveInventories && inventory.duration > 0)
                      Text(S.of(context).inventoryDuration(inventory.duration)),
                    Selector<SpeciesProvider, int>(
                      selector: (context, speciesProvider) => speciesProvider
                          .getSpeciesForInventory(inventory.id)
                          .length,
                      shouldRebuild: (previous, next) => previous != next,
                      builder: (context, speciesCount, child) {
                        return Text(
                            '$speciesCount ${S.of(context).speciesCount(speciesCount)}');
                      },
                    ),
                  ],
                ),
                // Padding(
                //   padding: const EdgeInsets.fromLTRB(0.16, 16.0, 0.0, 16.0),
                //   child: 
                  Row(children: [
                    Visibility(
                      visible: inventory.type ==
                          InventoryType.invIntervalQualitative,
                      child: ValueListenableBuilder<int>(
                          valueListenable:
                              inventory.intervalWithoutSpeciesNotifier,
                          builder: (context, intervalWithoutSpecies, child) {
                            return intervalWithoutSpecies > 0
                                ? Badge.count(count: intervalWithoutSpecies)
                                : SizedBox.shrink();
                          }),
                    ),
                    Visibility(
                      visible:
                          _isShowingActiveInventories && inventory.duration > 0,
                      child: IconButton(
                        icon: Icon(inventory.isPaused
                            ? Theme.of(context).brightness == Brightness.light
                                ? Icons.play_arrow_outlined
                                : Icons.play_arrow
                            : Theme.of(context).brightness == Brightness.light
                                ? Icons.pause_outlined
                                : Icons.pause),
                        tooltip: inventory.isPaused
                            ? S.of(context).resume
                            : S.of(context).pause,
                        onPressed: () {
                          if (inventory.isPaused) {
                            Provider.of<InventoryProvider>(context,
                                    listen: false)
                                .resumeInventoryTimer(
                                    inventory, inventoryRepository);
                          } else {
                            Provider.of<InventoryProvider>(context,
                                    listen: false)
                                .pauseInventoryTimer(
                                    inventory, inventoryRepository);
                          }
                          Provider.of<InventoryProvider>(context, listen: false)
                              .updateInventory(inventory);
                        },
                      ),
                    ),
                  ]),
                // ),
              ],
            ),
          ),
        ],
      ),
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
        leading: Stack(
            alignment: Alignment.center,
            children: [
              ValueListenableBuilder<double>(
                valueListenable: inventory.elapsedTimeNotifier,
                builder: (context, elapsedTime, child) {
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
                        : Colors.black : null,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      inventory.isPaused ? Colors.amber : Theme.of(context).brightness == Brightness.light
                          ? Colors.deepPurple
                          : Colors.deepPurpleAccent,
                    ),
                  );
                },
              ),
              if (!isHistory && inventory.type == InventoryType.invIntervalQualitative)
                ValueListenableBuilder<int>(
                    valueListenable: inventory.currentIntervalNotifier,
                    builder: (context, currentInterval, child) {
                      return Text(currentInterval.toString());
                    }
                )
            ]
        ),
        title: Text(inventory.id),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${inventoryTypeFriendlyNames[inventory.type]}'),
            if (!isHistory && inventory.duration > 0) Text(S.of(context).inventoryDuration(inventory.duration)),
            if (isHistory) Text('${DateFormat('dd/MM/yyyy HH:mm:ss').format(inventory.startTime!)} - ${DateFormat('HH:mm:ss').format(inventory.endTime!)}'),
            Selector<SpeciesProvider, int>(
              selector: (context, speciesProvider) => speciesProvider.getSpeciesForInventory(inventory.id).length,
              shouldRebuild: (previous, next) => previous != next,
              builder: (context, speciesCount, child) {
                return Text('$speciesCount ${S.of(context).speciesCount(speciesCount)}');
              },
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Visibility(
              visible: inventory.type == InventoryType.invIntervalQualitative,
                child: ValueListenableBuilder<int>(
                    valueListenable: inventory.intervalWithoutSpeciesNotifier,
                    builder: (context, intervalWithoutSpecies, child) {
                      return intervalWithoutSpecies > 0 ? Badge.count(count: intervalWithoutSpecies) : SizedBox.shrink();
                    }
                ),
            ),
            Visibility(
              visible: !isHistory && inventory.duration > 0,
              child: IconButton(
                icon: Icon(inventory.isPaused ? Theme.of(context).brightness == Brightness.light
                    ? Icons.play_arrow_outlined
                    : Icons.play_arrow : Theme.of(context).brightness == Brightness.light
                    ? Icons.pause_outlined
                    : Icons.pause),
                tooltip: inventory.isPaused ? S.of(context).resume : S.of(context).pause,
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
            // Visibility(
            //   visible: isHistory,
            //   child: Checkbox(
            //     value: inventory.isSelected,
            //     onChanged: (bool? value) {
            //       setState(() {
            //         if (value == true) {
            //           selectedInventories.add(inventory.id);
            //         } else {
            //           selectedInventories.remove(inventory.id);
            //         }
            //       });
            //     },
            //   ),
            // ),
          ],
        ),
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
              Provider.of<InventoryProvider>(context, listen: false).notifyListeners();
            }
          });
        },
      ),
    );
  }
}