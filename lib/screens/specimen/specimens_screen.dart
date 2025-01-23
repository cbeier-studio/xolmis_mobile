import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _isSearchBarVisible = false;
  String _searchQuery = '';
  bool _isAscendingOrder = false;
  String _sortField = 'sampleTime';
  Set<int> selectedSpecimens = {};

  @override
  void initState() {
    super.initState();
    specimenProvider = context.read<SpecimenProvider>();
    specimenProvider.fetchSpecimens();
  }

  void _toggleSearchBarVisibility() {
    setState(() {
      _isSearchBarVisible = !_isSearchBarVisible;
    });
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

  void _deleteSelectedSpecimens() async {
    final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirmDelete),
          content: Text(S
              .of(context)
              .confirmDeleteMessage(selectedSpecimens.length, "male", S.of(context).inventory(selectedSpecimens.length))),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                // Navigator.of(context).pop();
              },
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () async {
                // Call the function to delete species
                for (final id in selectedSpecimens) {
                  final specimen = await specimenProvider.getSpecimenById(id);
                  specimenProvider.removeSpecimen(specimen);
                }
                setState(() {
                  selectedSpecimens.clear();
                });
                Navigator.of(context).pop(true);
                // Navigator.of(context).pop();
              },
              child: Text(S.of(context).delete),
            ),
          ],
        );
      },
    );
  }

  void _exportSelectedSpecimensToJson() async {
    try {
      final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
      final specimens = await Future.wait(selectedSpecimens.map((id) => specimenProvider.getSpecimenById(id)));

      final jsonString = jsonEncode(specimens.map((specimen) => specimen.toJson()).toList());

      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final formattedDate = formatter.format(now);

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/selected_specimens_$formattedDate.json';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      // Share the file using share_plus
      await Share.shareXFiles([
        XFile(filePath, mimeType: 'application/json'),
      ], text: S.current.specimenExported(2), subject: S.current.specimenData(2));

      setState(() {
        selectedSpecimens.clear();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text(S.current.errorExportingSpecimen(2, error.toString())),
            ],
          ),
        ),
      );
    }
  }

  void _exportSelectedSpecimensToCsv() async {
    try {
      final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
      final specimens = await Future.wait(selectedSpecimens.map((id) => specimenProvider.getSpecimenById(id)));
            
        // 1. Create a list of data for the CSV
        List<List<dynamic>> rows = [];
    rows.add([
      'Date/Time',
      'Field number',
      'Species',
      'Type',
      'Locality',
      'Longitude',
      'Latitude',
      'Notes',
    ]);
    for (var specimen in specimens) {
      rows.add([
        specimen.sampleTime,
        specimen.fieldNumber,
        specimen.speciesName,
        specimenTypeFriendlyNames[specimen.type],
        specimen.locality,
        specimen.longitude,
        specimen.latitude,
        specimen.notes,
      ]);
    }

        // 2. Convert the list of data to CSV
        String csv = const ListToCsvConverter().convert(rows, fieldDelimiter: ';');

        final now = DateTime.now();
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final formattedDate = formatter.format(now);

        // 3. Create the file in a temporary directory
        Directory tempDir = await getApplicationDocumentsDirectory();
        final filePath = '${tempDir.path}/selected_specimens_$formattedDate.csv';
        final file = File(filePath);
        await file.writeAsString(csv);

      // Share the file using share_plus
      await Share.shareXFiles([XFile(filePath, mimeType: 'text/csv')], text: S.current.specimenExported(2), subject: S.current.specimenData(2));

      setState(() {
        selectedSpecimens.clear();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text(S.current.errorExportingSpecimen(2, error.toString())),
            ],
          ),
        ),
      );
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
          IconButton(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_off_outlined),
            isSelected: _isSearchBarVisible,
            onPressed: _toggleSearchBarVisibility,
          ),
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
          IconButton(
            icon: Icon(Icons.more_vert_outlined),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(100, 80, 0, 0),
                items: [
                  // PopupMenuItem(
                  //   value: 'import',
                  //   child: Row(
                  //     children: [
                  //       Icon(Icons.file_open_outlined),
                  //       SizedBox(width: 8),
                  //       Text(S.of(context).import),
                  //     ],
                  //   ),
                  // ),
                  PopupMenuItem(
                    value: 'exportCsv',
                    child: Row(
                      children: [
                        Icon(Icons.file_upload_outlined),
                        SizedBox(width: 8),
                        Text('${S.of(context).exportAll} (CSV)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'exportJson',
                    child: Row(
                      children: [
                        Icon(Icons.file_upload_outlined),
                        SizedBox(width: 8),
                        Text('${S.of(context).exportAll} (JSON)'),
                      ],
                    ),
                  ),
                ],
              ).then((value) async {
                if (value == 'import') {
                  // await importInventoryFromJson(context);
                  // await inventoryProvider.fetchInventories();
                } else if (value == 'exportCsv') {
                  await exportAllSpecimensToCsv(context);
                } else if (value == 'exportJson') {
                  await exportAllSpecimensToJson(context);
                }
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          if (_isSearchBarVisible)
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
              final filteredSpecimens =
                  _filterSpecimens(specimenProvider.specimens);

              if (filteredSpecimens.isEmpty) {
                return Center(
                  child: Text(S.of(context).noSpecimenCollected),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await specimenProvider.fetchSpecimens();
                },
                child: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isLargeScreen = screenWidth > 600;

                  if (isLargeScreen) {
                    final double minWidth = 220;
                    int crossAxisCountCalculated =
                        (constraints.maxWidth / minWidth).floor();
                    return SingleChildScrollView(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 840),
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCountCalculated,
                              childAspectRatio: 1,
                            ),
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: filteredSpecimens.length,
                            itemBuilder: (context, index) {
                              return specimenGridTileItem(filteredSpecimens, index, context);
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
                        return specimenListTileItem(filteredSpecimens, index, context);
                      },
                    );
                  }
                }),
              );
            }),
          ),
        ],
      ),
      floatingActionButtonLocation: selectedSpecimens.isNotEmpty 
        ? FloatingActionButtonLocation.endContained 
        : FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).newSpecimen,
        onPressed: () {
          _showAddSpecimenScreen(context);
        },
        child: const Icon(Icons.add_outlined),
      ),
      bottomNavigationBar: selectedSpecimens.isNotEmpty
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete_outlined),
                    tooltip: S.of(context).delete,
                    color: Colors.red,
                    onPressed: _deleteSelectedSpecimens,
                  ),
                  VerticalDivider(),
                  PopupMenuButton<String>(
                    position: PopupMenuPosition.over,
                    onSelected: (String item) {
                      switch (item) {
                        case 'csv':
                          _exportSelectedSpecimensToCsv();
                          break;
                        case 'json':
                          _exportSelectedSpecimensToJson();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        const PopupMenuItem<String>(
                          value: 'csv',
                          child: Text('CSV'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'json',
                          child: Text('JSON'),
                        ),
                      ];
                    },
                    icon: const Icon(Icons.file_upload_outlined),
                    tooltip: S.of(context).exportWhat(S.of(context).specimens(2).toLowerCase()),
                  ),
                  VerticalDivider(),
                  // Option to clear the selected specimens
                  IconButton(
                    icon: Icon(Icons.clear_outlined),
                    tooltip: S.current.clearSelection,
                    onPressed: () {
                      setState(() {
                        selectedSpecimens.clear();
                      });
                    },
                  ),
                ],
              ),
            )
          : null,
    );
  }

  GridTile specimenGridTileItem(List<Specimen> filteredSpecimens, int index, BuildContext context) {
    final specimen = filteredSpecimens[index];
    final isSelected =
        selectedSpecimens.contains(specimen.id);
    return GridTile(
      child: InkWell(
        onLongPress: () =>
            _showBottomSheet(context, specimen),
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
        child: Card.outlined(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment:
                    MainAxisAlignment.end,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child:
                        FutureBuilder<List<AppImage>>(
                      future: Provider.of<
                                  AppImageProvider>(
                              context,
                              listen: false)
                          .fetchImagesForSpecimen(
                              specimen.id!),
                      builder: (context, snapshot) {
                        if (snapshot
                                .connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot
                            .hasError) {
                          return const Icon(
                              Icons.error);
                        } else if (snapshot.hasData &&
                            snapshot
                                .data!.isNotEmpty) {
                          return ClipRRect(
                            borderRadius:
                                BorderRadius.vertical(
                                    top: Radius
                                        .circular(
                                            12.0)),
                            child: Image.file(
                              File(snapshot.data!
                                  .first.imagePath),
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          );
                        } else {
                          return const Center(
                              child: Icon(Icons
                                  .hide_image_outlined));
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.end,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          specimen.fieldNumber,
                          style: const TextStyle(
                              fontSize: 20),
                        ),
                        Text(
                            '${specimenTypeFriendlyNames[specimen.type]}'),
                        Text(
                          specimen.speciesName!,
                          style: const TextStyle(
                              fontStyle:
                                  FontStyle.italic),
                        ),
                        Text(specimen.locality!),
                        Text(DateFormat(
                                'dd/MM/yyyy HH:mm:ss')
                            .format(specimen
                                .sampleTime!)),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedSpecimens
                            .add(specimen.id!);
                      } else {
                        selectedSpecimens
                            .remove(specimen.id);
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ListTile specimenListTileItem(List<Specimen> filteredSpecimens, int index, BuildContext context) {
    final specimen = filteredSpecimens[index];
    final isSelected =
        selectedSpecimens.contains(specimen.id);
    return ListTile(
      leading: Checkbox(
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              selectedSpecimens.add(specimen.id!);
            } else {
              selectedSpecimens.remove(specimen.id);
            }
          });
        },
      ),
      trailing: FutureBuilder<List<AppImage>>(
        future: Provider.of<AppImageProvider>(context,
                listen: false)
            .fetchImagesForSpecimen(specimen.id ?? 0),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return const Icon(Icons.error);
          } else if (snapshot.hasData &&
              snapshot.data!.isNotEmpty) {
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
      title: Text(
          '${specimen.fieldNumber} - ${specimenTypeFriendlyNames[specimen.type]}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            specimen.speciesName!,
            style: const TextStyle(
                fontStyle: FontStyle.italic),
          ),
          Text(specimen.locality!),
          Text(
              '${specimen.longitude}; ${specimen.latitude}'),
          Text(DateFormat('dd/MM/yyyy HH:mm:ss')
              .format(specimen.sampleTime!)),
        ],
      ),
      onLongPress: () =>
          _showBottomSheet(context, specimen),
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
                    title: Text(specimen.fieldNumber),
                  ),
                  Divider(),
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