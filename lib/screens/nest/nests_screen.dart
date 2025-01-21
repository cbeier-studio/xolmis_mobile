import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/nest.dart';
import '../../providers/nest_provider.dart';

import 'add_nest_screen.dart';
import 'nest_detail_screen.dart';

import '../../utils/export_utils.dart';
import '../../generated/l10n.dart';

class NestsScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const NestsScreen({super.key, required this.scaffoldKey,});

  @override
  NestsScreenState createState() => NestsScreenState();
}

class NestsScreenState extends State<NestsScreen> {
  late NestProvider nestProvider;
  final _searchController = TextEditingController();
  bool _showActive = true;
  bool _isAscendingOrder = false;
  String _sortField = 'foundTime';
  bool _isSearchBarVisible = false;
  String _searchQuery = '';
  Set<int> selectedNests = {};

  @override
  void initState() {
    super.initState();
    nestProvider = context.read<NestProvider>();
    nestProvider.fetchNests();
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

  List<Nest> _sortNests(List<Nest> nests) {
    nests.sort((a, b) {
      int comparison;
      if (_sortField == 'fieldNumber') {
        comparison = a.fieldNumber!.compareTo(b.fieldNumber!);
      } else {
        comparison = a.foundTime!.compareTo(b.foundTime!);
      }
      return _isAscendingOrder ? comparison : -comparison;
    });
    return nests;
  }

  List<Nest> _filterNests(List<Nest> nests) {
    if (_searchQuery.isEmpty) {
      return _sortNests(nests);
    }
    List<Nest> filteredNests = nests.where((nest) =>
        nest.fieldNumber!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        nest.speciesName!.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
    return _sortNests(filteredNests);
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
        // Reload the nest list
        if (newNest != null) {
          nestProvider.fetchNests();
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddNestScreen()),
      ).then((newNest) {
        // Reload the nest list
        if (newNest != null) {
          nestProvider.fetchNests();
        }
      });
    }
  }

