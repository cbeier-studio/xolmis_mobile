import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../providers/nest_revision_provider.dart';

import 'revision_list_item.dart';

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
          return RefreshIndicator(
              onRefresh: () async {
            await nestRevisionProvider.getRevisionForNest(widget.nest.id ?? 0);
          },
        child: ListView.builder(
        itemCount: revisionList.length,
        itemBuilder: (context, index) {
              final nestRevision = revisionList[index];
              return RevisionListItem(
                nestRevision: nestRevision,
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
                              nestRevisionProvider.removeNestRevision(
                                  widget.nest.id!, nestRevision.id!);
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
          )
          );
        }
      },
    );
  }
}