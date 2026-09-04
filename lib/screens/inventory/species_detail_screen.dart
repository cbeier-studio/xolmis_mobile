import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../providers/poi_provider.dart';
import '../../data/models/inventory.dart';

import '../../utils/utils.dart';
import '../../generated/l10n.dart';

/// Detail screen for a species record, including its POI samples.
class SpeciesDetailScreen extends StatefulWidget {
  final Species species;

  const SpeciesDetailScreen({super.key, required this.species});

  @override
  SpeciesDetailScreenState createState() => SpeciesDetailScreenState();
}

/// Manages POI loading, creation, and removal for the selected species.
class SpeciesDetailScreenState extends State<SpeciesDetailScreen> {
  bool _isAddingPoi = false;

  @override
  void initState() {
    super.initState();
    _loadSpeciesData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Load the POIs for the species
  /// Loads POIs already associated with this species.
  Future<void> _loadSpeciesData() async {
    final poiProvider = Provider.of<PoiProvider>(context, listen: false);
    setState(() {
      widget.species.pois = poiProvider.getPoisForSpecies(widget.species.id ?? 0);
    });
  }

  // Add a new POI
  /// Captures location and creates a new POI linked to the species.
  Future<void> _addPoi() async {
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
      if (mounted) {
        final poiProvider = Provider.of<PoiProvider>(context, listen: false);
        await poiProvider.addPoi(context, widget.species.id!, poi);
      }
    } else {
      if (mounted) {
        // Show error message
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
  }

  // Delete a POI
  /// Deletes a POI after user confirmation.
  Future<void> _deletePoi(Poi poi) async {
    // Ask for user confirmation
    final confirmed = await _showDeleteConfirmationDialog(context);

    if (confirmed == true) {
      // Delete the POI from database
      if (mounted) {
        final poiProvider = Provider.of<PoiProvider>(context, listen: false);
        await poiProvider.removePoi(widget.species.id!, poi.id!);
      }
    }
  }

  // Show a dialog to confirm the deletion of a POI
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirmDelete),
          content: Text(S.of(context).confirmDeleteMessage(1, "male", S.of(context).poi)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).delete),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.species.name),
      ),
      body: Column(
        children: [
          _buildInfoPanel(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                S.of(context).pointsOfOccurrence,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Consumer<PoiProvider>(
                builder: (context, poiProvider, child) {
                  // Get the POIs for the species
                  final pois = poiProvider.getPoisForSpecies(widget.species.id ?? 0);
                  return RefreshIndicator(
                    onRefresh: () async {
                      // Refresh the POIs
                      poiProvider.getPoisForSpecies(widget.species.id ?? 0);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                            child: _buildListView(pois, poiProvider)
                          ),
                      ],
                    ),
                  );
                }
            ),
          ),
      ],
      ),
      // FAB to add a new POI
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).newPoi,
        onPressed: () {
          _addPoi();
        },
        child: _isAddingPoi
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            year2023: false,
          ),
        )
            : const Icon(Icons.add_location_outlined),
      ),
    );
  }

  void _showBottomSheet(BuildContext context, Poi poi) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: BottomSheet(
          onClosing: () {},
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('POI #${poi.id}', style: TextTheme.of(context).bodyLarge,),
                  ),
                  const Divider(),
                  GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 4 : 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      buildGridMenuItem(
                          context, Icons.edit_outlined, S.current.details, () {
                        Navigator.of(context).pop();
                        _showEditNotesDialog(context, poi);
                      }),
                      buildGridMenuItem(context, Icons.delete_outlined,
                          S.of(context).delete, () async {
                            Navigator.of(context).pop();
                            await _deletePoi(poi);
                          }, color: Theme.of(context).colorScheme.error),
                    ],
                  ),
                ],
              ),
              ),
            );
          },
          ),
        );
      },
    );
  }

  // Build a list view for small screens
  Widget _buildListView(List<Poi> pois, PoiProvider poiProvider) {
    if (pois.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                Icons.location_on_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.surfaceDim
            ),
            const SizedBox(height: 8),
            Text(S.of(context).noPoiFound),
            const SizedBox(height: 8),
            ActionChip(
              label: Text(S.of(context).addPoi),
              avatar: const Icon(Icons.add_outlined),
              onPressed: () {
                _addPoi();
              },
            ),
          ],
        ),
      );
    } else {
      return ListView.builder(
        itemCount: pois.length,
        itemBuilder: (context, index) {
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
              return await _showDeleteConfirmationDialog(context);
            },
            onDismissed: (direction) async {
              // Delete the POI from database
              await poiProvider.removePoi(widget.species.id!, poi.id!);
            },
            child: PoiListItem(
              poi: poi,
              onLongPress: () => _showBottomSheet(context, poi),
            ),
          );
        },
      );
    }
  }

  // Show the dialog to edit POI notes
  void _showEditNotesDialog(BuildContext context, Poi poi) {
    final notesController = TextEditingController(text: poi.notes);
    final poiProvider = Provider.of<PoiProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).editNotes),
          content: TextField(
            controller: notesController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: S.of(context).notes,
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(S.of(context).save),
              onPressed: () async {
                poi.notes = notesController.text;
                final updatedPoi = poi.copyWith(notes: poi.notes);
                poiProvider.updatePoi(poi.speciesId, updatedPoi);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoPanel() {
    final species = widget.species;
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (species.sampleTime != null)
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm:ss').format(species.sampleTime!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  species.isOutOfInventory ? S.of(context).outOfSample : S.of(context).withinSample,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: species.isOutOfInventory ? Colors.orange : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              textBaseline: TextBaseline.alphabetic,
              children: [
            Text(
              '${species.count} ${S.of(context).individual(species.count)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
                  if (species.distance != null) ...[
                    const SizedBox(width: 8),
                    const Text('•'),
                    const SizedBox(width: 8),
                    _buildInfoItem(Icons.straighten, '${species.distance} m', S.current.distance),
                  ],
                  if (species.flightHeight != null) ...[
                    const SizedBox(width: 8),
                    const Text('•'),
                    const SizedBox(width: 4),
                    _buildInfoItem(Icons.height, '${species.flightHeight} m', S.current.flightHeight),
                  ],
                  if (species.flightDirection != null && species.flightDirection!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    // const Text('•'),
                    // const SizedBox(width: 8),
                    Text(species.flightDirection!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
            ],
            ),
            if (species.notes != null && species.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                species.notes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

// POI list item
class PoiListItem extends StatelessWidget {
  final Poi poi;
  final VoidCallback onLongPress;

  const PoiListItem({
    super.key,
    required this.poi,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text('POI #${poi.id}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show the POI coordinates
            Text('${poi.latitude}, ${poi.longitude}'),
            // Show the POI notes
            if (poi.notes != null && poi.notes!.isNotEmpty)
              Text(poi.notes!, overflow: TextOverflow.ellipsis,),
          ],
        ),
        leading: const Icon(Icons.location_on_outlined),
        onLongPress: onLongPress,
    );
  }
}