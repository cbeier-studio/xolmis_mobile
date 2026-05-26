import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/inventory.dart';
import '../../data/models/app_image.dart';

import '../../providers/vegetation_provider.dart';
import '../../providers/app_image_provider.dart';

import '../images/app_image_screen.dart';
import '../../utils/utils.dart';
import '../../generated/l10n.dart';
import 'add_vegetation_screen.dart';


/// Inventory tab that lists vegetation samples and attached images.
class VegetationTab extends StatefulWidget {
  final Inventory inventory;

  const VegetationTab({super.key, required this.inventory});

  @override
  State<VegetationTab> createState() => _VegetationTabState();
}

/// Handles vegetation CRUD actions and responsive presentation.
class _VegetationTabState extends State<VegetationTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildVegetationList();
  }

  /// Deletes a vegetation record after confirmation.
  Future<void> _deleteVegetation(Vegetation vegetation) async {
    final confirmed = await _showDeleteConfirmationDialog(context);
    if (confirmed) {
      Provider.of<VegetationProvider>(context, listen: false).removeVegetation(widget.inventory.id, vegetation.id!);
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog.adaptive(
          title: Text(S.of(context).confirmDelete),
          content: Text(S.of(context).confirmDeleteMessage(2, "male", S.of(context).vegetationData.toLowerCase())),
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

  /// Opens the vegetation form using dialog or full screen based on width.
  void _showAddVegetationScreen(BuildContext context) {
    final vegetationProvider = Provider.of<VegetationProvider>(context, listen: false);
    if (MediaQuery.sizeOf(context).width > 600) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AddVegetationDataScreen(inventory: widget.inventory),
            ),
          );
        },
      ).then((newVegetation) async {
        // Reload the vegetation list
        if (newVegetation != null) {
          await vegetationProvider.loadVegetationForInventory(widget.inventory.id);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddVegetationDataScreen(inventory: widget.inventory),
        ),
      ).then((newVegetation) async {
        // Reload the vegetation list
        if (newVegetation != null) {
          await vegetationProvider.loadVegetationForInventory(widget.inventory.id);
        }
      });
    }
  }

  Widget _buildVegetationList() {
    return Column(
      children: [
        Expanded(
            child: Consumer<VegetationProvider>(
                builder: (context, vegetationProvider, child) {
                  final vegetationList = vegetationProvider.getVegetationForInventory(
                      widget.inventory.id);
                  if (vegetationList.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_florist_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.surfaceDim,
                            ),
                            const SizedBox(height: 8),
                            Text(S.of(context).noVegetationFound),
                            const SizedBox(height: 8),
                            ActionChip(
                              label: Text(S.of(context).newVegetation),
                              avatar: const Icon(Icons.add_outlined),
                              onPressed: () {
                                _showAddVegetationScreen(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return RefreshIndicator(
                      onRefresh: () async {
                        await vegetationProvider.loadVegetationForInventory(
                            widget.inventory.id);
                      },
                      child: _buildListView(vegetationList),
                    );
                  }
                }
            )
        )
      ],
    );
  }

  void _showBottomSheet(BuildContext context, Vegetation vegetation) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: BottomSheet(
          onClosing: () {},
          builder: (BuildContext innerContext) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat('dd/MM/yyyy HH:mm:ss').format(vegetation.sampleTime!),
                      style: TextTheme.of(innerContext).bodyLarge,
                    ),
                  ),
                  const Divider(),
                  GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(innerContext).width < 600 ? 4 : 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      buildGridMenuItem(
                          innerContext, Icons.edit_outlined, S.current.edit, () {
                        Navigator.of(innerContext).pop();
                        _showEditVegetationScreen(context, vegetation);
                      }),
                      buildGridMenuItem(innerContext, Icons.delete_outlined,
                          S.of(innerContext).delete, () async {
                            Navigator.of(innerContext).pop();
                            await _deleteVegetation(vegetation);
                          }, color: Theme.of(innerContext).colorScheme.error),
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

  void _showEditVegetationScreen(BuildContext context, Vegetation vegetation) {
    final vegetationProvider = Provider.of<VegetationProvider>(context, listen: false);
    if (MediaQuery.sizeOf(context).width > 600) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AddVegetationDataScreen(
                inventory: widget.inventory,
                vegetation: vegetation,
                isEditing: true,
              ),
            ),
          );
        },
      ).then((result) async {
        if (result != null) {
          await vegetationProvider.loadVegetationForInventory(widget.inventory.id);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddVegetationDataScreen(
            inventory: widget.inventory,
            vegetation: vegetation,
            isEditing: true,
          ),
        ),
      ).then((result) async {
        if (result != null) {
          await vegetationProvider.loadVegetationForInventory(widget.inventory.id);
        }
      });
    }
  }

  Widget _buildListView(List<Vegetation> vegetationList) {
    return ListView.separated(
      separatorBuilder: (context, index) => Divider(),
      shrinkWrap: true,
      itemCount: vegetationList.length,
      itemBuilder: (context, index) {
        final vegetation = vegetationList[index];
        return VegetationListItem(
          vegetation: vegetation,
          onLongPress: () =>
              _showBottomSheet(context, vegetation),
        );
      },
    );
  }
}

