import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/nest.dart';
import '../providers/nest_revision_provider.dart';

import 'revision_list_item.dart';

class NestRevisionsTab extends StatefulWidget {
  final Nest nest;
  final GlobalKey<AnimatedListState> revisionListKey;

  const NestRevisionsTab(
      {super.key, required this.nest, required this.revisionListKey});

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

  Widget _buildNestRevisionList() {
    return Consumer<NestRevisionProvider>(
      builder: (context, nestRevisionProvider, child) {
        final revisionList = nestRevisionProvider.getRevisionForNest(
            widget.nest.id!);
        if (revisionList.isEmpty) {
          return const Center(
            child: Text('Nenhuma revisão de ninho registrada.'),
          );
        } else {
          return AnimatedList(
            key: widget.revisionListKey,
            initialItemCount: revisionList.length,
            itemBuilder: (context, index, animation) {
              final nestRevision = revisionList[index];
              return RevisionListItem(
                nestRevision: nestRevision,
                animation: animation,
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirmar exclusão'),
                        content: const Text(
                            'Tem certeza que deseja excluir esta revisão de ninho?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                              final indexToRemove = revisionList.indexOf(
                                  nestRevision);
                              nestRevisionProvider.removeNestRevision(
                                  widget.nest.id!, nestRevision.id!).then((
                                  _) {
                                widget.revisionListKey.currentState?.removeItem(
                                  indexToRemove,
                                      (context, animation) =>
                                      RevisionListItem(
                                          nestRevision: nestRevision,
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