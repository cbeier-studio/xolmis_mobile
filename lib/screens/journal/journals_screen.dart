import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/models/journal.dart';
import '../../providers/journal_provider.dart';

import 'add_journal_screen.dart';
import '../../core/core_consts.dart';
import '../../utils/utils.dart';
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
  String _searchQuery = '';
  Set<int> selectedJournals = {};
  JournalSortField _sortField = JournalSortField.creationDate;
  SortOrder _sortOrder = SortOrder.descending;
  FieldJournal? _selectedJournalEntry;

  @override
  void initState() {
    super.initState();
    journalProvider = context.read<FieldJournalProvider>();
    journalProvider.fetchJournalEntries();
  }

  List<FieldJournal> _sortJournalEntries(List<FieldJournal> journalEntries) {
    journalEntries.sort((a, b) {
      int comparison;
      switch (_sortField) {
        case JournalSortField.title:
          comparison = a.title.compareTo(b.title);
          break;
        case JournalSortField.lastModifiedDate:
          comparison = a.lastModifiedDate!.compareTo(b.lastModifiedDate!);
          break;
        case JournalSortField.creationDate:
          comparison = a.creationDate!.compareTo(b.creationDate!);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    return journalEntries;
  }

  void _showSortOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
            child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.of(context).sortBy, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0, // Space between chips
                    children: <Widget>[
                      ChoiceChip(
                        label: Text(S.current.title),
                        showCheckmark: false,
                        selected: _sortField == JournalSortField.title,
                        onSelected: (bool selected) {
                          setModalState(() {
                            _sortField = JournalSortField.title;
                          });
                          setState(() {
                            _sortField = JournalSortField.title;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(S.current.creationTime),
                        showCheckmark: false,
                        selected: _sortField == JournalSortField.creationDate,
                        onSelected: (bool selected) {
                          setModalState(() {
                            _sortField = JournalSortField.creationDate;
                          });
                          setState(() {
                            _sortField = JournalSortField.creationDate;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(S.current.lastModifiedTime),
                        showCheckmark: false,
                        selected: _sortField == JournalSortField.lastModifiedDate,
                        onSelected: (bool selected) {
                          setModalState(() {
                            _sortField = JournalSortField.lastModifiedDate;
                          });
                          setState(() {
                            _sortField = JournalSortField.lastModifiedDate;
                          });
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(S.of(context).direction, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<SortOrder>(
                    segments: [
                      ButtonSegment(value: SortOrder.ascending, label: Text(S.of(context).ascending), icon: const Icon(Icons.south_outlined)),
                      ButtonSegment(value: SortOrder.descending, label: Text(S.of(context).descending), icon: const Icon(Icons.north_outlined)),
                    ],
                    selected: {_sortOrder},
                    showSelectedIcon: false,
                    onSelectionChanged: (Set<SortOrder> newSelection) {
                      setModalState(() {
                        _sortOrder = newSelection.first;
                      });
                      setState(() {
                        _sortOrder = newSelection.first;
                      });
                    },
                  ),
                ],
              ),
              ),
            );
          },
            ),
        );
      },
    );
  }

  List<FieldJournal> _filterJournalEntries(List<FieldJournal> journalEntries) {
    if (_searchQuery.isEmpty) {
      return _sortJournalEntries(journalEntries);
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
              constraints: const BoxConstraints(maxWidth: 800),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSplitScreen = screenWidth >= kTabletBreakpoint;
    final isMenuShown = screenWidth < kDesktopBreakpoint;

    return Scaffold(
      appBar: !isSplitScreen ? AppBar(
        title: SearchBar(
          controller: _searchController,
          hintText: S.of(context).fieldJournal,
          elevation: WidgetStateProperty.all(0),
          leading: isMenuShown ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_outlined),
            onPressed: () {
              widget.scaffoldKey.currentState?.openDrawer();
            },
          ),
        ) : const SizedBox.shrink(),
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
            ) : const SizedBox.shrink(),
            IconButton(
              icon: const Icon(Icons.sort_outlined),
              tooltip: S.of(context).sortBy,
              onPressed: () {
                _showSortOptionsBottomSheet();
              },
            ),
            
              MediaQuery.sizeOf(context).width < 600
              ? IconButton(
            icon: const Icon(Icons.more_vert_outlined),
            onPressed: () {
              _showMoreOptionsBottomSheet(context);
            },
          )
              : MenuAnchor(
            builder: (context, controller, child) {
              return IconButton(
                icon: const Icon(Icons.more_vert_outlined),
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
              // Action to select all journal entries
              MenuItemButton(
                leadingIcon: const Icon(Icons.library_add_check_outlined),
                onPressed: () {
                  final filteredJournals = _filterJournalEntries(journalProvider.journalEntries);
                  setState(() {
                    selectedJournals = filteredJournals
                        .map((journal) => journal.id)
                        .whereType<int>()
                        .toSet();
                  });
                },
                child: Text(S.of(context).selectAll),
              ),
            ],
          ),
          ],
          onChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
        ),
        // title: Text(S.of(context).fieldJournal),
        
        actions: [
          
        ],
      ) : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // On large screens we show a split screen master/detail
          if (isSplitScreen) {
            return Row(
              children: [
                // Left: list (takes 40% width)
                Container(
                  width: constraints.maxWidth * 0.45, // adjust ratio as needed
                  //decoration: BoxDecoration(
                  //  border: Border(
                  //    right: BorderSide(color: Theme.of(context).dividerColor),
                  //  ),
                  //),
                  child: _buildListPane(context, isSplitScreen, isMenuShown),
                ),
                VerticalDivider(),
                // Right: detail pane
                Expanded(
                  child: _buildDetailPane(context),
                ),
              ],
            );
          } else {
            // Small screens: keep current column layout
            return _buildListPane(context, isSplitScreen, isMenuShown);
          }
        },
      ),
      floatingActionButtonLocation: selectedJournals.isNotEmpty
          ? FloatingActionButtonLocation.endContained
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).newJournalEntry,
        onPressed: () {
          _showAddJournalScreen(context);
        },
        child: const Icon(Icons.note_add_outlined),
      ),
      bottomNavigationBar: selectedJournals.isNotEmpty
          ? BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outlined),
              tooltip: S.of(context).delete,
              color: Colors.red,
              onPressed: _deleteSelectedEntries,
            ),
            const VerticalDivider(),
            // MenuAnchor(
            //   builder: (context, controller, child) {
            //     return IconButton(
            //       icon: const Icon(Icons.file_upload_outlined),
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
            //       child: const Text('CSV'),
            //     ),
            //     MenuItemButton(
            //       onPressed: () {
            //         _exportSelectedSpecimensToJson();
            //       },
            //       child: const Text('JSON'),
            //     ),
            //   ],
            // ),
            // const VerticalDivider(),
            // Option to clear the selected specimens
            IconButton(
              icon: const Icon(Icons.clear_outlined),
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

  Widget _buildListPane(BuildContext context, bool isSplitScreen, bool isMenuShown) {
    return Column(
        children: [
          if (isSplitScreen) const SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
            child: isSplitScreen ? SearchBar(
          controller: _searchController,
          hintText: S.of(context).fieldJournal,
          elevation: WidgetStateProperty.all(0),
              leading: isMenuShown
                  ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_outlined),
                  onPressed: () {
                    widget.scaffoldKey.currentState?.openDrawer();
                  },
                ),
              )
                  : const SizedBox.shrink(),
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
                : const SizedBox.shrink(),
            IconButton(
              icon: const Icon(Icons.sort_outlined),
              tooltip: S.of(context).sortBy,
              onPressed: () {
                _showSortOptionsBottomSheet();
              },
            ),
            MenuAnchor(
            builder: (context, controller, child) {
              return IconButton(
                icon: const Icon(Icons.more_vert_outlined),
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
              // Action to select all journal entries
              MenuItemButton(
                leadingIcon: const Icon(Icons.library_add_check_outlined),
                onPressed: () {
                  final filteredJournals = _filterJournalEntries(journalProvider.journalEntries);
                  setState(() {
                    selectedJournals = filteredJournals
                        .map((journal) => journal.id)
                        .whereType<int>()
                        .toSet();
                  });
                },
                child: Text(S.of(context).selectAll),
              ),
            ],
          ),
          ],
          onChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
        ) : null,
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
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            label: Text(S.of(context).refresh),
                            icon: const Icon(Icons.refresh_outlined),
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
                  '${filteredEntries.length} ${S.of(context).journalEntries(filteredEntries.length).toLowerCase()}',
                  // style: TextStyle(fontSize: 16,),
                ),
              ),
              Expanded(
                child: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                    return ListView.separated(
                                separatorBuilder: (context, index) => Divider(),
                                shrinkWrap: true,
                                itemCount: filteredEntries.length,
                                itemBuilder: (context, index) {
                                  return journalListTileItem(filteredEntries, index, context);
                                },
                              );
                  
                }),
              ),
            ],
                )
                  );
              }
            
          ))
        ],
      );
  }

  Widget _buildDetailPane(BuildContext context) {
    if (_selectedJournalEntry == null) {
      // Placeholder when nothing selected
      return Center(
        child: Text(S.of(context).selectInventoryToView),
      );
    }

    // Show InventoryDetailScreen in-place for the selected inventory
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AddJournalScreen(
              journalEntry: _selectedJournalEntry,
              isEditing: true,
              isEmbedded: true,
            ),
    );
  }

  ListTile journalListTileItem(List<FieldJournal> filteredEntries, int index, BuildContext context) {
    final entry = filteredEntries[index];
    final isSelected = selectedJournals.contains(entry.id);
    final isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

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
        if (isLargeScreen) {
          setState(() {
            _selectedJournalEntry = entry;
          });
        } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddJournalScreen(
              journalEntry: entry,
              isEditing: true,
            ),
          ),
        );
        }
      },
    );
  }

  void _showBottomSheet(BuildContext context, FieldJournal journalEntry) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: BottomSheet(
          onClosing: () {},
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(journalEntry.title, style: TextTheme.of(context).bodyLarge,),
                  ),
                  // ListTile(
                  //   title: Text(journalEntry.title, overflow: TextOverflow.fade,),
                  // ),
                  const Divider(),
                  GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 4 : 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      buildGridMenuItem(
                          context, Icons.edit_outlined, S.current.edit, () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddJournalScreen(
                              journalEntry: journalEntry,
                              isEditing: true,
                            ),
                          ),
                        );
                      }),
                      buildGridMenuItem(context, Icons.delete_outlined,
                          S.of(context).delete, () {
                            Navigator.of(context).pop();
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
                                        // Navigator.of(context).pop();
                                      },
                                      child: Text(S.of(context).cancel),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                        // Navigator.of(context).pop();
                                        // Call the function to delete species
                                        journalProvider.removeJournalEntry(journalEntry);
                                      },
                                      child: Text(S.of(context).delete),
                                    ),
                                  ],
                                );
                              },
                            );
                          }, color: Theme.of(context).colorScheme.error),
                    ],
                  ),
                ],
              ),
              ),
            );
          },
          ),
        );
      },
    );
  }

  void _showMoreOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: BottomSheet(
            onClosing: () {},
            builder: (BuildContext context) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GridView.count(
                        crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 4 : 5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: <Widget>[
                          buildGridMenuItem(
                              context, Icons.library_add_check_outlined, S.of(context).selectAll,
                                  () async {
                                Navigator.of(context).pop();
                                final filteredJournals = _filterJournalEntries(journalProvider.journalEntries);
                                setState(() {
                                  selectedJournals = filteredJournals
                                      .map((journal) => journal.id)
                                      .whereType<int>()
                                      .toSet();
                                });
                              }),
                        ],
                      ),
                    ],
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