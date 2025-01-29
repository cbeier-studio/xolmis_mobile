import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/journal.dart';
import '../../providers/journal_provider.dart';

import 'add_journal_screen.dart';
import '../../utils/export_utils.dart';
import '../../generated/l10n.dart';

class JournalsScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const JournalsScreen({super.key, required this.scaffoldKey});

  @override
  JournalsScreenState createState() => JournalsScreenState();
}

class JournalsScreenState extends State<JournalsScreen> {
  late FieldJournalProvider journalProvider;
  final _searchController = TextEditingController();
  bool _isSearchBarVisible = false;
  String _searchQuery = '';
  bool _isAscendingOrder = false;
  String _sortField = 'sampleTime';
  Set<int> selectedJournals = {};

  @override
  void initState() {
    super.initState();
    journalProvider = context.read<FieldJournalProvider>();
    journalProvider.fetchJournalEntries();
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

  List<FieldJournal> _sortJournalEntries(List<FieldJournal> journalEntries) {
    journalEntries.sort((a, b) {
      int comparison;
      if (_sortField == 'title') {
        comparison = a.title.compareTo(b.title);
      } else if (_sortField == 'lastModifiedDate') {
        comparison = a.lastModifiedDate!.compareTo(b.lastModifiedDate!);
      } else {
        comparison = a.creationDate!.compareTo(b.creationDate!);
      }
      return _isAscendingOrder ? comparison : -comparison;
    });
    return journalEntries;
  }

  List<FieldJournal> _filterJournalEntries(List<FieldJournal> journalEntries) {
    if (_searchQuery.isEmpty) {
      return journalEntries;
    }
    List<FieldJournal> filteredEntries = journalEntries.where((entry) =>
      entry.title.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
    return _sortJournalEntries(filteredEntries);
  }

  void _showAddJournalScreen(BuildContext context) {
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
              child: const AddJournalScreen(),
            ),
          );
        },
      ).then((newEntry) {
        // Reload the inventory list
        if (newEntry != null) {
          journalProvider.fetchJournalEntries();
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddJournalScreen()),
      ).then((newEntry) {
        // Reload the specimen list
        if (newEntry != null) {
          journalProvider.fetchJournalEntries();
        }
      });
    }
  }

  void _deleteSelectedEntries() async {
    final journalProvider = Provider.of<FieldJournalProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirmDelete),
          content: Text(S
              .of(context)
              .confirmDeleteMessage(selectedJournals.length, "female", S.of(context).journalEntries(selectedJournals.length))),
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
                for (final id in selectedJournals) {
                  final entry = await journalProvider.getJournalEntryById(id);
                  journalProvider.removeJournalEntry(entry);
                }
                setState(() {
                  selectedJournals.clear();
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

  // void _exportSelectedSpecimensToJson() async {
  //   try {
  //     final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
  //     final specimens = await Future.wait(selectedSpecimens.map((id) => specimenProvider.getSpecimenById(id)));
  //
  //     final jsonString = jsonEncode(specimens.map((specimen) => specimen.toJson()).toList());
  //
  //     final now = DateTime.now();
  //     final formatter = DateFormat('yyyyMMdd_HHmmss');
  //     final formattedDate = formatter.format(now);
  //
  //     final directory = await getApplicationDocumentsDirectory();
  //     final filePath = '${directory.path}/selected_specimens_$formattedDate.json';
  //     final file = File(filePath);
  //     await file.writeAsString(jsonString);
  //
  //     // Share the file using share_plus
  //     await Share.shareXFiles([
  //       XFile(filePath, mimeType: 'application/json'),
  //     ], text: S.current.specimenExported(2), subject: S.current.specimenData(2));
  //
  //     setState(() {
  //       selectedSpecimens.clear();
  //     });
  //   } catch (error) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Row(
  //           children: [
  //             Icon(Icons.error_outlined, color: Colors.red),
  //             SizedBox(width: 8),
  //             Text(S.current.errorExportingSpecimen(2, error.toString())),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  // }
  //
  // void _exportSelectedSpecimensToCsv() async {
  //   try {
  //     final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
  //     final specimens = await Future.wait(selectedSpecimens.map((id) => specimenProvider.getSpecimenById(id)));
  //
  //     // 1. Create a list of data for the CSV
  //     List<List<dynamic>> rows = [];
  //     rows.add([
  //       'Date/Time',
  //       'Field number',
  //       'Species',
  //       'Type',
  //       'Locality',
  //       'Longitude',
  //       'Latitude',
  //       'Notes',
  //     ]);
  //     for (var specimen in specimens) {
  //       rows.add([
  //         specimen.sampleTime,
  //         specimen.fieldNumber,
  //         specimen.speciesName,
  //         specimenTypeFriendlyNames[specimen.type],
  //         specimen.locality,
  //         specimen.longitude,
  //         specimen.latitude,
  //         specimen.notes,
  //       ]);
  //     }
  //
  //     // 2. Convert the list of data to CSV
  //     String csv = const ListToCsvConverter().convert(rows, fieldDelimiter: ';');
  //
  //     final now = DateTime.now();
  //     final formatter = DateFormat('yyyyMMdd_HHmmss');
  //     final formattedDate = formatter.format(now);
  //
  //     // 3. Create the file in a temporary directory
  //     Directory tempDir = await getApplicationDocumentsDirectory();
  //     final filePath = '${tempDir.path}/selected_specimens_$formattedDate.csv';
  //     final file = File(filePath);
  //     await file.writeAsString(csv);
  //
  //     // Share the file using share_plus
  //     await Share.shareXFiles([XFile(filePath, mimeType: 'text/csv')], text: S.current.specimenExported(2), subject: S.current.specimenData(2));
  //
  //     setState(() {
  //       selectedSpecimens.clear();
  //     });
  //   } catch (error) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Row(
  //           children: [
  //             Icon(Icons.error_outlined, color: Colors.red),
  //             SizedBox(width: 8),
  //             Text(S.current.errorExportingSpecimen(2, error.toString())),
  //           ],
  //         ),
  //       ),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).fieldJournal),
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
                onPressed: () {
                  _changeSortField('creationDate');
                },
                child: Row(
                  children: [
                    Icon(Icons.schedule_outlined),
                    SizedBox(width: 8),
                    Text(S.of(context).sortByTime),
                  ],
                ),
              ),
              MenuItemButton(
                onPressed: () {
                  _changeSortField('lastModifiedDate');
                },
                child: Row(
                  children: [
                    Icon(Icons.schedule_outlined),
                    SizedBox(width: 8),
                    Text(S.of(context).sortByLastModified),
                  ],
                ),
              ),
              MenuItemButton(
                onPressed: () {
                  _changeSortField('title');
                },
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha_outlined),
                    SizedBox(width: 8),
                    Text(S.of(context).sortByTitle),
                  ],
                ),
              ),
              Divider(),
              MenuItemButton(
                onPressed: () {
                  _toggleSortOrder('ascending');
                },
                child: Row(
                  children: [
                    Icon(Icons.south_outlined),
                    SizedBox(width: 8),
                    Text(S.of(context).sortAscending),
                  ],
                ),
              ),
              MenuItemButton(
                onPressed: () {
                  _toggleSortOrder('descending');
                },
                child: Row(
                  children: [
                    Icon(Icons.north_outlined),
                    SizedBox(width: 8),
                    Text(S.of(context).sortDescending),
                  ],
                ),
              ),
            ],
          ),
          // MenuAnchor(
          //   builder: (context, controller, child) {
          //     return IconButton(
          //       icon: Icon(Icons.more_vert_outlined),
          //       onPressed: () {
          //         if (controller.isOpen) {
          //           controller.close();
          //         } else {
          //           controller.open();
          //         }
          //       },
          //     );
          //   },
          //   menuChildren: [
          //     MenuItemButton(
          //       onPressed: () {
          //         exportAllSpecimensToCsv(context);
          //       },
          //       child: Row(
          //         children: [
          //           Icon(Icons.file_upload_outlined),
          //           SizedBox(width: 8),
          //           Text('${S.of(context).exportAll} (CSV)'),
          //         ],
          //       ),
          //     ),
          //     MenuItemButton(
          //       onPressed: () {
          //         exportAllSpecimensToJson(context);
          //       },
          //       child: Row(
          //         children: [
          //           Icon(Icons.file_upload_outlined),
          //           SizedBox(width: 8),
          //           Text('${S.of(context).exportAll} (JSON)'),
          //         ],
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchBarVisible)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              child: SearchBar(
                controller: _searchController,
                hintText: S.of(context).findJournalEntries,
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
            child: Consumer<FieldJournalProvider>(
                builder: (context, journalProvider, child) {
                  final filteredEntries =
                  _filterJournalEntries(journalProvider.journalEntries);

                  if (filteredEntries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(S.of(context).noJournalEntriesFound),
                          SizedBox(height: 8),
                          IconButton.filled(
                            icon: Icon(Icons.refresh_outlined),
                            onPressed: () async {
                              await journalProvider.fetchJournalEntries();
                            },
                          )
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await journalProvider.fetchJournalEntries();
                    },
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
                          child: Text(
                            '${filteredEntries.length} ${S.of(context).journalEntries(filteredEntries.length)}',
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
                                      itemCount: filteredEntries.length,
                                      itemBuilder: (context, index) {
                                        return journalGridTileItem(filteredEntries, index, context);
                                      },
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return ListView.builder(
                                shrinkWrap: true,
                                itemCount: filteredEntries.length,
                                itemBuilder: (context, index) {
                                  return journalListTileItem(filteredEntries, index, context);
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
      floatingActionButtonLocation: selectedJournals.isNotEmpty
          ? FloatingActionButtonLocation.endContained
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).newJournalEntry,
        onPressed: () {
          _showAddJournalScreen(context);
        },
        child: const Icon(Icons.add_outlined),
      ),
      bottomNavigationBar: selectedJournals.isNotEmpty
          ? BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(Icons.delete_outlined),
              tooltip: S.of(context).delete,
              color: Colors.red,
              onPressed: _deleteSelectedEntries,
            ),
            VerticalDivider(),
            // MenuAnchor(
            //   builder: (context, controller, child) {
            //     return IconButton(
            //       icon: Icon(Icons.file_upload_outlined),
            //       tooltip: S.of(context).exportWhat(
            //           S.of(context).specimens(2).toLowerCase()),
            //       onPressed: () {
            //         if (controller.isOpen) {
            //           controller.close();
            //         } else {
            //           controller.open();
            //         }
            //       },
            //     );
            //   },
            //   menuChildren: [
            //     MenuItemButton(
            //       onPressed: () {
            //         _exportSelectedSpecimensToCsv();
            //       },
            //       child: Text('CSV'),
            //     ),
            //     MenuItemButton(
            //       onPressed: () {
            //         _exportSelectedSpecimensToJson();
            //       },
            //       child: Text('JSON'),
            //     ),
            //   ],
            // ),
            // VerticalDivider(),
            // Option to clear the selected specimens
            IconButton(
              icon: Icon(Icons.clear_outlined),
              tooltip: S.current.clearSelection,
              onPressed: () {
                setState(() {
                  selectedJournals.clear();
                });
              },
            ),
          ],
        ),
      )
          : null,
    );
  }

  GridTile journalGridTileItem(List<FieldJournal> filteredEntries, int index, BuildContext context) {
    final entry = filteredEntries[index];
    final isSelected =
    selectedJournals.contains(entry.id);
    return GridTile(
      child: InkWell(
        onLongPress: () =>
            _showBottomSheet(context, entry),
        onTap: () {
          // open AddJournalScreen
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
                          entry.title,
                          style: const TextStyle(
                              fontSize: 20),
                        ),
                        Text(DateFormat(
                            'dd/MM/yyyy HH:mm:ss')
                            .format(entry
                            .creationDate!)),
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
                        selectedJournals
                            .add(entry.id!);
                      } else {
                        selectedJournals
                            .remove(entry.id);
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

  ListTile journalListTileItem(List<FieldJournal> filteredEntries, int index, BuildContext context) {
    final entry = filteredEntries[index];
    final isSelected =
    selectedJournals.contains(entry.id);
    return ListTile(
      leading: Checkbox(
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              selectedJournals.add(entry.id!);
            } else {
              selectedJournals.remove(entry.id);
            }
          });
        },
      ),
      title: Text(entry.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('dd/MM/yyyy HH:mm:ss')
              .format(entry.creationDate!)),
        ],
      ),
      onLongPress: () =>
          _showBottomSheet(context, entry),
      onTap: () {
        // open AddJournalScreen
      },
    );
  }

  void _showBottomSheet(BuildContext context, FieldJournal journalEntry) {
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
                    title: Text(journalEntry.title, overflow: TextOverflow.fade,),
                  ),
                  Divider(),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(S.of(context).editJournalEntry),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddJournalScreen(
                            journalEntry: journalEntry,
                            isEditing: true,
                          ),
                        ),
                      );
                    },
                  ),
                  // Divider(),
                  ListTile(
                    leading: Icon(Icons.delete_outlined, color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red
                        : Colors.redAccent,),
                    title: Text(S.of(context).deleteJournalEntry, style: TextStyle(color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red
                        : Colors.redAccent,),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(S.of(context).confirmDelete),
                            content: Text(S.of(context).confirmDeleteMessage(1, "female", S.of(context).journalEntries(1).toLowerCase())),
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
                                  journalProvider.removeJournalEntry(journalEntry);
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