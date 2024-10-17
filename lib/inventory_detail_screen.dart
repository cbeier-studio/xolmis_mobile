import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'inventory.dart';
import 'database_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:animated_list/animated_list.dart';
import 'add_vegetation_screen.dart';
import 'species_detail_screen.dart';

class InventoryDetailScreen extends StatefulWidget {
  final Inventory inventory;
  final VoidCallback onInventoryUpdated;

  const InventoryDetailScreen({
    super.key,
    required this.inventory,
    required this.onInventoryUpdated,
  });

  @override
  _InventoryDetailScreenState createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<AnimatedListState> _speciesListKey = GlobalKey<AnimatedListState>();
  final GlobalKey<AnimatedListState> _vegetationListKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _sortSpeciesList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addSpeciesToInventory(String speciesName) async {
    // Verifica se a espécie já existe na lista do inventário atual
    bool speciesExistsInCurrentInventory = widget.inventory.speciesList.any((species) => species.name == speciesName);

    if (!speciesExistsInCurrentInventory) {
      // Adicione a espécie ao inventário atual
      final newSpecies = Species(
        inventoryId: widget.inventory.id,
        name: speciesName,
        isOutOfInventory: widget.inventory.isFinished,
        pois: [],
      );
      await DatabaseHelper().insertSpecies(newSpecies.inventoryId, newSpecies).then((id) {
        if (id != 0) {
          // Espécie inserida com sucesso
          if (kDebugMode) {
            print('Espécie inserida com ID: $id');
          }
        } else {
          // Lidar com erro de inserção
          if (kDebugMode) {
            print('Erro ao inserir espécie');
          }
        }
      });
      setState(() {
        widget.inventory.speciesList.add(newSpecies);
        _speciesListKey.currentState!.insertItem(
          widget.inventory.speciesList.length - 1,
          duration: const Duration(milliseconds: 300),
        );
      });

      final activeInventories = await DatabaseHelper().loadActiveInventories();
      for (final inventory in activeInventories) {
        // Verifica se o inventário é diferente do atual e se a espécie não existe nele
        if (inventory.id != widget.inventory.id &&
            !inventory.speciesList.any((species) => species.name == speciesName)) {
          final newSpeciesForOtherInventory = Species(inventoryId: inventory.id,
            name: speciesName,
            isOutOfInventory: inventory.isFinished, // Define isOutOfInventory com base no inventário atual
            pois: [],
          );
          await DatabaseHelper().insertSpecies(newSpeciesForOtherInventory.inventoryId, newSpeciesForOtherInventory).then((id) {
            if (id != 0) {
              // Espécie inserida com sucesso
              if (kDebugMode) {
                print('Espécie inserida com ID: $id');
              }
            } else {
              // Lidar com erro de inserção
              if (kDebugMode) {
                print('Erro ao inserir espécie');
              }
            }
          });

          // Atualiza a lista de espécies do inventário ativo
          inventory.speciesList.add(newSpeciesForOtherInventory);
          await DatabaseHelper().updateInventory(inventory); // Atualiza o inventário no banco de dados
        }
      }

      // Reinicia o temporizador se o inventário for do tipo invCumulativeTime
      if (widget.inventory.type == InventoryType.invCumulativeTime) {
        widget.inventory.elapsedTime = 0;
        widget.inventory.startTimer();
      }

      widget.onInventoryUpdated();
    } else {
      // Exibe uma mensagem informando que a espécie já existe
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Espécie já adicionada a este inventário.')),
      );
    }
  }

  void _updateSpeciesList() {
    setState(() {}); // Atualiza o estado do InventoryDetailScreen
  }

  void _sortSpeciesList() {
    widget.inventory.speciesList.sort((a, b) => a.name!.compareTo(b.name!));
    setState(() {}); // Atualiza a interface do usuário
  }

  void _showSpeciesSearch() async {
    final allSpecies = await _loadSpeciesData();
    final selectedSpecies = await showSearch(
      context: context,
      delegate: SpeciesSearchDelegate(allSpecies, _addSpeciesToInventory, _updateSpeciesList),
    );

    if (selectedSpecies != null) {
      _updateSpeciesList();
    }
  }

  void onVegetationAdded(Vegetation vegetation) {
    setState(() {widget.inventory.vegetationList.add(vegetation);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inventory.id),
        actions: [
          IconButton(
            icon: const Icon(Icons.nature_people),
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(
                  builder: (context) => AddVegetationDataScreen(
                      inventory: widget.inventory,
                      onVegetationAdded: onVegetationAdded,
                  ),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Espécies'),
            Tab(text: 'Vegetação'),
          ],
        ),
        flexibleSpace: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: widget.inventory.duration > 0 && !widget.inventory.isFinished
              ? ValueListenableBuilder<double>(
            valueListenable: widget.inventory.elapsedTimeNotifier,
            builder: (context, elapsedTime, child) {
              return LinearProgressIndicator(
                value: elapsedTime / widget.inventory.duration,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              );
            },
          )
              : const SizedBox.shrink(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSpeciesList(),
          _buildVegetationList(),
        ],
      ),
      floatingActionButton: !widget.inventory.isFinished ? FloatingActionButton(
        onPressed: () async {
          // Lógica para encerrar oinventário
          await widget.inventory.stopTimer(); // Para o timer
          widget.onInventoryUpdated();
          Navigator.pop(context); // Navega de volta para a tela anterior
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.stop), // Ícone do botão
      ) : null,
    );
  }

  Widget _buildSpeciesList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar espécie...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            readOnly: true, // Impede a edição direta do campo
            onTap: () async {
              _showSpeciesSearch();
            },
          ),
        ),
        Expanded(
          child: AnimatedList(
            key: _speciesListKey,
            initialItemCount: widget.inventory.speciesList.length,
            itemBuilder: (context, index, animation) {
              final species = widget.inventory.speciesList[index];
              return Dismissible(
                key: Key(species.id.toString()), // Chave única para o item da lista
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  // Exibe um diálogo de confirmação
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirmar exclusão'),
                        content: const Text('Tem certeza que deseja excluir esta espécie?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Excluir'),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  // Remove a espécie da lista e do AnimatedList
                  final removedSpecies = widget.inventory.speciesList.removeAt(index);
                  _speciesListKey.currentState!.removeItem(
                    index,
                        (context, animation) => SpeciesListItem(species: removedSpecies, animation: animation),
                  );
                  DatabaseHelper().deleteSpeciesFromInventory(widget.inventory.id, removedSpecies.name);
                  // Atualiza o inventário no banco de dados
                  DatabaseHelper().updateInventory(widget.inventory);
                },
                child: SpeciesListItem(
                  species: species,
                  animation: animation,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<List<String>> _loadSpeciesData() async {
    final jsonString = await rootBundle.loadString('assets/species_data.json');
    final jsonData = json.decode(jsonString) as List<dynamic>;
    return jsonData.map((species) => species['scientificName'].toString())
        .toList();
  }

  Widget _buildVegetationList() {
    return AnimatedList(
      key: _vegetationListKey,
      initialItemCount: widget.inventory.vegetationList.length,
      itemBuilder: (context, index, animation) {
        final vegetation = widget.inventory.vegetationList[index];
        return VegetationListItem(
          vegetation: vegetation,
          animation: animation,
        );
      },
    );
  }
}

class SpeciesListItem extends StatefulWidget {
  final Species species;
  final Animation<double> animation;

  const SpeciesListItem({
    super.key,
    required this.species,
    required this.animation,
  });

  @override
  _SpeciesListItemState createState() => _SpeciesListItemState();
}

class _SpeciesListItemState extends State<SpeciesListItem> {
  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: widget.animation,
      child: ListTile(
        title: Text(widget.species.name),
        tileColor: widget.species.isOutOfInventory ? Colors.grey[200] : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    widget.species.count--;
                    DatabaseHelper().updateSpecies(widget.species); // Atualiza no banco de dados
                  });
                }
              },
            ),
            Text(widget.species.count.toString()),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    widget.species.count++;
                    DatabaseHelper().updateSpecies(widget.species); // Atualiza no banco de dados
                  });
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add_location),
              onPressed: () async {
                // Obtém a localização atual
                Position position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                );

                // Cria um novo POI
                final poi = Poi(
                  speciesId: widget.species.id!,
                  longitude: position.longitude,
                  latitude: position.latitude,
                );

                // Insere o POI no banco de dados
                await DatabaseHelper().insertPoi(poi).then((_) {
                  if (mounted) {
                    setState(() {
                      widget.species.pois.add(poi);
                    });
                  }
                });
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpeciesDetailScreen(species: widget.species),
            ),
          );
        },
      ),
    );
  }
}

