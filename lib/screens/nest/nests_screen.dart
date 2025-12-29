import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/nest.dart';
import '../../providers/nest_provider.dart';

import '../statistics/stats_nests_screen.dart';
import 'add_nest_screen.dart';
import 'nest_detail_screen.dart';

import '../../core/core_consts.dart';
import '../../utils/utils.dart';
import '../../utils/export_utils.dart';
import '../../utils/import_utils.dart';
import '../../generated/l10n.dart';

class NestsScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const NestsScreen({super.key, required this.scaffoldKey});

  @override
  NestsScreenState createState() => NestsScreenState();
}

class NestsScreenState extends State<NestsScreen> {
  late NestProvider nestProvider;
  final _searchController = TextEditingController();
  bool _showActive = true; // Show active nests by default
  String _searchQuery = ''; // Empty search query by default
  NestFateType? _selectedFate;
  String? _selectedSpecies;
  String? _selectedLocality;
  String? _selectedObserver;
  DateFilter? _selectedDateFilter;
  Set<int> selectedNests = {}; // Set of selected nests
  SortOrder _sortOrder = SortOrder.descending; // Default sort order
  NestSortField _sortField = NestSortField.foundTime; // Default sort field
  Nest? _selectedNest;

  static final Map<DateFilter, String> _dateFilterLabels = {
    DateFilter.today: S.current.today,
    DateFilter.yesterday: S.current.yesterday,
    DateFilter.last7Days: S.current.last7Days,
    DateFilter.last30Days: S.current.last30Days,
    DateFilter.last90Days: S.current.last90Days,
    DateFilter.last180Days: S.current.last180Days,
    DateFilter.last365Days: S.current.last365Days,
  };

