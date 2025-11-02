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


class VegetationTab extends StatefulWidget {
  final Inventory inventory;

  const VegetationTab({super.key, required this.inventory});

  @override
  State<VegetationTab> createState() => _VegetationTabState();
}

class _VegetationTabState extends State<VegetationTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildVegetationList();
  }

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
                        child: Text(S.of(context).noVegetationFound),
                      ),
                    );
                  } else {
                    return RefreshIndicator(
                      onRefresh: () async {
                        await vegetationProvider.loadVegetationForInventory(
                            widget.inventory.id);
                      },
                      child: LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            final screenWidth = constraints.maxWidth;
                            final isLargeScreen = screenWidth > 600;

                            if (isLargeScreen) {
                              final double minWidth = 340;
                              int crossAxisCountCalculated = (constraints.maxWidth / minWidth).floor();
                              return SingleChildScrollView(
        child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: SingleChildScrollView(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCountCalculated,
              childAspectRatio: 1,
            ),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: vegetationList.length,
            itemBuilder: (context, index) {
              final vegetation = vegetationList[index];
              return GridTile(
                child: InkWell(
                  onLongPress: () =>
                      _showBottomSheet(context, vegetation),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppImageScreen(
                          vegetationId: vegetation.id,
                        ),
                      ),
                    );
                  },
                  child: Card.outlined(
      child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child:
                        FutureBuilder<List<AppImage>>(
                      future: Provider.of<
                                  AppImageProvider>(
                              context,
                              listen: false)
                          .fetchImagesForVegetation(
                              vegetation.id!),
                      builder: (context, snapshot) {
                        if (snapshot
                                .connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator(
                            year2023: false,
                          );
                        } else if (snapshot
                            .hasError) {
                          return const Icon(
                              Icons.error);
                        } else if (snapshot.hasData &&
                            snapshot
                                .data!.isNotEmpty) {
                          return ClipRRect(
                            borderRadius:
                                BorderRadius.vertical(
                                    top: Radius
                                        .circular(
                                            12.0)),
                            child: Image.file(
                              File(snapshot.data!
                                  .first.imagePath),
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          );
                        } else {
                          return const Center(
                              child: Icon(Icons
                                  .hide_image_outlined));
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.end,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [                        
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm:ss').format(vegetation.sampleTime!),
                          style: TextTheme.of(context).bodyLarge,
                        ),
                        Text('${vegetation.latitude}; ${vegetation.longitude}'),
                        Text('${S.of(context).herbs}: ${vegetation.herbsDistribution?.index ?? 0}; ${vegetation.herbsProportion}%; ${vegetation.herbsHeight} cm'),
                        Text('${S.of(context).shrubs}: ${vegetation.shrubsDistribution?.index ?? 0}; ${vegetation.shrubsProportion}%; ${vegetation.shrubsHeight} cm'),
                        Text('${S.of(context).trees}: ${vegetation.treesDistribution?.index ?? 0}; ${vegetation.treesProportion}%; ${vegetation.treesHeight} cm'),
                        if (vegetation.notes!.isNotEmpty) 
                          Text('${vegetation.notes}'),
                      ],
                    ),
                  ),
                ],
              ),
      
    ),
                ),
              );
            },
          ),
        ),
      ),
        ),
    );
                            } else {
                              return _buildListView(vegetationList);
                            }
                          }
                      ),
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
                  ListTile(
                    title: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(vegetation.sampleTime!),),
                  ),
                  Divider(),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      buildGridMenuItem(
                          context, Icons.edit_outlined, S.current.edit, () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddVegetationDataScreen(
                              inventory: widget.inventory,
                              vegetation: vegetation,
                              isEditing: true,
                            ),
                          ),
                        );
                      }),
                      buildGridMenuItem(context, Icons.delete_outlined,
                          S.of(context).delete, () async {
                            Navigator.of(context).pop();
                            await _deleteVegetation(vegetation);
                          }, color: Theme.of(context).colorScheme.error),
                    ],
                  ),
                  /*
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(S.of(context).editVegetation),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddVegetationDataScreen(
                            inventory: widget.inventory,
                            vegetation: vegetation, // Passe o objeto Vegetation
                            isEditing: true, // Defina isEditing como true
                          ),
                        ),
                      );
                    },
                  ),
                  // Divider(),
                  ListTile(
                    leading: Icon(Icons.delete_outlined, color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red
                        : Colors.redAccent,),
                    title: Text(S.of(context).deleteVegetation, style: TextStyle(color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red
                        : Colors.redAccent,),),
                    onTap: () async {
                      await _deleteVegetation(vegetation);
                      Navigator.pop(context);
                    },
                  )
                  */
                ],
              ),
            );
          },
          ),
        );
      },
    );
  }

  // Widget _buildGridView(List<Vegetation> vegetationList) {
  //   return SingleChildScrollView(
  //       child: Align(
  //     alignment: Alignment.topCenter,
  //     child: ConstrainedBox(
  //       constraints: const BoxConstraints(maxWidth: 840),
  //       child: SingleChildScrollView(
  //         child: GridView.builder(
  //           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //             crossAxisCount: 2,
  //             childAspectRatio: 2.8,
  //           ),
  //           physics: const NeverScrollableScrollPhysics(),
  //           shrinkWrap: true,
  //           itemCount: vegetationList.length,
  //           itemBuilder: (context, index) {
  //             final vegetation = vegetationList[index];
  //             return GridTile(
  //               child: InkWell(
  //                 onLongPress: () =>
  //                     _showBottomSheet(context, vegetation),
  //                 onTap: () {
  //                   Navigator.push(
  //                     context,
  //                     MaterialPageRoute(
  //                       builder: (context) => AppImageScreen(
  //                         vegetationId: vegetation.id,
  //                       ),
  //                     ),
  //                   );
  //                 },
  //                 child: VegetationGridItem(vegetation: vegetation),
  //               ),
  //             );
  //           },
  //         ),
  //       ),
  //     ),
  //       ),
  //   );
  // }

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