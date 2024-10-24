import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory.dart';
import '../providers/vegetation_provider.dart';
import 'vegetation_list_item.dart';

class VegetationTab extends StatefulWidget {
  final Inventory inventory;
  final GlobalKey<AnimatedListState> vegetationListKey;

  const VegetationTab({super.key, required this.inventory, required this.vegetationListKey});

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
          return AnimatedList(
            key: widget.vegetationListKey,
            initialItemCount: vegetationList.length,
            itemBuilder: (context, index, animation) {
              final vegetation = vegetationList[index];
              return VegetationListItem(
                vegetation: vegetation,
                animation: animation,
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirmar exclusão'),
                        content: const Text(
                            'Tem certeza que deseja excluir estes dados de vegetação?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                              final indexToRemove = vegetationList.indexOf(
                                  vegetation);
                              vegetationProvider.removeVegetation(
                                  widget.inventory.id, vegetation.id!).then((
                                  _) {
                                widget.vegetationListKey.currentState?.removeItem(
                                  indexToRemove,
                                      (context, animation) =>
                                      VegetationListItem(
                                          vegetation: vegetation,
                                          animation: animation,
                                          onDelete: () {}),
                                );
                              });
                            },
                            child: const Text('Excluir'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}