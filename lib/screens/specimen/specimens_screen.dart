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

enum SpecimenSortField {
  fieldNumber,
  sampleTime,
}

enum SortOrder {
  ascending,
  descending,
}

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
  bool _showPending = true; // Show pending specimens by default
  Set<int> selectedSpecimens = {};
  SortOrder _sortOrder = SortOrder.descending;
  SpecimenSortField _sortField = SpecimenSortField.sampleTime;

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

  void _setSortOrder(SortOrder order) {
    setState(() {
      _sortOrder = order;
    });
  }

  void _setSortField(SpecimenSortField field) {
    setState(() {
      _sortField = field;
    });
  }

  List<Specimen> _sortSpecimens(List<Specimen> specimens) {
    specimens.sort((a, b) {
      int comparison;
      switch (_sortField) {
        case SpecimenSortField.fieldNumber:
          comparison = a.fieldNumber.compareTo(b.fieldNumber);
          break;
        case SpecimenSortField.sampleTime:
          comparison = a.sampleTime!.compareTo(b.sampleTime!);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
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
        return AlertDialog.adaptive(
          title: Text(S.of(context).confirmDelete),
          content: Text(S
              .of(context)
              .confirmDeleteMessage(selectedSpecimens.length, "male", S.of(context).specimens(selectedSpecimens.length))),
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
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/json')], 
          text: S.current.specimenExported(2), 
          subject: S.current.specimenData(2)
        ),
      );

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
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'text/csv')], 
          text: S.current.specimenExported(2), 
          subject: S.current.specimenData(2)
        ),
      );

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
          MenuAnchor(
            builder: (context, controller, child) {
              return IconButton(
                icon: Icon(Icons.sort_outlined),
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              );
            },
            menuChildren: [
              MenuItemButton(
                leadingIcon: Icon(Icons.schedule_outlined),
                trailingIcon: _sortField == SpecimenSortField.sampleTime
                    ? Icon(Icons.check_outlined)
                    : null, 
                onPressed: () {
                  _setSortField(SpecimenSortField.sampleTime);
                },
                child: Text(S.of(context).sortByTime),
              ),
              MenuItemButton(
                leadingIcon: Icon(Icons.sort_by_alpha_outlined),
                trailingIcon: _sortField == SpecimenSortField.fieldNumber
                    ? Icon(Icons.check_outlined)
                    : null, 
                onPressed: () {
                  _setSortField(SpecimenSortField.fieldNumber);
                },
                child: Text(S.of(context).sortByName),
              ),
              Divider(),
              MenuItemButton(
                leadingIcon: Icon(Icons.south_outlined),
                trailingIcon: _sortOrder == SortOrder.ascending
                    ? Icon(Icons.check_outlined)
                    : null, 
                onPressed: () {
                  _setSortOrder(SortOrder.ascending);
                },
                child: Text(S.of(context).sortAscending),
              ),
              MenuItemButton(
                leadingIcon: Icon(Icons.north_outlined),
                trailingIcon: _sortOrder == SortOrder.descending
                    ? Icon(Icons.check_outlined)
                    : null, 
                onPressed: () {
                  _setSortOrder(SortOrder.descending);
                },
                child: Text(S.of(context).sortDescending),
              ),
            ],
          ),
          MenuAnchor(
            builder: (context, controller, child) {
              return IconButton(
                icon: Icon(Icons.more_vert_outlined),
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              );
            },
            menuChildren: [
              MenuItemButton(
                leadingIcon: Icon(Icons.file_upload_outlined),
                onPressed: () {
                  exportAllSpecimensToCsv(context, _showPending ? specimenProvider.pendingSpecimens : specimenProvider.archivedSpecimens);
                },
                child: Text('${S.of(context).exportAll} (CSV)'),
              ),
              MenuItemButton(
                leadingIcon: Icon(Icons.file_upload_outlined),
                onPressed: () {
                  exportAllSpecimensToJson(context, _showPending ? specimenProvider.pendingSpecimens : specimenProvider.archivedSpecimens);
                },
                child: Text('${S.of(context).exportAll} (JSON)'),
              ),
            ],
          ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final screenWidth = constraints.maxWidth;
                final buttonWidth = screenWidth < 600 ? screenWidth : 400.0;

                // Show the segmented button to toggle between active and inactive nests
                return SizedBox(
                  width: buttonWidth,
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: true, label: Text(S.of(context).pending)),
                      ButtonSegment(value: false, label: Text(S.of(context).archived)),
                    ],
                    selected: {_showPending},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        selectedSpecimens.clear();
                        _showPending = newSelection.first;
                      });
                      // nestProvider.notifyListeners();
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Consumer<SpecimenProvider>(
                builder: (context, specimenProvider, child) {
              final filteredSpecimens =
                  _filterSpecimens(_showPending 
                    ? specimenProvider.pendingSpecimens
                    : specimenProvider.archivedSpecimens);

              if (_showPending && specimenProvider.pendingSpecimens.isEmpty ||
                  !_showPending && specimenProvider.archivedSpecimens.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(S.of(context).noSpecimenCollected),
                      SizedBox(height: 8),
                      IconButton.filled(
                        icon: Icon(Icons.refresh_outlined),
                        onPressed: () async {
                          await specimenProvider.fetchSpecimens();
                        }, 
                      )
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await specimenProvider.fetchSpecimens();
                },
                child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
                child: Text(
                  '${filteredSpecimens.length} ${S.of(context).specimens(filteredSpecimens.length).toLowerCase()}',
                  // style: TextStyle(fontSize: 16,),
                ),
              ),
              Expanded(
                child: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isLargeScreen = screenWidth > 600;

                  if (isLargeScreen) {
                    final double minWidth = 300;
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
                    return ListView.separated(
                      separatorBuilder: (context, index) => Divider(),
                      shrinkWrap: true,
                      itemCount: filteredSpecimens.length,
                      itemBuilder: (context, index) {
                        return specimenListTileItem(filteredSpecimens, index, context);
                      },
                    );
                  }
                }),
              ),
            ],
                ),
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
                  MenuAnchor(
                    builder: (context, controller, child) {
                      return IconButton(
                        icon: Icon(Icons.file_upload_outlined),
                        tooltip: S.of(context).exportWhat(
                            S.of(context).specimens(2).toLowerCase()),
                        onPressed: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                      );
                    },
                    menuChildren: [
                      MenuItemButton(
                        onPressed: () {
                          _exportSelectedSpecimensToCsv();
                        },
                        child: Text('CSV'),
                      ),
                      MenuItemButton(
                        onPressed: () {
                          _exportSelectedSpecimensToJson();
                        },
                        child: Text('JSON'),
                      ),
                    ],
                  ),
                  if (_showPending)
                    IconButton(
                      icon: Icon(Icons.archive_outlined),
                      tooltip: S.of(context).archiveSpecimen,
                      onPressed: () async {
                        for (final id in selectedSpecimens) {
                          final specimen = await specimenProvider.getSpecimenById(id);
                          specimen.isPending = false;
                          specimenProvider.updateSpecimen(specimen);
                        }
                        setState(() {
                          selectedSpecimens.clear();
                        });
                      },
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
                          return const CircularProgressIndicator(year2023: false,);
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
                          style: TextTheme.of(context).bodyLarge,
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
                child: Checkbox.adaptive(
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
      leading: Checkbox.adaptive(
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
            return const CircularProgressIndicator(year2023: false,);
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
                  if (_showPending)
                    ListTile(
                      leading: const Icon(Icons.archive_outlined),
                      title: Text(S.of(context).archiveSpecimen),
                      onTap: () {
                        specimen.isPending = false;
                        specimenProvider.updateSpecimen(specimen);
                        Navigator.pop(context);
                      },
                    ),
                  // Divider(),
                  ListTile(
                    leading: Icon(Icons.delete_outlined, color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red
                        : Colors.redAccent,),
                    title: Text(S.of(context).deleteSpecimen, style: TextStyle(color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red
                        : Colors.redAccent,),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog.adaptive(
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