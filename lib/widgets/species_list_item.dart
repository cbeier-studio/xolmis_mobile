import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../data/models/inventory.dart';
import '../providers/species_provider.dart';
import '../providers/poi_provider.dart';

import '../screens/inventory/species_detail_screen.dart';
import '../utils/utils.dart';
import '../generated/l10n.dart';

/// Displays a species record with count controls and POI shortcuts.
class SpeciesListItem extends StatefulWidget {
  final Species species;
  final VoidCallback onLongPress;

  /// Creates a tile for [species] and wires the long-press callback.
  const SpeciesListItem({
    super.key,
    required this.species,
    required this.onLongPress,
  });

  /// Creates the mutable state for [SpeciesListItem].
  @override
  SpeciesListItemState createState() => SpeciesListItemState();
}

/// State implementation for [SpeciesListItem].
class SpeciesListItemState extends State<SpeciesListItem> {
  bool _isAddingPoi = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        widget.species.name,
         style: const TextStyle(fontStyle: FontStyle.italic),
      ),
      subtitle: _buildSubtitle(),
      tileColor: widget.species.isOutOfInventory
          ? Theme.of(context).highlightColor
          : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_outlined),
              tooltip: S.of(context).decreaseIndividuals,
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
                      style: TextTheme.of(context).bodyMedium,
                    ),
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_outlined),
              tooltip: S.of(context).increaseIndividuals,
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      year2023: false,
                    ),
                  ) // Show a CircularProgressIndicator while _isAddingPoi is true
                      : pois.isNotEmpty
                      ? Badge.count(
                    backgroundColor: Colors.deepPurple[100],
                    textColor: Colors.deepPurple[800],
                    count: pois.length,
                    child: const Icon(Icons.add_location_outlined),
                  )
                      : const Icon(Icons.add_location_outlined),
                  tooltip: S.of(context).addPoi,
                  onPressed: _isAddingPoi ? null : () async {
                    setState(() {
                      _isAddingPoi = true;
                    });

                    // Get the current location
                    Position? position = await getPosition(context);

                    if (position != null) {
                      // Create a new POI
                      final poi = Poi(
                        speciesId: widget.species.id!,
                        sampleTime: DateTime.now(),
                        longitude: position.longitude,
                        latitude: position.latitude,
                      );

                      // Insert the POI in the database
                      if (context.mounted) {
                        poiProvider.addPoi(context, widget.species.id!, poi);
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            persist: true,
                            showCloseIcon: true,
                            backgroundColor: Theme.of(context).colorScheme.error,
                            content: Text(S.of(context).errorGettingLocation),
                          ),
                        );
                      }
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

  /// Builds the optional subtitle shown below the species name.
  Widget? _buildSubtitle() {
    final species = widget.species;
    final parts = <String>[];

    if (species.distance != null) {
      parts.add('Dist: ${species.distance} m');
    }
    if (species.flightHeight != null) {
      parts.add('Alt: ${species.flightHeight} m ${species.flightDirection ?? ''}');
    }
    if (species.notes != null && species.notes!.isNotEmpty) {
      parts.add(species.notes!);
    }

    if (parts.isEmpty) {
      return null; // Do not show subtitle if there is no data
    }

    return Text(
      parts.join(' | '), // Join parts with separator
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Shows a dialog that lets the user edit the species individual count.
  Future<void> _showEditCountDialog(BuildContext context) async {
    int? newCount = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int currentCount = widget.species.count;
        return AlertDialog(
          title: Text(S.of(context).editCount),
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
                    decoration: InputDecoration(
                      labelText: S.of(context).individualsCount,
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
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(currentCount),
              child: Text(S.of(context).save),
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