import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/inventory.dart';
import '../data/daos/species_dao.dart';

import '../providers/inventory_provider.dart';

class SpeciesProvider with ChangeNotifier {
  final SpeciesDao _speciesDao;

  SpeciesProvider(this._speciesDao);

  final Map<String, List<Species>> _speciesMap = {};
  final ValueNotifier<int> individualsCountNotifier = ValueNotifier<int>(0);

  void refreshState() {
    notifyListeners();
  }

  // Get list of all inventory IDs
  List<String> getAllInventoryIds() {
    return _speciesMap.keys.toList();
  }

  // Load list of species for an inventory ID
  Future<void> loadSpeciesForInventory(String inventoryId) async {
    if (inventoryId.isEmpty) {
      debugPrint('[PROVIDER] !!! Invalid inventoryId: empty or null');
      return;
    }
    try {
      final speciesList = await _speciesDao.getSpeciesByInventory(inventoryId, false);
      _speciesMap[inventoryId] = speciesList;
      debugPrint('[PROVIDER] Loaded ${speciesList.length} species for inventory $inventoryId');
    } catch (e) {
      debugPrint('[PROVIDER] !!! ERROR loading species list for inventory $inventoryId: $e');
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

  Future<List<Species>> getAllSpeciesRecords() async {
    return await _speciesDao.getAllSpeciesRecords();
  }

  /// Retorna o número total de registros de espécies no banco de dados.
  Future<int> getTotalRecordsOfAllSpecies() async {
    return await _speciesDao.countAllSpeciesRecords();
  }

  // Add species to the database and the list
  Future<void> addSpecies(BuildContext context, String inventoryId, Species species) async {
    debugPrint('[PROVIDER] Adding species ${species.name} to inventory $inventoryId');
    await _speciesDao.insertSpecies(inventoryId, species);
    
    // Check if the species list is empty for the inventory ID
    if (_speciesMap[inventoryId] == null) {
      debugPrint('[PROVIDER] Initializing species list for inventory $inventoryId');
      _speciesMap[inventoryId] = [];
    }
    // Check if the species already exists in the list
    if (_speciesMap[inventoryId]!.any((s) => s.name == species.name)) {
      debugPrint('[PROVIDER] Species ${species.name} already exists in inventory $inventoryId');
      return; // Species already exists, no need to add
    }
    // Add the species to the list
    debugPrint('[PROVIDER] Adding species ${species.name} to local list for inventory $inventoryId');
    _speciesMap[inventoryId]!.add(species);
    
    if (context.mounted) {
      debugPrint('[PROVIDER] Updating species count for inventory $inventoryId');
      Provider.of<InventoryProvider>(context, listen: false).updateSpeciesCount(inventoryId);
    }
    notifyListeners();
  }

  // Update species in the database and the list
  Future<void> updateSpecies(String inventoryId, Species species) async {
    debugPrint('[PROVIDER] Updating species ${species.name} in inventory $inventoryId');
    await _speciesDao.updateSpecies(species);
    // Update the species in the list
    final speciesList = _speciesMap[inventoryId];
    if (speciesList != null) {
      debugPrint('[PROVIDER] Updating species ${species.name} in local list for inventory $inventoryId');
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
    debugPrint('[PROVIDER] Removing species $speciesId from inventory $inventoryId');
    await _speciesDao.deleteSpecies(speciesId);
    // Remove the species from the list
    final speciesList = _speciesMap[inventoryId];
    if (speciesList != null) {
      debugPrint('[PROVIDER] Removing species $speciesId from local list for inventory $inventoryId');
      speciesList.removeWhere((s) => s.id == speciesId);
    }

    // _speciesMap[inventoryId] = await _speciesRepository.getSpeciesByInventory(inventoryId);
    notifyListeners();

    if (context.mounted) {
      debugPrint('[PROVIDER] Updating species count for inventory $inventoryId');
      Provider.of<InventoryProvider>(context, listen: false).updateSpeciesCount(inventoryId);
    }
  }

  Future<void> removeSpeciesFromInventory(BuildContext context, String inventoryId, String speciesName) async {
    debugPrint('[PROVIDER] Removing species $speciesName from inventory $inventoryId');
    await _speciesDao.deleteSpeciesFromInventory(inventoryId, speciesName);
    // Remove the species from the list
    final speciesList = _speciesMap[inventoryId];
    if (speciesList != null) {
      debugPrint('[PROVIDER] Removing species $speciesName from local list for inventory $inventoryId');
      speciesList.removeWhere((s) => s.name == speciesName);
    }

    // _speciesMap[inventoryId] = await _speciesRepository.getSpeciesByInventory(inventoryId);
    notifyListeners();

    if (context.mounted) {
      debugPrint('[PROVIDER] Updating species count for inventory $inventoryId');
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