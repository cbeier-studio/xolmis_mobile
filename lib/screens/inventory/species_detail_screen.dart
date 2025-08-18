import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../providers/poi_provider.dart';
import '../../data/models/inventory.dart';

import '../../utils/utils.dart';
import '../../generated/l10n.dart';

class SpeciesDetailScreen extends StatefulWidget {
  final Species species;

  const SpeciesDetailScreen({super.key, required this.species});

  @override
  SpeciesDetailScreenState createState() => SpeciesDetailScreenState();
}

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
  Future<void> _loadSpeciesData() async {
    final poiProvider = Provider.of<PoiProvider>(context, listen: false);
    setState(() {
      widget.species.pois = poiProvider.getPoisForSpecies(widget.species.id ?? 0);
    });
  }

  // Add a new POI
  Future<void> _addPoi() async {
    setState(() {
      _isAddingPoi = true;
    });

    // Get the current location
    Position? position = await getPosition();

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

      // Update the UI
      // poiProvider.notifyListeners();

      // Show success message
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Row(
      //       children: [
      //         Icon(Icons.check_circle_outlined, color: Colors.green),
      //         SizedBox(width: 8),
      //         Text('POI inserido com sucesso!'),
      //       ],
      //     ),
      //   ),
      // );
    } else {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outlined, color: Colors.red),
                const SizedBox(width: 8),
                Text(S.of(context).errorGettingLocation),
              ],
            ),
          ),
        );
      }
    }

    setState(() {
      _isAddingPoi = false;
    });
  }

  // Delete a POI
  Future<void> _deletePoi(Poi poi) async {
    // Ask for user confirmation
    final confirmed = await _showDeleteConfirmationDialog(context);

    if (confirmed == true) {
      // Delete the POI from database
      if (mounted) {
        final poiProvider = Provider.of<PoiProvider>(context, listen: false);
        await poiProvider.removePoi(widget.species.id!, poi.id!);
      }

      // Update the UI
      // poiProvider.notifyListeners();
    }
  }

  // Show a dialog to confirm the deletion of a POI
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog.adaptive(
          title: Text(S.of(context).confirmDelete),
          content: Text(S.of(context).confirmDeleteMessage(1, "male", S.of(context).poi)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
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
        actions: [
          // Option to view species info
          IconButton(
            icon: const Icon(Icons.info_outlined),
            onPressed: () {
              _showSpeciesInfoDialog(context, widget.species);
            },
          ),
        ],
      ),
      body: Consumer<PoiProvider>(
              builder: (context, poiProvider, child) {
                // Get the POIs for the species
                final pois = poiProvider.getPoisForSpecies(widget.species.id ?? 0);
                return RefreshIndicator(
                  onRefresh: () async {
                    // Refresh the POIs
                    poiProvider.getPoisForSpecies(widget.species.id ?? 0);
                  },
                  child: Column(
                    children: [
                      Expanded(
                          child: pois.isEmpty
                            // Show message when there are no POIs
                              ? Center(child: Text(S.of(context).noPoiFound),)
                              : LayoutBuilder(
                              builder: (BuildContext context, BoxConstraints constraints) {
                                final screenWidth = constraints.maxWidth;
                                final isLargeScreen = screenWidth > 600;

                                if (isLargeScreen) {
                                  // Show grid view for large screens
                                  return _buildGridView(pois);
                                } else {
                                  // Show list view for small screens
                                  return _buildListView(pois, poiProvider);
                                }
                              }
                          ),
                        ), 
                    ],
                  ),                     
                );
              }
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Option to delete the POI
                  ListTile(
                    leading: const Icon(Icons.delete_outlined, color: Colors.red,),
                    title: Text(S.of(context).deletePoi, style: TextStyle(color: Colors.red),),
                    onTap: () async {                      
                      await _deletePoi(poi);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),                  
                ],
              ),
            );
          },
          ),
        );
      },
    );
  }

  // Build a grid view for large screens
  Widget _buildGridView(List<Poi> pois) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            // mainAxisSpacing: 16,
            // crossAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          shrinkWrap: true,
          itemCount: pois.length,
          itemBuilder: (context, index) {
            final poi = pois[index];
            return GridTile(
              child: InkWell(
                onLongPress: () => _showBottomSheet(context, poi),
                child: Card.outlined(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,                       
                      children: [
                        const Icon(Icons.location_on_outlined),
                        Expanded(child: SizedBox.shrink()),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${poi.latitude}'),
                            Text('${poi.longitude}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Build a list view for small screens
  Widget _buildListView(List<Poi> pois, PoiProvider poiProvider) {
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

  void _showSpeciesInfoDialog(BuildContext context, Species species) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog.adaptive(
          title: Text(S.of(context).speciesInfo),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                ListTile(
                  title: Text('${species.count} ${S.of(context).individual(species.count)}'),
                  subtitle: Text(S.of(context).count),
                ),
                ListTile(
                  title: Text('${species.sampleTime}'),
                  subtitle: Text(S.of(context).recordTime),
                ),
                ListTile(
                  title: Text(species.isOutOfInventory ? S.of(context).outOfSample : S.of(context).withinSample),
                ),
                if (species.notes != null && species.notes!.isNotEmpty)
                  ListTile(
                    title: Text(species.notes ?? ''),
                    subtitle: Text(S.of(context).notes),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).close),
            ),
          ],
        );
      },
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
        title: Text('${poi.latitude}, ${poi.longitude}'),
        leading: const Icon(Icons.location_on_outlined),
        onLongPress: onLongPress,
    );
  }
}