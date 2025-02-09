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
  bool _showActive = true; // Show active nests by default
  bool _isAscendingOrder = false; // Sort descending by default
  String _sortField = 'foundTime'; // Sort by found time by default
  bool _isSearchBarVisible = false; // Hide search bar by default
  String _searchQuery = ''; // Empty search query by default
  Set<int> selectedNests = {}; // Set of selected nests

  @override
  void initState() {
    super.initState();
    nestProvider = context.read<NestProvider>();
    nestProvider.fetchNests();
  }

  // Toggle the visibility of the search bar
  void _toggleSearchBarVisibility() {
    setState(() {
      _isSearchBarVisible = !_isSearchBarVisible;
    });
  }

  // Toggle the sort order
  void _toggleSortOrder(String order) {
    setState(() {
      _isAscendingOrder = order == 'ascending';
    });
  }

  // Change the sort field
  void _changeSortField(String field) {
    setState(() {
      _sortField = field;
    });
  }

  // Sort the nests by the selected field
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

  // Filter the nests based on the search query
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

  // Show the add nest screen
  void _showAddNestScreen(BuildContext context) {
    if (MediaQuery.sizeOf(context).width > 600) {
      // Show the dialog on large screens
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
      // Show the screen on small screens
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

  // Delete all the selected nests
  void _deleteSelectedNests() async {
    final nestProvider = Provider.of<NestProvider>(context, listen: false);
    // final nests = selectedNests.map((id) => nestProvider.getNestById(id)).toList();

    // Ask for user confirmation
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

  // Export all the selected nests to JSON
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

  // Export all the selected nests to CSV
  void _exportSelectedNestsToCsv() async {
    try {
      final nestProvider = Provider.of<NestProvider>(context, listen: false);
      final nests = await Future.wait(selectedNests.map((id) => nestProvider.getNestById(id)));
      final locale = Localizations.localeOf(context);
      List<XFile> csvFiles = [];

      for (final nest in nests) {
        // 1. Create a list of data for the CSV
        List<List<dynamic>> rows = await buildNestCsvRows(nest, locale);

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
          // Action to toggle the visibility of the search bar
          IconButton(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_off_outlined),
            isSelected: _isSearchBarVisible,
            onPressed: _toggleSearchBarVisibility,
          ),
          // Action to sort the nests
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
                  _changeSortField('foundTime');
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
                  _changeSortField('fieldNumber');
                },
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha_outlined),
                    SizedBox(width: 8),
                    Text(S.of(context).sortByName),
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
                onPressed: () async {
                  await exportAllInactiveNestsToJson(context);
                },
                child: Row(
                  children: [
                    Icon(Icons.file_upload_outlined),
                    SizedBox(width: 8),
                    Text(S.of(context).exportAll),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Show the search bar
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

                // Show the segmented button to toggle between active and inactive nests
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
            child:
                Consumer<NestProvider>(builder: (context, nestProvider, child) {
              // Filter the nests based on the active/inactive status
              final filteredNests = _filterNests(_showActive
                  ? nestProvider.activeNests
                  : nestProvider.inactiveNests);

              // Show a message if no nests are found
              if (_showActive && nestProvider.activeNests.isEmpty ||
                  !_showActive && nestProvider.inactiveNests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(S.of(context).noNestsFound),
                      SizedBox(height: 8),
                      IconButton.filled(
                        icon: Icon(Icons.refresh_outlined),
                        onPressed: () async {
                          await nestProvider.fetchNests();
                        }, 
                      )
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  // Refresh the nests
                  await nestProvider.fetchNests();
                },
                child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 8.0),
                child: Text(
                  '${filteredNests.length} ${S.of(context).nest(filteredNests.length)}',
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
                    int crossAxisCountCalculated = (constraints.maxWidth / minWidth).floor();
                    // Show the nests in a grid view on large screens
                    return SingleChildScrollView(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 840),
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCountCalculated,
                              childAspectRatio: 1,
                            ),
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: filteredNests.length,
                            itemBuilder: (context, index) {
                              return nestGridTileItem(filteredNests, index, context, nestProvider);
                            },
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Show the nests in a list view on small screens
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredNests.length,
                      itemBuilder: (context, index) {
                        return nestListTileItem(filteredNests, index, context, nestProvider);
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
      // Show the FAB at the end of the screen
      floatingActionButtonLocation: selectedNests.isNotEmpty && !_showActive
        ? FloatingActionButtonLocation.endContained 
        : FloatingActionButtonLocation.endFloat,
      // FAB to add a new nest
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).newNest,
        onPressed: () {
          _showAddNestScreen(context);
        },
        child: const Icon(Icons.add_outlined),
      ),
      // Show the bottom app bar if there are selected nests
      bottomNavigationBar: selectedNests.isNotEmpty && !_showActive
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Option to delete the selected nests
                  IconButton(
                    icon: Icon(Icons.delete_outlined),
                    tooltip: S.of(context).delete,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red
                        : Colors.redAccent,
                    onPressed: _deleteSelectedNests,
                  ),
                  VerticalDivider(),
                  // Option to export the selected nests
                  MenuAnchor(
                    builder: (context, controller, child) {
                      return IconButton(
                        icon: Icon(Icons.file_upload_outlined),
                        tooltip:
                            S.of(context).exportWhat(S.of(context).nest(2)),
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
                          _exportSelectedNestsToCsv();
                        },
                        child: Text('CSV'),
                      ),
                      MenuItemButton(
                        onPressed: () {
                          _exportSelectedNestsToJson();
                        },
                        child: Text('JSON'),
                      ),
                    ],
                  ),
                  VerticalDivider(),
                  // Option to clear the selected nests
                  IconButton(
                    icon: Icon(Icons.clear_outlined),
                    tooltip: S.current.clearSelection,
                    onPressed: () {
                      setState(() {
                        selectedNests.clear();
                      });
                    },
                  ),                  
                ],
              ),
            )
          : null,
    );
  }

  ListTile nestListTileItem(List<Nest> filteredNests, int index, BuildContext context, NestProvider nestProvider) {
    final nest = filteredNests[index];
    final isSelected = selectedNests.contains(nest.id);
    return ListTile(
      title: Text(nest.fieldNumber!),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nest.speciesName!,
            style: const TextStyle(
                fontStyle: FontStyle.italic),
          ),
          Text(nest.localityName!),
          Text('${nest.longitude}; ${nest.latitude}'),
          Text(DateFormat('dd/MM/yyyy HH:mm:ss')
              .format(nest.foundTime!)),
        ],
      ),
      leading:
          // Show checkbox if showing inactive nests
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
      // Show icon based on the nest fate
      trailing: nest.nestFate == NestFateType.fatSuccess
          ? const Icon(Icons.check_circle,
              color: Colors.green)
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
  }

  GridTile nestGridTileItem(List<Nest> filteredNests, int index, BuildContext context, NestProvider nestProvider) {
    final nest = filteredNests[index];
    final isSelected = selectedNests.contains(nest.id);
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
        child: Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    nest.nestFate == NestFateType.fatSuccess
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : nest.nestFate == NestFateType.fatLost
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : const Icon(Icons.help, color: Colors.grey),
                    Expanded(child: SizedBox.shrink(),),
                    // Show checkbox to select inventories if not active
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
                  ],
                ),
                Expanded(child: SizedBox.shrink()),
                Text(nest.fieldNumber!, style: const TextStyle(fontSize: 20),),
                Text(nest.speciesName!, style: const TextStyle(fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis,),
                Text(nest.localityName!, overflow: TextOverflow.ellipsis,),
                Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(nest.foundTime!), overflow: TextOverflow.ellipsis,),
                Text('${nest.latitude}, ${nest.longitude}', overflow: TextOverflow.ellipsis,),
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Visibility(
                        visible: _showActive,
                        child:FilledButton.icon(
                        onPressed: () async {
                    NestFateType? selectedNestFate;

                    // Show dialog with the DropdownButton
                    await showDialog<NestFateType>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(S.of(context).confirmFate),
                        content: DropdownButtonFormField<NestFateType>(
                          value: selectedNestFate,
                          decoration: InputDecoration(
                            labelText: S.of(context).nestFate,
                            helperText: S.of(context).requiredField,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (NestFateType? newValue) {
                            setState(() {
                              selectedNestFate = newValue;
                            });
                          },
                          items: NestFateType.values.map((NestFateType fate) {
                            return DropdownMenuItem<NestFateType>(
                              value: fate,
                              child: Row(
                                children: [
                                  fate == NestFateType.fatSuccess
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : fate == NestFateType.fatLost
                                      ? const Icon(Icons.cancel, color: Colors.red)
                                      : const Icon(Icons.help, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(nestFateTypeFriendlyNames[fate]!),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(S.of(context).cancel),
                          ),
                          TextButton(
                            onPressed: () async {
                              if (selectedNestFate != null) {
                                // setState(() {
                                //   _isSubmitting = true;
                                // });

                                try {
                                  // Update nest with fate, lastTime and isActive = false
                                  nest.nestFate = selectedNestFate;
                                  nest.lastTime = DateTime.now();
                                  nest.isActive = false;

                                  // Save changes to database using the provider
                                  await Provider.of<NestProvider>(context, listen: false)
                                      .updateNest(nest);

                                  // Close screen of nest details
                                  Navigator.pop(context, selectedNestFate);
                                  // Navigator.pop(context);
                                } catch (error) {
                                  // Handle errors
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(S.of(context).errorInactivatingNest(error.toString())),
                                    ),
                                  );
                                } finally {
                                  // setState(() {
                                  //   _isSubmitting = false;
                                  // });
                                }
                              }
                            },
                            child: Text(S.of(context).save),
                          ),
                        ],
                      ),
                    );
                        }, 
                        label: Text(S.current.finish),
                        icon: Icon(Icons.flag_outlined),
                      ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show the bottom sheet with options to edit, delete, and export the nest
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
                  // Show the field number of the nest
                  ListTile(
                    title: Text(nest.fieldNumber!),
                  ),
                  Divider(),
                  // Option to edit the nest
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
                  // Divider(),
                  // Option to export the nest to CSV or JSON
                  if (!_showActive) 
                    ListTile(
                      leading: const Icon(Icons.file_upload_outlined),
                      title: Text(S.of(context).export), 
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,                       
                        children: [
                          // Option to export the selected nest to CSV
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              exportNestToCsv(context, nest);
                            },
                            child: Text('CSV'),
                          ),
                          // Option to export the selected nest to JSON
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              exportNestToJson(context, nest);
                            },
                            child: Text('JSON'),
                          ),
                        ]
                      ),
                    ),
                  // if (!_showActive) 
                  //   Divider(),
                  // Option to delete the nest
                  ListTile(
                    leading: Icon(Icons.delete_outlined, color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red
                        : Colors.redAccent,),
                    title: Text(S.of(context).deleteNest, style: TextStyle(color: Theme.of(context).brightness == Brightness.light
                        ? Colors.red
                        : Colors.redAccent,),),
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
