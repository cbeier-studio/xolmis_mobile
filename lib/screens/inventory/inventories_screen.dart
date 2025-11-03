import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../statistics/individuals_count_chart_screen.dart';
import 'edit_inventory_screen.dart';
import 'inventory_detail_screen.dart';
import '../statistics/inventory_report_screen.dart';
import 'add_vegetation_screen.dart';
import 'add_weather_screen.dart';

import '../../utils/utils.dart';
import '../../utils/export_utils.dart';
import '../../utils/import_utils.dart';
import '../../services/inventory_completion_service.dart';
import '../../generated/l10n.dart';
import '../statistics/mackinnon_chart_screen.dart';
import '../statistics/species_count_chart_screen.dart';

enum InventorySortField {
  id,
  startTime,
}

enum SortOrder {
  ascending,
  descending,
}

// Enum for warning dialog actions
enum ConditionalAction { add, ignore, cancelDialog }

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
  bool _isSearchBarVisible = false; // Default to hide search bar
  String _searchQuery = ''; // Default search query
  Set<String> selectedInventories = {}; // Set of selected inventories
  SortOrder _sortOrder = SortOrder.descending; // Default sort order
  InventorySortField _sortField = InventorySortField.startTime; // Default sort field

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
            inventory.startTimer(context, inventoryRepository);
          }
        }
      });
    });
    onInventoryStopped = (inventoryId) {
      // When an inventory is stopped, update the inventory list
      inventoryProvider.fetchInventories(context);
    };
  }

  @override
  void dispose() {
    onInventoryStopped = null;
    super.dispose();
  }

  // void _onInventoryPausedOrResumed(Inventory inventory) {
  //   inventoryProvider.updateInventory(inventory);
  // }

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
  void _setSortOrder(SortOrder order) {
    setState(() {
      _sortOrder = order;
    });
  }

  // Change the field to sort by
  void _setSortField(InventorySortField field) {
    setState(() {
      _sortField = field;
    });
  }

  // Sort the inventories by the selected field and order
  List<Inventory> _sortInventories(List<Inventory> inventories) {
    inventories.sort((a, b) {
      int comparison;
      switch (_sortField) {
        case InventorySortField.id:
          comparison = a.id.compareTo(b.id);
          break;
        case InventorySortField.startTime:
          comparison = a.startTime!.compareTo(b.startTime!);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    return inventories;
  }

  // Filter the inventories by the search query
  List<Inventory> _filterInventories(List<Inventory> inventories) {
    if (_searchQuery.isEmpty) {
      return _sortInventories(inventories);
    }
    List<Inventory> filteredInventories = inventories.where((inventory) =>
      inventory.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      inventory.localityName!.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
    return _sortInventories(filteredInventories);
  }

  // Show the dialog to add a new inventory
  Future<void> _showAddInventoryScreen(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final String observerAbbreviation = prefs.getString('observerAcronym') ?? '';

    if (observerAbbreviation.isEmpty) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog.adaptive(
              title: Text(S.of(context).warningTitle),
              content: Text(S.of(context).observerAbbreviationMissing),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).ok),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
      return;
    }

    // Check if the maximum number of simultaneous inventories has been reached
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
        return AlertDialog.adaptive(
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
  void _exportSelectedInventoriesToJson(BuildContext context) async {
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
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/json')],
          text: S.current.inventoryExported(2), 
          subject: S.current.inventoryData(2)
        )
      );

      // Clear the selected inventories
      setState(() {
        selectedInventories.clear();
      });
    } catch (error) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outlined, color: Colors.red),
                const SizedBox(width: 10),
                Text(S.current.errorTitle),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                S.current.errorExportingInventory(2, error.toString()),
              ),
            ),
            actions: [
              TextButton(
                child: Text(S.of(context).ok),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }

  // Export all selected inventories to CSV
  void _exportSelectedInventoriesToCsv(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text(S.current.exportingPleaseWait),
              ],
            ),
          ),
        );
      },
    );
    try {
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      final inventories = selectedInventories.map((id) => inventoryProvider.getInventoryById(id)).toList();
      final locale = Localizations.localeOf(context);
      List<XFile> csvFiles = [];

      if (inventories.isNotEmpty) {
        for (final inventory in inventories) {
          final filePath = await exportInventoryToCsv(context, inventory!, locale);
          
          csvFiles.add(XFile(filePath, mimeType: 'text/csv'));
        }
      }

      // Share the file using share_plus
      await SharePlus.instance.share(
        ShareParams(
          files: csvFiles, 
          text: S.current.inventoryExported(2), 
          subject: S.current.inventoryData(2)
        )
      );

      // Clear the selected inventories
      setState(() {
        selectedInventories.clear();
      });
    } catch (error) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outlined, color: Colors.red),
                const SizedBox(width: 10),
                Text(S.current.errorTitle),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(S.current.errorExportingInventory(2, error.toString())),
            ),
            actions: [
              TextButton(
                child: Text(S.of(context).ok),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss the loading dialog
      }
    }
  }

  // Export all selected inventories to Excel
  void _exportSelectedInventoriesToExcel(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text(S.current.exportingPleaseWait),
              ],
            ),
          ),
        );
      },
    );
    try {
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      final inventories = selectedInventories.map((id) => inventoryProvider.getInventoryById(id)).toList();
      final locale = Localizations.localeOf(context);
      List<XFile> excelFiles = [];

      if (inventories.isNotEmpty) {
        for (final inventory in inventories) {
          // 1. Create a list of data
          final filePath = await exportInventoryToExcel(context, inventory!, locale);

          excelFiles.add(XFile(filePath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'));
        }
      }

      // Share the file using share_plus
      await SharePlus.instance.share(
        ShareParams(
          files: excelFiles, 
          text: S.current.inventoryExported(2), 
          subject: S.current.inventoryData(2)
        )
      );

      // Clear the selected inventories
      setState(() {
        selectedInventories.clear();
      });
    } catch (error) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outlined, color: Colors.red),
                const SizedBox(width: 10),
                Text(S.current.errorTitle),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                S.current.errorExportingInventory(2, error.toString()),
              ),
            ),
            actions: [
              TextButton(
                child: Text(S.of(context).ok),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss the loading dialog
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SearchBar(
          controller: _searchController,
          hintText: S.of(context).inventories,
          elevation: WidgetStateProperty.all(0),
          // leading: const Icon(Icons.search_outlined),
          trailing: [
            MenuAnchor(
              builder: (context, controller, child) {
                return IconButton(
                  icon: Icon(Icons.sort_outlined),
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
                  leadingIcon: Icon(Icons.schedule_outlined),
                  trailingIcon: _sortField == InventorySortField.startTime
                      ? Icon(Icons.check_outlined)
                      : null,
                  onPressed: () {
                    _setSortField(InventorySortField.startTime);
                  },
                  child: Text(S.of(context).sortByTime),
                ),
                MenuItemButton(
                  leadingIcon: Icon(Icons.sort_by_alpha_outlined),
                  trailingIcon: _sortField == InventorySortField.id
                      ? Icon(Icons.check_outlined)
                      : null,
                  onPressed: () {
                    _setSortField(InventorySortField.id);
                  },
                  child: Text(S.of(context).sortByName),
                ),
                Divider(),
                MenuItemButton(
                  leadingIcon: Icon(Icons.south_outlined),
                  trailingIcon: _sortOrder == SortOrder.ascending
                      ? Icon(Icons.check_outlined)
                      : null,
                  onPressed: () {
                    _setSortOrder(SortOrder.ascending);
                  },
                  child: Text(S.of(context).sortAscending),
                ),
                MenuItemButton(
                  leadingIcon: Icon(Icons.north_outlined),
                  trailingIcon: _sortOrder == SortOrder.descending
                      ? Icon(Icons.check_outlined)
                      : null,
                  onPressed: () {
                    _setSortOrder(SortOrder.descending);
                  },
                  child: Text(S.of(context).sortDescending),
                ),
              ],
            ),
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
        // title: Text(S.of(context).inventories),
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
          // Action to show or hide the search bar
          // IconButton(
          //   icon: Icon(Icons.search_outlined),
          //   selectedIcon: Icon(Icons.search_off_outlined),
          //   isSelected: _isSearchBarVisible,
          //   onPressed: _toggleSearchBarVisibility,
          // ),
          // Action to show the sort options
          // MenuAnchor(
          //   builder: (context, controller, child) {
          //     return IconButton(
          //       icon: Icon(Icons.sort_outlined),
          //       onPressed: () {
          //         if (controller.isOpen) {
          //           controller.close();
          //         } else {
          //           controller.open();
          //         }
          //       },
          //     );
          //   },
          //   menuChildren: [
          //     MenuItemButton(
          //       leadingIcon: Icon(Icons.schedule_outlined),
          //       trailingIcon: _sortField == InventorySortField.startTime
          //           ? Icon(Icons.check_outlined)
          //           : null,
          //       onPressed: () {
          //         _setSortField(InventorySortField.startTime);
          //       },
          //       child: Text(S.of(context).sortByTime),
          //     ),
          //     MenuItemButton(
          //       leadingIcon: Icon(Icons.sort_by_alpha_outlined),
          //       trailingIcon: _sortField == InventorySortField.id
          //           ? Icon(Icons.check_outlined)
          //           : null,
          //       onPressed: () {
          //         _setSortField(InventorySortField.id);
          //       },
          //       child: Text(S.of(context).sortByName),
          //     ),
          //     Divider(),
          //     MenuItemButton(
          //       leadingIcon: Icon(Icons.south_outlined),
          //       trailingIcon: _sortOrder == SortOrder.ascending
          //           ? Icon(Icons.check_outlined)
          //           : null,
          //       onPressed: () {
          //         _setSortOrder(SortOrder.ascending);
          //       },
          //       child: Text(S.of(context).sortAscending),
          //     ),
          //     MenuItemButton(
          //       leadingIcon: Icon(Icons.north_outlined),
          //       trailingIcon: _sortOrder == SortOrder.descending
          //           ? Icon(Icons.check_outlined)
          //           : null,
          //       onPressed: () {
          //         _setSortOrder(SortOrder.descending);
          //       },
          //       child: Text(S.of(context).sortDescending),
          //     ),
          //   ],
          // ),
          MenuAnchor(
            builder: (context, controller, child) {
              return IconButton(
                icon: Icon(Icons.more_vert_outlined),
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
              // Action to select all inventories
              if (!_isShowingActiveInventories)
                MenuItemButton(
                  leadingIcon: Icon(Icons.library_add_check_outlined),
                  onPressed: () {
                    final filteredInventories = _filterInventories(inventoryProvider.finishedInventories);
                    setState(() {
                      selectedInventories = filteredInventories
                          .map((inventory) => inventory.id)
                          .toSet();
                    });
                  },
                  child: Text(S.of(context).selectAll),
                ),
              // Action to import inventories from JSON
              MenuItemButton(
                leadingIcon: Icon(Icons.file_open_outlined),
                onPressed: () async {
                  await importInventoryFromJson(context);
                  await inventoryProvider.fetchInventories(context);
                },
                child: Text(S.of(context).import),
              ),
              // Action to export all finished inventories to JSON
              MenuItemButton(
                leadingIcon: Icon(Icons.share_outlined),
                onPressed: () async {
                  await exportAllInventoriesToJson(context, inventoryProvider);
                },
                child: Text(S.of(context).exportAll),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // if (_isSearchBarVisible)
          //   Padding(
          //     padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
          //     child: SearchBar(
          //       controller: _searchController,
          //       hintText: S.of(context).findInventories,
          //       elevation: WidgetStateProperty.all(2),
          //       leading: const Icon(Icons.search_outlined),
          //       trailing: [
          //         _searchController.text.isNotEmpty
          //             ? IconButton(
          //                 icon: const Icon(Icons.clear_outlined),
          //                 onPressed: () {
          //                   setState(() {
          //                     _searchQuery = '';
          //                     _searchController.clear();
          //                   });
          //                 },
          //               )
          //             : SizedBox.shrink(),
          //       ],
          //       onChanged: (query) {
          //         setState(() {
          //           _searchQuery = query;
          //         });
          //       },
          //     ),
          //   ),
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
              await inventoryProvider.fetchInventories(context);
            },
            child: Consumer<InventoryProvider>(
                builder: (context, inventoryProvider, child) {
              if (inventoryProvider.isLoading) {
                return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(year2023: false,)),
                );
              } else if (_isShowingActiveInventories &&
                      inventoryProvider.activeInventories.isEmpty ||
                  !_isShowingActiveInventories &&
                      inventoryProvider.finishedInventories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(S.of(context).noInventoriesFound),
                      SizedBox(height: 8),
                      IconButton.filled(
                        icon: Icon(Icons.refresh_outlined),
                        onPressed: () async {
                          await inventoryProvider.fetchInventories(context);
                        }, 
                      )
                    ],
                  ),
                );
              } else {
                final filteredInventories = _filterInventories(
                    _isShowingActiveInventories
                        ? inventoryProvider.activeInventories
                        : inventoryProvider.finishedInventories);
                return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
                child: Text(
                  '${filteredInventories.length} ${S.of(context).inventory(filteredInventories.length)}',
                  // style: TextStyle(fontSize: 16,),
                ),
              ),
              Expanded(
                child: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isLargeScreen = screenWidth > 600;

                  // Show the inventories in a grid on large screens
                  if (isLargeScreen) {
                    final double minWidth = 300; // Minimum width for each grid tile
                    int crossAxisCount = (constraints.maxWidth / minWidth).floor();

                    return SingleChildScrollView(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 840),
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
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
                    return ListView.separated(
                      separatorBuilder: (context, index) => Divider(),
                      shrinkWrap: true,
                      itemCount: filteredInventories.length,
                      itemBuilder: (context, index) {
                        return inventoryListTileItem(filteredInventories, index,
                            context, inventoryProvider);
                      },
                    );
                  }
                }),
              ),
            ],
                );
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
                  MenuAnchor(
                    builder: (context, controller, child) {
                      return IconButton(
                        icon: Icon(Icons.share_outlined),
                        tooltip: S
                            .of(context)
                            .exportWhat(S.of(context).inventory(2)),
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
                          _exportSelectedInventoriesToCsv(context);
                        },
                        child: Text('CSV'),
                      ),
                      MenuItemButton(
                        onPressed: () {
                          _exportSelectedInventoriesToExcel(context);
                        },
                        child: Text('Excel'),
                      ),
                      MenuItemButton(
                        onPressed: () {
                          _exportSelectedInventoriesToJson(context);
                        },
                        child: Text('JSON'),
                      ),
                    ],
                  ),
                  MenuAnchor(
                    builder: (context, controller, child) {
                      return IconButton(
                        icon: Icon(Icons.more_vert_outlined),
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
                          final inventories = selectedInventories
                              .map((id) =>
                                  inventoryProvider.getInventoryById(id))
                              .toList();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InventoryReportScreen(
                                selectedInventories:
                                    inventories.whereType<Inventory>().toList(),
                              ),
                            ),
                          );
                        },
                        leadingIcon: const Icon(Icons.table_view_outlined),
                        child: Text(S.current.reportSpeciesByInventory),
                      ),
                      MenuItemButton(
                        onPressed: () {
                          final inventories = selectedInventories
                              .map((id) =>
                                  inventoryProvider.getInventoryById(id))
                              .toList();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MackinnonChartScreen(
                                selectedInventories:
                                    inventories.whereType<Inventory>().toList(),
                              ),
                            ),
                          );
                        },
                        leadingIcon: const Icon(Icons.show_chart_outlined),
                        child: Text(S.current.speciesAccumulationCurve),
                      ),
                      MenuItemButton(
                        onPressed: () {
                          final inventories = selectedInventories
                              .map((id) =>
                                  inventoryProvider.getInventoryById(id))
                              .toList();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SpeciesCountChartScreen(
                                selectedInventories:
                                    inventories.whereType<Inventory>().toList(),
                              ),
                            ),
                          );
                        },
                        leadingIcon: const Icon(Icons.bar_chart_outlined),
                        child: Text(S.current.speciesCounted),
                      ),
                      // MenuItemButton(
                      //   onPressed: () {
                      //     final inventories = selectedInventories
                      //         .map((id) =>
                      //             inventoryProvider.getInventoryById(id))
                      //         .toList();
                      //     Navigator.push(
                      //       context,
                      //       MaterialPageRoute(
                      //         builder: (context) => IndividualsCountChartScreen(
                      //           selectedInventories:
                      //               inventories.whereType<Inventory>().toList(),
                      //         ),
                      //       ),
                      //     );
                      //   },
                      //   leadingIcon: const Icon(Icons.bar_chart_outlined),
                      //   child: Text(S.current.individualsCounted),
                      // ),
                    ],
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
        if (_isShowingActiveInventories && inventory.duration == 0)
          const SizedBox(width: 47,),
        if (_isShowingActiveInventories && inventory.duration > 0)
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
              year2023: false,
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
          child: Checkbox.adaptive(
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
          Text('${inventoryTypeFriendlyNames[inventory.type]}', overflow: TextOverflow.ellipsis,),
          // Show the inventory locality
          if (inventory.localityName != null && inventory.localityName!.isNotEmpty)
            Text(inventory.localityName!, overflow: TextOverflow.ellipsis,),
          // Show the inventory timer duration if active
          if (_isShowingActiveInventories && inventory.duration > 0)
            Text(S.of(context).inventoryDuration(inventory.duration)),
          // Show the date and time of the inventory
          if (!_isShowingActiveInventories)
            Text('${DateFormat('dd/MM/yyyy HH:mm:ss').format(inventory.startTime!)} - ${DateFormat('HH:mm:ss').format(inventory.endTime!)}'),
          // Show the species count
          Selector<SpeciesProvider, Map<String, int>>(
            selector: (context, speciesProvider) {
              final speciesList = speciesProvider.getSpeciesForInventory(inventory.id);
              int speciesWithinCount = 0;
              int speciesOutOfCount = 0;

              for (final species in speciesList) {
                if (species.isOutOfInventory) {
                  speciesOutOfCount++;
                } else {
                  speciesWithinCount++;
                }
              }
              return {
                'within': speciesWithinCount,
                'out': speciesOutOfCount,
              };
            },
            shouldRebuild: (previous, next) =>
            previous['within'] != next['within'] || previous['out'] != next['out'],
            builder: (context, speciesCounts, child) {
              final int withinCount = speciesCounts['within'] ?? 0;
              final int outCount = speciesCounts['out'] ?? 0;

              String speciesText = "$withinCount ${S.current.speciesCount(withinCount)}";
              if (outCount > 0) {
                speciesText += " + $outCount ${S.current.outOfSample.toLowerCase()}";
              }

              return Text(speciesText);
            },
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show icon for discarded inventory
          Visibility(
            visible: inventory.isDiscarded,
            child: const Icon(Icons.block),
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
                    .resumeInventoryTimer(context, inventory, inventoryRepository);
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
        child: Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
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
                    Expanded(child: SizedBox.shrink()),
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
                              .resumeInventoryTimer(context, inventory, inventoryRepository);
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
                    Visibility(
                      visible: !_isShowingActiveInventories,
                      child: Checkbox.adaptive(
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
                        year2023: false,
                      );
                    },
                  ),
                Expanded(child: SizedBox.shrink()),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Show the inventory ID
                  Text(inventory.id, style: TextTheme.of(context).bodyLarge, overflow: TextOverflow.ellipsis,),
                  // Show the inventory type
                  Text('${inventoryTypeFriendlyNames[inventory.type]}', overflow: TextOverflow.ellipsis,),
                  // Show the inventory locality
                  if (inventory.localityName != null && inventory.localityName!.isNotEmpty)
                    Text(inventory.localityName!, overflow: TextOverflow.ellipsis,),
                  // Show the inventory timer duration if active
                  if (_isShowingActiveInventories && inventory.duration > 0)
                    Text(S.of(context).inventoryDuration(inventory.duration), overflow: TextOverflow.ellipsis,),
                  // Show the date and time of the inventory
                  if (!_isShowingActiveInventories)
                    Text('${DateFormat('dd/MM/yyyy HH:mm:ss').format(inventory.startTime!)} - ${DateFormat('HH:mm:ss').format(inventory.endTime!)}',
                      overflow: TextOverflow.ellipsis,),
                  // Show the species count
                  Selector<SpeciesProvider, int>(
                    selector: (context, speciesProvider) =>
                      speciesProvider.getSpeciesForInventory(inventory.id).length,
                    shouldRebuild: (previous, next) =>
                      previous != next,
                    builder: (context, speciesCount, child) {
                      return Text(
                        '$speciesCount ${S.of(context).speciesCount(speciesCount)}', overflow: TextOverflow.ellipsis,);
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Option to finish the inventory
                      Visibility(
                        visible: _isShowingActiveInventories,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.flag_outlined),
                            label: Text(S.of(context).finish),
                            onPressed: () async {
                              // Ask for user confirmation
                              // showFinishDialog(context, inventory);
                              final completionService = InventoryCompletionService(
                                context: context,
                                inventory: inventory,
                                inventoryProvider: inventoryProvider,
                                inventoryRepository: inventoryRepository,
                              );
                              await completionService.attemptFinishInventory(context);
                            },
                          ),
                        ),
                      ),
                // Visibility(
                //   visible: !_isShowingActiveInventories,
                //   child: Align(
                //   alignment: Alignment.bottomRight,
                //   child: TextButton(
                //       child: Text(S.of(context).reactivateInventory),
                //       onPressed: () {
                //         Navigator.of(context).pop();
                //         inventory.updateElapsedTime(0);
                //         inventory.updateCurrentInterval(inventory.currentInterval + 1);
                //         inventory.currentIntervalSpeciesCount = 0;
                //         inventory.intervalsWithoutNewSpecies = 0;
                //         inventory.intervalWithoutSpeciesNotifier.value = inventory.intervalsWithoutNewSpecies;
                //         inventory.updateIsFinished(false);
                //         inventoryProvider.updateInventory(inventory);
                //         inventoryProvider.startInventoryTimer(inventory, inventoryRepository);
                //         // inventoryProvider.notifyListeners();
                //       },
                //     ),
                //   ),
                // ),
                    ],
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
        return SafeArea(
        child: BottomSheet(
          onClosing: () {},
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Show the inventory ID
                  ListTile(
                    // leading: const Icon(Icons.info_outlined),
                    title: Text(inventory.id),
                    // subtitle: Text(S.of(context).inventoryId),
                  ),
                  Divider(),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      // buildGridMenuItem(
                      //     context, Icons.edit_outlined, '${S.current.edit} ID', () {
                      //   Navigator.of(context).pop();
                      //   _showEditIdDialog(context, inventory);
                      // }),
                      buildGridMenuItem(context, Icons.edit_outlined,
                          S.current.edit, () async {
                            Navigator.of(context).pop();
                            // _showEditDetailsDialog(context, inventory);
                            // final speciesProvider = Provider.of<SpeciesProvider>(
                            //     context, listen: false);
                            final editedInventory = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditInventoryScreen(inventory: inventory),
                              ),
                            );
                            if (editedInventory != null && editedInventory is Inventory) {
                              if (inventory.id != editedInventory.id) {
                                final idExists = await inventoryProvider.inventoryIdExists(editedInventory.id);

                                if (idExists) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.error_outline, color: Colors.orange),
                                            const SizedBox(width: 8),
                                            Text(S.of(context).inventoryIdAlreadyExists),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return;
                                }

                                try {
                                  await inventoryProvider.changeInventoryId(context, inventory.id, editedInventory.id);

                                  // If successful, close the dialog
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('ID do inventário atualizado com sucesso!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // If an error occurs, show a message
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Update ID failed: $e'),
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              }

                              await inventoryProvider.updateInventory(editedInventory);
                            }
                          }),
                      if (_isShowingActiveInventories)
                        buildGridMenuItem(
                            context, Icons.flag_outlined, S.of(context).finish,
                            () async {
                              Navigator.of(context).pop();
                          final completionService = InventoryCompletionService(
                            context: context,
                            inventory: inventory,
                            inventoryProvider: inventoryProvider,
                            inventoryRepository: inventoryRepository,
                          );
                          await completionService.attemptFinishInventory(context);
                        }),
                      if (!_isShowingActiveInventories)
                        buildGridMenuItem(context, Icons.undo_outlined,
                            S.of(context).reactivate, () {
                          Navigator.of(context).pop();
                          inventory.updateElapsedTime(0);
                          inventory.updateCurrentInterval(
                              inventory.currentInterval + 1);
                          inventory.currentIntervalSpeciesCount = 0;
                          inventory.intervalsWithoutNewSpecies = 0;
                          inventory.intervalWithoutSpeciesNotifier.value =
                              inventory.intervalsWithoutNewSpecies;
                          inventory.updateIsFinished(false);
                          inventoryProvider.updateInventory(inventory);
                          inventoryProvider.startInventoryTimer(
                              context, inventory, inventoryRepository);
                        }),
                      buildGridMenuItem(context, Icons.delete_outlined,
                          S.of(context).delete, () {
                            Navigator.of(context).pop();
                            // Ask for user confirmation
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog.adaptive(
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
                          }, color: Theme.of(context).colorScheme.error),
                      // if (!_isShowingActiveInventories)
                      // buildGridMenuItem(
                      //     context, Icons.share_outlined, 'CSV',
                      //     () async {
                      //   Navigator.of(context).pop();
                      //   final locale = Localizations.localeOf(context);
                      //   final csvFile = await exportInventoryToCsv(context, inventory, locale);
                      //   // Share the file using share_plus
                      //   await SharePlus.instance.share(
                      //     ShareParams(
                      //         files: [XFile(csvFile, mimeType: 'text/csv')],
                      //         text: S.current.inventoryExported(1),
                      //         subject: S.current.inventoryData(1)
                      //     ),
                      //   );
                      // }),
                      // if (!_isShowingActiveInventories)
                      // buildGridMenuItem(
                      //     context, Icons.share_outlined, 'Excel',
                      //     () async {
                      //   Navigator.of(context).pop();
                      //   final locale = Localizations.localeOf(context);
                      //   final excelFile = await exportInventoryToExcel(context, inventory, locale);
                      //   // Share the file using share_plus
                      //   await SharePlus.instance.share(
                      //     ShareParams(
                      //         files: [XFile(excelFile, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
                      //         text: S.current.inventoryExported(1),
                      //         subject: S.current.inventoryData(1)
                      //     ),
                      //   );
                      // }),
                      // if (!_isShowingActiveInventories)
                      // buildGridMenuItem(
                      //     context, Icons.share_outlined, 'JSON',
                      //     () {
                      //   Navigator.of(context).pop();
                      //   exportInventoryToJson(context, inventory, true);
                      // }),
                      // if (!_isShowingActiveInventories)
                      // buildGridMenuItem(context, Icons.share_outlined,
                      //     'KML', () {
                      //       Navigator.of(context).pop();
                      //       exportInventoryToKml(context, inventory);
                      // }),

                    ],
                  ),
                  Divider(),
                  Row(
                    children: [
                      const SizedBox(width: 8.0),
                      Text(S.current.export, style: TextTheme
                          .of(context)
                          .bodyMedium,),
                      // Icon(Icons.share_outlined),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child:
                          Row(
                            children: [
                              const SizedBox(width: 16.0),
                              ActionChip(
                                label: Text('CSV'),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  final locale = Localizations.localeOf(
                                      context);
                                  final csvFile = await exportInventoryToCsv(
                                      context, inventory, locale);
                                  // Share the file using share_plus
                                  await SharePlus.instance.share(
                                    ShareParams(
                                        files: [
                                          XFile(csvFile, mimeType: 'text/csv')
                                        ],
                                        text: S.current.inventoryExported(1),
                                        subject: S.current.inventoryData(1)
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8.0),
                              ActionChip(
                                label: Text('Excel'),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  final locale = Localizations.localeOf(
                                      context);
                                  final excelFile = await exportInventoryToExcel(
                                      context, inventory, locale);
                                  // Share the file using share_plus
                                  await SharePlus.instance.share(
                                    ShareParams(
                                        files: [
                                          XFile(excelFile,
                                              mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
                                        ],
                                        text: S.current.inventoryExported(1),
                                        subject: S.current.inventoryData(1)
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8.0),
                              ActionChip(
                                label: Text('JSON'),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  exportInventoryToJson(
                                      context, inventory, true);
                                },
                              ),
                              const SizedBox(width: 8.0),
                              ActionChip(
                                label: Text('KML'),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  exportInventoryToKml(context, inventory);
                                },
                              ),
                              const SizedBox(width: 8.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  /*
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(S.current.edit),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showEditIdDialog(context, inventory);
                          },
                          child: Text('ID'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showEditDetailsDialog(context, inventory);
                          },
                          child: Text(S.current.details),
                        ),
                      ],
                    ),
                  ),

                  if (_isShowingActiveInventories)
                    ListTile(
                      leading: const Icon(Icons.flag_outlined),
                      title: Text(S.of(context).finishInventory),
                      onTap: () async {
                        // Ask for user confirmation
                        // showFinishDialog(context, inventory);
                        final completionService = InventoryCompletionService(
                          context: context,
                          inventory: inventory,
                          inventoryProvider: inventoryProvider,
                          inventoryRepository: inventoryRepository,
                        );
                        await completionService.attemptFinishInventory(context);
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
                        inventoryProvider.startInventoryTimer(context, inventory, inventoryRepository);
                        // inventoryProvider.notifyListeners();
                      },
                    ),

                  if (!_isShowingActiveInventories)
                    ListTile(
                      leading: const Icon(Icons.file_upload_outlined),
                      title: Text(S.of(context).export), 
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,                       
                        children: [
                          // Option to export the selected inventory to CSV
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              final locale = Localizations.localeOf(context);
                              final csvFile = await exportInventoryToCsv(context, inventory, locale);
                              // Share the file using share_plus
                              await SharePlus.instance.share(
                                ShareParams(
                                  files: [XFile(csvFile, mimeType: 'text/csv')], 
                                  text: S.current.inventoryExported(1), 
                                  subject: S.current.inventoryData(1)
                                ),
                              );
                            },
                            child: Text('CSV'),
                          ),
                          // Option to export the selected inventory to Excel
                          TextButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              final locale = Localizations.localeOf(context);
                              final excelFile = await exportInventoryToExcel(context, inventory, locale);
                              // Share the file using share_plus
                              await SharePlus.instance.share(
                                ShareParams(
                                  files: [XFile(excelFile, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')], 
                                  text: S.current.inventoryExported(1), 
                                  subject: S.current.inventoryData(1)
                                ),
                              );
                            },
                            child: Text('Excel'),
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
                  if (!_isShowingActiveInventories)
                    ListTile(
                      leading: const Icon(Icons.file_upload_outlined),
                      title: Text(S.of(context).exportKml),
                      onTap: () {
                        Navigator.of(context).pop();
                        exportInventoryToKml(context, inventory);
                      },
                    ),

                  ListTile(
                    leading: Icon(Icons.delete_outlined, color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red
                        : Colors.redAccent,),
                    title: Text(S.of(context).deleteInventory, style: TextStyle(color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red
                        : Colors.redAccent,),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog.adaptive(
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
                  */
                ],
              ),
            );
          },
        ),
        );
      },
    );
  }
}
