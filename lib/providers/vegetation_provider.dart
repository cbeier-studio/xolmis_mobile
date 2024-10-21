import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory.dart';
import '../data/database_helper.dart';

class VegetationProvider with ChangeNotifier {
  final Map<String, List<Vegetation>> _vegetationMap = {};

  Future<void> loadVegetationForInventory(String inventoryId) async {
    try {
      final vegetationList = await DatabaseHelper().getVegetationByInventory(inventoryId);
      _vegetationMap[inventoryId] = vegetationList;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading vegetation for inventory $inventoryId: $e');
      }
    }
  }

  List<Vegetation> getVegetationForInventory(String inventoryId) {
    return _vegetationMap[inventoryId] ?? [];
  }

  Future<void> addVegetation(BuildContext context, String inventoryId, Vegetation vegetation) async {
    // Insert the vegetation data in the database
    await DatabaseHelper().insertVegetation(vegetation);

    // Add the POI to the list of the provider
    _vegetationMap[inventoryId] = _vegetationMap[inventoryId] ?? [];
    _vegetationMap[inventoryId]!.add(vegetation);

    notifyListeners();

    (context as Element).markNeedsBuild(); // Force screen to update
  }

  Future<void> removeVegetation(String inventoryId, int vegetationId) async {
    await DatabaseHelper().deleteVegetation(vegetationId);

    final vegetationList = _vegetationMap[inventoryId];
    if (vegetationList != null) {
      vegetationList.removeWhere((v) => v.id == vegetationId);
      notifyListeners();
    }
  }
}