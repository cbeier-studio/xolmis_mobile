import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/specimen.dart';
import '../../data/models/app_image.dart';
import '../../providers/specimen_provider.dart';
import '../../providers/app_image_provider.dart';

import '../../core/core_consts.dart';
import '../../utils/utils.dart';
import '../../utils/import_utils.dart';
import 'add_specimen_screen.dart';
import '../images/app_image_screen.dart';
import '../../utils/export_utils.dart';
import '../statistics/stats_specimens_screen.dart';
import '../../generated/l10n.dart';
import '../../widgets/filter_selection_bottom_sheet.dart';

/// Displays the specimen registry with filtering, selection, and export actions.
class SpecimensScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  /// Creates the specimens screen.
  const SpecimensScreen({super.key, required this.scaffoldKey});

  /// Creates the mutable state for [SpecimensScreen].
  @override
  SpecimensScreenState createState() => SpecimensScreenState();
}

/// State implementation for [SpecimensScreen].
class SpecimensScreenState extends State<SpecimensScreen> {
  late SpecimenProvider specimenProvider;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedSpecies;
  String? _selectedLocality;
  String? _selectedObserver;
  DateFilter? _selectedDateFilter;
  DateTimeRange? _selectedDateRange;
  bool _showPending = true; // Show pending specimens by default
  Set<int> selectedSpecimens = {};
  SortOrder _sortOrder = SortOrder.descending;
  SpecimenSortField _sortField = SpecimenSortField.sampleTime;
  Specimen? _selectedSpecimen;

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
    specimenProvider = context.read<SpecimenProvider>();
    specimenProvider.fetchSpecimens();
  }

  /// Returns whether [date] matches the currently selected date [filter].
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

  /// Sorts [specimens] using the active sort field and direction.
  List<Specimen> _sortSpecimens(List<Specimen> specimens) {
    specimens.sort((a, b) {
      int comparison;

      // Helper function to handle nulls. Null values are treated as "smaller".
      int compareNullables<T extends Comparable>(T? a, T? b) {
        if (a == null && b == null) return 0; // Both are equal
        if (a == null) return -1; // a is "smaller"
        if (b == null) return 1; // b is "smaller"
        return a.compareTo(b);
      }

      // Helper function for comparing strings via a map lookup.
      int compareMappedStrings(SpecimenType? aKey, SpecimenType? bKey) {
        final aValue = aKey != null ? specimenTypeFriendlyNames[aKey] : null;
        final bValue = bKey != null ? specimenTypeFriendlyNames[bKey] : null;
        return compareNullables(aValue, bValue);
      }

      switch (_sortField) {
        case SpecimenSortField.fieldNumber:
          comparison = a.fieldNumber.compareTo(b.fieldNumber);
          break;
        case SpecimenSortField.sampleTime:
          comparison = compareNullables(a.sampleTime, b.sampleTime);
          break;
        case SpecimenSortField.species:
          comparison = compareNullables(a.speciesName, b.speciesName);
          break;
        case SpecimenSortField.locality:
          comparison = compareNullables(a.locality, b.locality);
          break;
        case SpecimenSortField.specimenType:
          comparison = compareMappedStrings(a.type, b.type);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    return specimens;
  }

  /// Shows the bottom sheet used to configure specimen sorting.
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
                      Text(
                        S.of(context).sortBy,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0, // Space between chips
                        children: <Widget>[
                          ChoiceChip(
                            label: Text(S.current.fieldNumber),
                            showCheckmark: false,
                            selected:
                                _sortField == SpecimenSortField.fieldNumber,
                            onSelected: (bool selected) {
                              setModalState(() {
                                _sortField = SpecimenSortField.fieldNumber;
                              });
                              setState(() {
                                _sortField = SpecimenSortField.fieldNumber;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: Text(S.current.sampleTime),
                            showCheckmark: false,
                            selected:
                                _sortField == SpecimenSortField.sampleTime,
                            onSelected: (bool selected) {
                              setModalState(() {
                                _sortField = SpecimenSortField.sampleTime;
                              });
                              setState(() {
                                _sortField = SpecimenSortField.sampleTime;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: Text(S.current.species(1)),
                            showCheckmark: false,
                            selected: _sortField == SpecimenSortField.species,
                            onSelected: (bool selected) {
                              setModalState(() {
                                _sortField = SpecimenSortField.species;
                              });
                              setState(() {
                                _sortField = SpecimenSortField.species;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: Text(S.current.locality),
                            showCheckmark: false,
                            selected: _sortField == SpecimenSortField.locality,
                            onSelected: (bool selected) {
                              setModalState(() {
                                _sortField = SpecimenSortField.locality;
                              });
                              setState(() {
                                _sortField = SpecimenSortField.locality;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: Text(S.current.specimenType),
                            showCheckmark: false,
                            selected:
                                _sortField == SpecimenSortField.specimenType,
                            onSelected: (bool selected) {
                              setModalState(() {
                                _sortField = SpecimenSortField.specimenType;
                              });
                              setState(() {
                                _sortField = SpecimenSortField.specimenType;
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(
                        S.of(context).direction,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<SortOrder>(
                        segments: [
                          ButtonSegment(
                            value: SortOrder.ascending,
                            label: Text(S.of(context).ascending),
                            icon: Icon(Icons.south_outlined),
                          ),
                          ButtonSegment(
                            value: SortOrder.descending,
                            label: Text(S.of(context).descending),
                            icon: Icon(Icons.north_outlined),
                          ),
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

  /// Returns all distinct species names available in the active specimen subset.
  List<String> _getUniqueSpecies() {
    final specimens =
        _showPending
            ? specimenProvider.pendingSpecimens
            : specimenProvider.archivedSpecimens;

    final species =
        specimens
            .where(
              (specimen) =>
                  specimen.speciesName != null &&
                  specimen.speciesName!.isNotEmpty,
            )
            .map((specimen) => specimen.speciesName!)
            .toSet()
            .toList();

    species.sort();
    return species;
  }

  /// Returns all distinct localities available in the active specimen subset.
  List<String> _getUniqueLocalities() {
    final specimens =
        _showPending
            ? specimenProvider.pendingSpecimens
            : specimenProvider.archivedSpecimens;

    final localities =
        specimens
            .where(
              (specimen) =>
                  specimen.locality != null && specimen.locality!.isNotEmpty,
            )
            .map((specimen) => specimen.locality!)
            .toSet()
            .toList();

    localities.sort();
    return localities;
  }

  /// Returns all distinct observers available in the active specimen subset.
  List<String> _getUniqueObservers() {
    final specimens =
        _showPending
            ? specimenProvider.pendingSpecimens
            : specimenProvider.archivedSpecimens;

    final observers =
        specimens
            .where(
              (specimen) =>
                  specimen.observer != null && specimen.observer!.isNotEmpty,
            )
            .map((specimen) => specimen.observer!)
            .toSet()
            .toList();

    observers.sort();
    return observers;
  }

  /// Opens the reusable string filter bottom sheet for list filters.
  Future<FilterSelectionResult<String>?> _showStringFilterBottomSheet({
    required String title,
    required List<String> items,
    bool useSpeciesSearch = false,
  }) {
    return showFilterSelectionBottomSheet<String>(
      context: context,
      title: title,
      items: items,
      itemLabel: (item) => item,
      matchesQuery:
          useSpeciesSearch
              ? (item, query, label) => speciesMatchesQuery(label, query)
              : null,
      clearActionLabel: S.current.clearSelection,
    );
  }

  /// Opens the species filter selector.
  Future<void> _selectSpeciesFromBottomSheet() async {
    final result = await _showStringFilterBottomSheet(
      title: S.current.species(1),
      items: _getUniqueSpecies(),
      useSpeciesSearch: true,
    );
    if (!mounted || result == null) return;

    setState(() {
      _selectedSpecies = result.cleared ? null : result.selectedItem;
    });
  }

  /// Opens the locality filter selector.
  Future<void> _selectLocalityFromBottomSheet() async {
    final result = await _showStringFilterBottomSheet(
      title: S.current.locality,
      items: _getUniqueLocalities(),
    );
    if (!mounted || result == null) return;

    setState(() {
      _selectedLocality = result.cleared ? null : result.selectedItem;
    });
  }

  /// Applies the active filters and sorting options to [specimens].
  List<Specimen> _filterSpecimens(List<Specimen> specimens) {
    List<Specimen> filtered = specimens;

    // Filtro por espécie
    if (_selectedSpecies != null) {
      filtered =
          filtered
              .where((specimen) => specimen.speciesName == _selectedSpecies)
              .toList();
    }

    // Filtro por localidade
    if (_selectedLocality != null) {
      filtered =
          filtered
              .where((specimen) => specimen.locality == _selectedLocality)
              .toList();
    }

    // Filtro por observador
    if (_selectedObserver != null) {
      filtered =
          filtered
              .where((specimen) => specimen.observer == _selectedObserver)
              .toList();
    }

    // Filtro por data (usa startTime)
    if (_selectedDateFilter != null) {
      filtered =
          filtered
              .where(
                (specimen) => _isWithinDateFilter(
                  specimen.sampleTime,
                  _selectedDateFilter,
                ),
              )
              .toList();
    }

    // Filtro por busca textual
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (specimen) =>
                    specimen.fieldNumber.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    specimen.speciesName!.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (specimen.locality?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
    }

    return _sortSpecimens(filtered);
  }

  /// Resolves the specimen that should be shown in the detail pane.
  Specimen? _getEffectiveSelectedSpecimen(
    List<Specimen> filteredSpecimens,
    bool isSplitScreen,
  ) {
    if (!isSplitScreen || filteredSpecimens.isEmpty) {
      return _selectedSpecimen;
    }

    if (_selectedSpecimen == null) {
      return filteredSpecimens.first;
    }

    final selectedIndex = filteredSpecimens.indexWhere(
      (specimen) => specimen.id == _selectedSpecimen!.id,
    );

    if (selectedIndex == -1) {
      return filteredSpecimens.first;
    }

    return filteredSpecimens[selectedIndex];
  }

  /// Returns the identifier of the specimen currently selected for details.
  int? _getEffectiveSelectedSpecimenId(
    List<Specimen> filteredSpecimens,
    bool isSplitScreen,
  ) {
    return _getEffectiveSelectedSpecimen(filteredSpecimens, isSplitScreen)?.id;
  }

  /// Opens the add-specimen flow using a dialog or route depending on screen size.
  void _showAddSpecimenScreen(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final String observerAbbreviation =
        prefs.getString('observerAcronym') ?? '';

    if (observerAbbreviation.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            backgroundColor: Colors.amber,
            content: Text(S.of(context).observerAbbreviationMissing),
          ),
        );
      }
      return;
    }

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

  /// Deletes all specimens currently selected in the list.
  void _deleteSelectedSpecimens() async {
    final specimenProvider = Provider.of<SpecimenProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog.adaptive(
          title: Text(S.of(context).confirmDelete),
          content: Text(
            S
                .of(context)
                .confirmDeleteMessage(
                  selectedSpecimens.length,
                  "male",
                  S.of(context).specimens(selectedSpecimens.length),
                ),
          ),
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
                for (final id in selectedSpecimens) {
                  final specimen = await specimenProvider.getSpecimenById(id);
                  await specimenProvider.removeSpecimen(specimen);
                }
                setState(() {
                  selectedSpecimens.clear();
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isSplitScreen = screenWidth >= kTabletBreakpoint;
    final isMenuShown = screenWidth < kDesktopBreakpoint;

    return Scaffold(
      appBar:
          !isSplitScreen
              ? AppBar(
                title: SearchBar(
                  controller: _searchController,
                  hintText: S.of(context).specimens(2),
                  elevation: WidgetStateProperty.all(0),
                  leading:
                      isMenuShown
                          ? Builder(
                            builder:
                                (context) => IconButton(
                                  icon: const Icon(Icons.menu_outlined),
                                  onPressed: () {
                                    widget.scaffoldKey.currentState
                                        ?.openDrawer();
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
                            // Action to select all specimens
                            MenuItemButton(
                              leadingIcon: const Icon(
                                Icons.library_add_check_outlined,
                              ),
                              onPressed: () {
                                final filteredSpecimens = _filterSpecimens(
                                  _showPending
                                      ? specimenProvider.pendingSpecimens
                                      : specimenProvider.archivedSpecimens,
                                );
                                setState(() {
                                  selectedSpecimens =
                                      filteredSpecimens
                                          .map((specimen) => specimen.id)
                                          .whereType<int>()
                                          .toSet();
                                });
                              },
                              child: Text(S.of(context).selectAll),
                            ),
                            // Action to import specimens from JSON
                            MenuItemButton(
                              leadingIcon: const Icon(Icons.file_open_outlined),
                              onPressed: () async {
                                await importSpecimensFromJson(context);
                                await specimenProvider.fetchSpecimens();
                              },
                              child: Text(S.of(context).import),
                            ),
                            MenuItemButton(
                              leadingIcon: const Icon(Icons.share_outlined),
                              onPressed: () {
                                exportAllSpecimensToCsv(
                                  context,
                                  _showPending
                                      ? specimenProvider.pendingSpecimens
                                      : specimenProvider.archivedSpecimens,
                                );
                              },
                              child: Text('${S.of(context).exportAll} (CSV)'),
                            ),
                            MenuItemButton(
                              leadingIcon: const Icon(Icons.share_outlined),
                              onPressed: () {
                                exportAllSpecimensToExcel(
                                  context,
                                  _showPending
                                      ? specimenProvider.pendingSpecimens
                                      : specimenProvider.archivedSpecimens,
                                );
                              },
                              child: Text('${S.of(context).exportAll} (Excel)'),
                            ),
                            MenuItemButton(
                              leadingIcon: const Icon(Icons.share_outlined),
                              onPressed: () {
                                exportAllSpecimensToJson(
                                  context,
                                  _showPending
                                      ? specimenProvider.pendingSpecimens
                                      : specimenProvider.archivedSpecimens,
                                );
                              },
                              child: Text('${S.of(context).exportAll} (JSON)'),
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
              )
              : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // On large screens we show a split screen master/detail
          if (isSplitScreen) {
            final leftPaneWidth = (constraints.maxWidth * 0.4).clamp(
              kSideSheetWidth,
              520.0,
            );
            return Row(
              children: [
                // Left: list pane with bounded width for better readability.
                Container(
                  width: leftPaneWidth,
                  child: _buildListPane(context, isSplitScreen, isMenuShown),
                ),
                VerticalDivider(),
                // Right: detail pane
                Expanded(child: _buildDetailPane(context)),
              ],
            );
          } else {
            // Small screens: keep current column layout
            return _buildListPane(context, isSplitScreen, isMenuShown);
          }
        },
      ),
      floatingActionButtonLocation:
          selectedSpecimens.isNotEmpty
              ? FloatingActionButtonLocation.endContained
              : FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        tooltip: S.of(context).newSpecimen,
        onPressed: () {
          _showAddSpecimenScreen(context);
        },
        child: const Icon(Icons.add_outlined),
      ),
      bottomNavigationBar:
          selectedSpecimens.isNotEmpty
              ? BottomAppBar(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outlined),
                      tooltip: S.of(context).delete,
                      color: Colors.red,
                      onPressed: _deleteSelectedSpecimens,
                    ),
                    const VerticalDivider(),
                    MenuAnchor(
                      builder: (context, controller, child) {
                        return IconButton(
                          icon: const Icon(Icons.share_outlined),
                          tooltip: S
                              .of(context)
                              .exportWhat(
                                S.of(context).specimens(2).toLowerCase(),
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
                            final specimens = await Future.wait(
                              selectedSpecimens.map(
                                (id) => specimenProvider.getSpecimenById(id),
                              ),
                            );
                            await exportSelectedSpecimensToCsv(
                              context,
                              specimens,
                            );
                            if (!mounted) return;
                            setState(() {
                              selectedSpecimens.clear();
                            });
                          },
                          child: const Text('CSV'),
                        ),
                        MenuItemButton(
                          onPressed: () async {
                            final specimens = await Future.wait(
                              selectedSpecimens.map(
                                (id) => specimenProvider.getSpecimenById(id),
                              ),
                            );
                            await exportSelectedSpecimensToExcel(
                              context,
                              specimens,
                            );
                            if (!mounted) return;
                            setState(() {
                              selectedSpecimens.clear();
                            });
                          },
                          child: const Text('Excel'),
                        ),
                        MenuItemButton(
                          onPressed: () async {
                            final specimens = await Future.wait(
                              selectedSpecimens.map(
                                (id) => specimenProvider.getSpecimenById(id),
                              ),
                            );
                            await exportSelectedSpecimensToJson(
                              context,
                              specimens,
                            );
                            if (!mounted) return;
                            setState(() {
                              selectedSpecimens.clear();
                            });
                          },
                          child: const Text('JSON'),
                        ),
                        MenuItemButton(
                          onPressed: () async {
                            final specimens = await Future.wait(
                              selectedSpecimens.map(
                                (id) => specimenProvider.getSpecimenById(id),
                              ),
                            );
                            await exportSelectedSpecimensToKml(
                              context,
                              specimens,
                            );
                            if (!mounted) return;
                            setState(() {
                              selectedSpecimens.clear();
                            });
                          },
                          child: const Text('KML'),
                        ),
                      ],
                    ),
                    if (selectedSpecimens.length > 1)
                      IconButton(
                        icon: const Icon(Icons.insert_chart_outlined),
                        tooltip: S.of(context).statistics,
                        onPressed: () async {
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => StatsSpecimensScreen(
                                      specimens:
                                          selectedSpecimens
                                              .map(
                                                (id) => specimenProvider
                                                    .specimens
                                                    .firstWhere(
                                                      (n) => n.id == id,
                                                      orElse:
                                                          () =>
                                                              Specimen(id: id),
                                                    ),
                                              )
                                              .toList(),
                                    ),
                              ),
                            );
                          }
                        },
                      ),
                    if (_showPending)
                      IconButton(
                        icon: const Icon(Icons.archive_outlined),
                        tooltip: S.of(context).archiveSpecimen,
                        onPressed: () async {
                          for (final id in selectedSpecimens) {
                            final specimen = await specimenProvider
                                .getSpecimenById(id);
                            specimen.isPending = false;
                            specimenProvider.updateSpecimen(specimen);
                          }
                          setState(() {
                            selectedSpecimens.clear();
                          });
                        },
                      ),
                    const VerticalDivider(),
                    // Option to clear the selected specimens
                    IconButton(
                      icon: const Icon(Icons.clear_outlined),
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

  /// Builds the master list pane for the specimen screen.
  Widget _buildListPane(
    BuildContext context,
    bool isSplitScreen,
    bool isMenuShown,
  ) {
    return Column(
      children: [
        if (isSplitScreen) const SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
          child:
              isSplitScreen
                  ? SearchBar(
                    controller: _searchController,
                    hintText: S.of(context).specimens(1),
                    elevation: WidgetStateProperty.all(0),
                    leading:
                        isMenuShown
                            ? Builder(
                              builder:
                                  (context) => IconButton(
                                    icon: const Icon(Icons.menu_outlined),
                                    onPressed: () {
                                      widget.scaffoldKey.currentState
                                          ?.openDrawer();
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
                          // Action to select all specimens
                          MenuItemButton(
                            leadingIcon: const Icon(
                              Icons.library_add_check_outlined,
                            ),
                            onPressed: () {
                              final filteredSpecimens = _filterSpecimens(
                                _showPending
                                    ? specimenProvider.pendingSpecimens
                                    : specimenProvider.archivedSpecimens,
                              );
                              setState(() {
                                selectedSpecimens =
                                    filteredSpecimens
                                        .map((specimen) => specimen.id)
                                        .whereType<int>()
                                        .toSet();
                              });
                            },
                            child: Text(S.of(context).selectAll),
                          ),
                          // Action to import specimens from JSON
                          MenuItemButton(
                            leadingIcon: const Icon(Icons.file_open_outlined),
                            onPressed: () async {
                              await importSpecimensFromJson(context);
                              await specimenProvider.fetchSpecimens();
                            },
                            child: Text(S.of(context).import),
                          ),
                          if (specimenProvider.specimens.isNotEmpty) ...[
                            MenuItemButton(
                              leadingIcon: const Icon(Icons.share_outlined),
                              onPressed: () {
                                exportAllSpecimensToCsv(
                                  context,
                                  _showPending
                                      ? specimenProvider.pendingSpecimens
                                      : specimenProvider.archivedSpecimens,
                                );
                              },
                              child: Text('${S.of(context).exportAll} (CSV)'),
                            ),
                            MenuItemButton(
                              leadingIcon: const Icon(Icons.share_outlined),
                              onPressed: () {
                                exportAllSpecimensToExcel(
                                  context,
                                  _showPending
                                      ? specimenProvider.pendingSpecimens
                                      : specimenProvider.archivedSpecimens,
                                );
                              },
                              child: Text('${S.of(context).exportAll} (Excel)'),
                            ),
                            MenuItemButton(
                              leadingIcon: const Icon(Icons.share_outlined),
                              onPressed: () {
                                exportAllSpecimensToJson(
                                  context,
                                  _showPending
                                      ? specimenProvider.pendingSpecimens
                                      : specimenProvider.archivedSpecimens,
                                );
                              },
                              child: Text('${S.of(context).exportAll} (JSON)'),
                            ),
                          ],
                        ],
                      ),
                    ],
                    onChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                    },
                  )
                  : null,
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
                    ButtonSegment(
                      value: true,
                      label: Text(S.of(context).pending),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text(S.of(context).archived),
                    ),
                  ],
                  selected: {_showPending},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      selectedSpecimens.clear();
                      _showPending = newSelection.first;
                    });
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MenuAnchor(
                        builder: (context, controller, child) {
                          String label;
                          if (_selectedDateFilter == DateFilter.customRange &&
                              _selectedDateRange != null) {
                            final start = DateFormat(
                              'dd/MM/yyyy',
                            ).format(_selectedDateRange!.start);
                            final end = DateFormat(
                              'dd/MM/yyyy',
                            ).format(_selectedDateRange!.end);
                            label = "$start - $end";
                          } else {
                            label =
                                _selectedDateFilter != null
                                    ? _dateFilterLabels[_selectedDateFilter]!
                                    : S.of(context).date;
                          }

                          return FilterChip(
                            label: Text(label),
                            avatar:
                                _selectedDateFilter == null
                                    ? const Icon(Icons.calendar_today_outlined)
                                    : null,
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
                                  final DateTimeRange? picked =
                                      await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 365),
                                        ),
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
                      FilterChip(
                        label: Text(_selectedSpecies ?? S.current.species(1)),
                        avatar:
                            _selectedSpecies == null
                                ? const Icon(Icons.account_tree_outlined)
                                : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        selected: _selectedSpecies != null,
                        onSelected: (selected) async {
                          if (selected) {
                            await _selectSpeciesFromBottomSheet();
                          } else {
                            setState(() {
                              _selectedSpecies = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8.0),
                      FilterChip(
                        label: Text(_selectedLocality ?? S.current.locality),
                        avatar:
                            _selectedLocality == null
                                ? const Icon(Icons.location_on_outlined)
                                : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        visualDensity: VisualDensity.compact,
                        selected: _selectedLocality != null,
                        onSelected: (selected) async {
                          if (selected) {
                            await _selectLocalityFromBottomSheet();
                          } else {
                            setState(() {
                              _selectedLocality = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8.0),
                      MenuAnchor(
                        builder: (context, controller, child) {
                          return FilterChip(
                            label: Text(
                              _selectedObserver ?? S.current.observer,
                            ),
                            avatar:
                                _selectedObserver == null
                                    ? Icon(Icons.person_outlined)
                                    : null,
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
          child: Consumer<SpecimenProvider>(
            builder: (context, specimenProvider, child) {
              final filteredSpecimens = _filterSpecimens(
                _showPending
                    ? specimenProvider.pendingSpecimens
                    : specimenProvider.archivedSpecimens,
              );

              final effectiveSelectedSpecimen = _getEffectiveSelectedSpecimen(
                filteredSpecimens,
                isSplitScreen,
              );

              if (isSplitScreen &&
                  effectiveSelectedSpecimen != null &&
                  _selectedSpecimen?.id != effectiveSelectedSpecimen.id) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() {
                    _selectedSpecimen = effectiveSelectedSpecimen;
                  });
                });
              }

              if (_showPending && specimenProvider.pendingSpecimens.isEmpty ||
                  !_showPending && specimenProvider.archivedSpecimens.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.surfaceDim,
                      ),
                      const SizedBox(height: 8),
                      Text(S.of(context).noSpecimenCollected),
                      const SizedBox(height: 8),
                      ActionChip(
                        label: Text(S.of(context).newSpecimen),
                        avatar: const Icon(Icons.add_outlined),
                        onPressed: () {
                          _showAddSpecimenScreen(context);
                        },
                      ),
                      const SizedBox(height: 8),
                      ActionChip(
                        label: Text(S.of(context).import),
                        avatar: const Icon(Icons.file_open_outlined),
                        onPressed: () async {
                          await importSpecimensFromJson(context);
                          await specimenProvider.fetchSpecimens();
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
                          },
                        ),
                      ],
                      const SizedBox(height: 8),
                      ActionChip(
                        label: Text(S.of(context).refresh),
                        avatar: const Icon(Icons.refresh_outlined),
                        onPressed: () async {
                          await specimenProvider.fetchSpecimens();
                        },
                      ),
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
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        separatorBuilder: (context, index) => Divider(),
                        shrinkWrap: true,
                        itemCount: filteredSpecimens.length,
                        itemBuilder: (context, index) {
                          return specimenListTileItem(
                            filteredSpecimens,
                            index,
                            context,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailPane(BuildContext context) {
    if (_selectedSpecimen == null) {
      // Placeholder when nothing selected
      return Center(child: Text(S.of(context).selectSpecimenToView));
    }

    // Show InventoryDetailScreen in-place for the selected inventory
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AppImageScreen(
            specimenId: _selectedSpecimen!.id,
            isEmbedded: true,
          ),
        ),
      ),
    );
  }

  ListTile specimenListTileItem(
    List<Specimen> filteredSpecimens,
    int index,
    BuildContext context,
  ) {
    final specimen = filteredSpecimens[index];
    final isSelected = selectedSpecimens.contains(specimen.id);
    final isLargeScreen = MediaQuery.sizeOf(context).width >= kTabletBreakpoint;
    final selectedSpecimenId = _getEffectiveSelectedSpecimenId(
      filteredSpecimens,
      isLargeScreen,
    );
    final isDetailSelected = selectedSpecimenId == specimen.id;

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
        future: Provider.of<AppImageProvider>(
          context,
          listen: false,
        ).fetchImagesForSpecimen(specimen.id ?? 0),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(year2023: false);
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
      title: Text(
              specimen.fieldNumber,
              overflow: TextOverflow.ellipsis,
            ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            specimen.speciesName!,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          Text(specimen.locality!, overflow: TextOverflow.ellipsis),
          Text('${specimen.longitude}; ${specimen.latitude}'),
          Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(specimen.sampleTime!)),
          _buildSpecimenTypePill(context, specimen.type),
        ],
      ),
      selected: isLargeScreen ? isDetailSelected : isSelected,
      selectedTileColor:
          isLargeScreen
              ? Theme.of(context).colorScheme.secondaryContainer
              : Theme.of(context).colorScheme.primaryContainer,
      onLongPress: () => _showBottomSheet(context, specimen),
      onTap: () {
        if (isLargeScreen) {
          setState(() {
            _selectedSpecimen = specimen;
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppImageScreen(specimenId: specimen.id),
            ),
          );
        }
      },
    );
  }

  Widget _buildSpecimenTypePill(
    BuildContext context,
    SpecimenType? type,
  ) {
    final backgroundColor = _specimenTypePillColor(context, type);
    final foregroundColor =
        ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Text(
        specimenTypeFriendlyNames[type] ?? S.current.specimenType,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _specimenTypePillColor(BuildContext context, SpecimenType? type) {
    switch (type) {
      case SpecimenType.spcWholeCarcass:
        return _themeAwarePillColor(context, seedColor: Colors.red);
      case SpecimenType.spcPartialCarcass:
        return _themeAwarePillColor(context, seedColor: Colors.deepOrange);
      case SpecimenType.spcNest:
        return _themeAwarePillColor(context, seedColor: Colors.amber);
      case SpecimenType.spcBones:
        return _themeAwarePillColor(context, seedColor: Colors.brown);
      case SpecimenType.spcEgg:
        return _themeAwarePillColor(context, seedColor: Colors.yellow);
      case SpecimenType.spcParasites:
        return _themeAwarePillColor(context, seedColor: Colors.lime);
      case SpecimenType.spcFeathers:
        return _themeAwarePillColor(context, seedColor: Colors.lightBlue);
      case SpecimenType.spcBlood:
        return _themeAwarePillColor(context, seedColor: Colors.pink);
      case SpecimenType.spcClaw:
        return _themeAwarePillColor(context, seedColor: Colors.deepPurple);
      case SpecimenType.spcSwab:
        return _themeAwarePillColor(context, seedColor: Colors.teal);
      case SpecimenType.spcTissues:
        return _themeAwarePillColor(context, seedColor: Colors.indigo);
      case SpecimenType.spcFeces:
        return _themeAwarePillColor(context, seedColor: Colors.green);
      case SpecimenType.spcRegurgite:
        return _themeAwarePillColor(context, seedColor: Colors.orange);
      case null:
        return _themeAwarePillColor(context, seedColor: Colors.blueGrey);
    }
  }

  Color _themeAwarePillColor(
    BuildContext context, {
    required Color seedColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseSurface = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surface;
    final overlayOpacity = isDark ? 0.40 : 0.22;

    return Color.alphaBlend(
      seedColor.withValues(alpha: overlayOpacity),
      baseSurface,
    );
  }

  void _showBottomSheet(BuildContext context, Specimen specimen) {
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
                        child: Text(
                          specimen.fieldNumber,
                          style: TextTheme.of(context).bodyLarge,
                        ),
                      ),
                      const Divider(),
                      GridView.count(
                        crossAxisCount:
                            MediaQuery.sizeOf(context).width < 600 ? 4 : 5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: <Widget>[
                          buildGridMenuItem(
                            context,
                            Icons.edit_outlined,
                            S.current.edit,
                            () {
                              Navigator.of(context).pop();
                              if (MediaQuery.sizeOf(context).width > 600) {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          16.0,
                                        ),
                                      ),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 400,
                                        ),
                                        child: AddSpecimenScreen(
                                          specimen: specimen,
                                          isEditing: true,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AddSpecimenScreen(
                                          specimen: specimen,
                                          isEditing: true,
                                        ),
                                  ),
                                );
                              }
                            },
                          ),
                          if (_showPending)
                            buildGridMenuItem(
                              context,
                              Icons.archive_outlined,
                              S.current.archive,
                              () {
                                Navigator.of(context).pop();
                                specimen.isPending = false;
                                specimenProvider.updateSpecimen(specimen);
                              },
                            ),
                          buildGridMenuItem(
                            context,
                            Icons.delete_outlined,
                            S.of(context).delete,
                            () {
                              Navigator.of(context).pop();
                              // Ask for user confirmation
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog.adaptive(
                                    title: Text(S.of(context).confirmDelete),
                                    content: Text(
                                      S
                                          .of(context)
                                          .confirmDeleteMessage(
                                            1,
                                            "male",
                                            S.of(context).specimens(1),
                                          ),
                                    ),
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
                                          await specimenProvider.removeSpecimen(
                                            specimen,
                                          );
                                        },
                                        child: Text(S.of(context).delete),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ],
                      ),
                      // Divider(),
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
                                    label: const Text('KML'),
                                    onPressed: () async {
                                      exportSpecimenToKml(context, specimen);
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
                        crossAxisCount:
                            MediaQuery.sizeOf(context).width < 600 ? 4 : 5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: <Widget>[
                          buildGridMenuItem(
                            context,
                            Icons.library_add_check_outlined,
                            S.of(context).selectAll,
                            () async {
                              Navigator.of(context).pop();
                              final filteredSpecimens = _filterSpecimens(
                                _showPending
                                    ? specimenProvider.pendingSpecimens
                                    : specimenProvider.archivedSpecimens,
                              );
                              setState(() {
                                selectedSpecimens =
                                    filteredSpecimens
                                        .map((specimen) => specimen.id)
                                        .whereType<int>()
                                        .toSet();
                              });
                            },
                          ),
                          // Action to import nests from JSON
                          buildGridMenuItem(
                            context,
                            Icons.file_open_outlined,
                            S.of(context).import,
                            () async {
                              await importSpecimensFromJson(context);
                              await specimenProvider.fetchSpecimens();
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                      if (specimenProvider.specimens.isNotEmpty) ...[
                        Divider(),
                        Row(
                          children: [
                            const SizedBox(width: 8.0),
                            Text(
                              S.current.exportAll,
                              style: TextTheme.of(context).bodyMedium,
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    const SizedBox(width: 16.0),
                                    ActionChip(
                                      label: const Text('CSV'),
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        exportAllSpecimensToCsv(
                                          context,
                                          _showPending
                                              ? specimenProvider
                                                  .pendingSpecimens
                                              : specimenProvider
                                                  .archivedSpecimens,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8.0),
                                    ActionChip(
                                      label: const Text('Excel'),
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        exportAllSpecimensToExcel(
                                          context,
                                          _showPending
                                              ? specimenProvider
                                                  .pendingSpecimens
                                              : specimenProvider
                                                  .archivedSpecimens,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8.0),
                                    ActionChip(
                                      label: const Text('JSON'),
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        exportAllSpecimensToJson(
                                          context,
                                          _showPending
                                              ? specimenProvider
                                                  .pendingSpecimens
                                              : specimenProvider
                                                  .archivedSpecimens,
                                        );
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
