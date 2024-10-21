import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import '../models/inventory.dart';
import '../data/database_helper.dart';

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

  Future<void> loadInventories() async {
    _isLoading = true;
    // notifyListeners();
    try {
      _inventories.clear();
      final inventories = await DatabaseHelper().getInventories();
      _inventories.addAll(inventories);
      if (kDebugMode) {
        print('Inventories loaded');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading inventories: $e');
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  void addInventory(Inventory inventory) {
    _inventories.add(inventory);
    // inventory.startTimer();
    notifyListeners();
  }

  void updateInventory(Inventory inventory) {
    _inventoryMap[inventory.id] = inventory;
    final index = _inventories.indexWhere((inv) => inv.id == inventory.id);
    if (index != -1) {
      _inventories[index] = inventory;
    }
    notifyListeners();
  }

  void removeInventory(String id) {
    _inventories.removeWhere((inventory) => inventory.id == id);
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
}