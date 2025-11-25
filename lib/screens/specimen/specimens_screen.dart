import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
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

  List<Specimen> _sortSpecimens(List<Specimen> specimens) {
    specimens.sort((a, b) {
      int comparison;

      // Helper function to handle nulls. Null values are treated as "smaller".
      int compareNullables<T extends Comparable>(T? a, T? b) {
        if (a == null && b == null) return 0; // Both are equal
        if (a == null) return -1; // a is "smaller"
        if (b == null) return 1;  // b is "smaller"
        return a.compareTo(b);
      }

      // Helper function for comparing strings via a map lookup.
      int compareMappedStrings(SpecimenType aKey, SpecimenType bKey) {
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
                        label: Text(S.current.fieldNumber),
                        showCheckmark: false,
                        selected: _sortField == SpecimenSortField.fieldNumber,
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
                        selected: _sortField == SpecimenSortField.sampleTime,
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
                        selected: _sortField == SpecimenSortField.specimenType,
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
                  Text(S.of(context).direction, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  SegmentedButton<SortOrder>(
                    segments: [
                      ButtonSegment(value: SortOrder.ascending, label: Text(S.of(context).ascending), icon: Icon(Icons.south_outlined)),
                      ButtonSegment(value: SortOrder.descending, label: Text(S.of(context).descending), icon: Icon(Icons.north_outlined)),
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

  List<Specimen> _filterSpecimens(List<Specimen> specimens) {
    if (_searchQuery.isEmpty) {
      return specimens;
    }
    List<Specimen> filteredSpecimens = specimens.where((specimen) =>
      specimen.fieldNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      specimen.speciesName!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      specimen.locality!.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
    return _sortSpecimens(filteredSpecimens);
  }

  void _showAddSpecimenScreen(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final String observerAbbreviation = prefs.getString('observerAcronym') ?? '';

    if (observerAbbreviation.isEmpty) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog.adaptive(
              title: Text(S.of(context).warningTitle),
              content: Text(S.of(context).observerAbbreviationMissing),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).ok),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
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

  void _exportSelectedSpecimensToJson(BuildContext context) async {
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
              const SizedBox(width: 8),
              Text(S.current.errorExportingSpecimen(2, error.toString())),
            ],
          ),
        ),
      );
    }
  }

  void _exportSelectedSpecimensToCsv(BuildContext context) async {
    try {
      final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
      final specimens = await Future.wait(selectedSpecimens.map((id) => specimenProvider.getSpecimenById(id)));
            
      await exportAllSpecimensToCsv(context, specimens);

      setState(() {
        selectedSpecimens.clear();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outlined, color: Colors.red),
              const SizedBox(width: 8),
              Text(S.current.errorExportingSpecimen(2, error.toString())),
            ],
          ),
        ),
      );
    }
  }

  void _exportSelectedSpecimensToExcel(BuildContext context) async {
    try {
      final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
      final specimens = await Future.wait(selectedSpecimens.map((id) => specimenProvider.getSpecimenById(id)));
            
      await exportAllSpecimensToExcel(context, specimens);

      setState(() {
        selectedSpecimens.clear();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outlined, color: Colors.red),
              const SizedBox(width: 8),
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
        title: SearchBar(
          controller: _searchController,
          hintText: S.of(context).specimens(2),
          elevation: WidgetStateProperty.all(0),
          // leading: const Icon(Icons.search_outlined),
          trailing: [
            IconButton(
              icon: const Icon(Icons.sort_outlined),
              tooltip: S.of(context).sortBy,
              onPressed: () {
                _showSortOptionsBottomSheet();
              },
            ),
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
          ],
          onChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
        ),
        // title: Text(S.of(context).specimens(2)),
        leading: MediaQuery.sizeOf(context).width < 600 ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_outlined),
            onPressed: () {
              widget.scaffoldKey.currentState?.openDrawer();
            },
          ),
        ) : const SizedBox.shrink(),
        actions: [
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
                  leadingIcon: const Icon(Icons.library_add_check_outlined),
                  onPressed: () {
                    final filteredSpecimens = _filterSpecimens(_showPending 
                        ? specimenProvider.pendingSpecimens
                        : specimenProvider.archivedSpecimens);
                    setState(() {
                      selectedSpecimens = filteredSpecimens
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
                  exportAllSpecimensToCsv(context, _showPending ? specimenProvider.pendingSpecimens : specimenProvider.archivedSpecimens);
                },
                child: Text('${S.of(context).exportAll} (CSV)'),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.share_outlined),
                onPressed: () {
                  exportAllSpecimensToExcel(context, _showPending ? specimenProvider.pendingSpecimens : specimenProvider.archivedSpecimens);
                },
                child: Text('${S.of(context).exportAll} (Excel)'),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.share_outlined),
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
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        label: Text(S.of(context).refresh),
                        icon: const Icon(Icons.refresh_outlined),
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
                          _exportSelectedSpecimensToCsv(context);
                        },
                        child: const Text('CSV'),
                      ),
                      MenuItemButton(
                        onPressed: () {
                          _exportSelectedSpecimensToExcel(context);
                        },
                        child: const Text('Excel'),
                      ),
                      MenuItemButton(
                        onPressed: () {
                          _exportSelectedSpecimensToJson(context);
                        },
                        child: const Text('JSON'),
                      ),
                    ],
                  ),
                  if (_showPending)
                    IconButton(
                      icon: const Icon(Icons.archive_outlined),
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
                        Text(specimen.locality!, overflow: TextOverflow.ellipsis,),
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
          Text(specimen.locality!, overflow: TextOverflow.ellipsis,),
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
                    child: Text(specimen.fieldNumber, style: TextTheme.of(context).bodyLarge,),
                  ),
                  // ListTile(
                  //   title: Text(specimen.fieldNumber),
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
                            builder: (context) => AddSpecimenScreen(
                              specimen: specimen,
                              isEditing: true,
                            ),
                          ),
                        );
                      }),
                      if (_showPending)
                      buildGridMenuItem(context, Icons.archive_outlined,
                          S.current.archive, () {
                            Navigator.of(context).pop();
                            specimen.isPending = false;
                            specimenProvider.updateSpecimen(specimen);
                          }),
                      // buildGridMenuItem(
                      //       context, Icons.share_outlined, 'KML',
                      //           () async {
                      //         Navigator.of(context).pop();
                      //         exportSpecimenToKml(context, specimen);
                      //       }),
                      buildGridMenuItem(context, Icons.delete_outlined,
                          S.of(context).delete, () {
                            Navigator.of(context).pop();
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
                          }, color: Theme.of(context).colorScheme.error),
                    ],
                  ),
                  // Divider(),
                  Row(
                    children: [
                      const SizedBox(width: 8.0),
                      Text(S.current.export, style: TextTheme
                          .of(context)
                          .bodyMedium,),
                      // Icon(Icons.share_outlined),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child:
                          Row(
                            children: [
                              const SizedBox(width: 16.0),
                              ActionChip(
                                label: const Text('KML'),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  exportSpecimenToKml(context, specimen);
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
                        crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 4 : 5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: <Widget>[
                            buildGridMenuItem(
                                context, Icons.library_add_check_outlined, S.of(context).selectAll,
                                    () async {
                                  Navigator.of(context).pop();
                                  final filteredSpecimens = _filterSpecimens(_showPending
                                      ? specimenProvider.pendingSpecimens
                                      : specimenProvider.archivedSpecimens);
                                  setState(() {
                                    selectedSpecimens = filteredSpecimens
                                        .map((specimen) => specimen.id)
                                        .whereType<int>()
                                        .toSet();
                                  });
                                }),
                          // Action to import nests from JSON
                          buildGridMenuItem(
                              context, Icons.file_open_outlined, S.of(context).import,
                                  () async {
                                Navigator.of(context).pop();
                                await importSpecimensFromJson(context);
                                await specimenProvider.fetchSpecimens();
                              }),
                          // buildGridMenuItem(
                          //     context, Icons.share_outlined, '${S.of(context).exportAll} (CSV)',
                          //         () async {
                          //       Navigator.of(context).pop();
                          //       exportAllSpecimensToCsv(context, _showPending ? specimenProvider.pendingSpecimens : specimenProvider.archivedSpecimens);
                          //     }),
                          // buildGridMenuItem(
                          //     context, Icons.share_outlined, '${S.of(context).exportAll} (Excel)',
                          //         () async {
                          //       Navigator.of(context).pop();
                          //       exportAllSpecimensToExcel(context, _showPending ? specimenProvider.pendingSpecimens : specimenProvider.archivedSpecimens);
                          //     }),
                          // buildGridMenuItem(
                          //     context, Icons.share_outlined, '${S.of(context).exportAll} (JSON)',
                          //         () async {
                          //       Navigator.of(context).pop();
                          //       exportAllSpecimensToJson(context, _showPending ? specimenProvider.pendingSpecimens : specimenProvider.archivedSpecimens);
                          //     }),
                        ],
                      ),
                      Divider(),
                      Row(
                        children: [
                          const SizedBox(width: 8.0),
                          Text(S.current.exportAll, style: TextTheme
                              .of(context)
                              .bodyMedium,),
                          // Icon(Icons.share_outlined),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child:
                              Row(
                                children: [
                                  const SizedBox(width: 16.0),
                                  ActionChip(
                                    label: const Text('CSV'),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      exportAllSpecimensToCsv(context, _showPending ? specimenProvider.pendingSpecimens : specimenProvider.archivedSpecimens);
                                    },
                                  ),
                                  const SizedBox(width: 8.0),
                                  ActionChip(
                                    label: const Text('Excel'),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      exportAllSpecimensToExcel(context, _showPending ? specimenProvider.pendingSpecimens : specimenProvider.archivedSpecimens);
                                    },
                                  ),
                                  const SizedBox(width: 8.0),
                                  ActionChip(
                                    label: const Text('JSON'),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      exportAllSpecimensToJson(context, _showPending ? specimenProvider.pendingSpecimens : specimenProvider.archivedSpecimens);
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
}