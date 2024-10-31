import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/models/nest.dart';
import '../../providers/nest_provider.dart';

import 'nests_history_screen.dart';
import 'add_nest_screen.dart';
import 'nest_detail_screen.dart';

import '../settings_screen.dart';

class ActiveNestsScreen extends StatefulWidget {
  const ActiveNestsScreen({super.key});

  @override
  _ActiveNestsScreenState createState() => _ActiveNestsScreenState();
}

class _ActiveNestsScreenState extends State<ActiveNestsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<NestProvider>(context, listen: false).fetchNests();
  }

  void _showAddNestScreen(BuildContext context) {
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
              child: const AddNestScreen(),
            ),
          );
        },
      ).then((newNest) {
        // Reload the inventory list
        if (newNest != null) {
          Provider.of<NestProvider>(context, listen: false).fetchNests();
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddNestScreen()),
      ).then((newNest) {
        // Reload the inventory list
        if (newNest != null) {
          Provider.of<NestProvider>(context, listen: false).fetchNests();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ninhos ativos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            tooltip: 'Ninhos inativos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NestsHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<NestProvider>(
        builder: (context, nestProvider, child) {
          final activeNests = nestProvider.activeNests;

          if (activeNests.isEmpty) {
            return const Center(
              child: Text('Nenhum ninho ativo.'),
            );
          }

          return RefreshIndicator(
              onRefresh: () async {
            await nestProvider.fetchNests();
          },
          child: ListView.builder(
            itemCount: activeNests.length,
            itemBuilder: (context, index) {
              final nest = activeNests[index];
              return Dismissible(
                key: Key(nest.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete_outlined, color: Colors.white),
                ),
                confirmDismiss: (direction) {
                  return showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirmar Exclusão'),
                        content: const Text(
                            'Tem certeza que deseja excluir este ninho?'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Cancelar'),
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                          ),
                          TextButton(child: const Text('Excluir'),
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  nestProvider.removeNest(nest);
                },
                child: ListTile(
                  title: Text(nest.fieldNumber!),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nest.speciesName!,
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      Text(nest.localityName!),
                      Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(nest.foundTime!)),
                    ],
                  ),
                  onLongPress: () => _showBottomSheet(context, nest),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NestDetailScreen(
                          nest: nest,
                        ),
                      ),
                    ).then((result) {
                      if (result == true) {
                        nestProvider.fetchNests();
                      }
                    });
                  },
                ),
              );
            },
          ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo ninho',
        onPressed: () {
          _showAddNestScreen(context);
        },
        child: const Icon(Icons.add_outlined),
      ),
    );
  }

  void _showBottomSheet(BuildContext context, Nest nest) {
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
                    title: const Text('Apagar ninho', style: TextStyle(color: Colors.red),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar exclusão'),
                            content: const Text('Tem certeza que deseja excluir este ninho?'),
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
                                  Provider.of<NestProvider>(context, listen: false)
                                      .removeNest(nest);
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