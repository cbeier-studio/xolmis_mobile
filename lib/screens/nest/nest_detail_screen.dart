import 'package:fab_m3e/fab_m3e.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/nest.dart';
import '../../providers/nest_provider.dart';
import '../../providers/nest_revision_provider.dart';
import '../../providers/egg_provider.dart';

import 'nest_revision_tab.dart';
import 'nest_egg_tab.dart';
import 'add_egg_screen.dart';
import 'add_revision_screen.dart';
import '../../core/core_consts.dart';
import '../../utils/export_utils.dart';
import '../../generated/l10n.dart';

class NestDetailScreen extends StatefulWidget {
  final Nest nest;
  final bool isEmbedded;

  const NestDetailScreen({super.key, 
    required this.nest, 
    this.isEmbedded = false,
  });

  @override
  NestDetailScreenState createState() => NestDetailScreenState();
}

class NestDetailScreenState extends State<NestDetailScreen> with SingleTickerProviderStateMixin {
  bool _isSubmitting = false;
  final fabController = FabMenuController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Access the providers
    final revisionProvider = Provider.of<NestRevisionProvider>(
        context, listen: false);
    final eggProvider = Provider.of<EggProvider>(
        context, listen: false);

    // Load the nest revisions for the current nest
    revisionProvider.loadRevisionForNest(widget.nest.id!);
    // Load the eggs for the current nest
    eggProvider.loadEggForNest(widget.nest.id!);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddRevisionScreen(BuildContext context) {
    final revisionProvider = Provider.of<NestRevisionProvider>(context, listen: false);
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
              child: AddNestRevisionScreen(nest: widget.nest),
            ),
          );
        },
      ).then((newRevision) {
        // Reload the nest revision list
        if (newRevision != null) {
          revisionProvider.getRevisionForNest(widget.nest.id!);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddNestRevisionScreen(nest: widget.nest),
        ),
      ).then((newRevision) {
        // Reload the nest revision list
        if (newRevision != null) {
          revisionProvider.getRevisionForNest(widget.nest.id!);
        }
      });
    }
  }

  Future<void> _showAddEggScreen(BuildContext context) async {
    final eggProvider = Provider.of<EggProvider>(context, listen: false);
    int nextNumber = await eggProvider.getNextSequentialNumber(widget.nest.fieldNumber!);
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
              child: AddEggScreen(
                nest: widget.nest,
                initialFieldNumber: '${widget.nest.fieldNumber}-${nextNumber.toString().padLeft(2, '0')}',
                initialSpeciesName: widget.nest.speciesName,)
            ),
          );
        },
      ).then((newEgg) {
        // Reload the egg list
        if (newEgg != null) {
          eggProvider.getEggForNest(widget.nest.id!);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddEggScreen(
          nest: widget.nest,
          initialFieldNumber: '${widget.nest.fieldNumber}-${nextNumber.toString().padLeft(2, '0')}',
          initialSpeciesName: widget.nest.speciesName,)
        ),
      ).then((newEgg) {
        // Reload the egg list
        if (newEgg != null) {
          eggProvider.getEggForNest(widget.nest.id!);
        }
      });
    }
  }

  Widget _buildTopArea(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title + actions row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Row(
            children: [
              Expanded(
                child: Text('${widget.nest.fieldNumber}',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              // Pause/Resume button (only when active)
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  _showNestInfoDialog(context, widget.nest);
                },
              ),
              IconButton(
                onPressed: () {
                  _showAddRevisionScreen(context);
                }, 
                icon: Icon(Theme.of(context).brightness == Brightness.light ? Icons.beenhere_outlined : Icons.beenhere),
              ),
              IconButton(
                onPressed: () {
                  _showAddEggScreen(context);
                }, 
                icon: Icon(Theme.of(context).brightness == Brightness.light ? Icons.egg_outlined : Icons.egg),
              ),
              if (widget.nest.isActive)
                IconButton.filled(
                  onPressed: () async {
                    if (widget.nest.revisionsList != null && widget.nest.revisionsList!.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            showCloseIcon: true,
                            backgroundColor: Colors.amber,
                            content: Text(S.of(context).nestRevisionsMissing),
                          ),
                        );
                        // showDialog(
                        //   context: context,
                        //   builder: (context) {
                        //     return AlertDialog.adaptive(
                        //       title: Text(S.of(context).warningTitle),
                        //       content: Text(S.of(context).nestRevisionsMissing),
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

                    NestFateType? selectedNestFate;

                    // Show dialog with the DropdownButton
                    await showDialog<NestFateType>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(S.of(context).confirmFate),
                        content: DropdownButtonFormField<NestFateType>(
                          initialValue: selectedNestFate,
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
                                setState(() {
                                  _isSubmitting = true;
                                });

                                try {
                                  // Update nest with fate, lastTime and isActive = false
                                  widget.nest.nestFate = selectedNestFate;
                                  widget.nest.lastTime = DateTime.now();
                                  widget.nest.isActive = false;

                                  // Save changes to database using the provider
                                  await Provider.of<NestProvider>(context, listen: false)
                                      .updateNest(widget.nest);

                                  // ScaffoldMessenger.of(context).showSnackBar(
                                  //   const SnackBar(
                                  //     content: Text('Ninho desativado com sucesso!'),
                                  //   ),
                                  // );

                                  // Close screen of nest details
                                  Navigator.pop(context, selectedNestFate);
                                  Navigator.pop(context);
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      persist: true,
                                      showCloseIcon: true,
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                      content: Text(S.of(context).errorInactivatingNest(error.toString())),
                                    ),
                                  );
                                } finally {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                }
                              }
                            },
                            child: Text(S.of(context).save),
                          ),
                        ],
                      ),
                    );
                  },
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : Colors.deepPurple,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      year2023: false,
                    ),
                  )
                      : const Icon(Icons.flag_outlined),
                ),
              if (widget.nest.isActive == false)
                MediaQuery.sizeOf(context).width < 600
                    ? IconButton(
                  icon: const Icon(Icons.more_vert_outlined),
                  onPressed: () {
                    _showMoreOptionsBottomSheet(context, widget.nest);
                  },
                )
                    : MenuAnchor(
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
                    // Option to export the selected nest to CSV
                    MenuItemButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final locale = Localizations.localeOf(context);
                        final csvFile = await exportNestToCsv(context, widget.nest, locale);
                        // Share the file using share_plus
                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(csvFile, mimeType: 'text/csv')],
                            text: S.current.nestExported(1),
                            subject: S.current.nestData(1),
                          ),
                        );
                      },
                      child: const Text('CSV'),
                    ),
                    // Option to export the selected nest to Excel
                    MenuItemButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final locale = Localizations.localeOf(context);
                        final excelFile = await exportNestToExcel(context, widget.nest, locale);
                        // Share the file using share_plus
                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(excelFile, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')], 
                            text: S.current.nestExported(1), 
                            subject: S.current.nestData(1)
                          ),
                        );
                      },
                      child: const Text('Excel'),
                    ),
                    // Option to export the selected nest to JSON
                    MenuItemButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        exportNestToJson(context, widget.nest);
                      },
                      child: const Text('JSON'),
                    ),
                    // Option to export the selected nest to JSON
                    MenuItemButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        exportNestToKml(context, widget.nest);
                      },
                      child: const Text('KML'),
                    ),
                  ],
                ),
            ],
          ),
        ),
        // Inventory summary row (type, duration, max species)
        if (!widget.isEmbedded)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.nest.speciesName!),
          ],
        ),
        // TabBar
        TabBar(
          controller: _tabController,
                      tabs: [
                        Consumer<NestRevisionProvider>(
                          builder: (context, revisionProvider, child) {
                            final revisionList = revisionProvider.getRevisionForNest(
                                widget.nest.id!);
                            return revisionList.isNotEmpty
                                ? Badge.count(
                              backgroundColor: Colors.deepPurple[100],
                              textColor: Colors.deepPurple[800],
                              alignment: AlignmentDirectional.centerEnd,
                              offset: const Offset(24, -8),
                              count: revisionList.length,
                              child: Tab(text: S.of(context).revision(2)),
                            )
                                : Tab(text: S.of(context).revision(2));
                          },
                        ),
                        Consumer<EggProvider>(
                          builder: (context, eggProvider, child) {
                            final eggList = eggProvider.getEggForNest(
                                widget.nest.id!);
                            return eggList.isNotEmpty
                                ? Badge.count(
                              backgroundColor: Colors.deepPurple[100],
                              textColor: Colors.deepPurple[800],
                              alignment: AlignmentDirectional.centerEnd,
                              offset: const Offset(24, -8),
                              count: eggList.length,
                              child: Tab(text: S.of(context).egg(2)),
                            )
                                : Tab(text: S.of(context).egg(2));
                          },
                        ),
                      ],
                    ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // If embedded, return widget without Scaffold/AppBar
    if (widget.isEmbedded) {
      return SafeArea(
        child: Column(
          children: [
            _buildTopArea(context),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  NestRevisionsTab(nest: widget.nest),
                  EggsTab(nest: widget.nest),
                ],
              ),
            ),
            // Floating actions in embedded mode: show FAB aligned bottom-right
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FabMenuM3E(
                  controller: fabController,
                  alignment: Alignment.bottomRight,
                  direction: FabMenuDirection.up,
                  overlay: false,
                  primaryFab: FabM3E(
                      icon: fabController.isOpen ? const Icon(Icons.close) : const Icon(Icons.add),
                      onPressed: fabController.toggle),
                  items: [
                    FabMenuItem(
                      icon: Theme.of(context).brightness == Brightness.light
                          ? const Icon(Icons.beenhere_outlined)
                          : const Icon(Icons.beenhere),
                      label: Text(S.of(context).revision(1)),
                      onPressed: () {
                        _showAddRevisionScreen(context);
                      },
                    ),
                    FabMenuItem(
                      icon: Theme.of(context).brightness == Brightness.light
                          ? const Icon(Icons.egg_outlined)
                          : const Icon(Icons.egg),
                      label: Text(S.of(context).egg(1)),
                      onPressed: () {
                        _showAddEggScreen(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
            title: Text('${widget.nest.fieldNumber}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  _showNestInfoDialog(context, widget.nest);
                },
              ),
              if (widget.nest.isActive)
                IconButton.filled(
                  onPressed: () async {
                    if (widget.nest.revisionsList != null && widget.nest.revisionsList!.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            showCloseIcon: true,
                            backgroundColor: Colors.amber,
                            content: Text(S.of(context).nestRevisionsMissing),
                          ),
                        );
                        // showDialog(
                        //   context: context,
                        //   builder: (context) {
                        //     return AlertDialog.adaptive(
                        //       title: Text(S.of(context).warningTitle),
                        //       content: Text(S.of(context).nestRevisionsMissing),
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

                    NestFateType? selectedNestFate;

                    // Show dialog with the DropdownButton
                    await showDialog<NestFateType>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(S.of(context).confirmFate),
                        content: DropdownButtonFormField<NestFateType>(
                          initialValue: selectedNestFate,
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
                                setState(() {
                                  _isSubmitting = true;
                                });

                                try {
                                  // Update nest with fate, lastTime and isActive = false
                                  widget.nest.nestFate = selectedNestFate;
                                  widget.nest.lastTime = DateTime.now();
                                  widget.nest.isActive = false;

                                  // Save changes to database using the provider
                                  await Provider.of<NestProvider>(context, listen: false)
                                      .updateNest(widget.nest);

                                  // ScaffoldMessenger.of(context).showSnackBar(
                                  //   const SnackBar(
                                  //     content: Text('Ninho desativado com sucesso!'),
                                  //   ),
                                  // );

                                  // Close screen of nest details
                                  Navigator.pop(context, selectedNestFate);
                                  Navigator.pop(context);
                                } catch (error) {
                                  // Handle errors
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      persist: true,
                                      showCloseIcon: true,
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                      content: Text(S.of(context).errorInactivatingNest(error.toString())),
                                    ),
                                  );
                                } finally {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                }
                              }
                            },
                            child: Text(S.of(context).save),
                          ),
                        ],
                      ),
                    );
                  },
                  style: IconButton.styleFrom(
                    foregroundColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : Colors.deepPurple,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      year2023: false,
                    ),
                  )
                      : const Icon(Icons.flag_outlined),
                ),
              if (widget.nest.isActive == false)
                MediaQuery.sizeOf(context).width < 600
                    ? IconButton(
                  icon: const Icon(Icons.more_vert_outlined),
                  onPressed: () {
                    _showMoreOptionsBottomSheet(context, widget.nest);
                  },
                )
                    : MenuAnchor(
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
                    // Option to export the selected nest to CSV
                    MenuItemButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final locale = Localizations.localeOf(context);
                        final csvFile = await exportNestToCsv(context, widget.nest, locale);
                        // Share the file using share_plus
                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(csvFile, mimeType: 'text/csv')],
                            text: S.current.nestExported(1),
                            subject: S.current.nestData(1),
                          ),
                        );
                      },
                      child: const Text('CSV'),
                    ),
                    // Option to export the selected nest to Excel
                    MenuItemButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final locale = Localizations.localeOf(context);
                        final excelFile = await exportNestToExcel(context, widget.nest, locale);
                        // Share the file using share_plus
                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(excelFile, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')], 
                            text: S.current.nestExported(1), 
                            subject: S.current.nestData(1)
                          ),
                        );
                      },
                      child: const Text('Excel'),
                    ),
                    // Option to export the selected nest to JSON
                    MenuItemButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        exportNestToJson(context, widget.nest);
                      },
                      child: const Text('JSON'),
                    ),
                    // Option to export the selected nest to JSON
                    MenuItemButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        exportNestToKml(context, widget.nest);
                      },
                      child: const Text('KML'),
                    ),
                  ],
                ),
              // const SizedBox(width: 8.0,),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight + 4.0), // Adjust height as needed
              child: Column(
                  children: [
                    Text(
                      widget.nest.speciesName!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    TabBar(
                      controller: _tabController,
                      tabs: [
                        Consumer<NestRevisionProvider>(
                          builder: (context, revisionProvider, child) {
                            final revisionList = revisionProvider.getRevisionForNest(
                                widget.nest.id!);
                            return revisionList.isNotEmpty
                                ? Badge.count(
                              backgroundColor: Colors.deepPurple[100],
                              textColor: Colors.deepPurple[800],
                              alignment: AlignmentDirectional.centerEnd,
                              offset: const Offset(24, -8),
                              count: revisionList.length,
                              child: Tab(text: S.of(context).revision(2)),
                            )
                                : Tab(text: S.of(context).revision(2));
                          },
                        ),
                        Consumer<EggProvider>(
                          builder: (context, eggProvider, child) {
                            final eggList = eggProvider.getEggForNest(
                                widget.nest.id!);
                            return eggList.isNotEmpty
                                ? Badge.count(
                              backgroundColor: Colors.deepPurple[100],
                              textColor: Colors.deepPurple[800],
                              alignment: AlignmentDirectional.centerEnd,
                              offset: const Offset(24, -8),
                              count: eggList.length,
                              child: Tab(text: S.of(context).egg(2)),
                            )
                                : Tab(text: S.of(context).egg(2));
                          },
                        ),
                      ],
                    ),
                  ]
              ),
            )
        ),
        body: TabBarView(
          controller: _tabController,
                children: [
                  NestRevisionsTab(nest: widget.nest),
                  EggsTab(nest: widget.nest),
                ],
              ),
        floatingActionButton: widget.nest.isActive
            ? FabMenuM3E(
          controller: fabController,
          alignment: Alignment.bottomRight,
          direction: FabMenuDirection.up,
          overlay: false,
          primaryFab: FabM3E(
              icon: fabController.isOpen ? const Icon(Icons.close) : const Icon(Icons.add),
              onPressed: fabController.toggle
          ),
          items: [
            FabMenuItem(
              icon: Theme.of(context).brightness == Brightness.light
                  ? const Icon(Icons.beenhere_outlined)
                  : const Icon(Icons.beenhere),
              label: Text(S.of(context).revision(1)),
              onPressed: () {
                _showAddRevisionScreen(context);
              },
            ),
            FabMenuItem(
              icon: Theme.of(context).brightness == Brightness.light
                  ? const Icon(Icons.egg_outlined)
                  : const Icon(Icons.egg),
              label: Text(S.of(context).egg(1)),
              onPressed: () async {
                await _showAddEggScreen(context);
              },
            ),
          ],
        ) : null,
        // floatingActionButton: widget.nest.isActive
        //     ? SpeedDial(
        //   icon: Icons.add_outlined,
        //   activeIcon: Icons.close_outlined,
        //   spaceBetweenChildren: 8.0,
        //   children: [
        //     SpeedDialChild(
        //       child: Theme.of(context).brightness == Brightness.light
        //           ? const Icon(Icons.beenhere_outlined)
        //           : const Icon(Icons.beenhere),
        //       label: S.of(context).revision(1),
        //       onTap: () {
        //         _showAddRevisionScreen(context);
        //       },
        //     ),
        //     SpeedDialChild(
        //       child: Theme.of(context).brightness == Brightness.light
        //           ? const Icon(Icons.egg_outlined)
        //           : const Icon(Icons.egg),
        //       label: S.of(context).egg(1),
        //       onTap: () async {
        //         await _showAddEggScreen(context);
        //       },
        //     ),
        //   ],
        // )
        //     : null,
    );
  }

  void _showNestInfoDialog(BuildContext context, Nest nest) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).nestInfo),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                ListTile(
                  title: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(nest.foundTime!)),
                  subtitle: Text(S.of(context).timeFound),
                ),
                ListTile(
                  title: Text('${nest.localityName}'),
                  subtitle: Text(S.of(context).locality),
                ),
                ListTile(
                  title: Text('${nest.support}'),
                  subtitle: Text(S.of(context).nestSupport),
                ),
                if (nest.heightAboveGround != null) 
                  ListTile(
                    title: Text('${nest.heightAboveGround} m'),
                    subtitle: Text(S.of(context).heightAboveGround),
                  ),
                if (nest.male != '') 
                  ListTile(
                    title: Text('${nest.male}'),
                    subtitle: Text(S.of(context).male),
                  ),
                if (nest.female != '') 
                  ListTile(
                    title: Text('${nest.female}'),
                    subtitle: Text(S.of(context).female),
                  ),
                if (nest.helpers != '')
                  ListTile(
                    title: Text('${nest.helpers}'),
                    subtitle: Text(S.of(context).helpers),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(S.of(context).close),
            ),
          ],
        );
      },
    );
  }

  void _showMoreOptionsBottomSheet(BuildContext context, Nest nest) {
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
                      // Show the inventory ID
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(nest.fieldNumber ?? '', style: TextTheme.of(context).bodyLarge,),
                      ),
                      const Divider(),

                      // GridView.count(
                      //   crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 4 : 5,
                      //   shrinkWrap: true,
                      //   physics: const NeverScrollableScrollPhysics(),
                      //   children: <Widget>[
                      //     buildGridMenuItem(context, Icons.delete_outlined,
                      //         S.of(context).delete, () {
                      //           Navigator.of(context).pop();
                      //           // Ask for user confirmation
                      //           _confirmDelete(context, inventory);
                      //         }, color: Theme.of(context).colorScheme.error),
                      //   ],
                      // ),
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
                                    label: const Text('CSV'),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      final locale = Localizations.localeOf(context);
                                      final csvFile = await exportNestToCsv(context, nest, locale);
                                      // Share the file using share_plus
                                      await SharePlus.instance.share(
                                        ShareParams(
                                          files: [XFile(csvFile, mimeType: 'text/csv')],
                                          text: S.current.nestExported(1),
                                          subject: S.current.nestData(1),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8.0),
                                  ActionChip(
                                    label: const Text('Excel'),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      final locale = Localizations.localeOf(context);
                                      final excelFile = await exportNestToExcel(context, nest, locale);
                                      // Share the file using share_plus
                                      await SharePlus.instance.share(
                                        ShareParams(
                                            files: [XFile(excelFile, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
                                            text: S.current.nestExported(1),
                                            subject: S.current.nestData(1)
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8.0),
                                  ActionChip(
                                    label: const Text('JSON'),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      exportNestToJson(context, nest);
                                    },
                                  ),
                                  const SizedBox(width: 8.0),
                                  ActionChip(
                                    label: const Text('KML'),
                                    onPressed: () async {
                                      Navigator.of(context).pop();
                                      exportNestToKml(context, nest);
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