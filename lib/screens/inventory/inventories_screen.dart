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
import 'inventory_report_screen.dart';

import '../../utils/utils.dart';
import '../../utils/export_utils.dart';
import '../../utils/import_utils.dart';
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
  bool _isShowingActiveInventories = true; // Default to show active inventories
  bool _isAscendingOrder = false; // Default to descending order
  String _sortField = 'startTime'; // Default to sort by startTime
  bool _isSearchBarVisible = false; // Default to hide search bar
  String _searchQuery = ''; // Default search query
  Set<String> selectedInventories = {}; // Set of selected inventories

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
            // Restart the timer for active inventories
            inventory.startTimer(inventoryRepository);
          }
        }
      });
    });
    onInventoryStopped = (inventoryId) {
      // When an inventory is stopped, update the inventory list
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

  // Show or hide the search bar
  void _toggleSearchBarVisibility() {
    setState(() {
      _isSearchBarVisible = !_isSearchBarVisible;
    });
  }

  // Toggle the sort order between ascending and descending
  void _toggleSortOrder(String order) {
    setState(() {
      _isAscendingOrder = order == 'ascending';
    });
  }

  // Change the field to sort by
  void _changeSortField(String field) {
    setState(() {
      _sortField = field;
    });
  }

  // Sort the inventories by the selected field and order
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

  // Filter the inventories by the search query
  List<Inventory> _filterInventories(List<Inventory> inventories) {
    if (_searchQuery.isEmpty) {
      return _sortInventories(inventories);
    }
    List<Inventory> filteredInventories = inventories.where((inventory) =>
      inventory.id.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    return _sortInventories(filteredInventories);
  }

  // Show the dialog to add a new inventory
  Future<void> _showAddInventoryScreen(BuildContext context) async {
    // Check if the maximum number of simultaneous inventories has been reached
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
        // Show dialog on large screens
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
        // Show full screen on small screens
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

  // Delete all selected inventories
  void _deleteSelectedInventories() async {
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);

    // Ask for user confirmation
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

  // Export all selected inventories to JSON
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

      // Clear the selected inventories
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

  // Export all selected inventories to CSV
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

      // Clear the selected inventories
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
        leading: MediaQuery.sizeOf(context).width < 600
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_outlined),
                  onPressed: () {
                    widget.scaffoldKey.currentState?.openDrawer();
                  },
                ),
              )
            : SizedBox.shrink(),
        actions: [
          //Action to import inventories from JSON
          // IconButton(
          //   icon: Icon(Icons.file_open_outlined),
          //   onPressed: () async {
          //     await importInventoryFromJson(context);
          //     await inventoryProvider.fetchInventories();
          //   },
          // ),
          // Action to show or hide the search bar
          IconButton(
            icon: Icon(Icons.search_outlined),
            onPressed: _toggleSearchBarVisibility,
          ),
          // Action to show the sort options
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
          IconButton(
            icon: Icon(Icons.more_vert_outlined),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(100, 80, 0, 0),
                items: [
                  PopupMenuItem(
                    value: 'import',
                    child: Row(
                      children: [
                        Icon(Icons.file_open_outlined),
                        SizedBox(width: 8),
                        Text(S.of(context).import),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.file_upload_outlined),
                        SizedBox(width: 8),
                        Text(S.of(context).exportAll),
                      ],
                    ),
                  ),
                ],
              ).then((value) async {
                if (value == 'import') {
                  await importInventoryFromJson(context);
                  await inventoryProvider.fetchInventories();
                } else if (value == 'export') {
                  await exportAllInventoriesToJson(context, inventoryProvider);
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchBarVisible)
            Padding(
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
                      ButtonSegment(
                          value: true, 
                          label: Text(S.of(context).active)
                      ),
                      ButtonSegment(
                          value: false, 
                          label: Text(S.of(context).finished)
                      ),
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
                      child: CircularProgressIndicator()),
                );
              } else if (_isShowingActiveInventories &&
                      inventoryProvider.activeInventories.isEmpty ||
                  !_isShowingActiveInventories &&
                      inventoryProvider.finishedInventories.isEmpty) {
                return Center(
                  child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(S.of(context).noInventoriesFound)),
                );
              } else {
                final filteredInventories = _filterInventories(
                    _isShowingActiveInventories
                        ? inventoryProvider.activeInventories
                        : inventoryProvider.finishedInventories);
                return LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isLargeScreen = screenWidth > 600;

                  // Show the inventories in a grid on large screens
                  if (isLargeScreen) {
                    return SingleChildScrollView(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 840),
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: screenWidth / 3,
                              childAspectRatio: 1,
                            ),
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: filteredInventories.length,
                            itemBuilder: (context, index) {
                              return inventoryGridTileItem(filteredInventories,
                                  index, context, inventoryProvider);
                            },
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Show the inventories in a list on small screens
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredInventories.length,
                      itemBuilder: (context, index) {
                        return inventoryListTileItem(filteredInventories, index,
                            context, inventoryProvider);
                      },
                    );
                  }
                });
              }
            }),
          ))
        ],
      ),
      floatingActionButtonLocation:
          selectedInventories.isNotEmpty && !_isShowingActiveInventories
              ? FloatingActionButtonLocation.endContained
              : FloatingActionButtonLocation.endFloat,
      // FAB to add a new inventory
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).newInventory,
        onPressed: () {
          _showAddInventoryScreen(context);
        },
        child: const Icon(Icons.add_outlined),
      ),
      // Bottom app bar with actions for selected inventories
      bottomNavigationBar: selectedInventories.isNotEmpty && !_isShowingActiveInventories
        ? BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Option to delete all selected inventories
              IconButton(
                icon: Icon(Icons.delete_outlined),
                tooltip: S.of(context).delete,
                color: Colors.red,
                onPressed: _deleteSelectedInventories,
              ),
              VerticalDivider(),
              // Option to export all selected inventories to CSV or JSON
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
                icon: const Icon(Icons.file_upload_outlined),
                tooltip: S.of(context).exportWhat(S.of(context).inventory(2)),
              ),
              // Option to show report species by inventory
              IconButton(
                icon: Icon(Icons.table_view_outlined),
                tooltip: S.current.reportSpeciesByInventory,
                onPressed: () {
                  final inventories = selectedInventories.map((id) => 
                    inventoryProvider.getInventoryById(id)).toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InventoryReportScreen(
                        selectedInventories: inventories.whereType<Inventory>().toList()
                      ),
                    ),
                  );
                },
              ),
              VerticalDivider(),
              // Option to clear the selected inventories
              IconButton(
                icon: Icon(Icons.clear_outlined),
                tooltip: S.current.clearSelection,
                onPressed: () {
                  setState(() {
                    selectedInventories.clear();
                  });
                },
              ),
            ],
          ),
        )
        : null,
    );
  }

  ListTile inventoryListTileItem(List<Inventory> filteredInventories, int index, BuildContext context, InventoryProvider inventoryProvider) {
    final inventory = filteredInventories[index];
    final isSelected = selectedInventories.contains(inventory.id);

    return ListTile(
      // Show progress of the inventory timer
      leading: Stack(alignment: Alignment.center, children: [
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
              backgroundColor:
                _isShowingActiveInventories && inventory.duration > 0
                  ? Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[200]
                    : Colors.black
                  : null,
              valueColor: AlwaysStoppedAnimation<Color>(
                inventory.isPaused
                  ? Colors.amber
                  : Theme.of(context).brightness == Brightness.light
                    ? Colors.deepPurple
                    : Colors.deepPurpleAccent,
              ),
            );
          },
        ),
        // Show current interval for qualitative inventories
        if (_isShowingActiveInventories && inventory.type == InventoryType.invIntervalQualitative)
          ValueListenableBuilder<int>(
            valueListenable: inventory.currentIntervalNotifier,
            builder: (context, currentInterval, child) {
              return Text(currentInterval.toString());
            }
          ),
        // Show checkbox to select inventories if not active
        Visibility(
          visible: !_isShowingActiveInventories,
          child: Checkbox(
            value: isSelected,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  selectedInventories.add(inventory.id);
                } else {
                  selectedInventories.remove(inventory.id);
                }
              });
            },
          ),
        ),
      ]),
      title: Text(inventory.id),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show the inventory type
          Text('${inventoryTypeFriendlyNames[inventory.type]}'),
          // Show the inventory timer duration if active
          if (_isShowingActiveInventories && inventory.duration > 0)
            Text(S.of(context).inventoryDuration(inventory.duration)),
          // Show the date and time of the inventory
          if (!_isShowingActiveInventories)
            Text('${DateFormat('dd/MM/yyyy HH:mm:ss').format(inventory.startTime!)} - ${DateFormat('HH:mm:ss').format(inventory.endTime!)}'),
          // Show the species count
          Selector<SpeciesProvider, int>(
            selector: (context, speciesProvider) =>
              speciesProvider.getSpeciesForInventory(inventory.id).length,
            shouldRebuild: (previous, next) =>
              previous != next,
            builder: (context, speciesCount, child) {
              return Text('$speciesCount ${S.of(context).speciesCount(speciesCount)}');
            },
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show the number of intervals without species for qualitative inventories
          Visibility(
            visible: inventory.type == InventoryType.invIntervalQualitative,
            child: ValueListenableBuilder<int>(
              valueListenable: inventory.intervalWithoutSpeciesNotifier,
              builder: (context, intervalWithoutSpecies, child) {
                return intervalWithoutSpecies > 0
                  ? Badge.count(count: intervalWithoutSpecies)
                  : SizedBox.shrink();
              }
            ),
          ),
          // Show the pause/resume button for active inventories
          Visibility(
            visible: _isShowingActiveInventories && inventory.duration > 0,
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
                  Provider.of<InventoryProvider>(context, listen: false)
                    .resumeInventoryTimer(inventory, inventoryRepository);
                } else {
                  Provider.of<InventoryProvider>(context, listen: false)
                    .pauseInventoryTimer(inventory, inventoryRepository);
                }
              },
            ),
          ),
        ],
      ),
      onTap: () {
        // Navigate to the inventory detail screen
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
      onLongPress: () => _showBottomSheet(context, inventory),
    );
  }

  GridTile inventoryGridTileItem(List<Inventory> filteredInventories, int index, BuildContext context, InventoryProvider inventoryProvider) {
    final inventory = filteredInventories[index];
    final isSelected = selectedInventories.contains(inventory.id);

    return GridTile(
      child: InkWell(
        onLongPress: () => _showBottomSheet(context, inventory),
        onTap: () {
          // Navigate to the inventory detail screen
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Show current interval for qualitative inventories
                    Visibility(
                      visible: _isShowingActiveInventories && inventory.type == InventoryType.invIntervalQualitative,
                      child: ValueListenableBuilder<int>(
                        valueListenable: inventory.currentIntervalNotifier,
                        builder: (context, currentInterval, child) {
                          return Text(currentInterval.toString());
                        }
                      ),
                    ),
                    // Show the number of intervals without species for qualitative inventories
                    Visibility(
                      visible: inventory.type == InventoryType.invIntervalQualitative,
                      child: ValueListenableBuilder<int>(
                        valueListenable: inventory.intervalWithoutSpeciesNotifier,
                        builder: (context, intervalWithoutSpecies, child) {
                          return intervalWithoutSpecies > 0
                                ? Badge.count(count: intervalWithoutSpecies)
                                : SizedBox.shrink();
                        }
                      ),
                    ),
                    // Show the pause/resume button for active inventories
                    Visibility(
                      visible: _isShowingActiveInventories && inventory.duration > 0,
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
                            Provider.of<InventoryProvider>(context, listen: false)
                              .resumeInventoryTimer(inventory, inventoryRepository);
                          } else {
                            Provider.of<InventoryProvider>(context, listen: false)
                              .pauseInventoryTimer(inventory, inventoryRepository);
                          }
                          Provider.of<InventoryProvider>(context, listen: false)
                            .updateInventory(inventory);
                        },
                      ),
                    ),
                    // Show checkbox to select inventories if not active
                    if (!_isShowingActiveInventories)
                      Visibility(
                        visible: !_isShowingActiveInventories,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedInventories.add(inventory.id);
                              } else {
                                selectedInventories.remove(inventory.id);
                              }
                            });
                          },
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),
                // Show progress of the inventory timer
                if (_isShowingActiveInventories && inventory.duration > 0)
                  ValueListenableBuilder<double>(
                    valueListenable: inventory.elapsedTimeNotifier,
                    builder: (context, elapsedTime, child) {
                      var progress = (inventory.isPaused || inventory.duration < 0)
                        ? null
                        : (elapsedTime / (inventory.duration * 60)).toDouble();
    
                      if (progress != null &&
                          (progress.isNaN ||
                          progress.isInfinite ||
                          progress < 0 ||
                          progress > 1)) {
                        progress = 0;
                      }
    
                      return LinearProgressIndicator(
                        value: progress,
                        backgroundColor: _isShowingActiveInventories && inventory.duration > 0
                          ? Theme.of(context).brightness == Brightness.light
                            ? Colors.grey[200]
                            : Colors.black
                          : null,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          inventory.isPaused
                          ? Colors.amber
                          : Theme.of(context).brightness == Brightness.light
                            ? Colors.deepPurple
                            : Colors.deepPurpleAccent,
                        ),
                      );
                    },
                  ),
                SizedBox(height: 8),                                            
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Show the inventory ID
                  Text(inventory.id, style: const TextStyle(fontSize: 16,),),
                  // Show the inventory type
                  Text('${inventoryTypeFriendlyNames[inventory.type]}'),
                  // Show the inventory timer duration if active
                  if (_isShowingActiveInventories && inventory.duration > 0)
                    Text(S.of(context).inventoryDuration(inventory.duration)),
                  // Show the species count
                  Selector<SpeciesProvider, int>(
                    selector: (context, speciesProvider) =>
                      speciesProvider.getSpeciesForInventory(inventory.id).length,
                    shouldRebuild: (previous, next) =>
                      previous != next,
                    builder: (context, speciesCount, child) {
                      return Text(
                        '$speciesCount ${S.of(context).speciesCount(speciesCount)}');
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Option to finish the inventory
                Visibility(
                  visible: _isShowingActiveInventories,
                  child: Align(
                  alignment: Alignment.bottomRight,
                  child: FilledButton.icon(
                      icon: const Icon(Icons.flag_outlined),
                      label: Text(S.of(context).finishInventory),
                      onPressed: () {
                        // Ask for user confirmation
                        showFinishDialog(context, inventory);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                  // Show the inventory ID
                  ListTile(
                    // leading: const Icon(Icons.info_outlined),
                    title: Text(inventory.id),
                    // subtitle: Text(S.of(context).inventoryId),
                  ),
                  Divider(),
                  // Option to edit the inventory ID
                  ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(S.of(context).editInventoryId),
                      onTap: () {
                        Navigator.of(context).pop();
                        _showEditIdDialog(context, inventory);
                      },
                    ),
                  // Option to finish the active inventory
                  if (_isShowingActiveInventories)
                    ListTile(
                      leading: const Icon(Icons.flag_outlined),
                      title: Text(S.of(context).finishInventory),
                      onTap: () {
                        // Ask for user confirmation
                        showFinishDialog(context, inventory);
                      },
                    ),
                  // Option to reactivate the finished inventory
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
                    ListTile(
                      leading: const Icon(Icons.file_upload_outlined),
                      title: Text(S.of(context).export), 
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,                       
                        children: [
                          // Option to export the selected inventory to CSV
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              exportInventoryToCsv(context, inventory, true);
                            },
                            child: Text('CSV'),
                          ),
                          // Option to export the selected inventory to JSON
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              exportInventoryToJson(context, inventory, true);
                            },
                            child: Text('JSON'),
                          ),
                        ]
                      ),
                    ),
                  Divider(),
                  // Option to delete the inventory
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

  // Show the dialog to edit the inventory ID
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

  // Show the dialog to confirm finishing the inventory
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
