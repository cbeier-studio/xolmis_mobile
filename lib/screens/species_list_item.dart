import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../models/inventory.dart';
import '../providers/species_provider.dart';
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
        title: Text(
          widget.species.name,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
        tileColor: widget.species.isOutOfInventory ? Colors.grey[200] : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_outlined),
              tooltip: 'Diminuir contagem de indivíduos',
              onPressed: () {
                if (mounted && widget.species.count > 0) {
                  final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
                  speciesProvider.decrementSpeciesCount(widget.species);
                }
              },
            ),
            Selector<SpeciesProvider, int>(
              selector: (context, speciesProvider) => speciesProvider.speciesCountNotifier.value,
              builder: (context, count, child) {
                return Text(widget.species.count.toString());
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_outlined),
              tooltip: 'Aumentar contagem de indivíduos',
              onPressed: () {
                if (mounted) {
                  final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
                  speciesProvider.incrementSpeciesCount(widget.species);
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
                    child: const Icon(Icons.add_location_outlined),
                  )
                      : const Icon(Icons.add_location_outlined),
                  tooltip: 'Adicionar POI',
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
                            const Icon(Icons.check_circle_outlined, color: Colors.green),
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