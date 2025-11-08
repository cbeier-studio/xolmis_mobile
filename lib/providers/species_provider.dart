import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/inventory.dart';
import '../data/database/daos/species_dao.dart';

import '../providers/inventory_provider.dart';

class SpeciesProvider with ChangeNotifier {
  final SpeciesDao _speciesDao;

  SpeciesProvider(this._speciesDao);

  final Map<String, List<Species>> _speciesMap = {};
  final ValueNotifier<int> individualsCountNotifier = ValueNotifier<int>(0);

  // Get list of all inventory IDs
  List<String> getAllInventoryIds() {
    return _speciesMap.keys.toList();
  }

  // Load list of species for an inventory ID
  Future<void> loadSpeciesForInventory(String inventoryId) async {
    if (inventoryId.isEmpty) {
      if (kDebugMode) {
        print('Invalid inventoryId: empty or null');
      }
      return;
    }
    try {
      final speciesList = await _speciesDao.getSpeciesByInventory(inventoryId, false);
      _speciesMap[inventoryId] = speciesList;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading species for inventory $inventoryId: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  // Get list of species for an inventory
  List<Species> getSpeciesForInventory(String inventoryId) {
    return _speciesMap[inventoryId] ?? [];
  }

  Future<List<Species>> getAllRecordsBySpecies(String speciesName) async {
    return await _speciesDao.getAllRecordsBySpecies(speciesName);
  }

  // Add species to the database and the list
  Future<void> addSpecies(BuildContext context, String inventoryId, Species species) async {
    await _speciesDao.insertSpecies(inventoryId, species);
    
    // Check if the species list is empty for the inventory ID
    if (_speciesMap[inventoryId] == null) {
      _speciesMap[inventoryId] = [];
    }
    // Check if the species already exists in the list
    if (_speciesMap[inventoryId]!.any((s) => s.name == species.name)) {
      return; // Species already exists, no need to add
    }
    // Add the species to the list
    _speciesMap[inventoryId]!.add(species);
    
    // _speciesMap[inventoryId] = await _speciesRepository.getSpeciesByInventory(inventoryId);
    if (context.mounted) {
      Provider.of<InventoryProvider>(context, listen: false).updateSpeciesCount(inventoryId);
    }
    notifyListeners();
  }

  // Update species in the database and the list
  Future<void> updateSpecies(String inventoryId, Species species) async {
    await _speciesDao.updateSpecies(species);
    // Update the species in the list
    final speciesList = _speciesMap[inventoryId];
    if (speciesList != null) {
      final index = speciesList.indexWhere((s) => s.id == species.id);
      if (index != -1) {
        speciesList[index] = species;
      }
    }

    // _speciesMap[inventoryId] = await _speciesRepository.getSpeciesByInventory(inventoryId);

    notifyListeners();
  }

  // Remove species from database and from list
  Future<void> removeSpecies(BuildContext context, String inventoryId, int speciesId) async {
    await _speciesDao.deleteSpecies(speciesId);
    // Remove the species from the list
    final speciesList = _speciesMap[inventoryId];
    if (speciesList != null) {
      speciesList.removeWhere((s) => s.id == speciesId);
    }

    // _speciesMap[inventoryId] = await _speciesRepository.getSpeciesByInventory(inventoryId);
    notifyListeners();

    if (context.mounted) {
      Provider.of<InventoryProvider>(context, listen: false).updateSpeciesCount(inventoryId);
    }
  }

  Future<void> removeSpeciesFromInventory(BuildContext context, String inventoryId, String speciesName) async {
    await _speciesDao.deleteSpeciesFromInventory(inventoryId, speciesName);
    // Remove the species from the list
    final speciesList = _speciesMap[inventoryId];
    if (speciesList != null) {
      speciesList.removeWhere((s) => s.name == speciesName);
    }

    // _speciesMap[inventoryId] = await _speciesRepository.getSpeciesByInventory(inventoryId);
    notifyListeners();

    if (context.mounted) {
      Provider.of<InventoryProvider>(context, listen: false).updateSpeciesCount(inventoryId);
    }
  }

  // Update number of individuals for a species
  void updateIndividualsCount(Species species) async {
    // 1. Find the species in the list
    final speciesList = _speciesMap[species.inventoryId];
    if (speciesList == null) return;
    // final speciesList = await _speciesRepository.getSpeciesByInventory(species.inventoryId);
    final index = speciesList.indexWhere((s) => s.id == species.id);

    if (index != -1) {
      // 2. Update the species count
      speciesList[index] = species.copyWith(count: species.count);
      updateSpecies(species.inventoryId, species);

      // 3. Notify the listeners
      notifyListeners();
    }
  }

  // Increase number of individuals for a species
  Future<void> incrementIndividualsCount(Species species) async {
    species.count++;
    await _speciesDao.updateSpecies(species);
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

  // Decrease number of individuals for a species
  Future<void> decrementIndividualsCount(Species species) async {
    if (species.count > 0) {
      species.count--;
      await _speciesDao.updateSpecies(species);
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

  // Check if a species is already in the list
  bool speciesExistsInInventory(String inventoryId, String speciesName) {
    final speciesList = getSpeciesForInventory(inventoryId);
    return speciesList.any((species) => species.name == speciesName);
  }
}