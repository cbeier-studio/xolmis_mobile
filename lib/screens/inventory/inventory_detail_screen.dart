import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/inventory.dart';
import '../../data/database/repositories/inventory_repository.dart';
import '../../data/database/repositories/species_repository.dart';
import '../../data/database/repositories/poi_repository.dart';
import '../../data/database/repositories/vegetation_repository.dart';
import '../../data/database/repositories/weather_repository.dart';

import '../../providers/inventory_provider.dart';
import '../../providers/species_provider.dart';
import '../../providers/poi_provider.dart';
import '../../providers/vegetation_provider.dart';
import '../../providers/weather_provider.dart';

import 'add_vegetation_screen.dart';
import 'add_weather_screen.dart';
import 'species_tab.dart';
import 'vegetation_tab.dart';
import 'weather_tab.dart';
import '../../utils/export_utils.dart';
import '../../services/inventory_completion_service.dart';
import '../../generated/l10n.dart';

class InventoryDetailScreen extends StatefulWidget {
  final Inventory inventory;
  final SpeciesRepository speciesRepository;
  final InventoryRepository inventoryRepository;
  final PoiRepository poiRepository;
  final VegetationRepository vegetationRepository;
  final WeatherRepository weatherRepository;

  const InventoryDetailScreen({
    super.key,
    required this.inventory,
    required this.speciesRepository,
    required this.inventoryRepository,
    required this.poiRepository,
    required this.vegetationRepository,
    required this.weatherRepository,
  });

  @override
  InventoryDetailScreenState createState() => InventoryDetailScreenState();
}

class InventoryDetailScreenState extends State<InventoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSubmitting = false;

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

  @override
  Widget build(BuildContext context) {
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
                    inventoryProvider.resumeInventoryTimer(inventory, widget.inventoryRepository);
                  } else {
                    inventoryProvider.pauseInventoryTimer(inventory, widget.inventoryRepository);
                  }
                  inventoryProvider.updateInventory(inventory);
                },
              );
            },
          ) : const SizedBox.shrink(),
          if (!widget.inventory.isFinished)
            IconButton.filled(
              onPressed: () async {
                // Show confirmation dialog
                // final confirmed = await showDialog<bool>(
                //   context: context,
                //   builder: (context) => AlertDialog.adaptive(
                //     title: Text(S.of(context).confirmFinish),
                //     content: Text(S.of(context).confirmFinishMessage),
                //     actions: [
                //       TextButton(
                //         onPressed: () => Navigator.pop(context, false),
                //         child: Text(S.of(context).cancel),
                //       ),
                //       TextButton(
                //         onPressed: () => Navigator.pop(context, true),
                //         child: Text(S.of(context).finish),
                //       ),
                //     ],
                //   ),
                // );
                //
                // // If confirmed, finish the inventory
                // if (confirmed == true) {
                  setState(() {
                    _isSubmitting = true;
                  });
                  // widget.inventory.updateIsFinished(true);
                  // await widget.inventory.stopTimer(widget.inventoryRepository);
                  final completionService = InventoryCompletionService(
                    context: context,
                    inventory: widget.inventory,
                    inventoryProvider: Provider.of<InventoryProvider>(context, listen: false),
                    inventoryRepository: widget.inventoryRepository,
                  );
                  await completionService.attemptFinishInventory();
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
          if (widget.inventory.isFinished)
            MenuAnchor(
              builder: (context, controller, child) {
                return IconButton(
                  icon: Icon(Icons.file_upload_outlined),
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
                  child: Text('CSV'),
                ),
                MenuItemButton(
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
                  child: Text('Excel'),
                ),
                MenuItemButton(
                  onPressed: () {
                    exportInventoryToJson(context, widget.inventory, true);
                  },
                  child: Text('JSON'),
                ),
              ],
            ),
          // const SizedBox(width: 8.0,),
        ],
        bottom: PreferredSize( // Wrap TabBar and LinearProgressIndicator in PreferredSize
          preferredSize: const Size.fromHeight(kToolbarHeight + 4.0), // Adjust height as needed
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${inventoryTypeFriendlyNames[widget.inventory.type]}'),
                    if (widget.inventory.duration > 0) Text(': ${widget.inventory.duration} ${S.of(context).minutes(widget.inventory.duration)}'),
                    if (widget.inventory.maxSpecies > 0) Text(': ${widget.inventory.maxSpecies} ${S.of(context).speciesAcronym(widget.inventory.maxSpecies)}'),
                  ],
                ),
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
            speciesRepository: widget.speciesRepository,
            inventoryRepository: widget.inventoryRepository,
          ),
          VegetationTab(
            inventory: widget.inventory,
          ),
          WeatherTab(
            inventory: widget.inventory,
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add_outlined,
        activeIcon: Icons.close_outlined,
        spaceBetweenChildren: 8.0,
        children: [
          SpeedDialChild(
            child: Theme.of(context).brightness == Brightness.light
                ? const Icon(Icons.local_florist_outlined)
                : const Icon(Icons.local_florist),
            label: S.of(context).vegetationData,
            onTap: () {
              _showAddVegetationScreen(context);
            },
          ),
          SpeedDialChild(
            child: Theme.of(context).brightness == Brightness.light
                ? const Icon(Icons.wb_sunny_outlined)
                : const Icon(Icons.wb_sunny),
            label: S.of(context).weatherData,
            onTap: () {
              _showAddWeatherScreen(context);
            },
          ),
        ],
      ),
    );
  }
}
