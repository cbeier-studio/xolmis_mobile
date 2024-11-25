import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../data/models/app_image.dart';
import '../../providers/nest_revision_provider.dart';
import '../../providers/app_image_provider.dart';

import '../app_image_screen.dart';

class NestRevisionsTab extends StatefulWidget {
  final Nest nest;

  const NestRevisionsTab(
      {super.key, required this.nest});

  @override
  State<NestRevisionsTab> createState() => _NestRevisionsTabState();
}

class _NestRevisionsTabState extends State<NestRevisionsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildNestRevisionList();
  }

  Future<void> _deleteNestRevision(NestRevision revision) async {
    final confirmed = await _showDeleteConfirmationDialog(context);
    if (confirmed) {
      Provider.of<NestRevisionProvider>(context, listen: false)
          .removeNestRevision(widget.nest.id!, revision.id!);
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar exclusão'),
          content: const Text('Tem certeza que deseja excluir esta revisão de ninho?'),
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

  Widget _buildNestRevisionList() {
    return Column(
      children: [
        Expanded(
          child: Consumer<NestRevisionProvider>(
              builder: (context, nestRevisionProvider, child) {
                final revisionList = nestRevisionProvider.getRevisionForNest(
                    widget.nest.id!);

                if (revisionList.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
                      child: Text('Nenhuma revisão de ninho registrada.'),
                    ),
                  );
                } else {
                  return RefreshIndicator(
                    onRefresh: () async {
                      await nestRevisionProvider.getRevisionForNest(
                          widget.nest.id ?? 0);
                    },
                    child: LayoutBuilder(
                        builder: (BuildContext context,
                            BoxConstraints constraints) {
                          final screenWidth = constraints.maxWidth;
                          final isLargeScreen = screenWidth > 600;

                          if (isLargeScreen) {
                            return _buildGridView(revisionList);
                          } else {
                            return _buildListView(revisionList);
                          }
                        }
                    ),
                  );
                }
              }
          ),
        )
      ],
    );
  }

  void _showBottomSheet(BuildContext context, NestRevision revision) {
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
                    title: const Text('Apagar revisão de ninho', style: TextStyle(color: Colors.red),),
                    onTap: () async {
                      await _deleteNestRevision(revision);
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

  Widget _buildGridView(List<NestRevision> revisionList) {
    return SingleChildScrollView(
      child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.2,
            ),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: revisionList.length,
            itemBuilder: (context, index) {
              final revision = revisionList[index];
              return GridTile(
                child: InkWell(
                  onLongPress: () =>
                      _showBottomSheet(context, revision),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppImageScreen(
                          nestRevisionId: revision.id,
                        ),
                      ),
                    );
                  },
                  child: NestRevisionGridItem(revision: revision),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<NestRevision> revisionList) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: revisionList.length,
      itemBuilder: (context, index) {
        final nestRevision = revisionList[index];
        return RevisionListItem(
          nestRevision: nestRevision,
          onLongPress: () =>
              _showBottomSheet(context, nestRevision),
        );
      },
    );
  }
}

class NestRevisionGridItem extends StatelessWidget {
  const NestRevisionGridItem({
    super.key,
    required this.revision,
  });

  final NestRevision revision;

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
                    .fetchImagesForNestRevision(revision.id!),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy HH:mm:ss').format(revision.sampleTime!),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold),
                ),
                Text('${nestStatusTypeFriendlyNames[revision.nestStatus]}: ${nestStageTypeFriendlyNames[revision.nestStage]}'),
                Text('Hospedeiro: ${revision.eggsHost ?? 0} ${Intl.plural(revision.eggsHost ?? 0, one: 'ovo', other: 'ovos')}, ${revision.nestlingsHost ?? 0} ${Intl.plural(revision.nestlingsHost ?? 0, one: 'ninhego', other: 'ninhegos')}'),
                Text('Nidoparasita: ${revision.eggsParasite ?? 0} ${Intl.plural(revision.eggsParasite ?? 0, one: 'ovo', other: 'ovos')}, ${revision.nestlingsParasite ?? 0} ${Intl.plural(revision.nestlingsParasite ?? 0, one: 'ninhego', other: 'ninhegos')}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RevisionListItem extends StatefulWidget {
  final NestRevision nestRevision;
  final VoidCallback onLongPress;

  const RevisionListItem({
    super.key,
    required this.nestRevision,
    required this.onLongPress,
  });

  @override
  RevisionListItemState createState() => RevisionListItemState();
}

class RevisionListItemState extends State<RevisionListItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FutureBuilder<List<AppImage>>(
        future: Provider.of<AppImageProvider>(context, listen: false)
            .fetchImagesForNestRevision(widget.nestRevision.id ?? 0),
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
      title: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.nestRevision.sampleTime!)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${nestStatusTypeFriendlyNames[widget.nestRevision.nestStatus]}: ${nestStageTypeFriendlyNames[widget.nestRevision.nestStage]}',
            style: TextStyle(
              color: widget.nestRevision.nestStatus == NestStatusType.nstActive
                  ? Colors.blue
                  : widget.nestRevision.nestStatus == NestStatusType.nstInactive
                  ? Colors.red
                  : null,
            ),
          ),
          Text('Hospedeiro: ${widget.nestRevision.eggsHost ?? 0} ${Intl.plural(widget.nestRevision.eggsHost ?? 0, one: 'ovo', other: 'ovos')}, ${widget.nestRevision.nestlingsHost ?? 0} ${Intl.plural(widget.nestRevision.nestlingsHost ?? 0, one: 'ninhego', other: 'ninhegos')}'),
          Text('Nidoparasita: ${widget.nestRevision.eggsParasite ?? 0} ${Intl.plural(widget.nestRevision.eggsParasite ?? 0, one: 'ovo', other: 'ovos')}, ${widget.nestRevision.nestlingsParasite ?? 0} ${Intl.plural(widget.nestRevision.nestlingsParasite ?? 0, one: 'ninhego', other: 'ninhegos')}'),
        ],
      ),
      onLongPress: widget.onLongPress,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppImageScreen(
              nestRevisionId: widget.nestRevision.id,
            ),
          ),
        );
      },

    );
  }
}