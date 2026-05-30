import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../data/models/journal.dart';
import '../../providers/journal_provider.dart';

import 'add_journal_screen.dart';
import '../../core/core_consts.dart';
import '../../utils/import_utils.dart';
import '../../utils/export_utils.dart';
import '../../utils/utils.dart';
import '../../generated/l10n.dart';

/// Displays the list of journal entries with filtering, sorting, and selection tools.
class JournalsScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  /// Creates the journals screen.
  const JournalsScreen({super.key, required this.scaffoldKey});

  /// Creates the mutable state for [JournalsScreen].
  @override
  JournalsScreenState createState() => JournalsScreenState();
}

/// State implementation for [JournalsScreen].
class JournalsScreenState extends State<JournalsScreen> {
  late FieldJournalProvider journalProvider;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedObserver;
  DateFilter? _selectedDateFilter;
  DateTimeRange? _selectedDateRange;
  Set<int> selectedJournals = {};
  JournalSortField _sortField = JournalSortField.creationDate;
  SortOrder _sortOrder = SortOrder.descending;
  FieldJournal? _selectedJournalEntry;

  static final Map<DateFilter, String> _dateFilterLabels = {
    DateFilter.today: S.current.today,
    DateFilter.yesterday: S.current.yesterday,
    DateFilter.last7Days: S.current.last7Days,
    DateFilter.last30Days: S.current.last30Days,
    DateFilter.last90Days: S.current.last90Days,
    DateFilter.last180Days: S.current.last180Days,
    DateFilter.last365Days: S.current.last365Days,
    DateFilter.customRange: S.current.dateInterval,
  };

  @override
  void initState() {
    super.initState();
    journalProvider = context.read<FieldJournalProvider>();
    journalProvider.fetchJournalEntries();
  }

  /// Returns whether [date] matches the active date [filter].
  bool _isWithinDateFilter(DateTime? date, DateFilter? filter) {
    if (date == null || filter == null) return true; // sem filtro ou data nula
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final weekStart = todayStart.subtract(const Duration(days: 7));
    final monthStart = todayStart.subtract(const Duration(days: 30));
    final last90Start = todayStart.subtract(const Duration(days: 90));
    final last180Start = todayStart.subtract(const Duration(days: 180));
    final last365Start = todayStart.subtract(const Duration(days: 365));

    switch (filter) {
      case DateFilter.today:
        return date.isAfter(todayStart) || date.isAtSameMomentAs(todayStart);
      case DateFilter.yesterday:
        return (date.isAfter(yesterdayStart) ||
                date.isAtSameMomentAs(yesterdayStart)) &&
            date.isBefore(todayStart);
      case DateFilter.last7Days:
        return date.isAfter(weekStart) || date.isAtSameMomentAs(weekStart);
      case DateFilter.last30Days:
        return date.isAfter(monthStart) || date.isAtSameMomentAs(monthStart);
      case DateFilter.last90Days:
        return date.isAfter(last90Start) || date.isAtSameMomentAs(last90Start);
      case DateFilter.last180Days:
        return date.isAfter(last180Start) ||
            date.isAtSameMomentAs(last180Start);
      case DateFilter.last365Days:
        return date.isAfter(last365Start) ||
            date.isAtSameMomentAs(last365Start);
      case DateFilter.customRange:
        if (_selectedDateRange == null) return true;
        // Ajuste para incluir o dia inteiro da data final (até 23:59:59)
        final endOfDay = _selectedDateRange!.end.add(const Duration(days: 1));
        return (date.isAfter(_selectedDateRange!.start) ||
            date.isAtSameMomentAs(_selectedDateRange!.start)) &&
            date.isBefore(endOfDay);
    }
  }

