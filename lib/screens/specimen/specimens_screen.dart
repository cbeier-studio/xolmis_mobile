import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/specimen_provider.dart';

import 'add_specimen_screen.dart';
import '../settings_screen.dart';

class SpecimensScreen extends StatefulWidget {
  const SpecimensScreen({super.key});

  @override
  _SpecimensScreenState createState() => _SpecimensScreenState();
}

class _SpecimensScreenState extends State<SpecimensScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<SpecimenProvider>(context, listen: false).fetchSpecimens();
  }

  void _showAddSpecimenScreen(BuildContext context) {
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
              child: const AddSpecimenScreen(),
            ),
          );
        },
      ).then((newSpecimen) {
        // Reload the inventory list
        if (newSpecimen != null) {
          Provider.of<SpecimenProvider>(context, listen: false).fetchSpecimens();
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddSpecimenScreen()),
      ).then((newSpecimen) {
        // Reload the inventory list
        if (newSpecimen != null) {
          Provider.of<SpecimenProvider>(context, listen: false).fetchSpecimens();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espécimes coletados'),
        actions: [
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
      body: Consumer<SpecimenProvider>(
        builder: (context, specimenProvider, child) {
          final specimens = specimenProvider.specimens;

          if (specimens.isEmpty) {
            return const Center(
              child: Text('Nenhum espécime coletado.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await specimenProvider.fetchSpecimens();
            },
            child: ListView.builder(
              itemCount: specimens.length,
              itemBuilder: (context, index) {
                final specimen = specimens[index];
                return Dismissible(
                  key: Key(specimen.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(Icons.delete_outlined, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirmar Exclusão'),
                          content: const Text(
                              'Tem certeza que deseja excluir este espécime?'),
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
                                specimenProvider.removeSpecimen(specimen);
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: ListTile(
                    title: Text(specimen.fieldNumber),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          specimen.speciesName!,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        Text(specimen.locality!),
                        Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(specimen.sampleTime!)),
                      ],
                    ),
                    // onTap: () {
                    //   Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder: (context) => SpecimenDetailScreen(
                    //         specimen: specimen,
                    //       ),
                    //     ),
                    //   ).then((result) {
                    //     if (result == true) {
                    //       specimenProvider.fetchSpecimens();
                    //     }
                    //   });
                    // },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Novo espécime',
        onPressed: () {
          _showAddSpecimenScreen(context);
        },
        child: const Icon(Icons.add_outlined),
      ),
    );
  }
}