class VegetationListItem extends StatelessWidget {
  final Vegetation vegetation;
  final Animation<double> animation;

  const VegetationListItem({
    super.key,
    required this.vegetation,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        title: Text(vegetation.sampleTime.toIso8601String()),
        subtitle: Text('${vegetation.latitude}; ${vegetation.longitude}'),
        // ... outros widgets para exibir informações da vegetação ...
      ),
    );
  }
}

class SpeciesSearchDelegate extends SearchDelegate<String> {
  final List<String> allSpecies;
  final Function(String) addSpeciesToInventory;
  final VoidCallback updateSpeciesList;

  SpeciesSearchDelegate(this.allSpecies, this.addSpeciesToInventory, this.updateSpeciesList);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = allSpecies
        .where((species) => speciesMatchesQuery(species, query)) // Chama a função speciesMatchesQuery
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final species = suggestions[index];
        return ListTile(
          title: Text(species),
          onTap: () {
            addSpeciesToInventory(species);
            close(context, species); // Fecha a lista de sugestões e retorna a espécie selecionada
          },
        );
      },
    );
  }

  bool speciesMatchesQuery(String speciesName, String query) {
    if (query.length == 4 || query.length == 6) {
      final words = speciesName.split(' ');
      if (words.length >= 2) {
        final firstWord = words[0];
        final secondWord = words[1];
        final firstPartLength = query.length == 4 ? 2 : 3;
        final firstPart = query.substring(0, firstPartLength);
        final secondPart = query.substring(firstPartLength);

        // Verifica se as partes da consulta correspondem às partes do nome da espécie
        return firstWord.toLowerCase().startsWith(firstPart.toLowerCase()) &&
            secondWord.toLowerCase().startsWith(secondPart.toLowerCase());
      }
    }
    // Se a consulta não tiver 4 ou 6 letras, ou se o nome da espécie não tiver duas palavras,
    // utilize a lógica de busca anterior (ex: contains)
    return speciesName.toLowerCase().contains(query.toLowerCase());
  }

  @override
  Widget buildResults(BuildContext context) {
    // Adicionao primeiro item da lista de sugestões à lista
    if (query.isNotEmpty) { // Verifica se a consulta não está vazia
      final suggestions = allSpecies.where((species) => speciesMatchesQuery(species, query)).toList();
      if (suggestions.isNotEmpty) { // Verifica se a lista de sugestões não está vazia
        final firstSuggestion = suggestions[0]; // Obtém o primeiro item da lista de sugestões
        addSpeciesToInventory(firstSuggestion); // Adiciona o primeiro item à lista
        // updateSpeciesList();
        close(context, firstSuggestion); // Fecha a busca e retorna o primeiro item
      }
    }
    return Container(); // Retorna um widget vazio, pois buildResults não é usado neste caso
  }
}

class SpeciesSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onTap;

  const SpeciesSuggestions({
    super.key,
    required this.suggestions,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final species = suggestions[index];
        return ListTile(
          title: Text(species),
          onTap: () {
            onTap(species); // Chame o callback onTap com a espécie selecionada
          },
        );
      },
    );
  }
}