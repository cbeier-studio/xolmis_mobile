import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/models/specimen.dart';
import '../../data/models/app_image.dart';
import '../../providers/specimen_provider.dart';
import '../../providers/app_image_provider.dart';

import 'add_specimen_screen.dart';
import '../app_image_screen.dart';
import '../export_utils.dart';

class SpecimensScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const SpecimensScreen({super.key, required this.scaffoldKey});

  @override
  _SpecimensScreenState createState() => _SpecimensScreenState();
}

class _SpecimensScreenState extends State<SpecimensScreen> {
  late SpecimenProvider specimenProvider;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    specimenProvider = context.read<SpecimenProvider>();
    specimenProvider.fetchSpecimens();
  }

  List<Specimen> _filterSpecimens(List<Specimen> specimens) {
    if (_searchQuery.isEmpty) {
      return specimens;
    }
    return specimens.where((specimen) =>
      specimen.fieldNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      specimen.speciesName!.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
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
          specimenProvider.fetchSpecimens();
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddSpecimenScreen()),
      ).then((newSpecimen) {
        // Reload the inventory list
        if (newSpecimen != null) {
          specimenProvider.fetchSpecimens();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espécimes'),
        leading: MediaQuery.sizeOf(context).width < 600 ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_outlined),
            onPressed: () {
              widget.scaffoldKey.currentState?.openDrawer();
            },
          ),
        ) : SizedBox.shrink(),
        // actions: [
        //   specimenProvider.specimens.isNotEmpty
        //       ? IconButton(
        //     icon: const Icon(Icons.file_download_outlined),
        //     onPressed: () => exportAllSpecimensToJson(context),
        //     tooltip: 'Exportar todos os espécimes',
        //   ) : const SizedBox.shrink(),
        // ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Procurar espécimes...',
              // backgroundColor: WidgetStateProperty.all<Color>(Colors.deepPurple[50]!),
              leading: const Icon(Icons.search_outlined),
              trailing: [
                _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_outlined),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                )
                    : SizedBox.shrink(),
              ],
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
            ),
          ),
          Expanded(
          child: Consumer<SpecimenProvider>(
              builder: (context, specimenProvider, child) {
                final filteredSpecimens = _filterSpecimens(specimenProvider.specimens);

                if (filteredSpecimens.isEmpty) {
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
                          return Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 840),
                              child: SingleChildScrollView(
                                child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 2.5,
                                  ),
                                shrinkWrap: true,
                                itemCount: filteredSpecimens.length,
                                itemBuilder: (context, index) {
                                  final specimen = filteredSpecimens[index];
                                  return GridTile(
                                    child: InkWell(
                                        onLongPress: () => _showBottomSheet(context, specimen),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AppImageScreen(
                                                specimenId: specimen.id,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Card.filled(
                                  child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: [
                                              FutureBuilder<List<AppImage>>(
                                                future: Provider.of<AppImageProvider>(context, listen: false)
                                                    .fetchImagesForSpecimen(specimen.id!),
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
                                              const SizedBox(width: 16.0,),
                                              Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    specimen.fieldNumber,
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                  Text('${specimenTypeFriendlyNames[specimen.type]}'),
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
                            itemCount: filteredSpecimens.length,
                            itemBuilder: (context, index) {
                              final specimen = filteredSpecimens[index];
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
                                  leading: FutureBuilder<List<AppImage>>(
                                    future: Provider.of<AppImageProvider>(context, listen: false)
                                        .fetchImagesForSpecimen(specimen.id ?? 0),
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
                                  title: Text(specimen.fieldNumber),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${specimenTypeFriendlyNames[specimen.type]}'),
                                      Text(
                                        specimen.speciesName!,
                                        style: const TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                      Text(specimen.locality!),
                                      Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(specimen.sampleTime!)),
                                    ],
                                  ),
                                  onLongPress: () => _showBottomSheet(context, specimen),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AppImageScreen(
                                          specimenId: specimen.id,
                                        ),
                                      ),
                                    );
                                  },
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
                  ExpansionTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: const Text('Exportar todos os espécimes'),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.table_chart_outlined),
                          title: const Text('CSV'),
                          onTap: () {
                            Navigator.of(context).pop();
                            exportAllSpecimensToCsv(context);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.code_outlined),
                          title: const Text('JSON'),
                          onTap: () {
                            Navigator.of(context).pop();
                            exportAllSpecimensToJson(context);
                          },
                        ),
                      ]
                  ),
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
                                  specimenProvider.removeSpecimen(specimen);
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