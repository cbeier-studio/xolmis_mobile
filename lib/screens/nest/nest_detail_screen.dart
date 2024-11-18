import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../providers/nest_provider.dart';
import '../../providers/nest_revision_provider.dart';
import '../../providers/egg_provider.dart';

import 'nest_revision_tab.dart';
import 'nest_egg_tab.dart';
import 'add_egg_screen.dart';
import 'add_revision_screen.dart';

class NestDetailScreen extends StatefulWidget {
  final Nest nest;

  const NestDetailScreen({super.key, required this.nest});

  @override
  _NestDetailScreenState createState() => _NestDetailScreenState();
}

class _NestDetailScreenState extends State<NestDetailScreen> {
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
        // Reload the inventory list
        if (newRevision != null) {
          Provider.of<NestRevisionProvider>(context, listen: false).getRevisionForNest(widget.nest.id!);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddNestRevisionScreen(nest: widget.nest)),
      ).then((newRevision) {
        // Reload the inventory list
        if (newRevision != null) {
          Provider.of<NestRevisionProvider>(context, listen: false).getRevisionForNest(widget.nest.id!);
        }
      });
    }
  }

  void _showAddEggScreen(BuildContext context) {
    final eggs = Provider.of<EggProvider>(context, listen: false).getEggForNest(widget.nest.id!);
    if (MediaQuery.sizeOf(context).width > 600) {
      showDialog(
        context: context,
        builder: (context) {
          final nextNumber = eggs.length + 1;
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
        // Reload the inventory list
        if (newEgg != null) {
          Provider.of<EggProvider>(context, listen: false).getEggForNest(widget.nest.id!);
        }
      });
    } else {
      final nextNumber = eggs.length + 1;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddEggScreen(
          nest: widget.nest,
          initialFieldNumber: '${widget.nest.fieldNumber}-${nextNumber.toString().padLeft(2, '0')}',
          initialSpeciesName: widget.nest.speciesName,)
        ),
      ).then((newEgg) {
        // Reload the inventory list
        if (newEgg != null) {
          Provider.of<EggProvider>(context, listen: false).getEggForNest(widget.nest.id!);
        }
      });
    }
  }

  void _showFloatingMenu(BuildContext context) {
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
                    leading: Theme.of(context).brightness == Brightness.light
                        ? const Icon(Icons.beenhere_outlined)
                        : const Icon(Icons.beenhere),
                    title: const Text('Adicionar revisão de ninho'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddRevisionScreen(context);
                    },
                  ),
                  ListTile(
                    leading: Theme.of(context).brightness == Brightness.light
                        ? const Icon(Icons.egg_outlined)
                        : const Icon(Icons.egg),
                    title: const Text('Adicionar ovo'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddEggScreen(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
            title: Text('${widget.nest.fieldNumber}'),
            actions: [
              if (widget.nest.isActive)
                IconButton.filled(
                  onPressed: () async {
                    NestFateType? selectedNestFate;

                    // Show dialog with the DropdownButton
                    await showDialog<NestFateType>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar desativação'),
                        content: DropdownButtonFormField<NestFateType>(
                          value: selectedNestFate,
                          decoration: const InputDecoration(
                            labelText: 'Destino do ninho *',
                            helperText: '* campo obrigatório',
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
                            child: const Text('Cancelar'),
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

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ninho desativado com sucesso!'),
                                    ),
                                  );

                                  // Close screen of nest details
                                  Navigator.pop(context, selectedNestFate);
                                  Navigator.pop(context);
                                } catch (error) {
                                  // Handle errors
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erro ao desativar o ninho: $error'),
                                    ),
                                  );
                                } finally {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                }
                              }
                            },
                            child: const Text('Salvar'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: IconButton.styleFrom(
                    // backgroundColor: Colors.green,
                    foregroundColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.white
                        : Colors.deepPurple,
                  ),
                  // color: Colors.deepPurple,
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
              const SizedBox(width: 8.0,),
            ],
            bottom: PreferredSize( // Wrap TabBar and LinearProgressIndicator in PreferredSize
              preferredSize: const Size.fromHeight(kToolbarHeight + 4.0), // Adjust height as needed
              child: Column(
                  children: [
                    Text(
                      widget.nest.speciesName!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Text('${widget.nest.support}'),
                    //     Text(': ${widget.nest.heightAboveGround} m'),
                    //   ],
                    // ),
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
                              child: const Tab(text: 'Revisões'),
                            )
                                : const Tab(text: 'Revisões');
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
                              child: const Tab(text: 'Ovos'),
                            )
                                : const Tab(text: 'Ovos');
                          },
                        ),
                      ],
                    ),
                  ]
              ),
            )
        ),
        body: Column(
          children: [
            ExpansionTile(
              // backgroundColor: Colors.deepPurple[50],
              // collapsedBackgroundColor: Colors.deepPurple[50],
              leading: const Icon(Icons.info_outlined),
              title: const Text('Informações do ninho'),
              children: [
                ListTile(
                  title: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.nest.foundTime!)),
                  subtitle: Text('Data e hora de encontro'),
                ),
                ListTile(
                  title: Text('${widget.nest.localityName}'),
                  subtitle: Text('Localidade'),
                ),
                ListTile(
                  title: Text('${widget.nest.support}'),
                  subtitle: Text('Suporte do ninho'),
                ),
                widget.nest.heightAboveGround != '' ? ListTile(
                  title: Text('${widget.nest.heightAboveGround} m'),
                  subtitle: Text('Altura acima do solo'),
                ) : SizedBox.shrink(),
                widget.nest.male != '' ? ListTile(
                  title: Text('${widget.nest.male}'),
                  subtitle: Text('Macho'),
                ) : SizedBox.shrink(),
                widget.nest.female != '' ? ListTile(
                  title: Text('${widget.nest.female}'),
                  subtitle: Text('Fêmea'),
                ) : SizedBox.shrink(),
                widget.nest.helpers != '' ? ListTile(
                  title: Text('${widget.nest.helpers}'),
                  subtitle: Text('Ajudantes de ninho'),
                ) : SizedBox.shrink(),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  NestRevisionsTab(nest: widget.nest),
                  EggsTab(nest: widget.nest),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: widget.nest.isActive
            ? FloatingActionButton(
          onPressed: () {
            _showFloatingMenu(context);
          },
          child: const Icon(Icons.add_outlined),
        )
            : null,
      ),
    );
  }
}