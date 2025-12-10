import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fab_m3e/fab_m3e.dart';

import '../../data/models/inventory.dart';
import '../../data/daos/inventory_dao.dart';
import '../../data/daos/species_dao.dart';
import '../../data/daos/poi_dao.dart';
import '../../data/daos/vegetation_dao.dart';
import '../../data/daos/weather_dao.dart';

import '../../providers/inventory_provider.dart';
import '../../providers/species_provider.dart';
import '../../providers/poi_provider.dart';
import '../../providers/vegetation_provider.dart';
import '../../providers/weather_provider.dart';

import '../../utils/utils.dart';
import 'add_vegetation_screen.dart';
import 'add_weather_screen.dart';
import 'species_tab.dart';
import 'vegetation_tab.dart';
import 'weather_tab.dart';
import '../../core/core_consts.dart';
import '../../utils/export_utils.dart';
import '../../services/inventory_completion_service.dart';
import '../../generated/l10n.dart';

class InventoryDetailScreen extends StatefulWidget {
  final Inventory inventory;
  final SpeciesDao speciesDao;
  final InventoryDao inventoryDao;
  final PoiDao poiDao;
  final VegetationDao vegetationDao;
  final WeatherDao weatherDao;
  final bool isEmbedded;

  const InventoryDetailScreen({
    super.key,
    required this.inventory,
    required this.speciesDao,
    required this.inventoryDao,
    required this.poiDao,
    required this.vegetationDao,
    required this.weatherDao,
    this.isEmbedded = false,
  });

  @override
  InventoryDetailScreenState createState() => InventoryDetailScreenState();
}

