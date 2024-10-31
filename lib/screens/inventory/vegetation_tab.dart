import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/inventory.dart';
import '../../providers/vegetation_provider.dart';
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
    return Consumer<VegetationProvider>(
      builder: (context, vegetationProvider, child) {
        final vegetationList = vegetationProvider.getVegetationForInventory(
            widget.inventory.id);
        if (vegetationList.isEmpty) {
          return const Center(
            child: Text('Nenhum dado de vegetação registrado.'),
          );
        } else {
          return RefreshIndicator(
              onRefresh: () async {
            await vegetationProvider.getVegetationForInventory(widget.inventory.id);
          },
        child: ListView.builder(
        itemCount: vegetationList.length,
        itemBuilder: (context, index) {
              final vegetation = vegetationList[index];
              return VegetationListItem(
                vegetation: vegetation,
                onLongPress: () => _showBottomSheet(context, vegetation),
              );
            },
          )
          );
        }
      },
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