import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inventory.dart';

import '../providers/inventory_provider.dart';
import '../providers/species_provider.dart';
import '../providers/poi_provider.dart';
import '../providers/vegetation_provider.dart';
import '../providers/weather_provider.dart';

import 'add_vegetation_screen.dart';
import 'add_weather_screen.dart';

import 'species_tab.dart';
import 'vegetation_tab.dart';
import 'weather_tab.dart';

class InventoryDetailScreen extends StatefulWidget {
  final Inventory inventory;

  const InventoryDetailScreen({
    super.key,
    required this.inventory,
  });

  @override
  InventoryDetailScreenState createState() => InventoryDetailScreenState();
}

class InventoryDetailScreenState extends State<InventoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<AnimatedListState> _speciesListKey = GlobalKey<
      AnimatedListState>();
  final GlobalKey<AnimatedListState> _vegetationListKey = GlobalKey<
      AnimatedListState>();
  final GlobalKey<AnimatedListState> _weatherListKey = GlobalKey<
      AnimatedListState>();
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
    vegetationProvider.vegetationListKey = _vegetationListKey;
    final weatherProvider = Provider.of<WeatherProvider>(
        context, listen: false);
    weatherProvider.weatherListKey = _weatherListKey;

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
                icon: Icon(inventory.isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: () {
                  if (inventory.isPaused) {
                    inventoryProvider.resumeInventoryTimer(inventory);
                  } else {
                    inventoryProvider.pauseInventoryTimer(inventory);
                  }
                  Provider.of<InventoryProvider>(context, listen: false)
                      .updateInventory(inventory);
                },
              );
            },
          ) : const SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.local_florist),
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddVegetationDataScreen(
                        inventory: widget.inventory,
                      ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloudy_snowing),
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddWeatherScreen(
                        inventory: widget.inventory,
                      ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          // physics: const NeverScrollableScrollPhysics(),
          tabs: [
            Consumer<SpeciesProvider>(
              builder: (context, speciesProvider, child) {
                final speciesList = speciesProvider.getSpeciesForInventory(
                    widget.inventory.id);
                return speciesList.isNotEmpty
                    ? Badge.count(
                  backgroundColor: Colors.deepPurple,
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
                  backgroundColor: Colors.deepPurple,
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
                  backgroundColor: Colors.deepPurple,
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
        flexibleSpace: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: widget.inventory.duration > 0 && !widget.inventory.isFinished
              ? ValueListenableBuilder<double>(
            valueListenable: widget.inventory.elapsedTimeNotifier,
            builder: (context, elapsedTime, child) {
              return LinearProgressIndicator(
                value: widget.inventory.isPaused
                    ? null
                    : elapsedTime / (widget.inventory.duration * 60),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.inventory.isPaused
                      ? Colors.amber
                      : Colors.deepPurple,
                ),
              );
            },
          )
              : const SizedBox.shrink(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        dragStartBehavior: DragStartBehavior.down,
        children: [
          SpeciesTab(inventory: widget.inventory, speciesListKey: _speciesListKey),
          VegetationTab(inventory: widget.inventory, vegetationListKey: _vegetationListKey),
          WeatherTab(inventory: widget.inventory, weatherListKey: _weatherListKey),
        ],
      ),
      floatingActionButton: !widget.inventory.isFinished
          ? FloatingActionButton(
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
            await widget.inventory.stopTimer();
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
            : const Icon(Icons.flag, color: Colors.white),
      )
          : null,
    );
  }
}
