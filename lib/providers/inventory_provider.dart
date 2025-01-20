import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/inventory.dart';
import '../data/database/repositories/inventory_repository.dart';

import 'species_provider.dart';
import 'vegetation_provider.dart';
import 'weather_provider.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryRepository _inventoryRepository;
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

  InventoryProvider(this._inventoryRepository, this._speciesProvider, this._vegetationProvider, this._weatherProvider);

  // Load all inventories from the database
  Future<void> fetchInventories() async {
    _isLoading = true;
    try {
      _inventories.clear();
      _inventoryMap.clear();
      final inventories = await _inventoryRepository.getInventories();
      _inventories.addAll(inventories);
      // notifyListeners();
      for (var inventory in inventories) {
        _inventoryMap[inventory.id] = inventory; // Populate the inventories map
        await _speciesProvider.loadSpeciesForInventory(inventory.id);
        await _vegetationProvider.loadVegetationForInventory(inventory.id);
        await _weatherProvider.loadWeatherForInventory(inventory.id);
        startInventoryTimer(inventory, _inventoryRepository);
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
    return await _inventoryRepository.inventoryIdExists(id);
  }

  // Add inventory to the database and the list
  Future<bool> addInventory(Inventory inventory) async {
    try {
      await _inventoryRepository.insertInventory(inventory);
      _inventories.add(inventory);
      startInventoryTimer(inventory, _inventoryRepository);

      return true;
    } catch (error) {
      // Handle insertion error
      if (kDebugMode) {
        print('Error adding inventory: $error');
      }
      return false;
    } finally {
      notifyListeners();
    }
  }

  // Add imported inventory to the database and the list
  Future<bool> importInventory(Inventory inventory) async {
    try {
      await _inventoryRepository.importInventory(inventory);
      _inventories.add(inventory);

      return true;
    } catch (error) {
      // Handle insertion error
      if (kDebugMode) {
        print('Error importing inventory: $error');
      }
      return false;
    } finally {
      notifyListeners();
    }
  }

  // Update inventory in the database and the list
  void updateInventory(Inventory inventory) async {
    await _inventoryRepository.updateInventory(inventory);

    _inventoryMap[inventory.id] = inventory;
    notifyListeners();
  }

  // Remove inventory from the database and the list
  void removeInventory(String id) async {
    await _inventoryRepository.deleteInventory(id);

    _inventories.removeWhere((inventory) => inventory.id == id);
    _inventoryMap.remove(id);
    notifyListeners();
  }

  // Get an active inventory by ID
  Inventory getActiveInventoryById(String id) {
    return activeInventories.firstWhere((inventory) => inventory.id == id);
  }

  // Start inventory timer
  void startInventoryTimer(Inventory inventory, InventoryRepository inventoryRepository) {
    if (inventory.duration > 0 && !inventory.isFinished && !inventory.isPaused) {
      inventory.startTimer(inventoryRepository);
      updateInventory(inventory);
      notifyListeners();
    }
  }

  // Pause inventory timer
  void pauseInventoryTimer(Inventory inventory, InventoryRepository inventoryRepository) {
    inventory.pauseTimer(inventoryRepository);
    updateInventory(inventory);
    notifyListeners();
  }

  // Resume inventory timer
  void resumeInventoryTimer(Inventory inventory, InventoryRepository inventoryRepository) {
    inventory.resumeTimer(inventoryRepository);
    updateInventory(inventory);
    notifyListeners();
  }

  // Update the ID in the database and the list
  Future<void> changeInventoryId(String oldId, String newId) async {
    await _inventoryRepository.changeInventoryId(oldId, newId);
    fetchInventories();
    notifyListeners();
  }

  // Update the elapsed time in the database and the list
  Future<void> updateInventoryElapsedTime(String inventoryId, double elapsedTime) async {
    await _inventoryRepository.updateInventoryElapsedTime(inventoryId, elapsedTime);
    _inventoryMap[inventoryId]?.elapsedTime = elapsedTime;
    notifyListeners();
  }

  // Update the current interval in the database and the list
  Future<void> updateInventoryCurrentInterval(String inventoryId, int currentInterval) async {
    await _inventoryRepository.updateInventoryCurrentInterval(inventoryId, currentInterval);
    _inventoryMap[inventoryId]?.currentInterval = currentInterval;
    notifyListeners();
  }

  // Update the species list count
  void updateSpeciesCount(String inventoryId) {
    final inventory = getInventoryById(inventoryId);
    if (inventory != null) {
      speciesCountNotifier.value = inventory.speciesList.length;
      speciesCountNotifier.notifyListeners();
    }
  }

  // Concatenate the next inventory ID
  Future<int> getNextSequentialNumber(String? local, String observer, int ano, int mes, int dia, String? typeChar) {
    return _inventoryRepository.getNextSequentialNumber(local, observer, ano, mes, dia, typeChar);
  }

}