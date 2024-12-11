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

  Future<void> _loadSpeciesData() async {
    final poiProvider = Provider.of<PoiProvider>(context, listen: false);
    setState(() {
      widget.species.pois = poiProvider.getPoisForSpecies(widget.species.id ?? 0);
    });
  }

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
        longitude: position.longitude,
        latitude: position.latitude,
      );

      // Insert the POI in the database
      final poiProvider = Provider.of<PoiProvider>(context, listen: false);
      await poiProvider.addPoi(context, widget.species.id!, poi);

      // Update the UI
      poiProvider.notifyListeners();

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
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text(S.of(context).errorGettingLocation),
            ],
          ),
        ),
      );
    }

    setState(() {
      _isAddingPoi = false;
    });
  }

  Future<void> _deletePoi(Poi poi) async {
    // Ask for user confirmation
    final confirmed = await _showDeleteConfirmationDialog(context);

    if (confirmed == true) {
      // Delete the POI from database
      final poiProvider = Provider.of<PoiProvider>(context, listen: false);
      await poiProvider.removePoi(widget.species.id!, poi.id!);

      // Update the UI
      poiProvider.notifyListeners();
    }
  }

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
      body: Consumer<PoiProvider>(
              builder: (context, poiProvider, child) {
                final pois = poiProvider.getPoisForSpecies(widget.species.id ?? 0);
                return RefreshIndicator(
                  onRefresh: () async {
                    await poiProvider.getPoisForSpecies(widget.species.id ?? 0);
                  },
                  child: Column(
                      children: [
                        ExpansionTile(
                          leading: const Icon(Icons.info_outlined),
                          title: Text(S.of(context).speciesInfo),
                          children: [
                            ListTile(
                              title: Text('${widget.species.count} ${S.of(context).individual(widget.species.count)}'),
                              subtitle: Text(S.of(context).count),
                            ),
                            ListTile(
                              title: Text(widget.species.isOutOfInventory ? S.of(context).outOfSample : S.of(context).withinSample),
                            ),
                            ListTile(
                              title: Text(widget.species.notes ?? ''),
                              subtitle: Text(S.of(context).notes),
                            ),
                          ],
                        ),
                        Expanded(
                          child: pois.isEmpty
                              ?  Center(
                            child: Text(S.of(context).noPoiFound),
                          )
                              : LayoutBuilder(
                              builder: (BuildContext context, BoxConstraints constraints) {
                                final screenWidth = constraints.maxWidth;
                                final isLargeScreen = screenWidth > 600;

                                if (isLargeScreen) {
                                  return _buildGridView(pois);
                                } else {
                                  return _buildListView(pois, poiProvider);
                                }
                              }
                          ),
                        ),
                      ]
                  ),
                );
              }
          ),
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).newPoi,
        onPressed: () {
          _addPoi();
        },
        child: _isAddingPoi
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.add_location_outlined),
      ),
    );
  }

  void _showBottomSheet(BuildContext context, Poi poi) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return BottomSheet(
          onClosing: () {},
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Expanded(
                  //     child:
                  ListTile(
                    leading: const Icon(Icons.delete_outlined, color: Colors.red,),
                    title: Text(S.of(context).deletePoi, style: TextStyle(color: Colors.red),),
                    onTap: () async {                      
                      await _deletePoi(poi);
                      Navigator.pop(context);
                    },
                  )
                  // )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridView(List<Poi> pois) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.5,
          ),
          shrinkWrap: true,
          itemCount: pois.length,
          itemBuilder: (context, index) {
            final poi = pois[index];
            return GridTile(
              child: InkWell(
                onLongPress: () => _showBottomSheet(context, poi),
                // onTap: () {
                //
                // },
                child: Card.filled(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0.0, 16.0, 16.0, 16.0),
                          child: const Icon(Icons.location_on_outlined),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${poi.latitude}, ${poi.longitude}'),
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
}

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