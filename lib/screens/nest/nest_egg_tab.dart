import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../providers/egg_provider.dart';

import 'egg_list_item.dart';

class EggsTab extends StatefulWidget {
  final Nest nest;

  const EggsTab(
      {super.key, required this.nest});

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
          return RefreshIndicator(
              onRefresh: () async {
            await eggProvider.getEggForNest(widget.nest.id ?? 0);
          },
        child: ListView.builder(
        itemCount: eggList.length,
        itemBuilder: (context, index) {
              final egg = eggList[index];
              return EggListItem(
                egg: egg,
                onLongPress: () => _showBottomSheet(context, egg),
              );
            },
          )
          );
        }
      },
    );
  }

  void _showBottomSheet(BuildContext context, Egg egg) {
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
                    title: const Text('Apagar ovo', style: TextStyle(color: Colors.red),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar exclusão'),
                            content: const Text('Tem certeza que deseja excluir este ovo?'),
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
                                  Provider.of<EggProvider>(context, listen: false)
                                      .removeEgg(widget.nest.id!, egg.id!);
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