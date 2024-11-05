import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../data/models/app_image.dart';
import '../../providers/egg_provider.dart';
import '../../providers/app_image_provider.dart';

import '../app_image_screen.dart';

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

  Future<void> _deleteEgg(Egg egg) async {
    final confirmed = await _showDeleteConfirmationDialog(context);
    if (confirmed) {
      Provider.of<EggProvider>(context, listen: false)
          .removeEgg(widget.nest.id!, egg.id!);
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Tem certeza que deseja excluir este ovo?'),
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

  Widget _buildEggList() {
    return Expanded(
      child: Consumer<EggProvider>(
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
                          return _buildGridView(eggList);
                        } else {
                          return _buildListView(eggList);
                        }
                      }
                  ),
                );
              }
            }
        ),
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
                      _deleteEgg(egg);
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

  Widget _buildGridView(List<Egg> eggList) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: SingleChildScrollView(
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppImageScreen(
                          eggId: egg.id,
                        ),
                      ),
                    );
                  },
                  child: Card.filled(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0.0, 16.0, 16.0, 16.0),
                            child: FutureBuilder<List<AppImage>>(
                              future: Provider.of<AppImageProvider>(context, listen: false)
                                  .fetchImagesForEgg(egg.id!),
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
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Egg> eggList) {
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