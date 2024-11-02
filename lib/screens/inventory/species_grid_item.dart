import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/inventory.dart';
import '../../providers/species_provider.dart';
import '../../providers/poi_provider.dart';

import 'species_detail_screen.dart';
import '../utils.dart';

class SpeciesGridItem extends StatefulWidget {
  final Species species;
  final VoidCallback onLongPress;

  const SpeciesGridItem({
    super.key,
    required this.species,
    required this.onLongPress,
  });

  @override
  SpeciesGridItemState createState() => SpeciesGridItemState();
}

class SpeciesGridItemState extends State<SpeciesGridItem> {
  late SpeciesProvider speciesProvider;
  bool _isAddingPoi = false;

  @override
  void initState() {
    super.initState();
    speciesProvider = context.read<SpeciesProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return GridTile(
      child: InkWell(
        onLongPress: widget.onLongPress,
        // onTap: () {
        //
        // },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
          child: Row(
            children: [
              Text(
                widget.species.name,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              IconButton(
                icon: const Icon(Icons.remove_outlined),
                tooltip: 'Diminuir contagem de indivíduos',
                onPressed: () {
                  if (mounted && widget.species.count > 0) {
                    speciesProvider.decrementIndividualsCount(widget.species);
                  }
                },
              ),
              Selector<SpeciesProvider, int>(
                selector: (context, speciesProvider) => speciesProvider.individualsCountNotifier.value,
                builder: (context, count, child) {
                  return Text(widget.species.count.toString());
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_outlined),
                tooltip: 'Aumentar contagem de indivíduos',
                onPressed: () {
                  if (mounted) {
                    speciesProvider.incrementIndividualsCount(widget.species);
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
                      backgroundColor: Colors.deepPurple[100],
                      textColor: Colors.deepPurple[800],
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
                      Position? position = await getPosition();

                      if (position != null) {
                        // Create a new POI
                        final poi = Poi(
                          speciesId: widget.species.id!,
                          longitude: position.longitude,
                          latitude: position.latitude,
                        );

                        // Insert the POI in the database
                        poiProvider.addPoi(context, widget.species.id!, poi);
                        poiProvider.notifyListeners();

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
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}