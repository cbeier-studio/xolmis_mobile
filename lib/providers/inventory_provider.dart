import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/inventory.dart';
import '../data/database_helper.dart';
import 'vegetation_provider.dart';

class InventoryProvider with ChangeNotifier {
  final List<Inventory> _inventories = [];
  final Map<String, Inventory> _inventoryMap = {};
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Inventory> get activeInventories =>
      _inventories.where((inventory) => !inventory.isFinished).toList();

  List<Inventory> get finishedInventories =>
      _inventories.where((inventory) => inventory.isFinished).toList();

  int get inventoriesCount => activeInventories.length;

  InventoryProvider() {
    // Add a listener to VegetationProvider
    VegetationProvider().addListener(_onVegetationListChanged);
  }

  Future<void> loadInventories() async {
    _isLoading = true;
    // notifyListeners();
    try {
      _inventories.clear();
      _inventoryMap.clear();
      final inventories = await DatabaseHelper().getInventories();
      _inventories.addAll(inventories);
      for (var inventory in inventories) {
        _inventoryMap[inventory.id] = inventory; // Populate the inventories map
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

  Inventory? getInventoryById(String id) {
    return _inventoryMap[id]; // Get the inventory from map
  }

  Future<bool> inventoryIdExists(String id) async {
    return await DatabaseHelper().inventoryIdExists(id);
  }

  Future<bool> addInventory(Inventory inventory) async {
    try {
      await DatabaseHelper().insertInventory(inventory);
      _inventories.add(inventory);
      notifyListeners();
      return true;
    } catch (error) {
      // Handle insertion error
      if (kDebugMode) {
        print('Error adding inventory: $error');
      }
      return false;
    }
  }

  void updateInventory(Inventory inventory) async {
    await DatabaseHelper().updateInventory(inventory);

    _inventoryMap[inventory.id] = inventory;
    notifyListeners();
  }

  void removeInventory(String id) async {
    await DatabaseHelper().deleteInventory(id);

    _inventories.removeWhere((inventory) => inventory.id == id);
    _inventoryMap.remove(id);
    notifyListeners();
  }

  Inventory getActiveInventoryById(String id) {
    return activeInventories.firstWhere((inventory) => inventory.id == id);
  }

  void pauseInventoryTimer(Inventory inventory) {
    inventory.pauseTimer();
    updateInventory(inventory);
    notifyListeners();
  }

  void resumeInventoryTimer(Inventory inventory) {
    inventory.resumeTimer();
    updateInventory(inventory);
    notifyListeners();
  }

  void _onVegetationListChanged() {
    // Update the vegetation list when have changes in VegetationProvider
    for (var inventoryId in _inventoryMap.keys) {
      final inventoryList = _inventoryMap[inventoryId];
      if (inventoryList != null) {
        for (var inventory in _inventories) {
          inventory.vegetationList = VegetationProvider().getVegetationForInventory(inventory.id);
        }
      }
    }
    notifyListeners();
  }
}