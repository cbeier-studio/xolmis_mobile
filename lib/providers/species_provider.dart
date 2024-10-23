import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory.dart';
import '../models/database_helper.dart';
import '../providers/inventory_provider.dart';

class SpeciesProvider with ChangeNotifier {
  final Map<String, List<Species>> _speciesMap = {};
  final speciesCountNotifier = ValueNotifier<int>(0);

  SpeciesProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load data from database and initialize the _speciesMap
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

  Future<void> addSpecies(BuildContext context, String inventoryId, Species species) async {
    await DatabaseHelper().insertSpecies(inventoryId, species);
    _speciesMap[inventoryId] = _speciesMap[inventoryId] ?? [];
    _speciesMap[inventoryId]!.add(species);
    Provider.of<InventoryProvider>(context, listen: false).updateSpeciesCount(inventoryId);
    notifyListeners();
  }

  Future<void> updateSpecies(String inventoryId, Species species) async {
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

  Future<void> removeSpecies(BuildContext context, String inventoryId, int speciesId) async {
    await DatabaseHelper().deleteSpecies(speciesId);

    final speciesList = _speciesMap[inventoryId];
    Provider.of<InventoryProvider>(context, listen: false).updateSpeciesCount(inventoryId);
    if (speciesList != null) {
      speciesList.removeWhere((s) => s.id == speciesId);
    }
    notifyListeners();
  }

  // void sortSpeciesForInventory(String inventoryId) {
  //   final speciesList = _speciesMap[inventoryId];
  //   if (speciesList != null) {
  //     speciesList.sort((a, b) => a.name.compareTo(b.name));
  //   }
  //   notifyListeners();
  // }

  Future<void> incrementSpeciesCount(Species species) async {
    species.count++;
    await DatabaseHelper().updateSpecies(species);
    speciesCountNotifier.value = species.count;

    final speciesList = _speciesMap[species.inventoryId];
    if (speciesList != null) {
      final index = speciesList.indexWhere((s) => s.id == species.id);
      if (index != -1) {
        speciesList[index].count = species.count;
      }
    }
    notifyListeners();
  }

  Future<void> decrementSpeciesCount(Species species) async {
    if (species.count > 0) {
      species.count--;
      await DatabaseHelper().updateSpecies(species);
      speciesCountNotifier.value = species.count;

      final speciesList = _speciesMap[species.inventoryId];
      if (speciesList != null) {
        final index = speciesList.indexWhere((s) => s.id == species.id);
        if (index != -1) {
          speciesList[index].count = species.count;
        }
      }
      notifyListeners();
    }
  }

  bool speciesExistsInInventory(String inventoryId, String speciesName) {
    final speciesList = getSpeciesForInventory(inventoryId);
    return speciesList.any((species) => species.name == speciesName);
  }
}