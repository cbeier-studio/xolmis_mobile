import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/poi_provider.dart';
import '../models/inventory.dart';

class SpeciesDetailScreen extends StatefulWidget {
  final Species species;

  const SpeciesDetailScreen({super.key, required this.species});

  @override
  SpeciesDetailScreenState createState() => SpeciesDetailScreenState();
}

class SpeciesDetailScreenState extends State<SpeciesDetailScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadSpeciesData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSpeciesData() async {
    final poiProvider = Provider.of<PoiProvider>(context, listen: false);
    setState(() {
      widget.species.pois = poiProvider.getPoisForSpecies(widget.species.id ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.species.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: () async {
              // Get the current location
              Position position = await Geolocator.getCurrentPosition(
                locationSettings: LocationSettings(
                  accuracy: LocationAccuracy.high,
                ),
              );

              // Create a new POI
              final poi = Poi(
                speciesId: widget.species.id!,
                longitude: position.longitude,
                latitude: position.latitude,
              );

              // Insert the POI in the database
              Provider.of<PoiProvider>(context, listen: false)
                  .addPoi(context, widget.species.id!, poi)
                  .then((_) {
                // Update the UI after the POI is inserted
                _listKey.currentState!.insertItem(widget.species.pois.length - 1);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('POI inserido com sucesso!'),
                ),
              );
            },

          ),
        ],
      ),
      body: Consumer<PoiProvider>(
        builder: (context, poiProvider, child) {
          final pois = poiProvider.getPoisForSpecies(widget.species.id ?? 0);
          return AnimatedList(
            key: _listKey,
            initialItemCount: pois.length,
            itemBuilder: (context, index, animation) {
              final poi = pois[index];
              return Dismissible(
                key: ValueKey(poi),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirmar exclusão'),
                        content: const Text(
                            'Tem certeza que deseja excluir este POI?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(
                              textStyle: const TextStyle(color: Colors.red),
                            ),
                            child: const Text('Excluir'),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  // Delete the POI from database
                  poiProvider.removePoi(widget.species.id!, poi.id!);
                  // poiProvider.notifyListeners();

                  // Remove the POI from list and update the AnimatedList
                  _listKey.currentState!.removeItem(
                    index, (context, animation) => PoiListItem(
                      poi: poi,
                      animation: animation,
                    ),
                  );
                },
                child: PoiListItem(
                  poi: poi,
                  animation: animation,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PoiListItem extends StatelessWidget {
  final Poi poi;
  final Animation<double> animation;

  const PoiListItem({super.key, required this.poi, required this.animation});

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        title: Text('${poi.latitude}, ${poi.longitude}'),
        leading: const Icon(Icons.location_pin),
      ),
    );
  }
}