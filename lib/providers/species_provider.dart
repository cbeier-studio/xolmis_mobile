import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../data/models/inventory.dart';
import '../data/database/repositories/species_repository.dart';
import '../data/database/repositories/inventory_repository.dart';

import '../providers/inventory_provider.dart';

class SpeciesProvider with ChangeNotifier {
  final SpeciesRepository _speciesRepository;
  final InventoryRepository _inventoryRepository;

  SpeciesProvider(this._speciesRepository, this._inventoryRepository);

  final Map<String, List<Species>> _speciesMap = {};
  final ValueNotifier<int> individualsCountNotifier = ValueNotifier<int>(0);
  final Map<String, List<Species>> _speciesByInventoryId = {};

  List<String> getAllInventoryIds() {
    return _speciesByInventoryId.keys.toList();
  }

  Future<void> _loadInitialData() async {
    // Load data from database and initialize the _speciesMap
    final inventories = await _inventoryRepository.getInventories();
    for (var inventory in inventories) {
      final speciesList = await _speciesRepository.getSpeciesByInventory(inventory.id);
      _speciesMap[inventory.id] = speciesList;
    }
    notifyListeners();
  }

  Future<void> loadSpeciesForInventory(String inventoryId) async {
    try {
      final speciesList = await _speciesRepository.getSpeciesByInventory(inventoryId);
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
    await _speciesRepository.insertSpecies(inventoryId, species);
    _speciesMap[inventoryId] = await _speciesRepository.getSpeciesByInventory(inventoryId);
    // _speciesMap[inventoryId] = _speciesMap[inventoryId] ?? [];
    // _speciesMap[inventoryId]!.add(species);
    Provider.of<InventoryProvider>(context, listen: false).updateSpeciesCount(inventoryId);
    notifyListeners();
  }

  Future<void> updateSpecies(String inventoryId, Species species) async {
    await _speciesRepository.updateSpecies(species);

    _speciesMap[inventoryId] = await _speciesRepository.getSpeciesByInventory(inventoryId);
    // final speciesList = _speciesMap[inventoryId];
    // if (speciesList != null) {
    //   final index = speciesList.indexWhere((s) => s.id == species.id);
    //   if (index != -1) {
    //     speciesList[index] = species;
    //   }
    // }
    notifyListeners();
  }

  Future<void> removeSpecies(BuildContext context, String inventoryId, int speciesId) async {
    await _speciesRepository.deleteSpecies(speciesId);

    _speciesMap[inventoryId] = await _speciesRepository.getSpeciesByInventory(inventoryId);
    notifyListeners();

    Provider.of<InventoryProvider>(context, listen: false).updateSpeciesCount(inventoryId);
  }

  // void sortSpeciesForInventory(String inventoryId) {
  //   final speciesList = _speciesMap[inventoryId];
  //   if (speciesList != null) {
  //     speciesList.sort((a, b) => a.name.compareTo(b.name));
  //   }
  //   notifyListeners();
  // }

  Future<void> incrementIndividualsCount(Species species) async {
    species.count++;
    await _speciesRepository.updateSpecies(species);
    individualsCountNotifier.value = species.count;

    final speciesList = _speciesMap[species.inventoryId];
    if (speciesList != null) {
      final index = speciesList.indexWhere((s) => s.id == species.id);
      if (index != -1) {
        speciesList[index].count = species.count;
      }
    }
    notifyListeners();
  }

  Future<void> decrementIndividualsCount(Species species) async {
    if (species.count > 0) {
      species.count--;
      await _speciesRepository.updateSpecies(species);
      individualsCountNotifier.value = species.count;

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