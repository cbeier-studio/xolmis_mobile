import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../data/models/app_image.dart';
import '../../providers/nest_revision_provider.dart';
import '../../providers/app_image_provider.dart';

import '../images/app_image_screen.dart';
import '../../core/core_consts.dart';
import '../../utils/utils.dart';
import '../../generated/l10n.dart';

import 'add_revision_screen.dart';

class NestRevisionsTab extends StatefulWidget {
  final Nest nest;

  const NestRevisionsTab({super.key, required this.nest});

  @override
  State<NestRevisionsTab> createState() => _NestRevisionsTabState();
}

class _NestRevisionsTabState extends State<NestRevisionsTab>
    with AutomaticKeepAliveClientMixin {
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
      Provider.of<NestRevisionProvider>(
        context,
        listen: false,
      ).removeNestRevision(widget.nest.id!, revision.id!);
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
                    .confirmDeleteMessage(
                      1,
                      "female",
                      S.of(context).revision(1).toLowerCase(),
                    ),
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

  void _showAddRevisionScreen(BuildContext context) {
    final revisionProvider = Provider.of<NestRevisionProvider>(context, listen: false);
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
              child: AddNestRevisionScreen(nest: widget.nest),
            ),
          );
        },
      ).then((newRevision) {
        // Reload the nest revision list
        if (newRevision != null) {
          revisionProvider.getRevisionForNest(widget.nest.id!);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddNestRevisionScreen(nest: widget.nest),
        ),
      ).then((newRevision) {
        // Reload the nest revision list
        if (newRevision != null) {
          revisionProvider.getRevisionForNest(widget.nest.id!);
        }
      });
    }
  }

  Widget _buildNestRevisionList() {
    return Column(
      children: [
        Expanded(
          child: Consumer<NestRevisionProvider>(
            builder: (context, nestRevisionProvider, child) {
              final revisionList = nestRevisionProvider.getRevisionForNest(
                widget.nest.id!,
              );

              if (revisionList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.beenhere_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.surfaceDim,
                        ),
                        const SizedBox(height: 8),
                        Text(S.of(context).noRevisionsFound),
                        const SizedBox(height: 8),
                        ActionChip(
                          label: Text(S.of(context).newRevision),
                          avatar: const Icon(Icons.add_outlined),
                          onPressed: () {
                            _showAddRevisionScreen(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return RefreshIndicator(
                  onRefresh: () async {
                    await nestRevisionProvider.getRevisionForNest(
                      widget.nest.id ?? 0,
                    );
                  },
                  child: _buildListView(revisionList),
                      
                    
                  
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _showBottomSheet(BuildContext context, NestRevision revision) {
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
                    child: Text(
                      DateFormat('dd/MM/yyyy HH:mm:ss',).format(revision.sampleTime!),
                      style: TextTheme.of(context).bodyLarge,
                    ),
                  ),
                  // ListTile(
                  //   title: Text(
                  //     DateFormat(
                  //       'dd/MM/yyyy HH:mm:ss',
                  //     ).format(revision.sampleTime!),
                  //   ),
                  // ),
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
                                (context) => AddNestRevisionScreen(
                              nest: widget.nest,
                              nestRevision: revision,
                              isEditing: true,
                            ),
                          ),
                        );
                      }),
                      buildGridMenuItem(context, Icons.delete_outlined,
                          S.of(context).delete, () async {
                            Navigator.of(context).pop();
                            await _deleteNestRevision(revision);
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

  Widget _buildListView(List<NestRevision> revisionList) {
    return ListView.separated(
      separatorBuilder: (context, index) => Divider(),
      shrinkWrap: true,
      itemCount: revisionList.length,
      itemBuilder: (context, index) {
        final nestRevision = revisionList[index];
        return RevisionListItem(
          nestRevision: nestRevision,
          onLongPress: () => _showBottomSheet(context, nestRevision),
        );
      },
    );
  }
}

class NestRevisionGridItem extends StatelessWidget {
  const NestRevisionGridItem({super.key, required this.revision});

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
                future: Provider.of<AppImageProvider>(
                  context,
                  listen: false,
                ).fetchImagesForNestRevision(revision.id!),
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
                  DateFormat(
                    'dd/MM/yyyy HH:mm:ss',
                  ).format(revision.sampleTime!),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${nestStatusTypeFriendlyNames[revision.nestStatus]}: ${nestStageTypeFriendlyNames[revision.nestStage]}',
                ),
                Text(
                  '${S.of(context).host}: ${revision.eggsHost ?? 0} ${S.of(context).egg(revision.eggsHost ?? 0)}, ${revision.nestlingsHost ?? 0} ${S.of(context).nestling(revision.nestlingsHost ?? 0).toLowerCase()}',
                ),
                Text(
                  '${S.of(context).nidoparasite}: ${revision.eggsParasite ?? 0} ${S.of(context).egg(revision.eggsParasite ?? 0)}, ${revision.nestlingsParasite ?? 0} ${S.of(context).nestling(revision.nestlingsParasite ?? 0).toLowerCase()}',
                ),
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
        future: Provider.of<AppImageProvider>(
          context,
          listen: false,
        ).fetchImagesForNestRevision(widget.nestRevision.id ?? 0),
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
      title: Text(
        DateFormat(
          'dd/MM/yyyy HH:mm:ss',
        ).format(widget.nestRevision.sampleTime!),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${nestStatusTypeFriendlyNames[widget.nestRevision.nestStatus]}: ${nestStageTypeFriendlyNames[widget.nestRevision.nestStage]}',
            style: TextStyle(
              color:
                  widget.nestRevision.nestStatus == NestStatusType.nstActive
                      ? Colors.blue
                      : widget.nestRevision.nestStatus ==
                          NestStatusType.nstInactive
                      ? Colors.red
                      : null,
            ),
          ),
          Text(
            '${S.of(context).host}: ${widget.nestRevision.eggsHost ?? 0} ${S.of(context).egg(widget.nestRevision.eggsHost ?? 0).toLowerCase()}, ${widget.nestRevision.nestlingsHost ?? 0} ${S.of(context).nestling(widget.nestRevision.nestlingsHost ?? 0).toLowerCase()}',
          ),
          Text(
            '${S.of(context).nidoparasite}: ${widget.nestRevision.eggsParasite ?? 0} ${S.of(context).egg(widget.nestRevision.eggsParasite ?? 0).toLowerCase()}, ${widget.nestRevision.nestlingsParasite ?? 0} ${S.of(context).nestling(widget.nestRevision.nestlingsParasite ?? 0).toLowerCase()}',
          ),
        ],
      ),
      onLongPress: widget.onLongPress,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    AppImageScreen(nestRevisionId: widget.nestRevision.id),
          ),
        );
      },
    );
  }
}
