import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    return Column(
      children: [
        Consumer<EggProvider>(
            builder: (context, eggProvider, child) {
              final eggList = eggProvider.getEggForNest(
                  widget.nest.id!);
              if (eggList.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
                    child: Text('Nenhum ovo registrado.'),
                  ),
                );
              } else {
                return RefreshIndicator(
                  onRefresh: () async {
                    await eggProvider.getEggForNest(widget.nest.id ?? 0);
                  },
                  child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final screenWidth = constraints.maxWidth;
                        final isLargeScreen = screenWidth > 600;

                        if (isLargeScreen) {
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 840),
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 3.5,
                                ),
                                shrinkWrap: true,
                                itemCount: eggList.length,
                                itemBuilder: (context, index) {
                                  final egg = eggList[index];
                                  return GridTile(
                                    child: InkWell(
                                      onLongPress: () =>
                                          _showBottomSheet(context, egg),
                                      // onTap: () {
                                      //
                                      // },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(0.0, 16.0, 16.0, 16.0),
                                              child: const Icon(Icons.egg_outlined),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Text(
                                                  egg.fieldNumber!,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold),
                                                ),
                                                Text(
                                                  egg.speciesName!,
                                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                                ),
                                                Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(egg.sampleTime!)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        } else {
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: eggList.length,
                            itemBuilder: (context, index) {
                              final egg = eggList[index];
                              return EggListItem(
                                egg: egg,
                                onLongPress: () => _showBottomSheet(context, egg),
                              );
                            },
                          );
                        }
                      }
                  ),
                );
              }
            }
        ),
      ],
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