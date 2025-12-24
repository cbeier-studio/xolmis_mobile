import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../data/models/app_image.dart';
import '../../providers/egg_provider.dart';
import '../../providers/app_image_provider.dart';

import '../images/app_image_screen.dart';
import '../../utils/utils.dart';
import '../../generated/l10n.dart';

import 'add_egg_screen.dart';

class EggsTab extends StatefulWidget {
  final Nest nest;

  const EggsTab({super.key, required this.nest});

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
      Provider.of<EggProvider>(
        context,
        listen: false,
      ).removeEgg(widget.nest.id!, egg.id!);
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog.adaptive(
              title: Text(S.of(context).confirmDelete),
              content: Text(
                S
                    .of(context)
                    .confirmDeleteMessage(1, "male", S.of(context).egg(1)),
              ),
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
        ) ??
        false;
  }

  Future<void> _showAddEggScreen(BuildContext context) async {
    final eggProvider = Provider.of<EggProvider>(context, listen: false);
    int nextNumber = await eggProvider.getNextSequentialNumber(widget.nest.fieldNumber!);
    if (MediaQuery.sizeOf(context).width > 600) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: AddEggScreen(
                  nest: widget.nest,
                  initialFieldNumber: '${widget.nest.fieldNumber}-${nextNumber.toString().padLeft(2, '0')}',
                  initialSpeciesName: widget.nest.speciesName,)
            ),
          );
        },
      ).then((newEgg) {
        // Reload the egg list
        if (newEgg != null) {
          eggProvider.getEggForNest(widget.nest.id!);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddEggScreen(
          nest: widget.nest,
          initialFieldNumber: '${widget.nest.fieldNumber}-${nextNumber.toString().padLeft(2, '0')}',
          initialSpeciesName: widget.nest.speciesName,)
        ),
      ).then((newEgg) {
        // Reload the egg list
        if (newEgg != null) {
          eggProvider.getEggForNest(widget.nest.id!);
        }
      });
    }
  }

  Widget _buildEggList() {
    return Column(
      children: [
        Expanded(
          child: Consumer<EggProvider>(
            builder: (context, eggProvider, child) {
              final eggList = eggProvider.getEggForNest(widget.nest.id!);
              if (eggList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.egg_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.surfaceDim,
                        ),
                        const SizedBox(height: 8),
                        Text(S.of(context).noEggsFound),
                        const SizedBox(height: 8),
                        ActionChip(
                          label: Text(S.of(context).newEgg),
                          avatar: const Icon(Icons.add_outlined),
                          onPressed: () {
                            _showAddEggScreen(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return RefreshIndicator(
                  onRefresh: () async {
                    await eggProvider.getEggForNest(widget.nest.id ?? 0);
                  },
                  child: _buildListView(eggList),
                      
                    
                  
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _showBottomSheet(BuildContext context, Egg egg) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: BottomSheet(
          onClosing: () {},
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(egg.fieldNumber!, style: TextTheme.of(context).bodyLarge,),
                  ),
                  // ListTile(title: Text(egg.fieldNumber!)),
                  const Divider(),
                  GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 4 : 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      buildGridMenuItem(
                          context, Icons.edit_outlined, S.current.edit, () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => AddEggScreen(
                              nest: widget.nest,
                              egg: egg,
                              isEditing: true,
                            ),
                          ),
                        );
                      }),
                      buildGridMenuItem(context, Icons.delete_outlined,
                          S.of(context).delete, () async {
                            Navigator.of(context).pop();
                            await _deleteEgg(egg);
                          }, color: Theme.of(context).colorScheme.error),
                    ],
                  ),
                ],
              ),
              ),
            );
          },
          ),
        );
      },
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
  const EggGridItem({super.key, required this.egg});

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
                future: Provider.of<AppImageProvider>(
                  context,
                  listen: false,
                ).fetchImagesForEgg(egg.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(year2023: false,);
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  egg.fieldNumber!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
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

  const EggListItem({super.key, required this.egg, required this.onLongPress});

  @override
  EggListItemState createState() => EggListItemState();
}

class EggListItemState extends State<EggListItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FutureBuilder<List<AppImage>>(
        future: Provider.of<AppImageProvider>(
          context,
          listen: false,
        ).fetchImagesForEgg(widget.egg.id ?? 0),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(year2023: false,);
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
          Text(
            DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.egg.sampleTime!),
          ),
        ],
      ),
      onLongPress: widget.onLongPress,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppImageScreen(eggId: widget.egg.id),
          ),
        );
      },
    );
  }
}
