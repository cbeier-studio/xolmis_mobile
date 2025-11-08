import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/inventory.dart';
import '../data/daos/inventory_dao.dart';

import 'species_provider.dart';
import 'vegetation_provider.dart';
import 'weather_provider.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryDao _inventoryDao;
  final List<Inventory> _inventories = [];
  final Map<String, Inventory> _inventoryMap = {};
  final ValueNotifier<int> speciesCountNotifier = ValueNotifier<int>(0);
  // Flag to indicate that data is loading
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Get list of active inventories
  List<Inventory> get activeInventories =>
      _inventories.where((inventory) => !inventory.isFinished).toList();

  // Get list of finished inventories
  List<Inventory> get finishedInventories =>
      _inventories.where((inventory) => inventory.isFinished).toList();

  // Get the number of active inventories
  int get inventoriesCount => activeInventories.length;

  final SpeciesProvider _speciesProvider;
  final VegetationProvider _vegetationProvider;
  final WeatherProvider _weatherProvider;
  SpeciesProvider get speciesProvider => _speciesProvider;
  VegetationProvider get vegetationProvider => _vegetationProvider;
  WeatherProvider get weatherProvider => _weatherProvider;

  InventoryProvider(this._inventoryDao, this._speciesProvider, this._vegetationProvider, this._weatherProvider);

  // Load all inventories from the database
  Future<void> fetchInventories(BuildContext context) async {
    _isLoading = true;
    try {
      _inventories.clear();
      _inventoryMap.clear();
      final inventories = await _inventoryDao.getInventories();
      _inventories.addAll(inventories);
      // notifyListeners();
      for (var inventory in inventories) {
        _inventoryMap[inventory.id] = inventory; // Populate the inventories map
        await _speciesProvider.loadSpeciesForInventory(inventory.id);
        await _vegetationProvider.loadVegetationForInventory(inventory.id);
        await _weatherProvider.loadWeatherForInventory(inventory.id);
        startInventoryTimer(context, inventory, _inventoryDao);
      }
      if (kDebugMode) {
        print('Inventories loaded');
      }
      // notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading inventories: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get inventory data by ID
  Inventory? getInventoryById(String id) {
    return _inventoryMap[id]; // Get the inventory from map
  }

  // Check if an inventory ID already exists
  Future<bool> inventoryIdExists(String id) async {
    return await _inventoryDao.inventoryIdExists(id);
  }

  // Add inventory to the database and the list
  Future<bool> addInventory(BuildContext context, Inventory inventory) async {
    try {
      await _inventoryDao.insertInventory(context, inventory);
      _inventories.add(inventory);
      _inventoryMap[inventory.id] = inventory; // Add to the map
      notifyListeners();
      startInventoryTimer(context, inventory, _inventoryDao);

      return true;
    } catch (error) {
      if (kDebugMode) {
        print('Error adding inventory: $error');
      }
      return false;
    }
  }

  // Add imported inventory to the database and the list
  Future<bool> importInventory(Inventory inventory) async {
    try {
      await _inventoryDao.importInventory(inventory);
      _inventories.add(inventory);
      _inventoryMap[inventory.id] = inventory; // Add to the map
      notifyListeners();

      return true;
    } catch (error) {
      if (kDebugMode) {
        print('Error importing inventory: $error');
      }
      return false;
    }
  }

  // Update inventory in the database and the list
  Future<void> updateInventory(Inventory inventory) async {
    await _inventoryDao.updateInventory(inventory);

    final index = _inventories.indexWhere((inv) => inv.id == inventory.id);
    if (index != -1) {
      _inventories[index] = inventory;
    }
    // Ensure the map also has the updated instance, though if instances are shared, this might be redundant.
    _inventoryMap[inventory.id] = inventory;
    notifyListeners();
  }

  // Remove inventory from the database and the list
  void removeInventory(String id) async {
    await _inventoryDao.deleteInventory(id);

    _inventories.removeWhere((inventory) => inventory.id == id);
    _inventoryMap.remove(id);
    notifyListeners();
  }

  // Get an active inventory by ID
  Inventory getActiveInventoryById(String id) {
    return activeInventories.firstWhere((inventory) => inventory.id == id);
  }

  // Start inventory timer
  void startInventoryTimer(BuildContext context, Inventory inventory, InventoryDao inventoryDao) {
    if (inventory.duration > 0 && !inventory.isFinished && !inventory.isPaused) {
      inventory.startTimer(context, inventoryDao);
      updateInventory(inventory);
      // notifyListeners();
    }
  }

  // Pause inventory timer
  void pauseInventoryTimer(Inventory inventory, InventoryDao inventoryDao) {
    inventory.pauseTimer(inventoryDao);
    updateInventory(inventory);
    // notifyListeners();
  }

  // Resume inventory timer
  void resumeInventoryTimer(BuildContext context, Inventory inventory, InventoryDao inventoryDao) {
    inventory.resumeTimer(context, inventoryDao);
    updateInventory(inventory);
    // notifyListeners();
  }

  // Update the ID in the database and the list
  Future<void> changeInventoryId(BuildContext context, String oldId, String newId) async {
    await _inventoryDao.changeInventoryId(oldId, newId);
    await fetchInventories(context);
    // notifyListeners();
  }

  // Update the elapsed time in the database and the list
  Future<void> updateInventoryElapsedTime(String inventoryId, double elapsedTime) async {
    await _inventoryDao.updateInventoryElapsedTime(inventoryId, elapsedTime);
    _inventoryMap[inventoryId]?.elapsedTime = elapsedTime;
    final index = _inventories.indexWhere((inv) => inv.id == inventoryId);
    if (index != -1 && _inventories[index].elapsedTime != elapsedTime) {
      // To ensure the instance in the list is also updated if it's a different object or for direct field update
      _inventories[index].elapsedTime = elapsedTime;
    }
    notifyListeners();
  }

  // Update the current interval in the database and the list
  Future<void> updateInventoryCurrentInterval(String inventoryId, int currentInterval) async {
    await _inventoryDao.updateInventoryCurrentInterval(inventoryId, currentInterval);
    _inventoryMap[inventoryId]?.currentInterval = currentInterval;
    final index = _inventories.indexWhere((inv) => inv.id == inventoryId);
    if (index != -1 && _inventories[index].currentInterval != currentInterval) {
      // To ensure the instance in the list is also updated
      _inventories[index].currentInterval = currentInterval;
    }
    notifyListeners();
  }

  // Update the species list count
  void updateSpeciesCount(String inventoryId) {
    final inventory = getInventoryById(inventoryId);
    if (inventory != null) {
      speciesCountNotifier.value = inventory.speciesList.length;
      // speciesCountNotifier.notifyListeners();
    }
  }

  // Concatenate the next inventory ID
  Future<int> getNextSequentialNumber(String? local, String observer, int ano, int mes, int dia, String? typeChar) {
    return _inventoryDao.getNextSequentialNumber(local, observer, ano, mes, dia, typeChar);
  }

  // Calculate the total sampling hours from all inventories
  Future<double> getTotalSamplingHours() async {
    final allInventories = await _inventoryDao.getInventories();
    final inventories = allInventories.where((inventory) => inventory.isFinished).toList();

    // Sort inventories by start time
    inventories.sort((a, b) => a.startTime!.compareTo(b.startTime!));

    Duration totalNonOverlappingDuration = Duration.zero;
    DateTime? coveredUntil; // The end of the currently covered time range

    for (final inventory in inventories) {
      if (inventory.startTime == null || inventory.endTime == null) {
        continue; // Skip inventories with missing start or end times
      }

      if (coveredUntil == null || inventory.startTime!.isAfter(coveredUntil)) {
        // No overlap: Add the entire duration
        totalNonOverlappingDuration += inventory.endTime!.difference(inventory.startTime!);
        coveredUntil = inventory.endTime;
      } else {
        // Overlap: Add only the non-overlapping portion
        if (inventory.endTime!.isAfter(coveredUntil)) {
          totalNonOverlappingDuration += inventory.endTime!.difference(coveredUntil);
          coveredUntil = inventory.endTime;
        }
      }
    }

    return totalNonOverlappingDuration.inMinutes / 60.0; // Convert to hours
  }

  // Calculate the average sampling hours from all inventories
  Future<double> getAverageSamplingHours() async {
    final allInventories = await _inventoryDao.getInventories();
    final inventories = allInventories.where((inventory) => inventory.isFinished).toList();

    // Sort inventories by start time
    inventories.sort((a, b) => a.startTime!.compareTo(b.startTime!));

    Duration totalNonOverlappingDuration = Duration.zero;
    DateTime? coveredUntil; // The end of the currently covered time range

    for (final inventory in inventories) {
      if (inventory.startTime == null || inventory.endTime == null) {
        continue; // Skip inventories with missing start or end times
      }

      if (coveredUntil == null || inventory.startTime!.isAfter(coveredUntil)) {
        // No overlap: Add the entire duration
        totalNonOverlappingDuration += inventory.endTime!.difference(inventory.startTime!);
        coveredUntil = inventory.endTime;
      } else {
        // Overlap: Add only the non-overlapping portion
        if (inventory.endTime!.isAfter(coveredUntil)) {
          totalNonOverlappingDuration += inventory.endTime!.difference(coveredUntil);
          coveredUntil = inventory.endTime;
        }
      }
    }

    return (totalNonOverlappingDuration.inMinutes / inventories.length) / 60.0; // Convert to hours
  }

  // Get list of distinct localities for autocomplete
  Future<List<String>> getDistinctLocalities() {
    return _inventoryDao.getDistinctLocalities();
  }

}