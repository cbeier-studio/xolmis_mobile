import 'dart:convert';
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

  const InventoryDetailScreen({Key? key, required this.inventory}) : super(key: key);

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
    super.initState();_tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inventory.id),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(context,
                MaterialPageRoute(
                  builder: (context) => AddVegetationDataScreen(inventory: widget.inventory),
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
              final allSpecies = await _loadSpeciesData();
              final selectedSpecies = await showSearch(
                context: context,
                delegate:SpeciesSearchDelegate(allSpecies),
              );

              if (selectedSpecies != null) {
                // Verifica se a espécie já existe na lista
                bool speciesExists = widget.inventory.speciesList.any((species) => species.name == selectedSpecies);

                if (!speciesExists) {
                  // Adicione a espécie ao inventário atual
                  final newSpecies = Species(inventoryId: widget.inventory.id,
                    name: selectedSpecies,
                    isOutOfInventory: widget.inventory.isFinished,
                    pois: [],
                  );
                  await DatabaseHelper().insertSpecies(newSpecies);
                  setState(() {
                    widget.inventory.speciesList.add(newSpecies);
                    _speciesListKey.currentState!.insertItem(
                      widget.inventory.speciesList.length - 1,
                    );
                  });

                  // Adicione a espécie aos outros inventários ativos, se não existir
                  final activeInventories = await DatabaseHelper().loadActiveInventories();
                  for (final inventory in activeInventories) {
                    if (inventory.id != widget.inventory.id &&
                        !inventory.speciesList.any((species) => species.name == selectedSpecies)) {
                      final newSpeciesForOtherInventory = Species(
                        inventoryId: inventory.id,
                        name: selectedSpecies,
                        isOutOfInventory: widget.inventory.isFinished,
                        pois: [],
                      );
                      await DatabaseHelper().insertSpecies(newSpeciesForOtherInventory);
                    }
                  }

                  // Reinicia o temporizador se o inventário for do tipo invCumulativeTime
                  if (widget.inventory.type == InventoryType.invCumulativeTime) {
                    widget.inventory.elapsedTime = 0;
                    widget.inventory.startTimer();
                  }
                } else {
                  // Exibe uma mensagem informando que a espécie já existe
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Espécie já adicionada a este inventário.')),
                  );
                }
              }
            },
          ),
        ),
        Expanded(
          child: AnimatedList(
            key: _speciesListKey,
            initialItemCount: widget.inventory.speciesList.length,
            itemBuilder: (context, index, animation) {
              final species = widget.inventory.speciesList[index];
              return SpeciesListItem(
                species: species,
                animation: animation,
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
    Key? key,
    required this.species,
    required this.animation,
  }) : super(key: key);

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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                if (widget.species.count > 0) {
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
                setState(() {
                  widget.species.count++;
                  DatabaseHelper().updateSpecies(widget.species); // Atualiza no banco de dados
                });
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
                await DatabaseHelper().insertPoi(poi);

                // Atualiza a lista de POIs da espécie (opcional)
                setState(() {
                  widget.species.pois.add(poi);
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
    Key? key,
    required this.vegetation,
    required this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        title: Text(vegetation.sampleTime.toString()),
        // ... outros widgets para exibir informações da vegetação ...
      ),
    );
  }
}

class SpeciesSearchDelegate extends SearchDelegate<String> {
  final List<String> allSpecies;

  SpeciesSearchDelegate(this.allSpecies);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {query = '';
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
  Widget buildResults(BuildContext context) {
    final results = allSpecies
        .where((species) => species.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final species = results[index];
        return ListTile(
          title: Text(species),
          onTap: () {
            close(context, species);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = allSpecies
        .where((species) => species.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final species = suggestions[index];
        return ListTile(
          title: Text(species),
          onTap: () {
            query = species;
            showResults(context);
          },
        );
      },
    );
  }
}

class SpeciesSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onTap;

  const SpeciesSuggestions({Key? key, required this.suggestions, required this.onTap}) : super(key: key);

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