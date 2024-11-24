import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/inventory.dart';
import '../../data/models/app_image.dart';

import '../../providers/vegetation_provider.dart';
import '../../providers/app_image_provider.dart';

import '../app_image_screen.dart';


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
      Provider.of<VegetationProvider>(context, listen: false)
          .removeVegetation(widget.inventory.id, vegetation.id!);
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Tem certeza que deseja excluir estes dados de vegetação?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
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
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
                        child: Text('Nenhum registro de vegetação.'),
                      ),
                    );
                  } else {
                    return RefreshIndicator(
                      onRefresh: () async {
                        await vegetationProvider.getVegetationForInventory(
                            widget.inventory.id);
                      },
                      child: LayoutBuilder(
                          builder: (BuildContext context, BoxConstraints constraints) {
                            final screenWidth = constraints.maxWidth;
                            final isLargeScreen = screenWidth > 600;

                            if (isLargeScreen) {
                              return _buildGridView(vegetationList);
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
        return BottomSheet(
          onClosing: () {},
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.delete_outlined, color: Colors.red,),
                    title: const Text('Apagar registro de vegetação', style: TextStyle(color: Colors.red),),
                    onTap: () async {
                      await _deleteVegetation(vegetation);
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridView(List<Vegetation> vegetationList) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: SingleChildScrollView(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.0,
            ),
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
                  child: Card.filled(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      child: Row(
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text('${vegetation.latitude}; ${vegetation.longitude}'),
                              Text('Herbáceas: ${vegetation.herbsDistribution?.index ?? 0}; ${vegetation.herbsProportion}%; ${vegetation.herbsHeight} cm'),
                              Text('Arbustos: ${vegetation.shrubsDistribution?.index ?? 0}; ${vegetation.shrubsProportion}%; ${vegetation.shrubsHeight} cm'),
                              Text('Árvores: ${vegetation.treesDistribution?.index ?? 0}; ${vegetation.treesProportion}%; ${vegetation.treesHeight} cm'),
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
      ),
    );
  }

  Widget _buildListView(List<Vegetation> vegetationList) {
    return ListView.builder(
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
            return const CircularProgressIndicator();
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
          Text('Herbáceas: ${widget.vegetation.herbsDistribution?.index ?? 0}; ${widget.vegetation.herbsProportion}%; ${widget.vegetation.herbsHeight} cm'),
          Text('Arbustos: ${widget.vegetation.shrubsDistribution?.index ?? 0}; ${widget.vegetation.shrubsProportion}%; ${widget.vegetation.shrubsHeight} cm'),
          Text('Árvores: ${widget.vegetation.treesDistribution?.index ?? 0}; ${widget.vegetation.treesProportion}%; ${widget.vegetation.treesHeight} cm'),
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