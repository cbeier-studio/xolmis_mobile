import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/inventory.dart';
import '../data/database_helper.dart';

class VegetationProvider with ChangeNotifier {
  final Map<String, List<Vegetation>> _vegetationMap = {};
  GlobalKey<AnimatedListState>? vegetationListKey;

  Future<void> loadVegetationForInventory(String inventoryId) async {
    try {
      final vegetationList = await DatabaseHelper().getVegetationByInventory(inventoryId);
      _vegetationMap[inventoryId] = vegetationList;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading vegetation for inventory $inventoryId: $e');
      }
    } finally {
      notifyListeners();
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

    vegetationListKey?.currentState?.insertItem(
        getVegetationForInventory(inventoryId).length - 1);
    notifyListeners();

    // (context as Element).markNeedsBuild(); // Force screen to update
  }

  Future<void> removeVegetation(String inventoryId, int vegetationId) async {
    await DatabaseHelper().deleteVegetation(vegetationId);

    final vegetationList = _vegetationMap[inventoryId];
    if (vegetationList != null) {
      // listKey.currentState?.removeItem(index, (context, animation) => Container());
      vegetationList.removeWhere((v) => v.id == vegetationId);
    }
    notifyListeners();
  }
}