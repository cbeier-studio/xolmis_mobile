import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/inventory.dart';
import '../data/database/repositories/vegetation_repository.dart';

class VegetationProvider with ChangeNotifier {
  final VegetationRepository _vegetationRepository;

  VegetationProvider(this._vegetationRepository);

  final Map<String, List<Vegetation>> _vegetationMap = {};

  // Load vegetation records for an inventory ID
  Future<void> loadVegetationForInventory(String inventoryId) async {
    try {
      final vegetationList = await _vegetationRepository.getVegetationByInventory(inventoryId);
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
    await _vegetationRepository.insertVegetation(vegetation);
    
    // Add the vegetation to the list of the provider
    _vegetationMap[inventoryId] = _vegetationMap[inventoryId] ?? [];
    _vegetationMap[inventoryId]!.add(vegetation);

    notifyListeners();
  }

  // Update vegetation in the database and the list
  Future<void> updateVegetation(String inventoryId, Vegetation vegetation) async {
    await _vegetationRepository.updateVegetation(vegetation);

    _vegetationMap[inventoryId] = await _vegetationRepository.getVegetationByInventory(inventoryId);

    notifyListeners();
  }

  // Remove vegetation record from database and from list
  Future<void> removeVegetation(String inventoryId, int vegetationId) async {
    await _vegetationRepository.deleteVegetation(vegetationId);

    final vegetationList = _vegetationMap[inventoryId];
    if (vegetationList != null) {
      vegetationList.removeWhere((v) => v.id == vegetationId);
    }
    notifyListeners();
  }
}