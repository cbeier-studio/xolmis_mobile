import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:side_sheet/side_sheet.dart';

import '../../data/models/nest.dart';
import '../../providers/nest_provider.dart';

import 'add_nest_screen.dart';
import 'nest_detail_screen.dart';

import '../settings_screen.dart';
import '../utils.dart';

class NestsScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const NestsScreen({super.key, required this.scaffoldKey,});

  @override
  _NestsScreenState createState() => _NestsScreenState();
}

class _NestsScreenState extends State<NestsScreen> {
  late NestProvider nestProvider;
  final _searchController = TextEditingController();
  bool _showActive = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    nestProvider = context.read<NestProvider>();
    nestProvider.fetchNests();
  }

  List<Nest> _filterNests(List<Nest> nests) {
    if (_searchQuery.isEmpty) {
      return nests;
    }
    return nests.where((nest) =>
        nest.fieldNumber!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        nest.speciesName!.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
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
        // Reload the inventory list
        if (newNest != null) {
          nestProvider.fetchNests();
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddNestScreen()),
      ).then((newNest) {
        // Reload the inventory list
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
        title: const Text('Ninhos'),
        leading: MediaQuery.sizeOf(context).width < 600 ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_outlined),
            onPressed: () {
              widget.scaffoldKey.currentState?.openDrawer();
            },
          ),
        ) : SizedBox.shrink(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Procurar ninhos...',
              backgroundColor: WidgetStateProperty.all<Color>(Colors.deepPurple[50]!),
              leading: const Icon(Icons.search_outlined),
              trailing: [
                IconButton(
                  icon: const Icon(Icons.clear_outlined),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                ),
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
                    segments: const [
                      ButtonSegment(value: true, label: Text('Ativos')),
                      ButtonSegment(value: false, label: Text('Inativos')),
                    ],
                    selected: {_showActive},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _showActive = newSelection.first;
                      });
                      nestProvider.fetchNests();
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
                  return const Center(
                    child: Text('Nenhum ninho encontrado.'),
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
                          return Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 840),
                              child: SingleChildScrollView(
                                child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 3.0,
                                  ),
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
                                      child: Card(
                                  child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Row(
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
                                      ),
                                      ),
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
                                        title: const Text('Confirmar Exclusão'),
                                        content: const Text(
                                            'Tem certeza que deseja excluir este ninho?'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: const Text('Cancelar'),
                                            onPressed: () {
                                              Navigator.of(context).pop(false);
                                            },
                                          ),
                                          TextButton(child: const Text('Excluir'),
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
                                      Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(nest.foundTime!)),
                                    ],
                                  ),
                                  leading: nest.nestFate == NestFateType.fatSuccess
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : nest.nestFate == NestFateType.fatLost
                                      ? const Icon(Icons.cancel, color: Colors.red)
                                      : const Icon(Icons.help, color: Colors.grey),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children:[
                                      !_showActive ? IconButton(
                                        icon: const Icon(Icons.file_download_outlined),
                                        tooltip: 'Exportar ninho',
                                        onPressed: () {
                                          exportNestToJson(context, nest);
                                        },
                                      ) : const SizedBox.shrink(),
                                    ],
                                  ),
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
        tooltip: 'Novo ninho',
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
                  !_showActive ? ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('Exportar ninho'),
                    onTap: () {
                      exportNestToJson(context, nest);
                    },
                  ) : const SizedBox.shrink(),
                  !_showActive ? ListTile(
                    leading: const Icon(Icons.file_download_outlined),
                    title: const Text('Exportar todos os ninhos'),
                    onTap: () {
                      exportAllInactiveNestsToJson(context);
                    },
                  ) : const SizedBox.shrink(),
                  ListTile(
                    leading: const Icon(Icons.delete_outlined, color: Colors.red,),
                    title: const Text('Apagar ninho', style: TextStyle(color: Colors.red),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar exclusão'),
                            content: const Text('Tem certeza que deseja excluir este ninho?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                  Navigator.of(context).pop();
                                  // Call the function to delete species
                                  Provider.of<NestProvider>(context, listen: false)
                                      .removeNest(nest);
                                },
                                child: const Text('Excluir'),
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