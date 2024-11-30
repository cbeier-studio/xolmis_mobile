import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../data/models/app_image.dart';
import '../../providers/nest_revision_provider.dart';
import '../../providers/app_image_provider.dart';

import '../app_image_screen.dart';
import '../../generated/l10n.dart';

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
          title: Text(S.of(context).confirmDelete),
          content: Text(S.of(context).confirmDeleteMessage(1, "female", S.of(context).revision(1).toLowerCase())),
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

  Widget _buildNestRevisionList() {
    return Column(
      children: [
        Expanded(
          child: Consumer<NestRevisionProvider>(
              builder: (context, nestRevisionProvider, child) {
                final revisionList = nestRevisionProvider.getRevisionForNest(
                    widget.nest.id!);

                if (revisionList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
                      child: Text(S.of(context).noRevisionsFound),
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
                    title: Text(S.of(context).deleteRevision, style: TextStyle(color: Colors.red),),
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
                Text('${S.of(context).host}: ${revision.eggsHost ?? 0} ${S.of(context).egg(revision.eggsHost ?? 0)}, ${revision.nestlingsHost ?? 0} ${S.of(context).nestling(revision.nestlingsHost ?? 0).toLowerCase()}'),
                Text('${S.of(context).nidoparasite}: ${revision.eggsParasite ?? 0} ${S.of(context).egg(revision.eggsParasite ?? 0)}, ${revision.nestlingsParasite ?? 0} ${S.of(context).nestling(revision.nestlingsParasite ?? 0).toLowerCase()}'),
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
          Text('${S.of(context).host}: ${widget.nestRevision.eggsHost ?? 0} ${S.of(context).egg(widget.nestRevision.eggsHost ?? 0)}, ${widget.nestRevision.nestlingsHost ?? 0} ${S.of(context).nestling(widget.nestRevision.nestlingsHost ?? 0).toLowerCase()}'),
          Text('${S.of(context).nidoparasite}: ${widget.nestRevision.eggsParasite ?? 0} ${S.of(context).egg(widget.nestRevision.eggsParasite ?? 0)}, ${widget.nestRevision.nestlingsParasite ?? 0} ${S.of(context).nestling(widget.nestRevision.nestlingsParasite ?? 0).toLowerCase()}'),
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