import 'package:flutter/foundation.dart';
import '../providers/poi_provider.dart';
import '../models/inventory.dart';
import '../data/database_helper.dart';

class SpeciesProvider with ChangeNotifier {
  final Map<String, List<Species>> _speciesMap = {};

  SpeciesProvider() {
    _loadInitialData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    // Carregue os dados do banco de dados e inicialize o _speciesMap
    final inventories = await DatabaseHelper().getInventories();
    for (var inventory in inventories) {
      final speciesList = await DatabaseHelper().getSpeciesByInventory(inventory.id);
      _speciesMap[inventory.id] = speciesList;
    }
    notifyListeners();
  }

  Future<void> loadSpeciesForInventory(String inventoryId) async {
    try {
      final speciesList = await DatabaseHelper().getSpeciesByInventory(inventoryId);
      _speciesMap[inventoryId] = speciesList;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading species for inventory $inventoryId: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  List<Species> getSpeciesForInventory(String inventoryId) {
    return _speciesMap[inventoryId] ?? [];
  }

  void addSpecies(String inventoryId, Species species) async {
    await DatabaseHelper().insertSpecies(inventoryId, species);
    _speciesMap[inventoryId] = _speciesMap[inventoryId] ?? [];
    _speciesMap[inventoryId]!.add(species);
    notifyListeners();
  }

  void updateSpecies(String inventoryId, Species species) async {
    await DatabaseHelper().updateSpecies(species);

    final speciesList = _speciesMap[inventoryId];
    if (speciesList != null) {
      final index = speciesList.indexWhere((s) => s.id == species.id);
      if (index != -1) {
        speciesList[index] = species;
      }
    }
    notifyListeners();
  }

  void removeSpecies(String inventoryId, int speciesId) async {
    await DatabaseHelper().deleteSpecies(speciesId);

    final speciesList = _speciesMap[inventoryId];
    if (speciesList != null) {
      speciesList.removeWhere((s) => s.id == speciesId);
    }
    notifyListeners();
  }

  void sortSpeciesForInventory(String inventoryId) {
    final speciesList = _speciesMap[inventoryId];
    if (speciesList != null) {
      speciesList.sort((a, b) => a.name.compareTo(b.name));
    }
    notifyListeners();
  }

  void _onPoisChanged() {
    // Update the species list when have changes in POIs
    for (var inventoryId in _speciesMap.keys) {
      final speciesList = _speciesMap[inventoryId];
      if (speciesList != null) {
        for (var species in speciesList) {
          // final poiProvider = Provider.of<PoiProvider>(context, listen: false);
          species.pois = PoiProvider().getPoisForSpecies(species.id!);
        }
      }
    }
    notifyListeners();
  }
}