  /// Sorts journal entries using the currently selected sort field and order.
  List<FieldJournal> _sortJournalEntries(List<FieldJournal> journalEntries) {
    journalEntries.sort((a, b) {
      int comparison;
      switch (_sortField) {
        case JournalSortField.title:
          final aNotesPreview = firstSentenceFromDelta(a.notes).toLowerCase();
          final bNotesPreview = firstSentenceFromDelta(b.notes).toLowerCase();
          comparison = aNotesPreview.compareTo(bNotesPreview);
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

  /// Shows the bottom sheet used to choose journal sorting options.
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
                        label: Text(S.current.journalEntries(1)),
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

  /// Returns all distinct observer values available in the loaded entries.
  List<String> _getUniqueObservers() {
    final entries =
        journalProvider.journalEntries;

    final observers =
        entries
            .where(
              (entry) => entry.observer != null && entry.observer!.isNotEmpty,
            )
            .map((entry) => entry.observer!)
            .toSet()
            .toList();

    observers.sort();
    return observers;
  }

  /// Applies the active filters and sorting options to [journalEntries].
  List<FieldJournal> _filterJournalEntries(List<FieldJournal> journalEntries) {
    List<FieldJournal> filtered = journalEntries;

    // Filtro por data (usa startTime)
    if (_selectedDateFilter != null) {
      filtered =
          filtered
              .where(
                (entry) =>
                    _isWithinDateFilter(entry.creationDate, _selectedDateFilter),
              )
              .toList();
    }

    // Filtro por busca textual
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered
              .where(
                (entry) =>
                    plainTextFromDelta(entry.notes).toLowerCase().contains(query),
              )
              .toList();
    }

    return _sortJournalEntries(filtered);
  }

  /// Resolves the journal entry that should be shown in the detail pane.
  FieldJournal? _getEffectiveSelectedJournalEntry(
    List<FieldJournal> filteredEntries,
    bool isSplitScreen,
  ) {
    if (!isSplitScreen || filteredEntries.isEmpty) {
      return _selectedJournalEntry;
    }

    if (_selectedJournalEntry == null) {
      return filteredEntries.first;
    }

    final selectedIndex = filteredEntries.indexWhere(
      (entry) => entry.id == _selectedJournalEntry!.id,
    );

    if (selectedIndex == -1) {
      return filteredEntries.first;
    }

    return filteredEntries[selectedIndex];
  }

  /// Returns the identifier of the journal entry currently selected for details.
  int? _getEffectiveSelectedJournalEntryId(
    List<FieldJournal> filteredEntries,
    bool isSplitScreen,
  ) {
    return _getEffectiveSelectedJournalEntry(filteredEntries, isSplitScreen)
        ?.id;
  }

  /// Opens the add-journal flow using a dialog or route depending on screen size.
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

  /// Deletes all journal entries currently selected in the list.
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
              },
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () async {
                // Call the function to delete species
                for (final id in selectedJournals) {
                  final entry = await journalProvider.getJournalEntryById(id);
                  await journalProvider.removeJournalEntry(entry);
                }
                setState(() {
                  selectedJournals.clear();
                });
                Navigator.of(context).pop(true);
              },
              child: Text(S.of(context).delete),
            ),
          ],
        );
      },
    );
  }

  /// Resolves currently selected journal entries for batch actions.
  Future<List<FieldJournal>> _getSelectedJournalEntries() async {
    final entriesById = {
      for (final entry in journalProvider.journalEntries)
        if (entry.id != null) entry.id!: entry,
    };

    final selectedEntries = <FieldJournal>[];
    for (final id in selectedJournals) {
      final cached = entriesById[id];
      if (cached != null) {
        selectedEntries.add(cached);
      } else {
        selectedEntries.add(await journalProvider.getJournalEntryById(id));
      }
    }

    return selectedEntries;
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
              // Action to import journal entries from JSON
              MenuItemButton(
                leadingIcon: const Icon(Icons.file_open_outlined),
                onPressed: () async {
                  await importJournalsFromJson(context);
                },
                child: Text(S.of(context).import),
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
        actions: [
          
        ],
      ) : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // On large screens we show a split screen master/detail
          if (isSplitScreen) {
            final leftPaneWidth =
                (constraints.maxWidth * 0.4).clamp(kSideSheetWidth, 520.0);
            return Row(
              children: [
                // Left: list pane with bounded width for better readability.
                Container(
                  width: leftPaneWidth,
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
            MenuAnchor(
              builder: (context, controller, child) {
                return IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: S.of(context).exportWhat(
                    S.of(context).journalEntries(2).toLowerCase(),
                  ),
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
                    final journals = await _getSelectedJournalEntries();
                    await exportSelectedJournalsToTxt(context, journals);
                    if (!mounted) return;
                    setState(() {
                      selectedJournals.clear();
                    });
                  },
                  child: Text(S.current.plainText),
                ),
                MenuItemButton(
                  onPressed: () async {
                    final journals = await _getSelectedJournalEntries();
                    await exportSelectedJournalsToMarkdown(context, journals);
                    if (!mounted) return;
                    setState(() {
                      selectedJournals.clear();
                    });
                  },
                  child: const Text('Markdown'),
                ),
                MenuItemButton(
                  onPressed: () async {
                    final journals = await _getSelectedJournalEntries();
                    await exportSelectedJournalsToWord(context, journals);
                    if (!mounted) return;
                    setState(() {
                      selectedJournals.clear();
                    });
                  },
                  child: const Text('Word'),
                ),
                MenuItemButton(
                  onPressed: () async {
                    final journals = await _getSelectedJournalEntries();
                    await exportSelectedJournalsToJson(context, journals);
                    if (!mounted) return;
                    setState(() {
                      selectedJournals.clear();
                    });
                  },
                  child: const Text('JSON'),
                ),
              ],
            ),
            const VerticalDivider(),
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

  /// Builds the master list pane for the journal screen.
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
              // Action to import journal entries from JSON
              MenuItemButton(
                leadingIcon: const Icon(Icons.file_open_outlined),
                onPressed: () async {
                  await importJournalsFromJson(context);
                },
                child: Text(S.of(context).import),
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
          Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MenuAnchor(
                        builder: (context, controller, child) {
                          String label;
                          if (_selectedDateFilter == DateFilter.customRange && _selectedDateRange != null) {
                            final start = DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start);
                            final end = DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end);
                            label = "$start - $end";
                          } else {
                            label = _selectedDateFilter != null
                                ? _dateFilterLabels[_selectedDateFilter]!
                                : S.of(context).date;
                          }

                          return FilterChip(
                            label: Text(label),
                            avatar: _selectedDateFilter == null ? const Icon(Icons.calendar_today_outlined) : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            visualDensity: VisualDensity.compact,
                            onSelected: (selected) {
                              if (selected) {
                                controller.open();
                              } else {
                                setState(() {
                                  _selectedDateFilter = null;
                                  _selectedDateRange = null;
                                });
                              }
                            },
                            selected: _selectedDateFilter != null,
                          );
                        },
                        menuChildren: [
                          ...DateFilter.values.map((filter) {
                            return MenuItemButton(
                              onPressed: () async {
                                if (filter == DateFilter.customRange) {
                                  final DateTimeRange? picked = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                    initialDateRange: _selectedDateRange,
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedDateFilter = filter;
                                      _selectedDateRange = picked;
                                    });
                                  }
                                } else {
                                  setState(() {
                                    _selectedDateFilter = filter;
                                    _selectedDateRange = null;
                                  });
                                }
                              },
                              child: Text(_dateFilterLabels[filter]!),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(width: 8.0),
                      MenuAnchor(
                        builder: (context, controller, child) {
                          return FilterChip(
                            label: Text(
                              _selectedObserver ?? S.current.observer,
                            ),
                            avatar: _selectedObserver == null ? Icon(Icons.person_outlined) : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            visualDensity: VisualDensity.compact,
                            onSelected: (selected) {
                              if (selected) {
                                controller.open();
                              } else {
                                setState(() {
                                  _selectedObserver = null;
                                });
                              }
                            },
                            selected: _selectedObserver != null,
                          );
                        },
                        menuChildren: [
                          ..._getUniqueObservers().map((observer) {
                            return MenuItemButton(
                              onPressed: () {
                                setState(() {
                                  _selectedObserver = observer;
                                });
                              },
                              child: Text(observer),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
          Expanded(
              child: Consumer<FieldJournalProvider>(
                builder: (context, journalProvider, child) {
                  final filteredEntries =
                  _filterJournalEntries(journalProvider.journalEntries);

                  final effectiveSelectedEntry =
                      _getEffectiveSelectedJournalEntry(
                        filteredEntries,
                        isSplitScreen,
                      );

                  if (isSplitScreen &&
                      effectiveSelectedEntry != null &&
                      _selectedJournalEntry?.id != effectiveSelectedEntry.id) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        _selectedJournalEntry = effectiveSelectedEntry;
                      });
                    });
                  }

                  if (filteredEntries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 48,
                            color: Theme.of(context).colorScheme.surfaceDim,
                          ),
                          const SizedBox(height: 8),
                          Text(S.of(context).noJournalEntriesFound),
                          const SizedBox(height: 8),
                          ActionChip(
                            label: Text(S.of(context).newJournalEntry),
                            avatar: const Icon(Icons.add_outlined),
                            onPressed: () {
                              _showAddJournalScreen(context);
                            },
                          ),
                          const SizedBox(height: 8),
                          ActionChip(
                            label: Text(S.of(context).import),
                            avatar: const Icon(Icons.file_open_outlined),
                            onPressed: () async {
                              await importJournalsFromJson(context);
                              await journalProvider.fetchJournalEntries();
                            },
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ActionChip(
                                label: Text(S.of(context).clearFilters),
                                avatar: const Icon(Icons.search_off_outlined),
                                onPressed: () async {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                }
                            ),
                          ],
                          const SizedBox(height: 8),
                          ActionChip(
                            label: Text(S.of(context).refresh),
                            avatar: const Icon(Icons.refresh_outlined),
                            onPressed: () async {
                              await journalProvider.fetchJournalEntries();
                            },
                          ),
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
                ),
              ),
              Expanded(
                child: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                    return ListView.builder(
                      padding: EdgeInsetsGeometry.fromLTRB(8, 0, 8, 0),
                      shrinkWrap: true,
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        final entry = filteredEntries[index];
                        final isSelected = selectedJournals.contains(entry.id);
                        final isLargeScreen = MediaQuery.sizeOf(context).width >= kTabletBreakpoint;
                        return Card(
                            color: isSelected ? isLargeScreen
                                ? Theme.of(context).colorScheme.secondaryContainer
                                : Theme.of(context).colorScheme.primaryContainer : Colors.amber[50],
                            child: journalListTileItem(filteredEntries, index, context)
                        );
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

  /// Builds the detail pane shown on larger screens.
  Widget _buildDetailPane(BuildContext context) {
    if (_selectedJournalEntry == null) {
      // Placeholder when nothing selected
      return Center(
        child: Text(S.of(context).selectJournalToView),
      );
    }

    // Show InventoryDetailScreen in-place for the selected inventory
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AddJournalScreen(
            journalEntry: _selectedJournalEntry,
            isEditing: true,
            isEmbedded: true,
          ),
        ),
      ),
    );
  }

  /// Builds a single journal list tile with selection and navigation behavior.
  ListTile journalListTileItem(List<FieldJournal> filteredEntries, int index, BuildContext context) {
    final entry = filteredEntries[index];
    final isSelected = selectedJournals.contains(entry.id);
    final isLargeScreen = MediaQuery.sizeOf(context).width >= kTabletBreakpoint;
    final selectedJournalId = _getEffectiveSelectedJournalEntryId(
      filteredEntries,
      isLargeScreen,
    );
    final isDetailSelected = selectedJournalId == entry.id;

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
      title: Builder(builder: (context) {
        final preview = firstSentenceFromDelta(entry.notes);
        if (preview.isEmpty) return const SizedBox.shrink();
        return Text(
          preview,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        );
      }),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('dd/MM/yyyy HH:mm:ss')
              .format(entry.creationDate!)),
        ],
      ),
      selected: isLargeScreen ? isDetailSelected : isSelected,
      // selectedTileColor:
      //     isLargeScreen
      //         ? Theme.of(context).colorScheme.secondaryContainer
      //         : Theme.of(context).colorScheme.primaryContainer,
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

  /// Shows contextual actions for a journal entry.
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
                                      },
                                      child: Text(S.of(context).cancel),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop(true);
                                        // Call the function to delete species
                                        await journalProvider.removeJournalEntry(journalEntry);
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
                  Row(
                    children: [
                      const SizedBox(width: 8.0),
                      Text(
                        S.current.export,
                        style: TextTheme.of(context).bodyMedium,
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              const SizedBox(width: 16.0),
                              ActionChip(
                                label: Text(S.current.plainText),
                                onPressed: () async {
                                  exportSelectedJournalsToTxt(context, [journalEntry]);
                                  Navigator.of(context).pop();
                                },
                              ),
                              const SizedBox(width: 8.0),
                              ActionChip(
                                label: const Text('Markdown'),
                                onPressed: () async {
                                  exportSelectedJournalsToMarkdown(context, [journalEntry]);
                                  Navigator.of(context).pop();
                                },
                              ),
                              const SizedBox(width: 8.0),
                              ActionChip(
                                label: const Text('Word'),
                                onPressed: () async {
                                  exportSelectedJournalsToWord(context, [journalEntry]);
                                  Navigator.of(context).pop();
                                },
                              ),
                              const SizedBox(width: 8.0),
                              ActionChip(
                                label: const Text('JSON'),
                                onPressed: () async {
                                  exportSelectedJournalsToJson(context, [journalEntry]);
                                  Navigator.of(context).pop();
                                },
                              ),
                              const SizedBox(width: 8.0),
                            ],
                          ),
                        ),
                      ),
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

  /// Shows additional list-level actions for smaller screens.
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
                          buildGridMenuItem(
                            context,
                            Icons.file_open_outlined,
                            S.of(context).import,
                                () async {
                              Navigator.of(context).pop();
                              await importJournalsFromJson(context);
                            },
                          ),
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