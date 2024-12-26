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
import '../../utils/export_utils.dart';
import '../../generated/l10n.dart';

class SpecimensScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const SpecimensScreen({super.key, required this.scaffoldKey});

  @override
  SpecimensScreenState createState() => SpecimensScreenState();
}

class SpecimensScreenState extends State<SpecimensScreen> {
  late SpecimenProvider specimenProvider;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAscendingOrder = false;
  String _sortField = 'sampleTime';

  @override
  void initState() {
    super.initState();
    specimenProvider = context.read<SpecimenProvider>();
    specimenProvider.fetchSpecimens();
  }

  void _toggleSortOrder(String order) {
    setState(() {
      _isAscendingOrder = order == 'ascending';
    });
  }

  void _changeSortField(String field) {
    setState(() {
      _sortField = field;
    });
  }

  List<Specimen> _sortSpecimens(List<Specimen> specimens) {
    specimens.sort((a, b) {
      int comparison;
      if (_sortField == 'fieldNumber') {
        comparison = a.fieldNumber.compareTo(b.fieldNumber);
      } else {
        comparison = a.sampleTime!.compareTo(b.sampleTime!);
      }
      return _isAscendingOrder ? comparison : -comparison;
    });
    return specimens;
  }

  List<Specimen> _filterSpecimens(List<Specimen> specimens) {
    if (_searchQuery.isEmpty) {
      return specimens;
    }
    List<Specimen> filteredSpecimens = specimens.where((specimen) =>
      specimen.fieldNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      specimen.speciesName!.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
    return _sortSpecimens(filteredSpecimens);
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
        // Reload the specimen list
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
        title: Text(S.of(context).specimens(2)),
        leading: MediaQuery.sizeOf(context).width < 600 ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_outlined),
            onPressed: () {
              widget.scaffoldKey.currentState?.openDrawer();
            },
          ),
        ) : SizedBox.shrink(),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort_outlined),
            position: PopupMenuPosition.under,
            onSelected: (value) {
              if (value == 'ascending' || value == 'descending') {
                _toggleSortOrder(value);
              } else {
                _changeSortField(value);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'sampleTime',
                  child: Row(
                    children: [
                      Icon(Icons.schedule_outlined),
                      SizedBox(width: 8),
                      Text(S.of(context).sortByTime),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'fieldNumber',
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha_outlined),
                      SizedBox(width: 8),
                      Text(S.of(context).sortByName),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'ascending',
                  child: Row(
                    children: [
                      Icon(Icons.south_outlined),
                      SizedBox(width: 8),
                      Text(S.of(context).sortAscending),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'descending',
                  child: Row(
                    children: [
                      Icon(Icons.north_outlined),
                      SizedBox(width: 8),
                      Text(S.of(context).sortDescending),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
            child: SearchBar(
              controller: _searchController,
              hintText: S.of(context).findSpecimens,
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
                  return Center(
                    child: Text(S.of(context).noSpecimenCollected),
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
                          return SingleChildScrollView(
                            child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 840),
                              child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 2.5,
                                  ),
                                physics: const NeverScrollableScrollPhysics(),
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
                                        title: Text(S.of(context).confirmDelete),
                                        content: Text(S.of(context).confirmDeleteMessage(1, "male", S.of(context).specimens(1))),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text(S.of(context).cancel),
                                            onPressed: () {
                                              Navigator.of(context).pop(false);
                                            },
                                          ),
                                          TextButton(
                                            child: Text(S.of(context).delete),
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
                                  title: Text('${specimen.fieldNumber} - ${specimenTypeFriendlyNames[specimen.type]}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        specimen.speciesName!,
                                        style: const TextStyle(fontStyle: FontStyle.italic),
                                      ),
                                      Text(specimen.locality!),
                                      Text('${specimen.longitude}; ${specimen.latitude}'),
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
        tooltip: S.of(context).newSpecimen,
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
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(S.of(context).editSpecimen),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddSpecimenScreen(
                            specimen: specimen, 
                            isEditing: true, 
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(),
                  ExpansionTile(
                      leading: const Icon(Icons.file_download_outlined),
                      title: Text(S.of(context).exportAll(S.of(context).specimens(2).toLowerCase())),
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
                  Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outlined, color: Colors.red,),
                    title: Text(S.of(context).deleteSpecimen, style: TextStyle(color: Colors.red),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(S.of(context).confirmDelete),
                            content: Text(S.of(context).confirmDeleteMessage(1, "male", S.of(context).specimens(1))),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                  Navigator.of(context).pop();
                                },
                                child: Text(S.of(context).cancel),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                  Navigator.of(context).pop();
                                  // Call the function to delete species
                                  specimenProvider.removeSpecimen(specimen);
                                },
                                child: Text(S.of(context).delete),
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