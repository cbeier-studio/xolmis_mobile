import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../providers/egg_provider.dart';

import 'egg_list_item.dart';

class EggsTab extends StatefulWidget {
  final Nest nest;
  final GlobalKey<AnimatedListState> eggListKey;

  const EggsTab(
      {super.key, required this.nest, required this.eggListKey});

  @override
  State<EggsTab> createState() => _EggsTabState();
}

class _EggsTabState extends State<EggsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildEggList();
  }

  Widget _buildEggList() {
    return Consumer<EggProvider>(
      builder: (context, eggProvider, child) {
        final eggList = eggProvider.getEggForNest(
            widget.nest.id!);
        if (eggList.isEmpty) {
          return const Center(
            child: Text('Nenhum ovo registrado.'),
          );
        } else {
          return AnimatedList(
            key: widget.eggListKey,
            initialItemCount: eggList.length,
            itemBuilder: (context, index, animation) {
              final egg = eggList[index];
              return EggListItem(
                egg: egg,
                animation: animation,
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirmar exclusão'),
                        content: const Text(
                            'Tem certeza que deseja excluir este ovo?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                              final indexToRemove = eggList.indexOf(
                                  egg);
                              eggProvider.removeEgg(
                                  widget.nest.id!, egg.id!).then((
                                  _) {
                                widget.eggListKey.currentState?.removeItem(
                                  indexToRemove,
                                      (context, animation) =>
                                      EggListItem(
                                          egg: egg,
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