  void _deleteSelectedNests() async {
    final nestProvider = Provider.of<NestProvider>(context, listen: false);
    // final nests = selectedNests.map((id) => nestProvider.getNestById(id)).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirmDelete),
          content: Text(S
              .of(context)
              .confirmDeleteMessage(selectedNests.length, "male", S.of(context).nest(selectedNests.length))),
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
                for (final id in selectedNests) {
                  final nest = await nestProvider.getNestById(id);
                  nestProvider.removeNest(nest);
                }
                setState(() {
                  selectedNests.clear();
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

  Future<void> _exportSelectedNestsToJson() async {
    try {
      final nestProvider = Provider.of<NestProvider>(context, listen: false);
      final nests = await Future.wait(selectedNests.map((id) => nestProvider.getNestById(id)));

      final jsonString = jsonEncode(nests.map((nest) => nest.toJson()).toList());

      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final formattedDate = formatter.format(now);

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/selected_nests_$formattedDate.json';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      // Share the file using share_plus
      await Share.shareXFiles([
        XFile(filePath, mimeType: 'application/json'),
      ], text: S.current.nestExported(2), subject: S.current.nestData(2));

      setState(() {
        selectedNests.clear();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text(S.current.errorExportingNest(2, error.toString())),
            ],
          ),
        ),
      );
    }
  }

  void _exportSelectedNestsToCsv() async {
    try {
      final nestProvider = Provider.of<NestProvider>(context, listen: false);
      final nests = await Future.wait(selectedNests.map((id) => nestProvider.getNestById(id)));
      List<XFile> csvFiles = [];

      for (final nest in nests) {
        // 1. Create a list of data for the CSV
        List<List<dynamic>> rows = [];
        rows.add([
          'Field number',
          'Species',
          'Locality',
          'Longitude',
          'Latitude',
          'Date found',
          'Support',
          'Height above ground',
          'Male',
          'Female',
          'Helpers',
          'Last date',
          'Fate',
        ]);
        rows.add([
          nest.fieldNumber,
          nest.speciesName,
          nest.localityName,
          nest.longitude,
          nest.latitude,
          nest.foundTime,
          nest.support,
          nest.heightAboveGround,
          nest.male,
          nest.female,
          nest.helpers,
          nest.lastTime,
          nestFateTypeFriendlyNames[nest.nestFate],
        ]);

        // Add nest revision data
        rows.add([]); // Empty line as separator
        rows.add(['REVISIONS']);
        rows.add([
          'Date/Time',
          'Status',
          'Phase',
          'Host eggs',
          'Host nestlings',
          'Nidoparasite eggs',
          'Nidoparasite nestlings',
          'Has Philornis larvae',
          'Notes',
        ]);
        for (var revision in nest.revisionsList ?? []) {
          rows.add([
            revision.sampleTime,
            nestStatusTypeFriendlyNames[revision.nestStatus],
            nestStageTypeFriendlyNames[revision.nestStage],
            revision.eggsHost,
            revision.nestlingsHost,
            revision.eggsParasite,
            revision.nestlingsParasite,
            revision.hasPhilornisLarvae,
            revision.notes,
          ]);
        }

        // Add egg data
        rows.add([]);
        rows.add(['EGGS']);
        rows.add([
          'Date/Time',
          'Field number',
          'Species',
          'Egg shape',
          'Width',
          'Length',
          'Weight',
        ]);
        for (var egg in nest.eggsList ?? []) {
          rows.add([
            egg.sampleTime,
            egg.fieldNumber,
            egg.speciesName,
            eggShapeTypeFriendlyNames[egg.eggShape],
            egg.width,
            egg.length,
            egg.mass,
          ]);
        }

        // 2. Convert the list of data to CSV
        String csv = const ListToCsvConverter().convert(rows, fieldDelimiter: ';');

        // 3. Create the file in a temporary directory
        Directory tempDir = await getApplicationDocumentsDirectory();
        final filePath = '${tempDir.path}/nest_${nest.fieldNumber}.csv';
        final file = File(filePath);
        await file.writeAsString(csv);

        csvFiles.add(XFile(filePath, mimeType: 'text/csv'));
      }

      // Share the file using share_plus
      await Share.shareXFiles(csvFiles, text: S.current.nestExported(2), subject: S.current.nestData(2));

      setState(() {
        selectedNests.clear();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text(S.current.errorExportingNest(2, error.toString())),
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
        title: Text(S.of(context).nests),
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
                  value: 'foundTime',
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
          if (_isSearchBarVisible) Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: SearchBar(
              controller: _searchController,
              hintText: S.of(context).findNests,
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

                return SizedBox(
                  width: buttonWidth,
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: true, label: Text(S.of(context).active)),
                      ButtonSegment(value: false, label: Text(S.of(context).inactive)),
                    ],
                    selected: {_showActive},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _showActive = newSelection.first;
                      });
                      // nestProvider.notifyListeners();
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Consumer<NestProvider>(
                builder: (context, nestProvider, child) {
                  final filteredNests = _filterNests(_showActive
                      ? nestProvider.activeNests
                      : nestProvider.inactiveNests);

                  if (_showActive && nestProvider.activeNests.isEmpty ||
                      !_showActive && nestProvider.inactiveNests.isEmpty) {
                    return Center(
                      child: Text(S.of(context).noNestsFound),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await nestProvider.fetchNests();
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
                                      childAspectRatio: 3.0,
                                    ),
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: filteredNests.length,
                                    itemBuilder: (context, index) {
                                      final nest = filteredNests[index];
                                      return GridTile(
                                        child: InkWell(
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
                                          child: NestGridItem(nest: nest),
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
                              itemCount: filteredNests.length,
                              itemBuilder: (context, index) {
                                final nest = filteredNests[index];
                                final isSelected = selectedNests.contains(nest.id);
                                return ListTile(
                                    title: Text(nest.fieldNumber!),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nest.speciesName!,
                                          style: const TextStyle(fontStyle: FontStyle.italic),
                                        ),
                                        Text(nest.localityName!),
                                        Text('${nest.longitude}; ${nest.latitude}'),
                                        Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(nest.foundTime!)),
                                      ],
                                    ),
                                    leading: 
                                        Visibility(
                                          visible: !_showActive,
                                          child: Checkbox(
                                            value: isSelected,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (value == true) {
                                                  selectedNests.add(nest.id!);
                                                } else {
                                                  selectedNests.remove(nest.id);
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                    trailing: nest.nestFate == NestFateType.fatSuccess
                                          ? const Icon(Icons.check_circle, color: Colors.green)
                                          : nest.nestFate == NestFateType.fatLost
                                          ? const Icon(Icons.cancel, color: Colors.red)
                                          : const Icon(Icons.help, color: Colors.grey),
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
      floatingActionButtonLocation: selectedNests.isNotEmpty && !_showActive
        ? FloatingActionButtonLocation.endContained 
        : FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).newNest,
        onPressed: () {
          _showAddNestScreen(context);
        },
        child: const Icon(Icons.add_outlined),
      ),
      bottomNavigationBar: selectedNests.isNotEmpty && !_showActive
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete_outlined),
                    tooltip: S.of(context).delete,
                    color: Colors.red,
                    onPressed: _deleteSelectedNests,
                  ),
                  VerticalDivider(),
                  PopupMenuButton<String>(
                    position: PopupMenuPosition.over,
                    onSelected: (String item) {
                      switch (item) {
                        case 'csv':
                          _exportSelectedNestsToCsv();
                          break;
                        case 'json':
                          _exportSelectedNestsToJson();
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
                    tooltip: S.of(context).export(S.of(context).nest(2)),
                  ),                  
                ],
              ),
            )
          : null,
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
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(S.of(context).editNest),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddNestScreen(
                            nest: nest, 
                            isEditing: true, 
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(),
                  !_showActive ? ExpansionTile(
                      leading: const Icon(Icons.file_upload_outlined),
                      title: Text(S.of(context).export(S.of(context).nest(1))),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.table_chart_outlined),
                          title: const Text('CSV'),
                          onTap: () {
                            Navigator.of(context).pop();
                            exportNestToCsv(context, nest);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.data_object_outlined),
                          title: const Text('JSON'),
                          onTap: () {
                            Navigator.of(context).pop();
                            exportNestToJson(context, nest);
                          },
                        ),
                      ]
                  ) : const SizedBox.shrink(),
                  !_showActive ? ListTile(
                    leading: const Icon(Icons.file_upload_outlined),
                    title: Text(S.of(context).exportAll(S.of(context).nests.toLowerCase())),
                    onTap: () {
                      Navigator.of(context).pop();
                      exportAllInactiveNestsToJson(context);
                    },
                  ) : const SizedBox.shrink(),
                  if (!_showActive) 
                    Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outlined, color: Colors.red,),
                    title: Text(S.of(context).deleteNest, style: TextStyle(color: Colors.red),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(S.of(context).confirmDelete),
                            content: Text(S.of(context).confirmDeleteMessage(1, "male", S.of(context).nest(1))),
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
                                  Provider.of<NestProvider>(context, listen: false)
                                      .removeNest(nest);
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

class NestGridItem extends StatelessWidget {
  const NestGridItem({
    super.key,
    required this.nest,
  });

  final Nest nest;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap (
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 16.0, 16.0, 16.0),
                  child: nest.nestFate == NestFateType.fatSuccess
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : nest.nestFate == NestFateType.fatLost
                      ? const Icon(Icons.cancel, color: Colors.red)
                      : const Icon(Icons.help, color: Colors.grey),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nest.fieldNumber!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      nest.speciesName!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    Text(nest.localityName!),
                    Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(nest.foundTime!)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}