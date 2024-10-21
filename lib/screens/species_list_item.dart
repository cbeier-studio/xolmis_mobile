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
                return IconButton(
                  icon: widget.species.pois.isNotEmpty ? Badge.count(
                    backgroundColor: Colors.deepPurple,
                    count: widget.species.pois.length,
                    child: const Icon(Icons.add_location),
                  ) : const Icon(Icons.add_location),
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
                    final poiProvider = Provider.of<PoiProvider>(context, listen: false);
                    poiProvider.addPoi(context, widget.species.id!, poi);
                    poiProvider.notifyListeners();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('POI inserido com sucesso!'),
                      ),
                    );

                    // Update the POIs list of the species
                    setState(() {
                      widget.species.pois = poiProvider.getPoisForSpecies(widget.species.id!);
                    });
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