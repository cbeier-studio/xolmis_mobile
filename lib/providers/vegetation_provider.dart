import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/inventory.dart';
import '../data/daos/vegetation_dao.dart';

class VegetationProvider with ChangeNotifier {
  final VegetationDao _vegetationDao;

  VegetationProvider(this._vegetationDao);

  final Map<String, List<Vegetation>> _vegetationMap = {};

  // Load vegetation records for an inventory ID
  Future<void> loadVegetationForInventory(String inventoryId) async {
    try {
      final vegetationList = await _vegetationDao.getVegetationByInventory(inventoryId);
      _vegetationMap[inventoryId] = vegetationList;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading vegetation for inventory $inventoryId: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  // Get list of vegetation record for an inventory ID
  List<Vegetation> getVegetationForInventory(String inventoryId) {
    return _vegetationMap[inventoryId] ?? [];
  }

  // Add vegetation record to the database and the list
  Future<void> addVegetation(BuildContext context, String inventoryId, Vegetation vegetation) async {
    // Insert the vegetation data in the database
    await _vegetationDao.insertVegetation(vegetation);
    
    // Add the vegetation to the list of the provider
    _vegetationMap[inventoryId] = _vegetationMap[inventoryId] ?? [];
    _vegetationMap[inventoryId]!.add(vegetation);

    notifyListeners();
  }

  // Update vegetation in the database and the list
  Future<void> updateVegetation(String inventoryId, Vegetation vegetation) async {
    await _vegetationDao.updateVegetation(vegetation);

    _vegetationMap[inventoryId] = await _vegetationDao.getVegetationByInventory(inventoryId);

    notifyListeners();
  }

  // Remove vegetation record from database and from list
  Future<void> removeVegetation(String inventoryId, int vegetationId) async {
    await _vegetationDao.deleteVegetation(vegetationId);

    final vegetationList = _vegetationMap[inventoryId];
    if (vegetationList != null) {
      vegetationList.removeWhere((v) => v.id == vegetationId);
    }
    notifyListeners();
  }
}