class InventoryDetailScreenState extends State<InventoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSubmitting = false;
  final fabController = FabMenuController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Access the providers
    final speciesProvider = Provider.of<SpeciesProvider>(
        context, listen: false);
    final poiProvider = Provider.of<PoiProvider>(context, listen: false);
    final vegetationProvider = Provider.of<VegetationProvider>(
        context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(
        context, listen: false);

    // Load the species for the current inventory
    speciesProvider.loadSpeciesForInventory(widget.inventory.id);
    // Load the vegetation for the current inventory
    vegetationProvider.loadVegetationForInventory(widget.inventory.id);
    // Load the weather for the current inventory
    weatherProvider.loadWeatherForInventory(widget.inventory.id);

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

  void _showAddVegetationScreen(BuildContext context) {
    final vegetationProvider = Provider.of<VegetationProvider>(context, listen: false);
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
                child: AddVegetationDataScreen(inventory: widget.inventory),
            ),
          );
        },
      ).then((newVegetation) async {
        // Reload the vegetation list
        if (newVegetation != null) {
          await vegetationProvider.loadVegetationForInventory(widget.inventory.id);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddVegetationDataScreen(inventory: widget.inventory),
        ),
      ).then((newVegetation) async {
        // Reload the vegetation list
        if (newVegetation != null) {
          await vegetationProvider.loadVegetationForInventory(widget.inventory.id);
        }
      });
    }
  }

  void _showAddWeatherScreen(BuildContext context) {
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
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
              child: AddWeatherScreen(inventory: widget.inventory),
            ),
          );
        },
      ).then((newWeather) {
        // Reload the weather list
        if (newWeather != null) {
          weatherProvider.getWeatherForInventory(widget.inventory.id);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddWeatherScreen(inventory: widget.inventory),
        ),
      ).then((newWeather) {
        // Reload the weather list
        if (newWeather != null) {
          weatherProvider.getWeatherForInventory(widget.inventory.id);
        }
      });
    }
  }

  Widget _buildTopArea(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title + actions row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Row(
            children: [
              Expanded(
                child: Text(widget.inventory.id,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              // Pause/Resume button (only when active)
              if (!widget.inventory.isFinished && widget.inventory.duration > 0)
                Consumer<InventoryProvider>(
                  builder: (context, inventoryProvider, child) {
                    final inventory = widget.inventory;
                    return IconButton(
                      icon: Icon(inventory.isPaused ? Icons.play_arrow_outlined : Icons.pause_outlined),
                      tooltip: inventory.isPaused ? S.of(context).resume : S.of(context).pause,
                      onPressed: () {
                        if (inventory.isPaused) {
                          inventoryProvider.resumeInventoryTimer(context, inventory, widget.inventoryDao);
                        } else {
                          inventoryProvider.pauseInventoryTimer(inventory, widget.inventoryDao);
                        }
                        inventoryProvider.updateInventory(inventory);
                      },
                    );
                  },
                )
              else
                const SizedBox.shrink(),
              IconButton(
                onPressed: () {
                  _showAddVegetationScreen(context);
                }, 
                icon: Icon(Theme.of(context).brightness == Brightness.light ? Icons.local_florist_outlined : Icons.local_florist),
              ),
              IconButton(
                onPressed: () {
                  _showAddWeatherScreen(context);
                }, 
                icon: Icon(Theme.of(context).brightness == Brightness.light ? Icons.wb_sunny_outlined : Icons.wb_sunny),
              ),
              // Finish button
              Visibility(
                visible: !widget.inventory.isFinished,
                child: IconButton.filled(
                  onPressed: () async {
                    setState(() {
                      _isSubmitting = true;
                    });
                    final completionService = InventoryCompletionService(
                      context: context,
                      inventory: widget.inventory,
                      inventoryProvider: Provider.of<InventoryProvider>(context, listen: false),
                      inventoryDao: widget.inventoryDao,
                    );
                    await completionService.attemptFinishInventory(context);
                    if (!widget.isEmbedded) {
                      Navigator.pop(context, true);
                    }
                    setState(() {
                      _isSubmitting = false;
                    });
                  },
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : Colors.deepPurple,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.flag_outlined),
                ),
              ),
              // More / export menu
              Visibility(
                visible: widget.inventory.isFinished,
                child: MediaQuery.sizeOf(context).width < 600
                    ? IconButton(
                        icon: const Icon(Icons.more_vert_outlined),
                        onPressed: () {
                          _showMoreOptionsBottomSheet(context, widget.inventory);
                        },
                      )
                    : MenuAnchor(
                        builder: (context, controller, child) {
                          return IconButton(
                            icon: const Icon(Icons.more_vert_outlined),
                            tooltip: S.of(context).exportWhat(S.of(context).inventory(1)),
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
                            leadingIcon: const Icon(Icons.share_outlined),
                            onPressed: () async {
                              final locale = Localizations.localeOf(context);
                              final csvFile = await exportInventoryToCsv(context, widget.inventory, locale);
                              await SharePlus.instance.share(ShareParams(
                                files: [XFile(csvFile, mimeType: 'text/csv')],
                                text: S.current.inventoryExported(1),
                                subject: S.current.inventoryData(1),
                              ));
                            },
                            child: Text('${S.current.export} CSV'),
                          ),
                          MenuItemButton(
                            leadingIcon: const Icon(Icons.share_outlined),
                            onPressed: () async {
                              final locale = Localizations.localeOf(context);
                              final excelFile = await exportInventoryToExcel(context, widget.inventory, locale);
                              await SharePlus.instance.share(ShareParams(
                                files: [XFile(excelFile, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
                                text: S.current.inventoryExported(1),
                                subject: S.current.inventoryData(1),
                              ));
                            },
                            child: Text('${S.current.export} Excel'),
                          ),
                          MenuItemButton(
                            leadingIcon: const Icon(Icons.share_outlined),
                            onPressed: () {
                              exportInventoryToJson(context, widget.inventory, true);
                            },
                            child: Text('${S.current.export} JSON'),
                          ),
                          MenuItemButton(
                            leadingIcon: const Icon(Icons.share_outlined),
                            onPressed: () {
                              exportInventoryToKml(context, widget.inventory);
                            },
                            child: Text('${S.current.export} KML'),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
        // Inventory summary row (type, duration, max species)
        if (!widget.isEmbedded)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${inventoryTypeFriendlyNames[widget.inventory.type]}'),
            if (widget.inventory.duration > 0) ...[
              // const SizedBox(width: 8.0),
              Text(': ${widget.inventory.duration} ${S.of(context).minutes(widget.inventory.duration)}'),
              // Show the remaining time
              if (!widget.inventory.isFinished)
                ValueListenableBuilder<double>(
                  valueListenable: widget.inventory.elapsedTimeNotifier,
                  builder: (context, elapsedTime, child) {
                    final remainingTime = (widget.inventory.duration * 60) - elapsedTime;
                    final minutes = (remainingTime / 60).floor();
                    final seconds = (remainingTime % 60).floor();
                    return Text(
                      ' (${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')})',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    );
                  },
                ),
            ],
            if (widget.inventory.maxSpecies > 0) ...[
              // const SizedBox(width: 8.0),
              Text(': ${widget.inventory.maxSpecies} ${S.of(context).speciesAcronym(widget.inventory.maxSpecies)}'),
            ],
            const SizedBox(width: 8.0,),
            // Show the number of intervals without species for qualitative inventories
            Visibility(
              visible: widget.inventory.type == InventoryType.invIntervalQualitative && !widget.inventory.isFinished,
              child: ValueListenableBuilder<int>(
                  valueListenable: widget.inventory.intervalWithoutSpeciesNotifier,
                  builder: (context, intervalWithoutSpecies, child) {
                    return intervalWithoutSpecies > 0
                        ? Badge.count(count: intervalWithoutSpecies)
                        : const SizedBox.shrink();
                  }
              ),
            ),
          ],
        ),
        // Progress indicator if active
        if (!widget.isEmbedded && widget.inventory.duration > 0 && !widget.inventory.isFinished)
          ValueListenableBuilder<double>(
            valueListenable: widget.inventory.elapsedTimeNotifier,
            builder: (context, elapsedTime, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(
                  value: widget.inventory.isPaused ? null : elapsedTime / (widget.inventory.duration * 60),
                  backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.grey[300] : Colors.black,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.inventory.isPaused ? Colors.amber
                        : Theme.of(context).brightness == Brightness.light ? Colors.deepPurple : Colors.deepPurpleAccent,
                  ),
                ),
              );
            },
          ),
        // TabBar
        TabBar(
          controller: _tabController,
          tabs: [
            Consumer<SpeciesProvider>(
              builder: (context, speciesProvider, child) {
                final speciesList = speciesProvider.getSpeciesForInventory(widget.inventory.id);
                return speciesList.isNotEmpty
                    ? Badge.count(
                        backgroundColor: Colors.deepPurple[100],
                        textColor: Colors.deepPurple[800],
                        alignment: AlignmentDirectional.centerEnd,
                        offset: const Offset(24, -8),
                        count: speciesList.length,
                        child: Tab(text: S.of(context).species(2)),
                      )
                    : Tab(text: S.of(context).species(2));
              },
            ),
            Consumer<VegetationProvider>(
              builder: (context, vegetationProvider, child) {
                final vegetationList = vegetationProvider.getVegetationForInventory(widget.inventory.id);
                return vegetationList.isNotEmpty
                    ? Badge.count(
                        backgroundColor: Colors.deepPurple[100],
                        textColor: Colors.deepPurple[800],
                        alignment: AlignmentDirectional.centerEnd,
                        offset: const Offset(24, -8),
                        count: vegetationList.length,
                        child: Tab(text: S.of(context).vegetation),
                      )
                    : Tab(text: S.of(context).vegetation);
              },
            ),
            Consumer<WeatherProvider>(
              builder: (context, weatherProvider, child) {
                final weatherList = weatherProvider.getWeatherForInventory(widget.inventory.id);
                return weatherList.isNotEmpty
                    ? Badge.count(
                        backgroundColor: Colors.deepPurple[100],
                        textColor: Colors.deepPurple[800],
                        alignment: AlignmentDirectional.centerEnd,
                        offset: const Offset(24, -8),
                        count: weatherList.length,
                        child: Tab(text: S.of(context).weather),
                      )
                    : Tab(text: S.of(context).weather);
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // If embedded, return widget without Scaffold/AppBar
    if (widget.isEmbedded) {
      return SafeArea(
        child: Column(
          children: [
            _buildTopArea(context),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                dragStartBehavior: DragStartBehavior.down,
                children: [
                  SpeciesTab(
                    inventory: widget.inventory,
                    speciesDao: widget.speciesDao,
                    inventoryDao: widget.inventoryDao,
                  ),
                  VegetationTab(inventory: widget.inventory),
                  WeatherTab(inventory: widget.inventory),
                ],
              ),
            ),
            // Floating actions in embedded mode: show FAB aligned bottom-right
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FabMenuM3E(
                  controller: fabController,
                  alignment: Alignment.bottomRight,
                  direction: FabMenuDirection.up,
                  overlay: false,
                  primaryFab: FabM3E(
                      icon: fabController.isOpen ? const Icon(Icons.close) : const Icon(Icons.add),
                      onPressed: fabController.toggle),
                  items: [
                    FabMenuItem(
                      icon: Theme.of(context).brightness == Brightness.light
                          ? const Icon(Icons.local_florist_outlined)
                          : const Icon(Icons.local_florist),
                      label: Text(S.of(context).vegetationData),
                      onPressed: () {
                        _showAddVegetationScreen(context);
                      },
                    ),
                    FabMenuItem(
                      icon: Theme.of(context).brightness == Brightness.light
                          ? const Icon(Icons.wb_sunny_outlined)
                          : const Icon(Icons.wb_sunny),
                      label: Text(S.of(context).weatherData),
                      onPressed: () {
                        _showAddWeatherScreen(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Not embedded: original Scaffold with AppBar
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inventory.id),
        actions: [
          !widget.inventory.isFinished && widget.inventory.duration > 0
              ? Consumer<InventoryProvider>(
            builder: (context, inventoryProvider, child) {
              final inventory = widget.inventory;
              return IconButton(
                icon: Icon(inventory.isPaused ? Icons.play_arrow_outlined : Icons.pause_outlined),
                tooltip: inventory.isPaused ? S.of(context).resume : S.of(context).pause,
                onPressed: () {
                  if (inventory.isPaused) {
                    inventoryProvider.resumeInventoryTimer(context, inventory, widget.inventoryDao);
                  } else {
                    inventoryProvider.pauseInventoryTimer(inventory, widget.inventoryDao);
                  }
                  inventoryProvider.updateInventory(inventory);
                },
              );
            },
          ) : const SizedBox.shrink(),
          Visibility(
              visible: !widget.inventory.isFinished,
              child: IconButton.filled(
              onPressed: () async {
                // Show confirmation dialog
                  setState(() {
                    _isSubmitting = true;
                  });
                  final completionService = InventoryCompletionService(
                    context: context,
                    inventory: widget.inventory,
                    inventoryProvider: Provider.of<InventoryProvider>(context, listen: false),
                    inventoryDao: widget.inventoryDao,
                  );
                  await completionService.attemptFinishInventory(context);
                  Navigator.pop(context, true);
                  setState(() {
                    _isSubmitting = false;
                  });
                // }
              },
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Colors.deepPurple,
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  year2023: false,
                ),
              )
                  : const Icon(Icons.flag_outlined),
            ),
          ),
          Visibility(
              visible: widget.inventory.isFinished,
              child: MediaQuery.sizeOf(context).width < 600
                  ? IconButton(
                icon: const Icon(Icons.more_vert_outlined),
                onPressed: () {
                  _showMoreOptionsBottomSheet(context, widget.inventory);
                },
              )
                  : MenuAnchor(
              builder: (context, controller, child) {
                return IconButton(
                  icon: Icon(Icons.more_vert_outlined),
                  tooltip: S.of(context).exportWhat(S.of(context).inventory(1)),
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
                  leadingIcon: const Icon(Icons.share_outlined),
                  onPressed: () async {
                    final locale = Localizations.localeOf(context);
                    final csvFile = await exportInventoryToCsv(context, widget.inventory, locale);
                    // Share the file using share_plus
                    await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(csvFile, mimeType: 'text/csv')],
                        text: S.current.inventoryExported(1),
                        subject: S.current.inventoryData(1),
                      ),
                    );
                  },
                  child: Text('${S.current.export} CSV'),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.share_outlined),
                  onPressed: () async {
                    final locale = Localizations.localeOf(context);
                    final excelFile = await exportInventoryToExcel(context, widget.inventory, locale);
                    // Share the file using share_plus
                    await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(excelFile, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
                        text: S.current.inventoryExported(1),
                        subject: S.current.inventoryData(1),
                      ),
                    );
                  },
                  child: Text('${S.current.export} Excel'),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    exportInventoryToJson(context, widget.inventory, true);
                  },
                  child: Text('${S.current.export} JSON'),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.share_outlined),
                  onPressed: () {
                    exportInventoryToKml(context, widget.inventory);
                  },
                  child: Text('${S.current.export} KML'),
                ),
              ],
            ),
          ),
          // const SizedBox(width: 8.0,),
        ],
        bottom: PreferredSize( // Wrap TabBar and LinearProgressIndicator in PreferredSize
          preferredSize: const Size.fromHeight(kToolbarHeight + 24.0), // Adjust height as needed
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${inventoryTypeFriendlyNames[widget.inventory.type]}'),
                    if (widget.inventory.duration > 0) ...[
                      Text(': ${widget.inventory.duration} ${S.of(context).minutes(widget.inventory.duration)}'),
                      // Show the remaining time
                      if (!widget.inventory.isFinished)
                        ValueListenableBuilder<double>(
                          valueListenable: widget.inventory.elapsedTimeNotifier,
                          builder: (context, elapsedTime, child) {
                            final remainingTime = (widget.inventory.duration * 60) - elapsedTime;
                            // Do not show if the time is negative
                            if (remainingTime < 0) return const SizedBox.shrink();

                            final minutes = (remainingTime / 60).floor();
                            final seconds = (remainingTime % 60).floor();
                            return Text(
                              ' (${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')})',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary),
                            );
                          },
                        ),
                    ],
                    if (widget.inventory.maxSpecies > 0) ...[
                      Text(': ${widget.inventory.maxSpecies} ${S.of(context).speciesAcronym(widget.inventory.maxSpecies)}'),
                    ],
                    const SizedBox(width: 8.0,),
                    // Show the number of intervals without species for qualitative inventories
                    Visibility(
                      visible: widget.inventory.type == InventoryType.invIntervalQualitative && !widget.inventory.isFinished,
                      child: ValueListenableBuilder<int>(
                          valueListenable: widget.inventory.intervalWithoutSpeciesNotifier,
                          builder: (context, intervalWithoutSpecies, child) {
                            return intervalWithoutSpecies > 0
                                ? Badge.count(count: intervalWithoutSpecies)
                                : const SizedBox.shrink();
                          }
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8.0,),
              widget.inventory.duration > 0 && !widget.inventory.isFinished
                  ? ValueListenableBuilder<double>(
                valueListenable: widget.inventory.elapsedTimeNotifier,
                builder: (context, elapsedTime, child) {
                  return LinearProgressIndicator(
                    value: widget.inventory.isPaused
                        ? null
                        : elapsedTime / (widget.inventory.duration * 60),
                    backgroundColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[300]
                        : Colors.black,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.inventory.isPaused
                          ? Colors.amber
                          : Theme.of(context).brightness == Brightness.light
                          ? Colors.deepPurple
                          : Colors.deepPurpleAccent,
                    ),
                    year2023: false,
                  );
                },
              )
                  : const SizedBox.shrink(),
              TabBar(
                controller: _tabController,
                tabs: [
                  Consumer<SpeciesProvider>(
                    builder: (context, speciesProvider, child) {
                      final speciesList = speciesProvider.getSpeciesForInventory(
                          widget.inventory.id);
                      return speciesList.isNotEmpty
                          ? Badge.count(
                        backgroundColor: Colors.deepPurple[100],
                        textColor: Colors.deepPurple[800],
                        alignment: AlignmentDirectional.centerEnd,
                        offset: const Offset(24, -8),
                        count: speciesList.length,
                        child: Tab(text: S.of(context).species(2)),
                      )
                          : Tab(text: S.of(context).species(2));
                    },
                  ),
                  Consumer<VegetationProvider>(
                    builder: (context, vegetationProvider, child) {
                      final vegetationList = vegetationProvider
                          .getVegetationForInventory(widget.inventory.id);
                      return vegetationList.isNotEmpty
                          ? Badge.count(
                        backgroundColor: Colors.deepPurple[100],
                        textColor: Colors.deepPurple[800],
                        alignment: AlignmentDirectional.centerEnd,
                        offset: const Offset(24, -8),
                        count: vegetationList.length,
                        child: Tab(text: S.of(context).vegetation),
                      )
                          : Tab(text: S.of(context).vegetation);
                    },
                  ),
                  Consumer<WeatherProvider>(
                    builder: (context, weatherProvider, child) {
                      final weatherList = weatherProvider
                          .getWeatherForInventory(widget.inventory.id);
                      return weatherList.isNotEmpty
                          ? Badge.count(
                        backgroundColor: Colors.deepPurple[100],
                        textColor: Colors.deepPurple[800],
                        alignment: AlignmentDirectional.centerEnd,
                        offset: const Offset(24, -8),
                        count: weatherList.length,
                        child: Tab(text: S.of(context).weather),
                      )
                          : Tab(text: S.of(context).weather);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.down,
        children: [
          SpeciesTab(
            inventory: widget.inventory,
            speciesDao: widget.speciesDao,
            inventoryDao: widget.inventoryDao,
          ),
          VegetationTab(
            inventory: widget.inventory,
          ),
          WeatherTab(
            inventory: widget.inventory,
          ),
        ],
      ),
      floatingActionButton: FabMenuM3E(
        controller: fabController,
        alignment: Alignment.bottomRight,
        direction: FabMenuDirection.up,
        overlay: false,
        primaryFab: FabM3E(
            icon: fabController.isOpen ? const Icon(Icons.close) : const Icon(Icons.add),
            onPressed: fabController.toggle
        ),
        items: [
          FabMenuItem(
            icon: Theme.of(context).brightness == Brightness.light
                  ? const Icon(Icons.local_florist_outlined)
                  : const Icon(Icons.local_florist),
            label: Text(S.of(context).vegetationData),
            onPressed: () {
              _showAddVegetationScreen(context);
            },
          ),
          FabMenuItem(
            icon: Theme.of(context).brightness == Brightness.light
              ? const Icon(Icons.wb_sunny_outlined)
              : const Icon(Icons.wb_sunny),
            label: Text(S.of(context).weatherData),
            onPressed: () {
              _showAddWeatherScreen(context);
            },
          ),
        ],
      ),
    );
  }

  void _showMoreOptionsBottomSheet(BuildContext context, Inventory inventory) {
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
                      const Divider(),

                      // GridView.count(
                      //   crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 4 : 5,
                      //   shrinkWrap: true,
                      //   physics: const NeverScrollableScrollPhysics(),
                      //   children: <Widget>[
                      //     buildGridMenuItem(context, Icons.delete_outlined,
                      //         S.of(context).delete, () {
                      //           Navigator.of(context).pop();
                      //           // Ask for user confirmation
                      //           _confirmDelete(context, inventory);
                      //         }, color: Theme.of(context).colorScheme.error),
                      //   ],
                      // ),
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
}
