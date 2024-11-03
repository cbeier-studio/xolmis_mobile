import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      ).then((newVegetation) {
        // Reload the inventory list
        if (newVegetation != null) {
          Provider.of<VegetationProvider>(context, listen: false).getVegetationForInventory(widget.inventory.id);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddVegetationDataScreen(inventory: widget.inventory),
        ),
      ).then((newVegetation) {
        // Reload the inventory list
        if (newVegetation != null) {
          Provider.of<VegetationProvider>(context, listen: false).getVegetationForInventory(widget.inventory.id);
        }
      });
    }
  }

  void _showAddWeatherScreen(BuildContext context) {
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
        // Reload the inventory list
        if (newWeather != null) {
          Provider.of<WeatherProvider>(context, listen: false).getWeatherForInventory(widget.inventory.id);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddWeatherScreen(inventory: widget.inventory),
        ),
      ).then((newWeather) {
        // Reload the inventory list
        if (newWeather != null) {
          Provider.of<WeatherProvider>(context, listen: false).getWeatherForInventory(widget.inventory.id);
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
                tooltip: inventory.isPaused ? 'Retomar' : 'Pausa',
                onPressed: () {
                  if (inventory.isPaused) {
                    inventoryProvider.resumeInventoryTimer(inventory, widget.inventoryRepository);
                  } else {
                    inventoryProvider.pauseInventoryTimer(inventory, widget.inventoryRepository);
                  }
                  Provider.of<InventoryProvider>(context, listen: false)
                      .updateInventory(inventory);
                },
              );
            },
          ) : const SizedBox.shrink(),
          IconButton(
            icon: Theme.of(context).brightness == Brightness.light
                ? const Icon(Icons.local_florist_outlined)
                : const Icon(Icons.local_florist),
            tooltip: 'Adicionar dados de vegetação',
            onPressed: () {
              _showAddVegetationScreen(context);
            },
          ),
          IconButton(
            icon: Theme.of(context).brightness == Brightness.light
                ? const Icon(Icons.wb_sunny_outlined)
                : const Icon(Icons.wb_sunny),
            tooltip: 'Adicionar dados do tempo',
            onPressed: () {
              _showAddWeatherScreen(context);
            },
          ),
        ],
        bottom: PreferredSize( // Wrap TabBar and LinearProgressIndicator in PreferredSize
          preferredSize: const Size.fromHeight(kToolbarHeight + 4.0), // Adjust height as needed
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${inventoryTypeFriendlyNames[widget.inventory.type]}'),
                    if (widget.inventory.duration > 0) Text(': ${widget.inventory.duration} minutos'),
                    if (widget.inventory.maxSpecies > 0) Text(': ${widget.inventory.maxSpecies} spp.'),
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
                        : Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.inventory.isPaused
                          ? Colors.amber
                          : Theme.of(context).brightness == Brightness.light
                          ? Colors.deepPurple
                          : Colors.deepPurpleAccent,
                    ),
                  );
                },
              )
                  : const SizedBox.shrink(),
              TabBar(
                controller: _tabController,
                // physics: const NeverScrollableScrollPhysics(),
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
                        child: const Tab(text: 'Espécies'),
                      )
                          : const Tab(text: 'Espécies');
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
                        child: const Tab(text: 'Vegetação'),
                      )
                          : const Tab(text: 'Vegetação');
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
                        child: const Tab(text: 'Tempo'),
                      )
                          : const Tab(text: 'Tempo');
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
        // physics: const NeverScrollableScrollPhysics(),
        dragStartBehavior: DragStartBehavior.down,
        children: [
          SpeciesTab(
            inventory: widget.inventory,
            speciesRepository: widget.speciesRepository,
            inventoryRepository: widget.inventoryRepository,
          ),
          VegetationTab(
            inventory: widget.inventory,
            // vegetationRepository: widget.vegetationRepository,
          ),
          WeatherTab(
            inventory: widget.inventory,
            // weatherRepository: widget.weatherRepository,
          ),
        ],
      ),
      floatingActionButton: !widget.inventory.isFinished
          ? FloatingActionButton(
        tooltip: 'Encerrar inventário',
        onPressed: () async {
          // Show confirmation dialog
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirmar Encerramento'),
              content: const Text('Tem certeza que deseja encerrar este inventário?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Encerrar'),
                ),
              ],
            ),
          );

          // If confirmed, finish the inventory
          if (confirmed == true) {
            setState(() {
              _isSubmitting = true;
            });
            await Inventory.stopTimer(widget.inventory, widget.inventoryRepository);
            Navigator.pop(context, true);
            setState(() {
              _isSubmitting = false;
            });
          }
        },
        backgroundColor: Colors.green,
        child: _isSubmitting
            ? const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        )
            : const Icon(Icons.flag_outlined, color: Colors.white),
      )
          : null,
    );
  }
}