  @override
  void initState() {
    super.initState();
    nestProvider = context.read<NestProvider>();
    nestProvider.fetchNests();
  }

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
    }
  }

  // Sort the nests by the selected field
  List<Nest> _sortNests(List<Nest> nests) {
    nests.sort((a, b) {
      int comparison;

      // Helper function to handle nulls. Null values are treated as "smaller".
      int compareNullables<T extends Comparable>(T? a, T? b) {
        if (a == null && b == null) return 0; // Both are equal
        if (a == null) return -1; // a is "smaller"
        if (b == null) return 1; // b is "smaller"
        return a.compareTo(b);
      }

      // Helper function for comparing strings via a map lookup.
      int compareMappedStrings(NestFateType? aKey, NestFateType? bKey) {
        final aValue = aKey != null ? nestFateTypeFriendlyNames[aKey] : null;
        final bValue = bKey != null ? nestFateTypeFriendlyNames[bKey] : null;
        return compareNullables(aValue, bValue);
      }

      switch (_sortField) {
        case NestSortField.fieldNumber:
          comparison = a.fieldNumber!.compareTo(b.fieldNumber!);
          break;
        case NestSortField.foundTime:
          comparison = a.foundTime!.compareTo(b.foundTime!);
          break;
        case NestSortField.lastTime:
          comparison = compareNullables(a.lastTime, b.lastTime);
          break;
        case NestSortField.species:
          comparison = compareNullables(a.speciesName, b.speciesName);
          break;
        case NestSortField.locality:
          comparison = compareNullables(a.localityName, b.localityName);
          break;
        case NestSortField.nestFate:
          comparison = compareMappedStrings(a.nestFate!, b.nestFate!);
          break;
      }
      return _sortOrder == SortOrder.ascending ? comparison : -comparison;
    });
    return nests;
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
                            selected: _sortField == NestSortField.fieldNumber,
                            onSelected: (bool selected) {
                              setModalState(() {
                                _sortField = NestSortField.fieldNumber;
                              });
                              setState(() {
                                _sortField = NestSortField.fieldNumber;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: Text(S.current.foundTime),
                            showCheckmark: false,
                            selected: _sortField == NestSortField.foundTime,
                            onSelected: (bool selected) {
                              setModalState(() {
                                _sortField = NestSortField.foundTime;
                              });
                              setState(() {
                                _sortField = NestSortField.foundTime;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: Text(S.current.lastTime),
                            showCheckmark: false,
                            selected: _sortField == NestSortField.lastTime,
                            onSelected: (bool selected) {
                              setModalState(() {
                                _sortField = NestSortField.lastTime;
                              });
                              setState(() {
                                _sortField = NestSortField.lastTime;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: Text(S.current.species(1)),
                            showCheckmark: false,
                            selected: _sortField == NestSortField.species,
                            onSelected: (bool selected) {
                              setModalState(() {
                                _sortField = NestSortField.species;
                              });
                              setState(() {
                                _sortField = NestSortField.species;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: Text(S.current.locality),
                            showCheckmark: false,
                            selected: _sortField == NestSortField.locality,
                            onSelected: (bool selected) {
                              setModalState(() {
                                _sortField = NestSortField.locality;
                              });
                              setState(() {
                                _sortField = NestSortField.locality;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: Text(S.current.nestFate),
                            showCheckmark: false,
                            selected: _sortField == NestSortField.nestFate,
                            onSelected: (bool selected) {
                              setModalState(() {
                                _sortField = NestSortField.nestFate;
                              });
                              setState(() {
                                _sortField = NestSortField.nestFate;
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
                            icon: const Icon(Icons.south_outlined),
                          ),
                          ButtonSegment(
                            value: SortOrder.descending,
                            label: Text(S.of(context).descending),
                            icon: const Icon(Icons.north_outlined),
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

  List<String> _getUniqueSpecies() {
    final nests =
        _showActive
            ? nestProvider.activeNests
            : nestProvider.inactiveNests;

    final species =
        nests
            .where(
              (nest) => nest.speciesName != null && nest.speciesName!.isNotEmpty,
            )
            .map((inv) => inv.speciesName!)
            .toSet()
            .toList();

    species.sort();
    return species;
  }

  List<String> _getUniqueLocalities() {
    final nests =
        _showActive
            ? nestProvider.activeNests
            : nestProvider.inactiveNests;

    final localities =
        nests
            .where(
              (nest) => nest.localityName != null && nest.localityName!.isNotEmpty,
            )
            .map((inv) => inv.localityName!)
            .toSet()
            .toList();

    localities.sort();
    return localities;
  }

  List<String> _getUniqueObservers() {
    final nests =
        _showActive
            ? nestProvider.activeNests
            : nestProvider.inactiveNests;

    final observers =
        nests
            .where(
              (nest) => nest.observer != null && nest.observer!.isNotEmpty,
            )
            .map((nest) => nest.observer!)
            .toSet()
            .toList();

    observers.sort();
    return observers;
  }

  // Filter the nests based on the search query
  List<Nest> _filterNests(List<Nest> nests) {
    List<Nest> filtered = nests;

    // Filtro por destino do ninho
    if (_selectedFate != null) {
      filtered =
          filtered.where((nest) => nest.nestFate == _selectedFate).toList();
    }

    // Filtro por espécie
    if (_selectedSpecies != null) {
      filtered =
          filtered.where((nest) => nest.speciesName == _selectedSpecies).toList();
    }

    // Filtro por localidade
    if (_selectedLocality != null) {
      filtered =
          filtered
              .where((nest) => nest.localityName == _selectedLocality)
              .toList();
    }

    // Filtro por data (usa startTime)
    if (_selectedDateFilter != null) {
      filtered =
          filtered
              .where(
                (nest) =>
                    _isWithinDateFilter(nest.foundTime, _selectedDateFilter),
              )
              .toList();
    }

    // Filtro por busca textual
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (nest) =>
                    nest.fieldNumber!.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                  nest.speciesName!.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                    (nest.localityName?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
    }

    return _sortNests(filtered);
  }

  // Show the add nest screen
  void _showAddNestScreen(BuildContext context) async {
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
        // showDialog(
        //   context: context,
        //   builder: (context) {
        //     return AlertDialog.adaptive(
        //       title: Text(S.of(context).warningTitle),
        //       content: Text(S.of(context).observerAbbreviationMissing),
        //       actions: <Widget>[
        //         TextButton(
        //           child: Text(S.of(context).ok),
        //           onPressed: () {
        //             Navigator.of(context).pop();
        //           },
        //         ),
        //       ],
        //     );
        //   },
        // );
      }
      return;
    }

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
          content: Text(
            S
                .of(context)
                .confirmDeleteMessage(
                  selectedNests.length,
                  "male",
                  S.of(context).nest(selectedNests.length),
                ),
          ),
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
  Future<void> _exportSelectedNestsToJson(BuildContext context) async {
    try {
      final nestProvider = Provider.of<NestProvider>(context, listen: false);
      final nests = await Future.wait(
        selectedNests.map((id) => nestProvider.getNestById(id)),
      );

      final jsonString = jsonEncode(
        nests.map((nest) => nest.toJson()).toList(),
      );

      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final formattedDate = formatter.format(now);

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/selected_nests_$formattedDate.json';
      final file = File(filePath);
      await file.writeAsString(jsonString);

      // Share the file using share_plus
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath, mimeType: 'application/json')],
          text: S.current.nestExported(2),
          subject: S.current.nestData(2),
        ),
      );

      setState(() {
        selectedNests.clear();
      });
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            persist: true,
                            showCloseIcon: true,
                            backgroundColor: Theme.of(context).colorScheme.error,
                            content: Text(S.of(context).errorExportingNest(2, error.toString())),
                          ),
                        );
      // showDialog(
      //   context: context,
      //   builder: (context) {
      //     return AlertDialog(
      //       title: Row(
      //         children: [
      //           const Icon(Icons.error_outlined, color: Colors.red),
      //           const SizedBox(width: 10),
      //           Text(S.current.errorTitle),
      //         ],
      //       ),
      //       content: SingleChildScrollView(
      //         child: Text(S.current.errorExportingNest(2, error.toString())),
      //       ),
      //       actions: [
      //         TextButton(
      //           child: Text(S.of(context).ok),
      //           onPressed: () => Navigator.of(context).pop(),
      //         ),
      //       ],
      //     );
      //   },
      // );
    }
  }

  // Export all the selected nests to CSV
  void _exportSelectedNestsToCsv(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(S.current.exportingPleaseWait),
              ],
            ),
          ),
        );
      },
    );
    try {
      final nestProvider = Provider.of<NestProvider>(context, listen: false);
      final nests = await Future.wait(
        selectedNests.map((id) => nestProvider.getNestById(id)),
      );
      final locale = Localizations.localeOf(context);
      List<XFile> csvFiles = [];

      if (nests.isNotEmpty) {
        for (final nest in nests) {
          final filePath = await exportNestToCsv(context, nest, locale);

          csvFiles.add(XFile(filePath, mimeType: 'text/csv'));
        }
      }

      // Share the file using share_plus
      await SharePlus.instance.share(
        ShareParams(
          files: csvFiles,
          text: S.current.nestExported(2),
          subject: S.current.nestData(2),
        ),
      );

      setState(() {
        selectedNests.clear();
      });
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            persist: true,
                            showCloseIcon: true,
                            backgroundColor: Theme.of(context).colorScheme.error,
                            content: Text(S.of(context).errorExportingNest(2, error.toString())),
                          ),
                        );
      // showDialog(
      //   context: context,
      //   builder: (context) {
      //     return AlertDialog(
      //       title: Row(
      //         children: [
      //           const Icon(Icons.error_outlined, color: Colors.red),
      //           const SizedBox(width: 10),
      //           Text(S.current.errorTitle),
      //         ],
      //       ),
      //       content: SingleChildScrollView(
      //         child: Text(S.current.errorExportingNest(2, error.toString())),
      //       ),
      //       actions: [
      //         TextButton(
      //           child: Text(S.of(context).ok),
      //           onPressed: () => Navigator.of(context).pop(),
      //         ),
      //       ],
      //     );
      //   },
      // );
    }
  }

  // Export all the selected nests to Excel
  void _exportSelectedNestsToExcel(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(S.current.exportingPleaseWait),
              ],
            ),
          ),
        );
      },
    );
    try {
      final nestProvider = Provider.of<NestProvider>(context, listen: false);
      final nests = await Future.wait(
        selectedNests.map((id) => nestProvider.getNestById(id)),
      );
      final locale = Localizations.localeOf(context);
      List<XFile> excelFiles = [];

      if (nests.isNotEmpty) {
        for (final nest in nests) {
          final filePath = await exportNestToExcel(context, nest, locale);

          excelFiles.add(
            XFile(
              filePath,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          );
        }
      }

      // Share the file using share_plus
      await SharePlus.instance.share(
        ShareParams(
          files: excelFiles,
          text: S.current.nestExported(2),
          subject: S.current.nestData(2),
        ),
      );

      setState(() {
        selectedNests.clear();
      });
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            persist: true,
                            showCloseIcon: true,
                            backgroundColor: Theme.of(context).colorScheme.error,
                            content: Text(S.of(context).errorExportingNest(2, error.toString())),
                          ),
                        );
      // showDialog(
      //   context: context,
      //   builder: (context) {
      //     return AlertDialog(
      //       title: Row(
      //         children: [
      //           const Icon(Icons.error_outlined, color: Colors.red),
      //           const SizedBox(width: 10),
      //           Text(S.current.errorTitle),
      //         ],
      //       ),
      //       content: SingleChildScrollView(
      //         child: Text(S.current.errorExportingNest(2, error.toString())),
      //       ),
      //       actions: [
      //         TextButton(
      //           child: Text(S.of(context).ok),
      //           onPressed: () => Navigator.of(context).pop(),
      //         ),
      //       ],
      //     );
      //   },
      // );
    }
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
                  hintText: S.of(context).nests,
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
                    IconButton(
                      icon: const Icon(Icons.more_vert_outlined),
                      onPressed: () {
                        _showMoreOptionsBottomSheet(context);
                      },
                    ),
                  ],
                  onChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                  },
                ),

                // title: Text(S.of(context).nests),
              )
              : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // On large screens we show a split screen master/detail
          if (isSplitScreen) {
            return Row(
              children: [
                // Left: list (takes 40% width)
                Container(
                  width: constraints.maxWidth * 0.45,
                  // adjust ratio as needed
                  //decoration: BoxDecoration(
                  //  border: Border(
                  //    right: BorderSide(color: Theme.of(context).dividerColor),
                  //  ),
                  //),
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
      // Show the FAB at the end of the screen
      floatingActionButtonLocation:
          selectedNests.isNotEmpty && !_showActive
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
      bottomNavigationBar:
          selectedNests.isNotEmpty && !_showActive
              ? BottomAppBar(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Option to delete the selected nests
                    IconButton(
                      icon: const Icon(Icons.delete_outlined),
                      tooltip: S.of(context).delete,
                      color:
                          Theme.of(context).brightness == Brightness.light
                              ? Colors.red
                              : Colors.redAccent,
                      onPressed: _deleteSelectedNests,
                    ),
                    const VerticalDivider(),
                    // Option to export the selected nests
                    MenuAnchor(
                      builder: (context, controller, child) {
                        return IconButton(
                          icon: const Icon(Icons.share_outlined),
                          tooltip: S
                              .of(context)
                              .exportWhat(S.of(context).nest(2)),
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
                            _exportSelectedNestsToCsv(context);
                          },
                          child: const Text('CSV'),
                        ),
                        MenuItemButton(
                          onPressed: () {
                            _exportSelectedNestsToExcel(context);
                          },
                          child: const Text('Excel'),
                        ),
                        MenuItemButton(
                          onPressed: () {
                            _exportSelectedNestsToJson(context);
                          },
                          child: const Text('JSON'),
                        ),
                      ],
                    ),
                    if (selectedNests.length > 1)
                    IconButton(
                      icon: const Icon(Icons.insert_chart_outlined),
                      tooltip: S.of(context).statistics,
                      onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StatsNestsScreen(
                                  nests: selectedNests
                                      .map((id) async =>
                                          await nestProvider.getNestById(id))
                                      .whereType<Nest>()
                                      .toList(),
                                ),
                              ),
                            );
                          },
                    ),
                    const VerticalDivider(),
                    // Option to clear the selected nests
                    IconButton(
                      icon: const Icon(Icons.clear_outlined),
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

  Widget _buildListPane(BuildContext context, bool isSplitScreen, bool isMenuShown) {
    return Column(
      children: [
        if (isSplitScreen) const SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
          child:
              isSplitScreen
                  ? SearchBar(
                    controller: _searchController,
                    hintText: S.of(context).nests,
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
                          // Action to select all nests
                          if (!_showActive)
                            MenuItemButton(
                              leadingIcon: const Icon(
                                Icons.library_add_check_outlined,
                              ),
                              onPressed: () {
                                final filteredNests = _filterNests(
                                  nestProvider.inactiveNests,
                                );
                                setState(() {
                                  selectedNests =
                                      filteredNests
                                          .map((nest) => nest.id)
                                          .whereType<int>()
                                          .toSet();
                                });
                              },
                              child: Text(S.of(context).selectAll),
                            ),
                          // Action to import nests from JSON
                          MenuItemButton(
                            leadingIcon: const Icon(Icons.file_open_outlined),
                            onPressed: () async {
                              await importNestsFromJson(context);
                              await nestProvider.fetchNests();
                            },
                            child: Text(S.of(context).import),
                          ),
                          if (nestProvider.inactiveNests.isNotEmpty) ...[
                          MenuItemButton(
                            leadingIcon: const Icon(Icons.share_outlined),
                            onPressed: () async {
                              await exportAllInactiveNestsToJson(context);
                            },
                            child: Text(S.of(context).exportAll),
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
                      label: Text(S.of(context).active),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text(S.of(context).inactive),
                    ),
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
                          return FilterChip(
                            label: Text(
                              _selectedDateFilter != null
                                  ? _dateFilterLabels[_selectedDateFilter] ??
                                      S.of(context).date
                                  : S.of(context).date,
                            ),
                            avatar: _selectedDateFilter == null ? Icon(Icons.calendar_today_outlined) : null,
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
                                });
                              }
                            },
                            selected: _selectedDateFilter != null,
                          );
                        },
                        menuChildren: [
                          // MenuItemButton(
                          //   onPressed: () {
                          //     setState(() {
                          //       _selectedDateFilter = null;
                          //     });
                          //   },
                          //   child: Text(S.of(context).allDates),
                          // ),
                          ...DateFilter.values.map((filter) {
                            return MenuItemButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDateFilter = filter;
                                });
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
                              _selectedFate != null
                                  ? nestFateTypeFriendlyNames[_selectedFate] ??
                                      S.current.nestFate
                                  : S.current.nestFate,
                            ),
                            avatar: _selectedFate == null ? Icon(Icons.category_outlined) : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            visualDensity: VisualDensity.compact,
                            onSelected: (selected) {
                              if (selected) {
                                controller.open();
                              } else {
                                setState(() {
                                  _selectedFate = null;
                                });
                              }
                            },
                            selected: _selectedFate != null,
                          );
                        },
                        menuChildren: [
                          // MenuItemButton(
                          //   onPressed: () {
                          //     setState(() {
                          //       _selectedFate = null;
                          //     });
                          //   },
                          //   child: Text(S.current.allTypes),
                          // ),
                          ...NestFateType.values.map((fate) {
                            return MenuItemButton(
                              onPressed: () {
                                setState(() {
                                  _selectedFate = fate;
                                });
                              },
                              child: Text(
                                nestFateTypeFriendlyNames[fate] ??
                                    fate.toString(),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(width: 8.0),
                      MenuAnchor(
                        builder: (context, controller, child) {
                          return FilterChip(
                            label: Text(
                              _selectedSpecies ?? S.current.species(1),
                            ),
                            avatar: _selectedSpecies == null ? Icon(Icons.account_tree_outlined) : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            visualDensity: VisualDensity.compact,
                            onSelected: (selected) {
                              if (selected) {
                                controller.open();
                              } else {
                                setState(() {
                                  _selectedSpecies = null;
                                });
                              }
                            },
                            selected: _selectedSpecies != null,
                          );
                        },
                        menuChildren: [
                          // MenuItemButton(
                          //   onPressed: () {
                          //     setState(() {
                          //       _selectedSpecies = null;
                          //     });
                          //   },
                          //   child: Text(S.current.allTypes),
                          // ),
                          ..._getUniqueSpecies().map((species) {
                            return MenuItemButton(
                              onPressed: () {
                                setState(() {
                                  _selectedSpecies = species;
                                });
                              },
                              child: Text(species),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(width: 8.0),
                      MenuAnchor(
                        builder: (context, controller, child) {
                          return FilterChip(
                            label: Text(
                              _selectedLocality ?? S.current.locality,
                            ),
                            avatar: _selectedLocality == null ? Icon(Icons.location_on_outlined) : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            visualDensity: VisualDensity.compact,
                            onSelected: (selected) {
                              if (selected) {
                                controller.open();
                              } else {
                                setState(() {
                                  _selectedLocality = null;
                                });
                              }
                            },
                            selected: _selectedLocality != null,
                          );
                        },
                        menuChildren: [
                          // MenuItemButton(
                          //   onPressed: () {
                          //     setState(() {
                          //       _selectedLocality = null;
                          //     });
                          //   },
                          //   child: Text(S.current.allLocalities),
                          // ),
                          ..._getUniqueLocalities().map((locality) {
                            return MenuItemButton(
                              onPressed: () {
                                setState(() {
                                  _selectedLocality = locality;
                                });
                              },
                              child: Text(locality),
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
                          // MenuItemButton(
                          //   onPressed: () {
                          //     setState(() {
                          //       _selectedObserver = null;
                          //     });
                          //   },
                          //   child: Text(S.current.allObservers),
                          // ),
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
          child: Consumer<NestProvider>(
            builder: (context, nestProvider, child) {
              // Filter the nests based on the active/inactive status
              final filteredNests = _filterNests(
                _showActive
                    ? nestProvider.activeNests
                    : nestProvider.inactiveNests,
              );

              // Show a message if no nests are found
              if (_showActive && nestProvider.activeNests.isEmpty ||
                  !_showActive && nestProvider.inactiveNests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.egg_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.surfaceDim,
                      ),
                      const SizedBox(height: 8),
                      Text(S.of(context).noNestsFound),
                      const SizedBox(height: 8),
                      ActionChip(
                        label: Text(S.of(context).newNest),
                        avatar: const Icon(Icons.add_outlined),
                        onPressed: () {
                          _showAddNestScreen(context);
                        },
                      ),
                      if (!_showActive) ...[
                        const SizedBox(height: 8),
                        ActionChip(
                          label: Text(S.of(context).import),
                          avatar: const Icon(Icons.file_open_outlined),
                          onPressed: () async {
                            await importNestsFromJson(context);
                          },
                        ),
                      ],
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
                          await nestProvider.fetchNests();
                        },
                      ),
                      // FilledButton.icon(
                      //   label: Text(S.of(context).refresh),
                      //   icon: const Icon(Icons.refresh_outlined),
                      //   onPressed: () async {
                      //     await nestProvider.fetchNests();
                      //   },
                      // ),
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
                      child: ListView.separated(
                        separatorBuilder: (context, index) => Divider(),
                        shrinkWrap: true,
                        itemCount: filteredNests.length,
                        itemBuilder: (context, index) {
                          return nestListTileItem(
                            filteredNests,
                            index,
                            context,
                            nestProvider,
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
    if (_selectedNest == null) {
      // Placeholder when nothing selected
      return Center(child: Text(S.of(context).selectInventoryToView));
    }

    // Show InventoryDetailScreen in-place for the selected inventory
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: NestDetailScreen(nest: _selectedNest!, isEmbedded: true),
    );
  }

  ListTile nestListTileItem(
    List<Nest> filteredNests,
    int index,
    BuildContext context,
    NestProvider nestProvider,
  ) {
    final nest = filteredNests[index];
    final isSelected = selectedNests.contains(nest.id);
    final isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

    return ListTile(
      title: Text(nest.fieldNumber!),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nest.speciesName!,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
          Text(nest.localityName!, overflow: TextOverflow.ellipsis),
          Text('${nest.longitude}; ${nest.latitude}'),
          Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(nest.foundTime!)),
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
      trailing:
          nest.nestFate == NestFateType.fatSuccess
              ? const Icon(Icons.check_circle, color: Colors.green)
              : nest.nestFate == NestFateType.fatLost
              ? const Icon(Icons.cancel, color: Colors.red)
              : const Icon(Icons.help, color: Colors.grey),
      onLongPress: () => _showBottomSheet(context, nest),
      onTap: () {
        if (isLargeScreen) {
          setState(() {
            _selectedNest = nest;
          });
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NestDetailScreen(nest: nest),
            ),
          ).then((result) {
            if (result == true) {
              nestProvider.fetchNests();
            }
          });
        }
      },
    );
  }

  // Show the bottom sheet with options to edit, delete, and export the nest
  void _showBottomSheet(BuildContext context, Nest nest) {
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
                      // Show the field number of the nest
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          nest.fieldNumber!,
                          style: TextTheme.of(context).bodyLarge,
                        ),
                      ),
                      // ListTile(
                      //   title: Text(nest.fieldNumber!),
                      // ),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => AddNestScreen(
                                        nest: nest,
                                        isEditing: true,
                                      ),
                                ),
                              );
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
                                            S.of(context).nest(1),
                                          ),
                                    ),
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
                                          // Navigator.of(context).pop();
                                          // Call the function to delete species
                                          Provider.of<NestProvider>(
                                            context,
                                            listen: false,
                                          ).removeNest(nest);
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
                          // Icon(Icons.share_outlined),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  const SizedBox(width: 16.0),
                                  ActionChip(
                                    label: const Text('CSV'),
                                    onPressed: () async {                             
                                      final locale = Localizations.localeOf(
                                        context,
                                      );
                                      final csvFile = await exportNestToCsv(
                                        context,
                                        nest,
                                        locale,
                                      );
                                      // Share the file using share_plus
                                      await SharePlus.instance.share(
                                        ShareParams(
                                          files: [
                                            XFile(
                                              csvFile,
                                              mimeType: 'text/csv',
                                            ),
                                          ],
                                          text: S.current.nestExported(1),
                                          subject: S.current.nestData(1),
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  const SizedBox(width: 8.0),
                                  ActionChip(
                                    label: const Text('Excel'),
                                    onPressed: () async {                                      
                                      final locale = Localizations.localeOf(
                                        context,
                                      );
                                      final excelFile = await exportNestToExcel(
                                        context,
                                        nest,
                                        locale,
                                      );
                                      // Share the file using share_plus
                                      await SharePlus.instance.share(
                                        ShareParams(
                                          files: [
                                            XFile(
                                              excelFile,
                                              mimeType:
                                                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                                            ),
                                          ],
                                          text: S.current.nestExported(1),
                                          subject: S.current.nestData(1),
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  const SizedBox(width: 8.0),
                                  ActionChip(
                                    label: const Text('JSON'),
                                    onPressed: () async {                                      
                                      exportNestToJson(context, nest);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  const SizedBox(width: 8.0),
                                  ActionChip(
                                    label: const Text('KML'),
                                    onPressed: () async {
                                      exportNestToKml(context, nest);
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
                    // crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GridView.count(
                        crossAxisCount:
                            MediaQuery.sizeOf(context).width < 600 ? 4 : 5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: <Widget>[
                          if (!_showActive)
                            buildGridMenuItem(
                              context,
                              Icons.library_add_check_outlined,
                              S.of(context).selectAll,
                              () async {
                                Navigator.of(context).pop();
                                final filteredNests = _filterNests(
                                  nestProvider.inactiveNests,
                                );
                                setState(() {
                                  selectedNests =
                                      filteredNests
                                          .map((nest) => nest.id)
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
                              await importNestsFromJson(context);
                              await nestProvider.fetchNests();
                              Navigator.of(context).pop();
                            },
                          ),
                          // buildGridMenuItem(
                          //     context, Icons.share_outlined, S.of(context).exportAll,
                          //         () async {
                          //       Navigator.of(context).pop();
                          //       await exportAllInactiveNestsToJson(context);
                          //     }),
                        ],
                      ),
                      if (nestProvider.inactiveNests.isNotEmpty) ...[
                      Divider(),
                      Row(
                        children: [
                          const SizedBox(width: 8.0),
                          Text(
                            S.current.exportAll,
                            style: TextTheme.of(context).bodyMedium,
                          ),
                          // Icon(Icons.share_outlined),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  const SizedBox(width: 16.0),
                                  ActionChip(
                                    label: const Text('JSON'),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      await exportAllInactiveNestsToJson(
                                        context,
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
