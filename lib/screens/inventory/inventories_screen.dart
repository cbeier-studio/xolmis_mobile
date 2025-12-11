import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/inventory.dart';
import '../../data/daos/inventory_dao.dart';
import '../../data/daos/species_dao.dart';
import '../../data/daos/poi_dao.dart';
import '../../data/daos/vegetation_dao.dart';
import '../../data/daos/weather_dao.dart';

import '../../providers/inventory_provider.dart';
import '../../providers/species_provider.dart';

import '../../widgets/timer_progress_indicator.dart';
import 'add_inventory_screen.dart';
import 'edit_inventory_screen.dart';
import 'inventory_detail_screen.dart';
import '../statistics/inventory_report_screen.dart';

import '../../core/core_consts.dart';
import '../../utils/utils.dart';
import '../../utils/export_utils.dart';
import '../../utils/import_utils.dart';
import '../../services/inventory_completion_service.dart';
import '../../generated/l10n.dart';
import '../statistics/mackinnon_chart_screen.dart';
import '../statistics/species_count_chart_screen.dart';

class InventoriesScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const InventoriesScreen({
    super.key,
    required this.scaffoldKey,
  });

  @override
  State<InventoriesScreen> createState() => _InventoriesScreenState();
}

class _InventoriesScreenState extends State<InventoriesScreen> with WidgetsBindingObserver {
  late InventoryProvider inventoryProvider;
  late InventoryDao inventoryDao;
  late SpeciesDao speciesDao;
  late PoiDao poiDao;
  late VegetationDao vegetationDao;
  late WeatherDao weatherDao;
  final _searchController = TextEditingController();
  bool _isShowingActiveInventories = true; // Default to show active inventories
  String _searchQuery = ''; // Default search query
  Set<String> selectedInventories = {}; // Set of selected inventories
  SortOrder _sortOrder = SortOrder.descending; // Default sort order
  InventorySortField _sortField = InventorySortField.startTime; // Default sort field
  Inventory? _selectedInventory;

