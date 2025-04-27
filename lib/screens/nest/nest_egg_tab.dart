import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../data/models/app_image.dart';
import '../../providers/egg_provider.dart';
import '../../providers/app_image_provider.dart';

import '../app_image_screen.dart';
import '../../generated/l10n.dart';

import 'add_egg_screen.dart';

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
          title: Text(S.of(context).confirmDelete),
          content: Text(S.of(context).confirmDeleteMessage(1, "male", S.of(context).egg(1))),
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

  Widget _buildEggList() {
    return Column(
        children: [
          Expanded(
            child: Consumer<EggProvider>(
                builder: (context, eggProvider, child) {
                  final eggList = eggProvider.getEggForNest(
                      widget.nest.id!);
                  if (eggList.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
                        child: Text(S.of(context).noEggsFound),
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
                              final double minWidth = 340;
                              int crossAxisCountCalculated = (constraints.maxWidth / minWidth).floor();
                              return SingleChildScrollView(
      child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCountCalculated,
              childAspectRatio: 1,
            ),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: eggList.length,
            itemBuilder: (context, index) {
              final egg = eggList[index];
              // final isSelected = selectedEggs.contains(egg.id);
        return GridTile(
          child: InkWell(
            onLongPress: () =>
                _showBottomSheet(context, egg),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppImageScreen(
                    specimenId: egg.id,
                  ),
                ),
              );
            },
            child: Card.outlined(
              child: Stack(
                children: [
                  Column(
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
                              .fetchImagesForEgg(
      egg.id!),
                          builder: (context, snapshot) {
                            if (snapshot
        .connectionState ==
    ConnectionState.waiting) {
                              return const CircularProgressIndicator();
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
                  egg.fieldNumber!,
                  style: const TextStyle(
      fontSize: 20),
                ),
                Text(
                  egg.speciesName!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(egg.sampleTime!)),
                            
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Positioned(
                  //   top: 8,
                  //   right: 8,
                  //   child: Checkbox(
                  //     value: isSelected,
                  //     onChanged: (bool? value) {
                  //       setState(() {
                  //         if (value == true) {
                  //           selectedSpecimens
                  //               .add(specimen.id!);
                  //         } else {
                  //           selectedSpecimens
                  //               .remove(specimen.id);
                  //         }
                  //       });
                  //     },
                  //   ),
                  // ),
                ],
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
                              return _buildListView(eggList);
                            }
                          }
                      ),
                    );
                  }
                }
            ),
          )
        ]
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
                  ListTile(
                    title: Text(egg.fieldNumber!),
                  ),
                  Divider(),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(S.of(context).editEgg),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEggScreen(
                            nest: widget.nest,
                            egg: egg, 
                            isEditing: true, 
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
                    title: Text(S.of(context).deleteEgg, style: TextStyle(color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red
                        : Colors.redAccent,),),
                    onTap: () async {
                      await _deleteEgg(egg);
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

  Widget _buildGridView(List<Egg> eggList) {
    return SingleChildScrollView(
      child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
            ),
            physics: const NeverScrollableScrollPhysics(),
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
                  child: EggGridItem(egg: egg),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<Egg> eggList) {
    return ListView.separated(
      separatorBuilder: (context, index) => Divider(),
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

class EggGridItem extends StatelessWidget {
  const EggGridItem({
    super.key,
    required this.egg,
  });

  final Egg egg;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
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
    );
  }
}

class EggListItem extends StatefulWidget {
  final Egg egg;
  final VoidCallback onLongPress;

  const EggListItem({
    super.key,
    required this.egg,
    required this.onLongPress,
  });

  @override
  EggListItemState createState() => EggListItemState();
}

class EggListItemState extends State<EggListItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FutureBuilder<List<AppImage>>(
        future: Provider.of<AppImageProvider>(context, listen: false)
            .fetchImagesForEgg(widget.egg.id ?? 0),
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
      title: Text('${widget.egg.fieldNumber}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.egg.speciesName!,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.egg.sampleTime!)),
        ],
      ),
      onLongPress: widget.onLongPress,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppImageScreen(
              eggId: widget.egg.id,
            ),
          ),
        );
      },

    );
  }
}