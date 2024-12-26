import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    nestProvider = context.read<NestProvider>();
    nestProvider.fetchNests();
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
          Padding(
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
                                return Dismissible(
                                  key: Key(nest.id.toString()),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.red,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20.0),
                                    child: const Icon(Icons.delete_outlined, color: Colors.white),
                                  ),
                                  confirmDismiss: (direction) {
                                    return showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(S.of(context).confirmDelete),
                                          content: Text(S.of(context).confirmDeleteMessage(1, "male", S.of(context).nest(1))),
                                          actions: <Widget>[
                                            TextButton(
                                              child: Text(S.of(context).cancel),
                                              onPressed: () {
                                                Navigator.of(context).pop(false);
                                              },
                                            ),
                                            TextButton(child: Text(S.of(context).delete),
                                              onPressed: () {
                                                Navigator.of(context).pop(true);
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  onDismissed: (direction) {
                                    nestProvider.removeNest(nest);
                                  },
                                  child: ListTile(
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
                                    leading: nest.nestFate == NestFateType.fatSuccess
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
        tooltip: S.of(context).newNest,
        onPressed: () {
          _showAddNestScreen(context);
        },
        child: const Icon(Icons.add_outlined),
      ),
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
                      leading: const Icon(Icons.file_download_outlined),
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
                          leading: const Icon(Icons.code_outlined),
                          title: const Text('JSON'),
                          onTap: () {
                            Navigator.of(context).pop();
                            exportNestToJson(context, nest);
                          },
                        ),
                      ]
                  ) : const SizedBox.shrink(),
                  !_showActive ? ListTile(
                    leading: const Icon(Icons.file_download_outlined),
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