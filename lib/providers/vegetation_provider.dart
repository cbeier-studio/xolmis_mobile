import 'package:flutter/material.dart';

import '../data/models/inventory.dart';
import '../data/daos/vegetation_dao.dart';

/// Manages vegetation samples grouped by inventory identifier.
class VegetationProvider with ChangeNotifier {
  final VegetationDao _vegetationDao;

  VegetationProvider(this._vegetationDao);

  final Map<String, List<Vegetation>> _vegetationMap = {};

  /// Notifies listeners without reloading data.
  void refreshState() {
    notifyListeners();
  }

  /// Loads all vegetation samples associated with [inventoryId].
  Future<void> loadVegetationForInventory(String inventoryId) async {
    try {
      final vegetationList = await _vegetationDao.getVegetationByInventory(inventoryId);
      _vegetationMap[inventoryId] = vegetationList;
    } catch (e) {
      debugPrint('Error loading vegetation for inventory $inventoryId: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Returns the cached vegetation samples for [inventoryId].
  List<Vegetation> getVegetationForInventory(String inventoryId) {
    return _vegetationMap[inventoryId] ?? [];
  }

  /// Persists [vegetation] for [inventoryId] and updates the local cache.
  Future<void> addVegetation(BuildContext context, String inventoryId, Vegetation vegetation) async {
    // Insert the vegetation data in the database
    await _vegetationDao.insertVegetation(vegetation);
    
    // Add the vegetation to the list of the provider
    _vegetationMap[inventoryId] = _vegetationMap[inventoryId] ?? [];
    _vegetationMap[inventoryId]!.add(vegetation);

    notifyListeners();
  }

  /// Updates a vegetation sample in storage and refreshes the inventory cache.
  Future<void> updateVegetation(String inventoryId, Vegetation vegetation) async {
    await _vegetationDao.updateVegetation(vegetation);

    _vegetationMap[inventoryId] = await _vegetationDao.getVegetationByInventory(inventoryId);

    notifyListeners();
  }

  /// Deletes a vegetation sample from storage and removes it from the cache.
  Future<void> removeVegetation(String inventoryId, int vegetationId) async {
    await _vegetationDao.deleteVegetation(vegetationId);

    final vegetationList = _vegetationMap[inventoryId];
    if (vegetationList != null) {
      vegetationList.removeWhere((v) => v.id == vegetationId);
    }
    notifyListeners();
  }
}