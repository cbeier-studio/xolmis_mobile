import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../../data/models/nest.dart';
import '../../providers/nest_provider.dart';
import '../../providers/nest_revision_provider.dart';
import '../../providers/egg_provider.dart';

import 'nest_revision_tab.dart';
import 'nest_egg_tab.dart';
import 'add_egg_screen.dart';
import 'add_revision_screen.dart';
import '../../utils/export_utils.dart';
import '../../generated/l10n.dart';

class NestDetailScreen extends StatefulWidget {
  final Nest nest;

  const NestDetailScreen({super.key, required this.nest});

  @override
  NestDetailScreenState createState() => NestDetailScreenState();
}

class NestDetailScreenState extends State<NestDetailScreen> {
  bool _isSubmitting = false;

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
        MaterialPageRoute(builder: (context) => AddNestRevisionScreen(nest: widget.nest)),
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                    ),
                  )
                      : const Icon(Icons.flag_outlined),
                ),
              if (widget.nest.isActive == false)
                MenuAnchor(
                  builder: (context, controller, child) {
                    return IconButton(
                      icon: Icon(Icons.file_upload_outlined),
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
                        exportNestToCsv(context, widget.nest);
                      },
                      child: Text('CSV'),
                    ),
                    MenuItemButton(
                      onPressed: () {
                        exportNestToJson(context, widget.nest);
                      },
                      child: Text('JSON'),
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
        body: Expanded(
              child: TabBarView(
                children: [
                  NestRevisionsTab(nest: widget.nest),
                  EggsTab(nest: widget.nest),
                ],
              ),
            ),          
        floatingActionButton: widget.nest.isActive
            ? SpeedDial(
          icon: Icons.add_outlined,
          activeIcon: Icons.close_outlined,
          spaceBetweenChildren: 8.0,
          children: [
            SpeedDialChild(
              child: Theme.of(context).brightness == Brightness.light
                  ? const Icon(Icons.beenhere_outlined)
                  : const Icon(Icons.beenhere),
              label: S.of(context).revision(1),
              onTap: () {
                _showAddRevisionScreen(context);
              },
            ),
            SpeedDialChild(
              child: Theme.of(context).brightness == Brightness.light
                  ? const Icon(Icons.egg_outlined)
                  : const Icon(Icons.egg),
              label: S.of(context).egg(1),
              onTap: () async {
                await _showAddEggScreen(context);
              },
            ),
          ],
        )
            : null,
      ),
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
}