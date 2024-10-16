import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animated_list/animated_list.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'database_helper.dart';
import 'inventory.dart';
import 'inventory_provider.dart';
import 'species_detail_screen.dart';
import 'species_list_item.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' as rootBundle;

class InventoryDetailScreen extends StatefulWidget {
  final Inventory inventory;
  final List<Inventory> allInventories;

  const InventoryDetailScreen({super.key, required this.inventory, required this.allInventories});

  @override
  _InventoryDetailScreenState createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _timer;
  int _timeLeft = 0;
  List<String> _allSpecies = [];
  List<String> _filteredSpecies = [];
  List<Species> _inventorySpecies = [];
  final SearchController _searchController = SearchController();

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final GlobalKey<AnimatedListState> _vegetationListKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _loadSpeciesData();
    _inventorySpecies = widget.inventory.speciesList;
    if (widget.inventory.type == InventoryType.invCumulativeTime) {
      _startTimer();
    }
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inventory.id),
        actions: [
          IconButton(icon: const Icon(Icons.nature_people),
            onPressed: () {
              _showVegetationDialog(context);
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
        flexibleSpace: Consumer<InventoryProvider>(
          builder: (context, inventoryProvider, child) {
            final inventory = inventoryProvider.getInventoryById(widget.inventory.id);
            return inventory.duration > 0
                ? PreferredSize(
              preferredSize: const Size.fromHeight(4.0), // Altura da LinearProgressIndicator
              child: Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(
                  value: inventory.elapsedTime / inventory.duration, // Calcular o valor do progresso
                ),
              ),
            )
                : const SizedBox.shrink();
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Species tab
          Consumer<InventoryProvider>(
            builder: (context, inventoryProvider, child) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SearchAnchor(
                      isFullScreen: false, // Prevents the SearchView to go full screen
                      suggestionsBuilder: (BuildContext context, SearchController controller) {
                        _filterSpecies(controller.text);
                        return List<ListTile>.generate(_filteredSpecies.length, (int index) {
                          final String item = _filteredSpecies[index];
                          return ListTile(
                            title: Text(item),
                            onTap: () {
                              setState(() {
                                _addSpecies(item);
                              });
                              // Close the SearchView and clear the SearchBar
                              controller.closeView(item);
                              controller.clear();
                            },
                          );
                        });
                      },
                      builder: (BuildContext context, SearchController controller) {
                        return SearchBar(
                          controller: _searchController,
                          padding: const WidgetStatePropertyAll<EdgeInsets>(
                              EdgeInsets.symmetric(horizontal: 16.0)),
                          onTap: () {
                            controller.openView();
                          },
                          onChanged: (_) {
                            _filterSpecies(_searchController.text);
                          },
                          onSubmitted: (String value) {
                            _addSpecies(value);
                            // Close the SearchView and clear the SearchBar pressing Enter
                            controller.closeView(value);
                            controller.clear();
                          },
                          leading: const Icon(Icons.search),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: AnimatedList(
                      key: _listKey,
                      initialItemCount: _inventorySpecies.length,
                      itemBuilder: (context, index, animation) {
                        final species = _inventorySpecies[index];
                        return SlideTransition(
                          position: animation.drive(Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: const Offset(0, 0),
                          )),
                          child: Dismissible(
                            key: Key(species.name), // A unique key for each item
                            direction: DismissDirection.endToStart, // Drag from right to left
                            confirmDismiss: (DismissDirection direction) async {
                              // Show the confirmation dialog
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Confirmar Exclusão"),
                                    content: Text("Tem certeza que deseja remover a espécie '${species.name}'?"),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text("Cancelar"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text("Remover"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) {
                              // Remove the species from the list with animation
                              _listKey.currentState!.removeItem(
                                index,
                                    (context, animation) => SlideTransition(
                                  position: animation.drive(Tween<Offset>(
                                    begin: const Offset(1, 0),
                                    end: const Offset(0, 0),
                                  )),
                                  child: const SizedBox.shrink(),
                                ),
                              );
                              // Remove the species from the database and update the state
                              DatabaseHelper().deleteSpecies(species.id);
                              setState(() {
                                widget.inventory.speciesList.removeAt(index);
                              });
                            },
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: ListTile(
                              title: Text(
                                species.name,
                                style: TextStyle(
                                  color: species.isOutOfInventory ? Colors.blueGrey : null,
                                ),
                              ),
                              subtitle: Text('${species.count} indivíduos'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () => _updateSpeciesCount(species, false),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () => _updateSpeciesCount(species, true),
                                  ),
                                  IconButton(icon: const Icon(Icons.add_location),
                                    onPressed: () => _addPoiForSpecies(species),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SpeciesDetailScreen(species: species, inventoryId: widget.inventory.id),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          // Vegetation tab
          Consumer<InventoryProvider>(
            builder: (context, inventoryProvider,child) {
              final vegetationList = inventoryProvider.getVegetationByInventoryId(widget.inventory.id);
              return AnimatedList(
                key: _vegetationListKey,
                initialItemCount: vegetationList.length,
                itemBuilder: (context, index, animation) {
                  final vegetation = vegetationList[index];
                  return SlideTransition( // Entry animation
                    position: animation.drive(Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: const Offset(0, 0),
                    )),
                    child: Dismissible(
                      key: Key(vegetation.id.toString()), // Unique key for each item
                      direction: DismissDirection.endToStart, // Drag from right to left
                      onDismissed: (direction) {
                        // Remove the Vegetation from list with animation
                        _vegetationListKey.currentState!.removeItem(
                          index,
                              (context, animation) => SlideTransition( // Exit animation
                            position: animation.drive(Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: const Offset(0, 0),
                            )),
                            child: const SizedBox.shrink(), // Empty widget during animation
                          ),
                        );
                        // Remove the Vegetation from database and update state
                        inventoryProvider.removeVegetation(vegetation);
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20.0),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        title: Text('Amostra ${index + 1}'),
                        subtitle: Text('${vegetation.sampleTime}'),
                        // ... (other fields of Vegetation) ...
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: !widget.inventory.isFinished // Condition to show the button
       ? FloatingActionButton.extended(
        onPressed: _finishInventory,
        label: const Text('Encerrar'),
        icon: const Icon(Icons.check),
        backgroundColor: Colors.green,
      )
      : null,
    );
  }

  Future<void> _loadSpeciesData() async {
    try {
      final jsonString = await rootBundle.rootBundle.loadString(
          'assets/species_data.json');
      final List<dynamic> jsonResponse = json.decode(jsonString);
      setState(() {
        _allSpecies =
            jsonResponse.map((species) => species['scientificName'].toString())
                .toList();
        _filteredSpecies = _allSpecies;
      });
    } catch (e) {
      // Error handling: Show a SnackBar if an error occurs when loading the JSON file
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar lista de espécies: $e')),
      );
    }
  }

  void _startTimer() {
    setState(() {
      _timeLeft = widget.inventory.duration;
    });
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _finishInventory();
        timer.cancel();
      }
    });
  }

  void _restartTimer() {
    if (widget.inventory.type == InventoryType.invCumulativeTime) {
      _timer?.cancel();
      _startTimer();
    }
  }

  void _updateSpeciesCount(Species species, bool increment) {
    setState(() {
      if (increment) {
        species.count++;
        _restartTimer(); // Restart the timer
      } else {
        if (species.count > 0) species.count--;
      }
    });
    DatabaseHelper().insertSpecies(species);
  }

  void _finishInventory() {
    setState(() {
      widget.inventory.isFinished = true;
    });
    DatabaseHelper().insertInventory(widget.inventory);
    Navigator.pop(context); // Go back to previous screen
  }

  void _filterSpecies(String query) {
    setState(() {
      _filteredSpecies = _allSpecies.where((species) => species.toLowerCase().contains(query.toLowerCase())).toList();
    });

    // Filtrar por regra de dois conjuntos de letras separados por espaço
    if (query.contains(' ')) {
      final queryParts = query.split(' '); // Dividir a consulta em partes
      if (queryParts.length == 2) { // Verificar se há duas partes
        _filteredSpecies = _allSpecies.where((species) {
          final speciesParts = species.split(' '); // Dividir o nome da espécie em palavras
          if (speciesParts.length >= 2) { // Verificar se há pelo menos duas palavras
            return speciesParts[0].toLowerCase().contains(queryParts[0].toLowerCase()) && // Verificar a primeira parte na primeira palavra (case-insensitive)
                speciesParts[1].toLowerCase().contains(queryParts[1].toLowerCase()); // Verificar a segunda parte na segunda palavra (case-insensitive)
          }
          return false; // Se não houver duas palavras, retornar falso
        }).toList();
      }
    }
  }

  void _addSpecies(String scientificName) {
    if (widget.inventory.speciesList.any((species) => species.name == scientificName)) {
      return;
    }

    final newSpecies = Species(inventoryId: widget.inventory.id, name: scientificName, count: 0, isOutOfInventory: false);
    setState(() {
      widget.inventory.speciesList.add(newSpecies);
      _inventorySpecies.add(newSpecies);
      int index = widget.inventory.speciesList.isEmpty ? 0 : widget.inventory.speciesList.length - 1; // Verificar se a lista está vazia
      _listKey.currentState!.insertItem(index);
    });
    Provider.of<InventoryProvider>(context, listen: false).addSpeciesToInventory(widget.inventory, newSpecies.name);
    DatabaseHelper().insertSpecies(newSpecies);
    _syncWithCumulativeInventory(newSpecies);
    _searchController.clear();
  }

  void _removeSpecies(int index) {
    if (index >= 0 && index < _inventorySpecies.length) {
      final speciesToRemove = _inventorySpecies[index]; // Get the species before removing

      _listKey.currentState!.removeItem(
        index,
            (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: SpeciesListItem(
            species: speciesToRemove, // Use the speciesToRemove here
            animation: animation,
          ),
        ),
      );

      setState(() {
        _inventorySpecies.removeAt(index);
        widget.inventory.speciesList.removeAt(index);
      });

      Provider.of<InventoryProvider>(context, listen: false)
          .removeSpeciesFromInventory(widget.inventory, speciesToRemove.name);
      DatabaseHelper().deleteSpeciesFromInventory(widget.inventory.id, speciesToRemove.name);
    }
  }

  void _syncWithCumulativeInventory(Species species) {
    final cumulativeInventory = widget.allInventories.firstWhere(
          (inventory) =>
      inventory.type == InventoryType.invCumulativeTime && !inventory.isFinished,
      orElse: () => Inventory(
        id: 'none',
        type: InventoryType.invCumulativeTime,
        duration: 0,
        speciesList: [],
      ),
    );

    if (cumulativeInventory.id != 'none' && !cumulativeInventory.speciesList.any((s) => s.name == species.name)) {
      cumulativeInventory.speciesList.add(species);
      DatabaseHelper().insertSpecies(species);
    }
  }

  Future<void> _addPoiForSpecies(Species species) async {
    // 1. Get latitude and longitude
    LatLng? currentLocation;
    try {
      currentLocation = await Provider.of<InventoryProvider>(context, listen: false).getCurrentLocation();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter a localização: $e');
      }
      // Lidar com o erro de localização, por exemplo, exibindo uma mensagem para o usuário
      return;
    }

    // 2. Create a Poi object
    final poi = Poi(
      speciesId: species.id!,
      longitude: currentLocation.longitude,
      latitude: currentLocation.latitude,
    );

    // 3. Save the POI to the database
    await DatabaseHelper().insertPoi(poi);

    // 4. Update the POIs list of species
    setState(() {
      species.pois.add(poi);
    });
  }

  void _showVegetationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildVegetationDialog(context);
      },
    );
  }

  Widget _buildVegetationDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    // controllers for the form fields
    final herbsProportionController = TextEditingController();
    final herbsDistributionController = TextEditingController();
    final herbsHeightController = TextEditingController();
    final shrubsProportionController = TextEditingController();
    final shrubsDistributionController = TextEditingController();
    final shrubsHeightController = TextEditingController();
    final treesProportionController = TextEditingController();
    final treesDistributionController = TextEditingController();
    final treesHeightController = TextEditingController();
    final notesController = TextEditingController();

    return AlertDialog(
      title: const Text('Adicionar Vegetação'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView( // To prevent overflow if the keyboard show
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Estrato Herbáceo'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller:herbsProportionController,
                        decoration: const InputDecoration(labelText: 'Proporção %'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final intValue = int.tryParse(value);
                            if (intValue == null) {
                              return 'Por favor, insira um número inteiro válido';
                            }
                            if (intValue < 0 || intValue > 100) {
                              return 'Por favor, insira um número entre 0 e 100';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16), // Spacing between fields
                    Expanded(
                      child: TextFormField(
                        controller: herbsDistributionController,
                        decoration: const InputDecoration(labelText: 'Distribuição'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final intValue = int.tryParse(value);
                            if (intValue == null) {
                              return 'Por favor, insira um número inteiro válido';
                            }
                            if (intValue < 0 || intValue > 14) {
                              return 'Por favor, insira um número entre 0 e 14';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16), // Spacing between fields
                    Expanded(
                      child: TextFormField(
                          controller: herbsHeightController,
                          decoration: const InputDecoration(labelText: 'Altura cm'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (int.tryParse(value) == null) {
                                return 'Por favor, insira um número inteiro válido';
                              }
                            }
                            return null;
                          }
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Estrato Arbustivo'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller:shrubsProportionController,
                        decoration: const InputDecoration(labelText: 'Proporção %'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final intValue = int.tryParse(value);
                            if (intValue == null) {
                              return 'Por favor, insira um número inteiro válido';
                            }
                            if (intValue < 0 || intValue > 100) {
                              return 'Por favor, insira um número entre 0 e 100';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16), // Spacing between fields
                    Expanded(
                      child: TextFormField(
                        controller: shrubsDistributionController,
                        decoration: const InputDecoration(labelText: 'Distribuição'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final intValue = int.tryParse(value);
                            if (intValue == null) {
                              return 'Por favor, insira um número inteiro válido';
                            }
                            if (intValue < 0 || intValue > 14) {
                              return 'Por favor, insira um número entre 0 e 14';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16), // Spacing between fields
                    Expanded(
                      child: TextFormField(
                          controller: shrubsHeightController,
                          decoration: const InputDecoration(labelText: 'Altura cm'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (int.tryParse(value) == null) {
                                return 'Por favor, insira um número inteiro válido';
                              }
                            }
                            return null;
                          }
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Estrato Arbóreo'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                          controller:treesProportionController,
                          decoration: const InputDecoration(labelText: 'Proporção %'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final intValue = int.tryParse(value);
                              if (intValue == null) {
                                return 'Por favor, insira um número inteiro válido';
                              }
                              if (intValue < 0 || intValue > 100) {
                                return 'Por favor, insira um número entre 0 e 100';
                              }
                            }
                            return null;
                          }
                      ),
                    ),
                    const SizedBox(width: 16), // Spacing between fields
                    Expanded(
                      child: TextFormField(
                        controller: treesDistributionController,
                        decoration: const InputDecoration(labelText: 'Distribuição'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final intValue = int.tryParse(value);
                            if (intValue == null) {
                              return 'Por favor, insira um número inteiro válido';
                            }
                            if (intValue < 0 || intValue > 14) {
                              return 'Por favor, insira um número entre 0 e 14';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16), // Spacing between fields
                    Expanded(
                      child: TextFormField(
                          controller: treesHeightController,
                          decoration: const InputDecoration(labelText: 'Altura cm'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              if (int.tryParse(value) == null) {
                                return 'Por favor, insira um número inteiro válido';
                              }
                            }
                            return null;
                          }
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notas'),
                  maxLines: 3, // Allows multiple lines
                ),
              ],
            )

        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              LatLng? currentLocation;
              try {
                currentLocation = await Provider.of<InventoryProvider>(context, listen: false).getCurrentLocation();
              } catch (e) {
                if (kDebugMode) {
                  print('Erro ao obter a localização: $e');
                }
                // Handle location error, e.g., showing a message to the user
                // You may opt to go back and do not save the data if the location is unavailable
                return;
              }

              // Create a Vegetation object with the form data
              Vegetation vegetation = Vegetation(
                inventoryId: widget.inventory.id,
                sampleTime: DateTime.now(),
                latitude: currentLocation.latitude,
                longitude: currentLocation.longitude,
                herbsProportion: int.tryParse(herbsProportionController.text) ?? 0,
                herbsDistribution: int.tryParse(herbsDistributionController.text) ?? 0,
                herbsHeight: int.tryParse(herbsHeightController.text) ?? 0,
                shrubsProportion: int.tryParse(shrubsProportionController.text) ?? 0,
                shrubsDistribution: int.tryParse(shrubsDistributionController.text) ?? 0,
                shrubsHeight: int.tryParse(shrubsHeightController.text) ?? 0,
                treesProportion: int.tryParse(treesProportionController.text) ?? 0,
                treesDistribution: int.tryParse(treesDistributionController.text) ?? 0,
                treesHeight: int.tryParse(treesHeightController.text) ?? 0,
                notes: notesController.text,
              );

              // Save vegetation to the database
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<InventoryProvider>(context, listen: false).addVegetation(vegetation);
              });

              Navigator.of(context).pop();
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
