import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/nest_provider.dart';

import 'nest_detail_screen.dart';

class NestsHistoryScreen extends StatefulWidget {
  const NestsHistoryScreen({super.key});

  @override
  _NestsHistoryScreenState createState() => _NestsHistoryScreenState();
}

class _NestsHistoryScreenState extends State<NestsHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<NestProvider>(context, listen: false).fetchNests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ninhos inativos'),
      ),
      body: Consumer<NestProvider>(
        builder: (context, nestProvider, child) {
          final inactiveNests = nestProvider.inactiveNests;

          if (inactiveNests.isEmpty) {
            return const Center(
              child: Text('Nenhum ninho inativo.'),
            );
          }

          return ListView.builder(
            itemCount: inactiveNests.length,
            itemBuilder: (context, index) {
              final nest = inactiveNests[index];
              return Dismissible(
                key: Key(nest.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  showDialog(
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
                              Navigator.of(context).pop();
                              setState(() {}); // Rebuild the list to restore the item
                            },
                          ),
                          TextButton(child: const Text('Excluir'),
                            onPressed: () {
                              nestProvider.removeNest(nest);
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                child: ListTile(
                  title: Text(nest.fieldNumber!),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nest.speciesName!),
                      Text(nest.localityName!),
                      Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(nest.foundTime!)),
                    ],
                  ),
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
          );
        },
      ),
    );
  }
}