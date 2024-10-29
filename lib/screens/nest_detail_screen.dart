import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/nest.dart';
import '../providers/nest_provider.dart';
import '../providers/nest_revision_provider.dart';
import '../providers/egg_provider.dart';

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
  final GlobalKey<AnimatedListState> _revisionListKey = GlobalKey<
      AnimatedListState>();
  final GlobalKey<AnimatedListState> _eggListKey = GlobalKey<
      AnimatedListState>();
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Access the providers
    final revisionProvider = Provider.of<NestRevisionProvider>(
        context, listen: false);
    revisionProvider.revisionListKey = _revisionListKey;
    final eggProvider = Provider.of<EggProvider>(
        context, listen: false);
    eggProvider.eggListKey = _eggListKey;

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
    final nextNumber = widget.nest.eggsList!.length + 1;
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
        // Reload the inventory list
        if (newEgg != null) {
          Provider.of<EggProvider>(context, listen: false).getEggForNest(widget.nest.id!);
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
        // Reload the inventory list
        if (newEgg != null) {
          Provider.of<EggProvider>(context, listen: false).getEggForNest(widget.nest.id!);
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
            widget.nest.isActive ? IconButton(
              icon: const Icon(
                Icons.reviews_outlined,
                semanticLabel: 'Adicionar revisão de ninho',
              ),
              tooltip: 'Adicionar revisão de ninho',
              onPressed: () {
                _showAddRevisionScreen(context);
              },
            ) : const SizedBox.shrink(),
            widget.nest.isActive ? IconButton(
              icon: const Icon(
                Icons.egg_outlined,
                semanticLabel: 'Adicionar ovo',
              ),
              tooltip: 'Adicionar ovo',
              onPressed: () {
                _showAddEggScreen(context);
              },
            ) : const SizedBox.shrink(),
          ],
          bottom: TabBar(
            tabs: [
              Consumer<NestRevisionProvider>(
                builder: (context, revisionProvider, child) {
                  final revisionList = revisionProvider.getRevisionForNest(
                      widget.nest.id!);
                  return revisionList.isNotEmpty
                      ? Badge.count(
                    backgroundColor: Colors.deepPurple,
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
                    backgroundColor: Colors.deepPurple,
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
        ),
        body: TabBarView(
          children: [
            NestRevisionsTab(nest: widget.nest, revisionListKey: _revisionListKey),
            EggsTab(nest: widget.nest, eggListKey: _eggListKey),
          ],
        ),
        floatingActionButton: widget.nest.isActive
            ? FloatingActionButton(
          tooltip: 'Desativar ninho',
          onPressed: () async {
            NestFateType? selectedNestFate;

            // Show dialog with the DropdownButton
            await showDialog<NestFateType>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirmar Desativação'),
                content: DropdownButtonFormField<NestFateType>(
                  value: selectedNestFate,
                  decoration: const InputDecoration(
                    labelText: 'Destino do ninho',
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
          backgroundColor: Colors.green,
          child: _isSubmitting
              ? const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          )
              : const Icon(Icons.flag_outlined, color: Colors.white),
        )
            : null,
      ),
    );
  }
}