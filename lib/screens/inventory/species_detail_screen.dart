import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../providers/poi_provider.dart';
import '../../data/models/inventory.dart';

import '../utils.dart';

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
  bool _isAddingPoi = false;

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
            icon: _isAddingPoi
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.add_location_outlined),
            onPressed: _isAddingPoi ? null : () async {
              setState(() {
                _isAddingPoi = true;
              });

              // Get the current location
              Position? position = await getPosition();

              if (position != null) {
                // Create a new POI
                final poi = Poi(
                  speciesId: widget.species.id!,
                  longitude: position!.longitude,
                  latitude: position!.latitude,
                );

                // Insert the POI in the database
                final poiProvider = Provider.of<PoiProvider>(
                    context, listen: false);
                poiProvider.addPoi(context, widget.species.id!, poi)
                    .then((_) {
                  // Update the UI after the POI is inserted
                  poiProvider.notifyListeners();

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final poiList = poiProvider.getPoisForSpecies(widget.species
                        .id!);
                    _listKey.currentState?.insertItem(
                        poiList.length - 1, duration: const Duration(
                        milliseconds: 300));
                  });
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_outlined, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('POI inserido com sucesso!'),
                      ],
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outlined, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Erro ao obter a localização.'),
                      ],
                    ),
                  ),
                );
              }

              setState(() {
                _isAddingPoi = false;
              });
            },

          ),
        ],
      ),
      body: Consumer<PoiProvider>(
        builder: (context, poiProvider, child) {
          final pois = poiProvider.getPoisForSpecies(widget.species.id ?? 0);
          return RefreshIndicator(
              onRefresh: () async {
            await poiProvider.getPoisForSpecies(widget.species.id ?? 0);
          },
          child: ListView.builder(
          itemCount: pois.length,
          itemBuilder: (context, index) {
              if (pois.isEmpty) {
                return const SizedBox.shrink();
              } else {
                final poi = pois[index];
                return Dismissible(
                  key: ValueKey(poi),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(Icons.delete_outlined, color: Colors.white),
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
                  },
                  child: PoiListItem(
                    poi: poi,
                  ),
                );
              }
            },
          )
          );
        },
      ),
    );
  }
}

class PoiListItem extends StatelessWidget {
  final Poi poi;

  const PoiListItem({super.key, required this.poi,});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text('${poi.latitude}, ${poi.longitude}'),
        leading: const Icon(Icons.location_on_outlined),

    );
  }
}