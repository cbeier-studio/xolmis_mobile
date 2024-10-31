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
                onLongPress: () => _showBottomSheet(context, nestRevision),
              );
            },
          )
          );
        }
      },
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
                  // Expanded(
                  //     child:
                  ListTile(
                    leading: const Icon(Icons.delete_outlined, color: Colors.red,),
                    title: const Text('Apagar revisão de ninho', style: TextStyle(color: Colors.red),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar exclusão'),
                            content: const Text('Tem certeza que deseja excluir esta revisão de ninho?'),
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
                                  Provider.of<NestRevisionProvider>(context, listen: false)
                                      .removeNestRevision(widget.nest.id!, revision.id!);
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