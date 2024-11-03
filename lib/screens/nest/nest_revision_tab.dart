import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../providers/nest_revision_provider.dart';

import '../app_image_screen.dart';

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
    return Expanded(
      child: Consumer<NestRevisionProvider>(
            builder: (context, nestRevisionProvider, child) {
              final revisionList = nestRevisionProvider.getRevisionForNest(
                  widget.nest.id!);

              if (revisionList.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
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
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 840),
                              child: SingleChildScrollView(
                                child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 3.2,
                                  ),
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
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(0.0, 16.0, 16.0, 16.0),
                                              child: const Icon(Icons.beenhere_outlined),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Text(
                                                  DateFormat('dd/MM/yyyy HH:mm:ss').format(revision.sampleTime!),
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold),
                                                ),
                                                Text('${nestStatusTypeFriendlyNames[revision.nestStatus]}: ${nestStageTypeFriendlyNames[revision.nestStage]}'),
                                                Text('Hospedeiro: ${revision.eggsHost ?? 0} ovo(s), ${revision.nestlingsHost ?? 0} ninhego(s)'),
                                                Text('Nidoparasita: ${revision.eggsParasite ?? 0} ovo(s), ${revision.nestlingsParasite ?? 0} ninhego(s)'),
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
                            ),
                          );
                        } else {
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
                  ),
                );
              }
            }
        ),
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