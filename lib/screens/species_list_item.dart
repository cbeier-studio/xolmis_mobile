import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../data/database_helper.dart';
import '../models/inventory.dart';
import '../providers/poi_provider.dart';
import 'species_detail_screen.dart';

class SpeciesListItem extends StatefulWidget {
  final Species species;
  final Animation<double> animation;

  const SpeciesListItem({
    super.key,
    required this.species,
    required this.animation,
  });

  @override
  SpeciesListItemState createState() => SpeciesListItemState();
}

class SpeciesListItemState extends State<SpeciesListItem> {
  bool _isAddingPoi = false;

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: widget.animation,
      child: ListTile(
        title: Text(widget.species.name),
        tileColor: widget.species.isOutOfInventory ? Colors.grey[200] : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                if (mounted && widget.species.count > 0) {
                  widget.species.count--;
                  DatabaseHelper().updateSpecies(widget.species).then((_) {
                    setState(() {});
                  });
                }
              },
            ),
            Text(widget.species.count.toString()),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (mounted) {
                  widget.species.count++;
                  DatabaseHelper().updateSpecies(widget.species).then((_) {
                    setState(() {});
                  });
                }
              },
            ),
            Consumer<PoiProvider>(
              builder: (context, poiProvider, child) {
                final pois = poiProvider.getPoisForSpecies(widget.species.id ?? 0);
                return IconButton(
                  icon: _isAddingPoi
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ) // Exibe o CircularProgressIndicator enquanto _isAddingPoi for true
                      : pois.isNotEmpty
                      ? Badge.count(
                    backgroundColor: Colors.deepPurple,
                    count: pois.length,
                    child: const Icon(Icons.add_location),
                  )
                      : const Icon(Icons.add_location),
                  onPressed: _isAddingPoi ? null : () async {
                    setState(() {
                      _isAddingPoi = true;
                    });

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
                    poiProvider.addPoi(context, widget.species.id!, poi);
                    poiProvider.notifyListeners();

                    setState(() {
                      _isAddingPoi = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check, color: Colors.green),
                            const SizedBox(width: 8),
                            const Text('POI inserido com sucesso!'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpeciesDetailScreen(species: widget.species),
            ),
          );
        },
      ),
    );
  }
}