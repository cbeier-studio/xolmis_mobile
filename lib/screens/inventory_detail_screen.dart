import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/inventory.dart';
import '../data/database_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'add_vegetation_screen.dart';
import 'species_detail_screen.dart';

class InventoryDetailScreen extends StatefulWidget {
  final Inventory inventory;
  final void Function(Inventory) onInventoryUpdated;

  const InventoryDetailScreen({
    super.key,
    required this.inventory,
    required this.onInventoryUpdated,
  });

  @override
  InventoryDetailScreenState createState() => InventoryDetailScreenState();
}

class InventoryDetailScreenState extends State<InventoryDetailScreen>
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
    // Check if species already exists in current inventory
    bool speciesExistsInCurrentInventory = widget.inventory.speciesList.any((species) => species.name == speciesName);

    if (!speciesExistsInCurrentInventory) {
      // Add the species to the current inventory
      final newSpecies = Species(
        inventoryId: widget.inventory.id,
        name: speciesName,
        isOutOfInventory: widget.inventory.isFinished,
        pois: [],
      );
      await DatabaseHelper().insertSpecies(newSpecies.inventoryId, newSpecies).then((id) {
        if (id != 0) {
          // Species inserted successfully
          if (kDebugMode) {
            print('Species inserted with ID: $id');
          }
        } else {
          // Handle insert error
          if (kDebugMode) {
            print('Error inserting species');
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
        // Check if the inventory is different from the current and if species exists in it
        if (inventory.id != widget.inventory.id &&
            !inventory.speciesList.any((species) => species.name == speciesName)) {
          final newSpeciesForOtherInventory = Species(inventoryId: inventory.id,
            name: speciesName,
            isOutOfInventory: inventory.isFinished,
            pois: [],
          );
          await DatabaseHelper().insertSpecies(newSpeciesForOtherInventory.inventoryId, newSpeciesForOtherInventory).then((id) {
            if (id != 0) {
              // Species inserted successfully
              if (kDebugMode) {
                print('Species inserted with ID: $id');
              }
            } else {
              // Handle insert error
              if (kDebugMode) {
                print('Error inserting species');
              }
            }
          });

          // Update the species list of the active inventory
          inventory.speciesList.add(newSpeciesForOtherInventory);
          // Provider.of<InventoryProvider>(context, listen: false).updateInventory(inventory);
          await DatabaseHelper().updateInventory(inventory); // Update the inventory in the database
        }
      }

      // Restart the timer if the inventory is of type invCumulativeTime
      if (widget.inventory.type == InventoryType.invCumulativeTime) {
        widget.inventory.elapsedTime = 0;
        widget.inventory.isPaused = false;
        widget.inventory.isFinished = false;
        await DatabaseHelper().updateInventoryElapsedTime(widget.inventory.id, widget.inventory.elapsedTime);
        widget.inventory.startTimer();
      }

      widget.onInventoryUpdated(widget.inventory);
    } else {
      // Show message informing that species already exists
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Espécie já adicionada a este inventário.')),
      );
    }
  }

  void _updateSpeciesList() async {
    final updatedSpeciesList = await DatabaseHelper().getSpeciesByInventory(widget.inventory.id);
    setState(() {
      widget.inventory.speciesList = updatedSpeciesList;
    });
  }

  void _sortSpeciesList() {
    widget.inventory.speciesList.sort((a, b) => a.name.compareTo(b.name));
    setState(() {});
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
    setState(() {
      widget.inventory.vegetationList.add(vegetation);
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
          tabs: [
            widget.inventory.speciesList.isNotEmpty
                ? Badge.count(
              alignment: AlignmentDirectional.centerEnd,
              offset: Offset(24, -8),
              count: widget.inventory.speciesList.length,
              child: const Tab(text: 'Espécies'),
            ): const Tab(text: 'Espécies'),
            widget.inventory.vegetationList.isNotEmpty
                ? Badge.count(
              alignment: AlignmentDirectional.centerEnd,
              offset: Offset(24, -8),
              count: widget.inventory.vegetationList.length,
              child: const Tab(text: 'Vegetação'),
            ): const Tab(text: 'Vegetação'),
          ],
        ),
        flexibleSpace: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: widget.inventory.duration > 0 && !widget.inventory.isFinished
              ? ValueListenableBuilder<double>(
            valueListenable: widget.inventory.elapsedTimeNotifier,
            builder: (context, elapsedTime, child) {
              return LinearProgressIndicator(
                value: elapsedTime / (widget.inventory.duration * 60),
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
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
          // Finishing the inventory
          await widget.inventory.stopTimer();
          widget.onInventoryUpdated(widget.inventory);
          Navigator.pop(context, true);
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.stop, color: Colors.white),
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
            readOnly: true,
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
                key: Key(species.id.toString()),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
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
                  // Remove the species from list and AnimatedList
                  final removedSpecies = widget.inventory.speciesList.removeAt(index);
                  _speciesListKey.currentState!.removeItem(
                    index,
                        (context, animation) => SpeciesListItem(species: removedSpecies, animation: animation),
                  );
                  DatabaseHelper().deleteSpeciesFromInventory(widget.inventory.id, removedSpecies.name);
                  // Update the inventory in the database
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
  SpeciesListItemState createState() => SpeciesListItemState();
}

class SpeciesListItemState extends State<SpeciesListItem> {
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
                if (mounted && widget.species.count > 0) {
                  widget.species.count--;
                  DatabaseHelper().updateSpecies(widget.species).then((_) {
                    setState(() {});
                  });
                }
              },
            ),
            Text(widget.species.count.toString()),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (mounted) {
                  widget.species.count++;
                  DatabaseHelper().updateSpecies(widget.species).then((_) {
                    setState(() {});
                  });
                }
              },
            ),
            IconButton(
              icon: widget.species.pois.isNotEmpty
              ? Badge.count(
              count: widget.species.pois.length,
              child: const Icon(Icons.add_location),
            ) : const Icon(Icons.add_location),
              onPressed: () async {
                // Get the current location
                Position position = await Geolocator.getCurrentPosition(
                  locationSettings: LocationSettings(
                    accuracy: LocationAccuracy.high,
                  ),
                );

                // Create a new POI
                final poi = Poi(
                  speciesId: widget.species.id!,
                  longitude: position.longitude,
                  latitude: position.latitude,
                );

                // Insert the POI in the database
                await DatabaseHelper().insertPoi(poi).then((_) {
                  // if (mounted) {
                    setState(() {
                      widget.species.pois.add(poi);
                    });
                  // }
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
        title: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(vegetation.sampleTime)),
        subtitle: Text('${vegetation.latitude}; ${vegetation.longitude}'),
        // ... other widgets to show vegetation info ...
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
        .where((species) => speciesMatchesQuery(species, query))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final species = suggestions[index];
        return ListTile(
          title: Text(species),
          onTap: () {
            addSpeciesToInventory(species);
            close(context, species); // Close the suggestions list and return the selected species
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

        // Check if the parts of query match the parts of the species name
        return firstWord.toLowerCase().startsWith(firstPart.toLowerCase()) &&
            secondWord.toLowerCase().startsWith(secondPart.toLowerCase());
      }
    }
    // If que query do not have 4 or 6 characters, or if the species name do not have two words,
    // use the previous search logic (e.g.: contains)
    return speciesName.toLowerCase().contains(query.toLowerCase());
  }

  @override
  Widget buildResults(BuildContext context) {
    // Add the first item from suggestions list
    if (query.isNotEmpty) {
      final suggestions = allSpecies.where((species) => speciesMatchesQuery(species, query)).toList();
      if (suggestions.isNotEmpty) {
        final firstSuggestion = suggestions[0];
        addSpeciesToInventory(firstSuggestion);
        // updateSpeciesList();
        close(context, firstSuggestion);
      }
    }
    return Container(); // Return a empty widget, because buildResults is not used in this case
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
            onTap(species);
          },
        );
      },
    );
  }
}