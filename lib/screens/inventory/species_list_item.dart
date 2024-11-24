import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/inventory.dart';
import '../../providers/species_provider.dart';
import '../../providers/poi_provider.dart';

import 'species_detail_screen.dart';
import '../utils.dart';

class SpeciesListItem extends StatefulWidget {
  final Species species;
  final VoidCallback onLongPress;

  const SpeciesListItem({
    super.key,
    required this.species,
    required this.onLongPress,
  });

  @override
  SpeciesListItemState createState() => SpeciesListItemState();
}

class SpeciesListItemState extends State<SpeciesListItem> {
  bool _isAddingPoi = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(
          widget.species.name,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ),
      tileColor: widget.species.isOutOfInventory
          ? Theme.of(context).highlightColor
          : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_outlined),
              tooltip: 'Diminuir contagem de indivíduos',
              onPressed: () {
                if (mounted && widget.species.count > 0) {
                  final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
                  speciesProvider.decrementIndividualsCount(widget.species);
                }
              },
            ),
            InkWell(
              onTap: () {
                _showEditCountDialog(context);
              },
              child: Selector<SpeciesProvider, int>(
                selector: (context, speciesProvider) => speciesProvider.individualsCountNotifier.value,
                builder: (context, count, child) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1.0,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Text(
                      widget.species.count.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_outlined),
              tooltip: 'Aumentar contagem de indivíduos',
              onPressed: () {
                if (mounted) {
                  final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
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
                  ) // Show a CircularProgressIndicator while _isAddingPoi is true
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

                      // ScaffoldMessenger.of(context).showSnackBar(
                      //   SnackBar(
                      //     content: Row(
                      //       children: [
                      //         const Icon(Icons.check_circle_outlined, color: Colors.green),
                      //         const SizedBox(width: 8),
                      //         const Text('POI inserido com sucesso!'),
                      //       ],
                      //     ),
                      //   ),
                      // );
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
        onLongPress: widget.onLongPress,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpeciesDetailScreen(species: widget.species),
            ),
          );
        },
    );
  }

  Future<void> _showEditCountDialog(BuildContext context) async {
    int? newCount = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int currentCount = widget.species.count;
        return AlertDialog(
          title: const Text('Editar contagem'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: currentCount.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        currentCount = int.tryParse(value) ?? 0;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Contagem de indivíduos',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(currentCount),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (newCount != null) {
      // Update the value of species.count
      setState(() {
        widget.species.count = newCount;
      });

      // Notify the provider
      Provider.of<SpeciesProvider>(context, listen: false)
          .updateIndividualsCount(widget.species);
    }
  }
}