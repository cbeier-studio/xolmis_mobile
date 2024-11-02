import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:side_sheet/side_sheet.dart';

import '../../data/models/specimen.dart';
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
          Provider.of<SpecimenProvider>(context, listen: false).specimens.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _exportAllSpecimensToJson(context),
            tooltip: 'Exportar todos os espécimes',
          ) : const SizedBox.shrink(),
          IconButton(
            icon: Theme.of(context).brightness == Brightness.light
                ? const Icon(Icons.settings_outlined)
                : const Icon(Icons.settings),
            tooltip: 'Configurações',
            onPressed: () {
              if (MediaQuery.sizeOf(context).width > 600) {
                SideSheet.right(
                  context: context,
                  width: 400,
                  body: const SettingsScreen(),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<SpecimenProvider>(
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
                  child: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        final screenWidth = constraints.maxWidth;
                        final isLargeScreen = screenWidth > 600;

                        if (isLargeScreen) {
                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 840),
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 3.5,
                                ),
                                shrinkWrap: true,
                                itemCount: specimens.length,
                                itemBuilder: (context, index) {
                                  final specimen = specimens[index];
                                  return GridTile(
                                    child: InkWell(
                                        onLongPress: () => _showBottomSheet(context, specimen),
                                        // onTap: () {
                                        //   Navigator.push(
                                        //     context,
                                        //     MaterialPageRoute(
                                        //       builder: (context) => NestDetailScreen(
                                        //         nest: nest,
                                        //       ),
                                        //     ),
                                        //   ).then((result) {
                                        //     if (result == true) {
                                        //       nestProvider.fetchNests();
                                        //     }
                                        //   });
                                        // },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    specimen.fieldNumber,
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                  Text(
                                                    specimen.speciesName!,
                                                    style: const TextStyle(fontStyle: FontStyle.italic),
                                                  ),
                                                  Text(specimen.locality!),
                                                  Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(specimen.sampleTime!)),
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
                          );
                        } else {
                          return ListView.builder(
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
                                confirmDismiss: (direction) async {
                                  return await showDialog(
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
                                onDismissed: (direction) async {
                                  specimenProvider.removeSpecimen(specimen);
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
                                  onLongPress: () => _showBottomSheet(context, specimen),
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
                          );
                        }
                      }
                  ),
                );
              }
          ),
        ],
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

  void _showBottomSheet(BuildContext context, Specimen specimen) {
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
                    title: const Text('Apagar espécime', style: TextStyle(color: Colors.red),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar exclusão'),
                            content: const Text('Tem certeza que deseja excluir este espécime?'),
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
                                  Provider.of<SpecimenProvider>(context, listen: false)
                                      .removeSpecimen(specimen);
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

  Future<void> _exportAllSpecimensToJson(BuildContext context) async {
    try {
      final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
      final specimenList = specimenProvider.specimens;
      final jsonData = specimenList.map((specimen) => specimen.toJson()).toList();
      final jsonString = jsonEncode(jsonData);

      Directory tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/specimens.json';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      await Share.shareXFiles([
        XFile(filePath, mimeType: 'application/json'),
      ], text: 'Espécimes exportados!', subject: 'Dados dos Espécimes');
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Row(
          children: [
            Icon(Icons.error_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text('Erro ao exportar os espécimes: $error'),
          ],
        ),
        ),
      );
    }
  }
}