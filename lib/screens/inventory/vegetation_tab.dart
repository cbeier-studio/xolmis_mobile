import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/inventory.dart';
import '../../providers/vegetation_provider.dart';
import '../app_image_screen.dart';
import 'vegetation_list_item.dart';

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

  Widget _buildVegetationList() {
    return Expanded(
        child: Consumer<VegetationProvider>(
        builder: (context, vegetationProvider, child) {
          final vegetationList = vegetationProvider.getVegetationForInventory(
              widget.inventory.id);
          if (vegetationList.isEmpty) {
            return const Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
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
                                  child: Card(
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
                    } else {
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
              ),
            );
          }
        }
    )
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
                  // Expanded(
                  //     child:
                  ListTile(
                    leading: const Icon(Icons.delete_outlined, color: Colors.red,),
                    title: const Text('Apagar registro de vegetação', style: TextStyle(color: Colors.red),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar exclusão'),
                            content: const Text('Tem certeza que deseja excluir estes dados de vegetação?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                  Navigator.of(context).pop();
                                  // Call the function to delete species
                                  Provider.of<VegetationProvider>(context, listen: false)
                                      .removeVegetation(widget.inventory.id, vegetation.id!);
                                },
                                child: const Text('Excluir'),
                              ),
                            ],
                          );
                        },
                      );
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
}