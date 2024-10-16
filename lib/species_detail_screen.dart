import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'database_helper.dart';
import 'inventory.dart';
import 'inventory_provider.dart';

class SpeciesDetailScreen extends StatefulWidget {
  final Species species;
  final String inventoryId;

  const SpeciesDetailScreen({super.key, required this.species, required this.inventoryId});

  @override
  _SpeciesDetailScreenState createState() => _SpeciesDetailScreenState();
}

class _SpeciesDetailScreenState extends State<SpeciesDetailScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.species.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: () => _addPoiForSpecies(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Inventário: ${widget.inventoryId}', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Indivíduos: ${widget.species.count}', style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Pontos de Interesse:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: AnimatedList(
              key: _listKey,
              initialItemCount: widget.species.pois.length,
              itemBuilder: (context, index, animation) {
                final poi = widget.species.pois[index];
                return SlideTransition(
                  position: animation.drive(Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: const Offset(0,0),
                  )),
                  child: Dismissible(
                    key: ValueKey(poi.id), // Unique key for each POI
                    direction: DismissDirection.endToStart, // Drag from right to left
                    onDismissed: (direction) {
                      _removePoi(index, poi);
                    },
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    child: ListTile(
                      title: Text('Latitude: ${poi.latitude}, Longitude: ${poi.longitude}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _removePoi(int index, Poi poi) async {
    // 1. Remove o POI do banco de dados
    await DatabaseHelper().deletePoi(poi.id!);

    // 2. Remove o POI da lista com animação
    _listKey.currentState!.removeItem(
      index,
          (context, animation) => SlideTransition(
        position: animation.drive(Tween<Offset>(
          begin: const Offset(1, 0),
          end: const Offset(0, 0),
        )),
        child: const SizedBox.shrink(),
      ),
    );

    // 3. Atualiza a lista de POIs da espécie
    setState(() {
      widget.species.pois.removeAt(index);
    });
  }

  Future<void> _addPoiForSpecies() async {
    // 1. Get latitude  longitude
    LatLng? currentLocation;
    try {
      currentLocation = await Provider.of<InventoryProvider>(context, listen: false).getCurrentLocation();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter alocalização: $e');
      }
      // Handle location error, e.g., showing a message to the user
      return;
    }

    // 2. Create a Poi object
    final poi = Poi(
      speciesId: widget.species.id!,
      longitude: currentLocation!.longitude,
      latitude: currentLocation!.latitude,
    );

    // 3. Save the POI to the database
    await DatabaseHelper().insertPoi(poi);

    // 4. Insert the POI in the list with animation
    _listKey.currentState!.insertItem(widget.species.pois.length, duration: const Duration(milliseconds: 300));

    // 5. Update the POIs list of species
    setState(() {
      widget.species.pois.add(poi);
    });

    // 6. Update the species list in InventoryProvider
    Provider.of<InventoryProvider>(context, listen: false).updateSpecies(widget.species);
  }
}