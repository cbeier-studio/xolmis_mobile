import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/inventory.dart';
import '../data/database/repositories/species_repository.dart';

import '../providers/inventory_provider.dart';

class SpeciesProvider with ChangeNotifier {
  final SpeciesRepository _speciesRepository;

  SpeciesProvider(this._speciesRepository);

  final Map<String, List<Species>> _speciesMap = {};
  final ValueNotifier<int> individualsCountNotifier = ValueNotifier<int>(0);
  final Map<String, List<Species>> _speciesByInventoryId = {};

  // Get list of all inventory IDs
  List<String> getAllInventoryIds() {
    return _speciesByInventoryId.keys.toList();
  }

  // Load list of species for an inventory ID
  Future<void> loadSpeciesForInventory(String inventoryId) async {
    if (inventoryId == null || inventoryId.isEmpty) {
      if (kDebugMode) {
        print('Invalid inventoryId: empty or null');
      }
      return;
    }
    try {
      final speciesList = await _speciesRepository.getSpeciesByInventory(inventoryId);
      _speciesMap[inventoryId] = speciesList;
      _speciesByInventoryId[inventoryId] = speciesList;
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
    return await _speciesRepository.getAllRecordsBySpecies(speciesName);
  }

  // Add species to the database and the list
  Future<void> addSpecies(BuildContext context, String inventoryId, Species species) async {
    await _speciesRepository.insertSpecies(inventoryId, species);
    _speciesMap[inventoryId] = await _speciesRepository.getSpeciesByInventory(inventoryId);
    // _speciesMap[inventoryId] = _speciesMap[inventoryId] ?? [];
    // _speciesMap[inventoryId]!.add(species);
    if (context.mounted) {
      Provider.of<InventoryProvider>(context, listen: false).updateSpeciesCount(inventoryId);
    }
    notifyListeners();
  }

  // Update species in the database and the list
  Future<void> updateSpecies(String inventoryId, Species species) async {
    await _speciesRepository.updateSpecies(species);

    _speciesMap[inventoryId] = await _speciesRepository.getSpeciesByInventory(inventoryId);

    notifyListeners();
  }

  // Remove species from database and from list
  Future<void> removeSpecies(BuildContext context, String inventoryId, int speciesId) async {
    await _speciesRepository.deleteSpecies(speciesId);

    _speciesMap[inventoryId] = await _speciesRepository.getSpeciesByInventory(inventoryId);
    notifyListeners();

    if (context.mounted) {
      Provider.of<InventoryProvider>(context, listen: false).updateSpeciesCount(inventoryId);
    }
  }

  Future<void> removeSpeciesFromInventory(BuildContext context, String inventoryId, String speciesName) async {
    await _speciesRepository.deleteSpeciesFromInventory(inventoryId, speciesName);

    _speciesMap[inventoryId] = await _speciesRepository.getSpeciesByInventory(inventoryId);
    notifyListeners();

    if (context.mounted) {
      Provider.of<InventoryProvider>(context, listen: false).updateSpeciesCount(inventoryId);
    }
  }

  // Update number of individuals for a species
  void updateIndividualsCount(Species species) async {
    // 1. Find the species in the list
    final speciesList = await _speciesRepository.getSpeciesByInventory(species.inventoryId);
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

  // Decrease number of individuals for a species
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

  // Check if a species is already in the list
  bool speciesExistsInInventory(String inventoryId, String speciesName) {
    final speciesList = getSpeciesForInventory(inventoryId);
    return speciesList.any((species) => species.name == speciesName);
  }
}