class VegetationGridItem extends StatelessWidget {
  const VegetationGridItem({
    super.key,
    required this.vegetation,
  });

  final Vegetation vegetation;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: Wrap (
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 16.0, 16.0, 16.0),
                  child: const Icon(Icons.local_florist_outlined),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm:ss').format(vegetation.sampleTime!),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${vegetation.latitude}; ${vegetation.longitude}'),
                    Text('${S.of(context).herbs}: ${vegetation.herbsDistribution?.index ?? 0}; ${vegetation.herbsProportion}%; ${vegetation.herbsHeight} cm'),
                    Text('${S.of(context).shrubs}: ${vegetation.shrubsDistribution?.index ?? 0}; ${vegetation.shrubsProportion}%; ${vegetation.shrubsHeight} cm'),
                    Text('${S.of(context).trees}: ${vegetation.treesDistribution?.index ?? 0}; ${vegetation.treesProportion}%; ${vegetation.treesHeight} cm'),
                    Text('${vegetation.notes}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VegetationListItem extends StatefulWidget {
  final Vegetation vegetation;
  final VoidCallback onLongPress;

  const VegetationListItem({
    super.key,
    required this.vegetation,
    required this.onLongPress,
  });

  @override
  VegetationListItemState createState() => VegetationListItemState();
}

class VegetationListItemState extends State<VegetationListItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FutureBuilder<List<AppImage>>(
        future: Provider.of<AppImageProvider>(context, listen: false)
            .fetchImagesForVegetation(widget.vegetation.id ?? 0),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(
              year2023: false,
            );
          } else if (snapshot.hasError) {
            return const Icon(Icons.error);
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: Image.file(
                File(snapshot.data!.first.imagePath),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            );
          } else {
            return const Icon(Icons.hide_image_outlined);
          }
        },
      ),
      title: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.vegetation.sampleTime!)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.vegetation.latitude}; ${widget.vegetation.longitude}'),
          Text('${S.of(context).herbs}: ${widget.vegetation.herbsDistribution?.index ?? 0}; ${widget.vegetation.herbsProportion}%; ${widget.vegetation.herbsHeight} cm'),
          Text('${S.of(context).shrubs}: ${widget.vegetation.shrubsDistribution?.index ?? 0}; ${widget.vegetation.shrubsProportion}%; ${widget.vegetation.shrubsHeight} cm'),
          Text('${S.of(context).trees}: ${widget.vegetation.treesDistribution?.index ?? 0}; ${widget.vegetation.treesProportion}%; ${widget.vegetation.treesHeight} cm'),
          Text('${widget.vegetation.notes}'),
        ],
      ),
      onLongPress: widget.onLongPress,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppImageScreen(
              vegetationId: widget.vegetation.id,
            ),
          ),
        );
      },
    );
  }
}