  @override
  void initState() {
    super.initState();
    inventoryProvider = context.read<InventoryProvider>();
    inventoryDao = context.read<InventoryDao>();
    speciesDao = context.read<SpeciesDao>();
    poiDao = context.read<PoiDao>();
    vegetationDao = context.read<VegetationDao>();
    weatherDao = context.read<WeatherDao>();
    _selectedInventory = null;

    // Register the observer to listen to changes in the app state
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration.zero, ()
      {
        // Synchronize and restart the timers when start the screen
        _resumeAllActiveTimers();
      });
    });
    onInventoryStopped = (inventoryId) {
      // When an inventory is stopped, update the inventory list
      inventoryProvider.fetchInventories(context);
    };
  }

  @override
  void dispose() {
    // Remove the observer to avoid memory leaks
    WidgetsBinding.instance.removeObserver(this);
    onInventoryStopped = null;
    super.dispose();
  }

  // Method to handle changes in app state
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // If the app was resumed (came back to foreground)
    if (state == AppLifecycleState.resumed) {
      // Synchronize and restart all active timers
      _resumeAllActiveTimers();
    }
  }

  // Function to synchronize and restart the timers
  void _resumeAllActiveTimers() async { // Tornando a função async
    for (var inventory in inventoryProvider.activeInventories) {
      // Ignore if the inventory is paused or finished
      if (inventory.isPaused || inventory.isFinished) continue;

      // Logic for inventories with intervals (invIntervalQualitative)
      if (inventory.type == InventoryType.invIntervalQualitative) {
        // Ensures that the duration and start time of inventory exist to calculate
        if (inventory.duration > 0 && inventory.startTime != null) {
          final now = DateTime.now();

          // 1. Calculate the total elapsed time since the start of the inventory.
          final totalElapsedTimeInSeconds = now.difference(inventory.startTime!).inSeconds.toDouble();
          final intervalDurationInSeconds = (inventory.duration * 60).toDouble();

          // 2. Determine in which interval the inventory should be now.
          final preciseCurrentInterval = (totalElapsedTimeInSeconds / intervalDurationInSeconds).floor() + 1;

          // 3. Calculate the elapsed time of the CURRENT interval.
          final timeOfCompletedIntervals = (preciseCurrentInterval - 1) * intervalDurationInSeconds;
          final elapsedTimeOfCurrentInterval = totalElapsedTimeInSeconds - timeOfCompletedIntervals;

          // 4. Find the date/time of last added species in the inventory.
          final lastSpeciesTime = await speciesDao.getLastSpeciesTimeByInventory(inventory.id);
          final referenceTimeForNewSpecies = lastSpeciesTime ?? inventory.startTime!;

          // 5. Calculate the elapsed time since the last species added (or inventory start).
          final timeSinceLastNewSpecies = now.difference(referenceTimeForNewSpecies).inSeconds.toDouble();

          // 6. Subtract the time of the current interval to isolate only the time od the completed intervals.
          // This ensures that the current interval is not counted.
          final timeCoveringOnlyPastIntervals = timeSinceLastNewSpecies - elapsedTimeOfCurrentInterval;

          // 7. Calculate how many COMPLETED intervals elapsed since the last species added.
          // We use `max(0, ...)` to avoid negative results if a species will be added in the current interval.
          final preciseIntervalsWithoutNewSpecies = (timeCoveringOnlyPastIntervals / intervalDurationInSeconds).floor().clamp(0, 100);

          // 8. Update the complete state of inventory with recalculated values.
          inventory.updateCurrentInterval(preciseCurrentInterval);
          inventory.updateElapsedTime(elapsedTimeOfCurrentInterval);
          inventory.updateIntervalsWithoutNewSpecies(preciseIntervalsWithoutNewSpecies);

          // Checks if the finishing condition was reached while the app was in background
          if (inventory.intervalsWithoutNewSpecies >= 3) {
            final completionService = InventoryCompletionService(
                context: context,
                inventory: inventory,
                inventoryProvider: inventoryProvider,
                inventoryDao: inventoryDao,
            );
            await completionService.attemptFinishInventory(context);

            continue;
          }
        }

        // Restart the Stream.periodic for the UI
        inventory.startTimer(context, inventoryDao);

        // Logic for other inventories with duration (timer)
      } else if (inventory.duration > 0) {
        if (inventory.startTime != null) {
          // Recalc the total elapsed time to fix the discrepancy
          final now = DateTime.now();
          final preciseElapsedTime = now.difference(inventory.startTime!).inSeconds.toDouble();

          // Update the notifier of total elapsed time
          inventory.updateElapsedTime(preciseElapsedTime);

          // Checks if the finishing condition was reached while the app was in background
          if (inventory.elapsedTime >= (inventory.duration * 60)) {
            final completionService = InventoryCompletionService(
              context: context,
              inventory: inventory,
              inventoryProvider: inventoryProvider,
              inventoryDao: inventoryDao,
            );
            await completionService.attemptFinishInventory(context);

            continue;
          }
        }
        // Restart the Stream.periodic for the UI
        inventory.startTimer(context, inventoryDao);
      }
    }

    // Force the UI to rebuild
    if (mounted) {
      setState(() {});
    }
  }

  void onInventoryUpdated(Inventory inventory) {
    inventoryProvider.updateInventory(inventory);
  }

  // Sort the inventories by the selected field and order
  List<Inventory> _sortInventories(List<Inventory> inventories) {
    inventories.sort((a, b) {
      int comparison;

      // Helper function to handle nulls. Null values are treated as "smaller".
      int compareNullables<T extends Comparable>(T? a, T? b) {
        if (a == null && b == null) return 0; // Both are equal
        if (a == null) return -1; // a is "smaller"
        if (b == null) return 1;  // b is "smaller"
        return a.compareTo(b);
      }

      // Helper function for comparing strings via a map lookup.
      int compareMappedStrings(InventoryType aKey, InventoryType bKey) {
        final aValue = aKey != null ? inventoryTypeFriendlyNames[aKey] : null;
        final bValue = bKey != null ? inventoryTypeFriendlyNames[bKey] : null;
        return compareNullables(aValue, bValue);
      }

      switch (_sortField) {
        case InventorySortField.id:
        // 'id' is non-nullable, so direct comparison is safe.
          comparison = a.id.compareTo(b.id);
          break;
        case InventorySortField.startTime:
          comparison = compareNullables(a.startTime, b.startTime);
          break;
        case InventorySortField.endTime:
          comparison = compareNullables(a.endTime, b.endTime);
          break;
        case InventorySortField.locality:
          comparison = compareNullables(a.localityName, b.localityName);
          break;
        case InventorySortField.inventoryType:
          comparison = compareMappedStrings(a.type, b.type);
          break;
      }

      // Apply the sort order (ascending or descending)
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    return inventories;
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
                        label: Text(S.current.inventoryId),
                        showCheckmark: false,
                        selected: _sortField == InventorySortField.id,
                        onSelected: (bool selected) {
                          setModalState(() {
                            _sortField = InventorySortField.id;
                          });
                          setState(() {
                            _sortField = InventorySortField.id;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(S.current.startTime),
                        showCheckmark: false,
                        selected: _sortField == InventorySortField.startTime,
                        onSelected: (bool selected) {
                          setModalState(() {
                            _sortField = InventorySortField.startTime;
                          });
                          setState(() {
                            _sortField = InventorySortField.startTime;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(S.current.endTime),
                        showCheckmark: false,
                        selected: _sortField == InventorySortField.endTime,
                        onSelected: (bool selected) {
                          setModalState(() {
                            _sortField = InventorySortField.endTime;
                          });
                          setState(() {
                            _sortField = InventorySortField.endTime;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(S.current.locality),
                        showCheckmark: false,
                        selected: _sortField == InventorySortField.locality,
                        onSelected: (bool selected) {
                          setModalState(() {
                            _sortField = InventorySortField.locality;
                          });
                          setState(() {
                            _sortField = InventorySortField.locality;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(S.current.inventoryType),
                        showCheckmark: false,
                        selected: _sortField == InventorySortField.inventoryType,
                        onSelected: (bool selected) {
                          setModalState(() {
                            _sortField = InventorySortField.inventoryType;
                          });
                          setState(() {
                            _sortField = InventorySortField.inventoryType;
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
  Future<void> showAddInventoryScreen(BuildContext context) async {
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSplitScreen = screenWidth >= kTabletBreakpoint;
    final isMenuShown = screenWidth < kDesktopBreakpoint;

    return Scaffold(
      appBar: isSplitScreen == false ? AppBar(
        title: SearchBar(
          controller: _searchController,
          hintText: S.of(context).inventories,
          elevation: WidgetStateProperty.all(0),
          leading: isMenuShown
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_outlined),
                  onPressed: () {
                    widget.scaffoldKey.currentState?.openDrawer();
                  },
                ),
              )
            : const SizedBox.shrink(),
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
                : const SizedBox.shrink(),
            IconButton(
              icon: const Icon(Icons.sort_outlined),
              tooltip: S.of(context).sortBy,
              onPressed: () {
                _showSortOptionsBottomSheet();
              },
            ),
            IconButton(
        icon: const Icon(Icons.more_vert_outlined),
        onPressed: () {
          _showMoreOptionsBottomSheet(context);
        },
      ),
          ],
          onChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
        ),
        // title: Text(S.of(context).inventories),
        
        
      ) : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // On large screens we show a split screen master/detail
          if (isSplitScreen) {
            return Row(
              children: [
                // Left: list (takes 40% width)
                Container(
                  width: constraints.maxWidth * 0.45, // adjust ratio as needed
                  //decoration: BoxDecoration(
                  //  border: Border(
                  //    right: BorderSide(color: Theme.of(context).dividerColor),
                  //  ),
                  //),
                  child: _buildListPane(context, isSplitScreen, isMenuShown),
                ),
                VerticalDivider(),
                // Right: detail pane
                Expanded(
                  child: _buildDetailPane(context),
                ),
              ],
            );
          } else {
            // Small screens: keep current column layout
            return _buildListPane(context, isSplitScreen, isMenuShown);
          }
        },
      ),
      floatingActionButtonLocation:
          selectedInventories.isNotEmpty && !_isShowingActiveInventories
              ? FloatingActionButtonLocation.endContained
              : FloatingActionButtonLocation.endFloat,
      // FAB to add a new inventory
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).newInventory,
        onPressed: () {
          showAddInventoryScreen(context);
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
                    icon: const Icon(Icons.delete_outlined),
                    tooltip: S.of(context).delete,
                    color: Colors.red,
                    onPressed: _deleteSelectedInventories,
                  ),
                  const VerticalDivider(),
                  // Option to export all selected inventories to CSV or JSON
                  MenuAnchor(
                    builder: (context, controller, child) {
                      return IconButton(
                        icon: const Icon(Icons.share_outlined),
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
                        child: const Text('CSV'),
                      ),
                      MenuItemButton(
                        onPressed: () {
                          _exportSelectedInventoriesToExcel(context);
                        },
                        child: const Text('Excel'),
                      ),
                      MenuItemButton(
                        onPressed: () {
                          _exportSelectedInventoriesToJson(context);
                        },
                        child: const Text('JSON'),
                      ),
                    ],
                  ),
                  MenuAnchor(
                    builder: (context, controller, child) {
                      return IconButton(
                        icon: const Icon(Icons.more_vert_outlined),
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
                      if (selectedInventories.length > 1)
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
                      if (selectedInventories.length > 1)
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
                      // if (selectedInventories.length > 1)
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
                  const VerticalDivider(),
                  // Option to clear the selected inventories
                  IconButton(
                    icon: const Icon(Icons.clear_outlined),
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

  Widget _buildListPane(BuildContext context, bool isSplitScreen, bool isMenuShown) {
    return Column(
        children: [
          if (isSplitScreen) const SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
            child: isSplitScreen ? SearchBar(
          controller: _searchController,
          hintText: S.of(context).inventories,
          elevation: WidgetStateProperty.all(0),
              leading: isMenuShown
                  ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_outlined),
                  onPressed: () {
                    widget.scaffoldKey.currentState?.openDrawer();
                  },
                ),
              )
                  : const SizedBox.shrink(),
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
                : const SizedBox.shrink(),
            IconButton(
              icon: const Icon(Icons.sort_outlined),
              tooltip: S.of(context).sortBy,
              onPressed: () {
                _showSortOptionsBottomSheet();
              },
            ),
            MenuAnchor(
            builder: (context, controller, child) {
              return IconButton(
                icon: const Icon(Icons.more_vert_outlined),
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
                  leadingIcon: const Icon(Icons.library_add_check_outlined),
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
                leadingIcon: const Icon(Icons.file_open_outlined),
                onPressed: () async {
                  await importInventoryFromJson(context);
                  await inventoryProvider.fetchInventories(context);
                },
                child: Text(S.of(context).import),
              ),
              // Action to export all finished inventories to JSON
              MenuItemButton(
                leadingIcon: const Icon(Icons.share_outlined),
                onPressed: () async {
                  await exportAllInventoriesToJson(context, inventoryProvider);
                },
                child: Text(S.of(context).exportAll),
              ),
            ],
          ),
          ],
          onChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
        ) : null,
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
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        label: Text(S.of(context).refresh),
                        icon: const Icon(Icons.refresh_outlined),
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
                    return ListView.separated(
                      separatorBuilder: (context, index) => Divider(),
                      shrinkWrap: true,
                      itemCount: filteredInventories.length,
                      itemBuilder: (context, index) {
                        return inventoryListTileItem(filteredInventories, index,
                            context, inventoryProvider);
                      },
                    );
                  
                }),
              ),
            ],
                );
              }
            }),
          ))
        ],
      );
  }

  Widget _buildDetailPane(BuildContext context) {
    if (_selectedInventory == null) {
      // Placeholder when nothing selected
      return Center(
        child: Text(S.of(context).selectInventoryToView),
      );
    }

    // Show InventoryDetailScreen in-place for the selected inventory
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InventoryDetailScreen(
        inventory: _selectedInventory!,
        speciesDao: speciesDao,
        inventoryDao: inventoryDao,
        poiDao: poiDao,
        vegetationDao: vegetationDao,
        weatherDao: weatherDao,
        isEmbedded: true,
      ),
    );
  }

  ListTile inventoryListTileItem(List<Inventory> filteredInventories, int index, BuildContext context, InventoryProvider inventoryProvider) {
    final inventory = filteredInventories[index];
    final isSelected = selectedInventories.contains(inventory.id);
    final isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

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

            return TimerProgressIndicator(
                value: progress,
                isVisible: _isShowingActiveInventories,
                inventory: inventory
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
      subtitle: buildItemSubtitle(inventory, context),
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
                  : const SizedBox.shrink();
              }
            ),
          ),
          // Show the pause/resume button for active inventories
          Visibility(
            visible: _isShowingActiveInventories && inventory.duration > 0,
            child: IconButton(
              icon: Icon(inventory.isPaused
                ? Icons.play_arrow
                : Icons.pause),
              tooltip: inventory.isPaused
                ? S.of(context).resume
                : S.of(context).pause,
              onPressed: () {
                if (inventory.isPaused) {
                  Provider.of<InventoryProvider>(context, listen: false)
                    .resumeInventoryTimer(context, inventory, inventoryDao);
                } else {
                  Provider.of<InventoryProvider>(context, listen: false)
                    .pauseInventoryTimer(inventory, inventoryDao);
                }
              },
            ),
          ),
        ],
      ),
      onTap: () {
        if (isLargeScreen) {
          setState(() {
            _selectedInventory = inventory;
          });
        } else {
        // Navigate to the inventory detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InventoryDetailScreen(
              inventory: inventory,
              speciesDao: speciesDao,
              inventoryDao: inventoryDao,
              poiDao: poiDao,
              vegetationDao: vegetationDao,
              weatherDao: weatherDao,
            ),
          ),
        ).then((result) {
          if (result == true) {
            inventoryProvider.notifyListeners();
          }
        });
      }
      },
      onLongPress: () => _showBottomSheet(context, inventory),
    );
  }

  Column buildItemSubtitle(Inventory inventory, BuildContext context) {
    return Column(
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
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                // crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Show the inventory ID
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(inventory.id, style: TextTheme.of(context).bodyLarge,),
                  ),
                  // ListTile(
                    // leading: const Icon(Icons.info_outlined),
                    // title: Text(inventory.id),
                    // subtitle: Text(S.of(context).inventoryId),
                  // ),
                  const Divider(),

                  GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 4 : 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      buildGridMenuItem(context, Icons.edit_outlined,
                          S.current.edit, () async {
                            Navigator.of(context).pop();
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
                                        content: Text(S.current.inventoryIdUpdated),
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
                            inventoryDao: inventoryDao,
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
                              context, inventory, inventoryDao);
                        }),
                      buildGridMenuItem(context, Icons.delete_outlined,
                          S.of(context).delete, () {
                            Navigator.of(context).pop();
                            // Ask for user confirmation
                            _confirmDelete(context, inventory);
                          }, color: Theme.of(context).colorScheme.error),
                    ],
                  ),
                  // Divider(),
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
                                label: const Text('CSV'),
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
                                label: const Text('Excel'),
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
                                label: const Text('JSON'),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  exportInventoryToJson(
                                      context, inventory, true);
                                },
                              ),
                              const SizedBox(width: 8.0),
                              ActionChip(
                                label: const Text('KML'),
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

  void _confirmDelete(BuildContext context, Inventory inventory) {
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
                // Navigator.of(context).pop();
              },
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                // Navigator.of(context).pop();
                // Call the function to delete species
                inventoryProvider.removeInventory(inventory.id);
              },
              child: Text(S.of(context).delete, style: TextStyle(color: ThemeData().colorScheme.error)),
            ),
          ],
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
                          if (!_isShowingActiveInventories)
                            buildGridMenuItem(
                                context, Icons.library_add_check_outlined, S.of(context).selectAll,
                                    () async {
                                  Navigator.of(context).pop();
                                  final filteredInventories = _filterInventories(inventoryProvider.finishedInventories);
                                  setState(() {
                                    selectedInventories = filteredInventories
                                        .map((inventory) => inventory.id)
                                        .toSet();
                                  });
                                }),
                          // Action to import inventories from JSON
                          buildGridMenuItem(
                              context, Icons.file_open_outlined, S.of(context).import,
                                  () async {
                                
                                await importInventoryFromJson(context);
                                await inventoryProvider.fetchInventories(context);
                                Navigator.of(context).pop();
                              }),
                          // Action to export all finished inventories to JSON
                          // buildGridMenuItem(
                          //     context, Icons.share_outlined, S.of(context).exportAll,
                          //         () async {
                          //       Navigator.of(context).pop();
                          //       await exportAllInventoriesToJson(context, inventoryProvider);
                          //     }),
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          const SizedBox(width: 8.0),
                          Text(S.current.exportAll, style: TextTheme
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
                                    label: const Text('JSON'),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      await exportAllInventoriesToJson(context, inventoryProvider);
                                    },
                                  ),
                                  const SizedBox(width: 8.0),
                                ],
                              ),
                            ),
                          ),
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

