import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/inventory.dart';
import '../data/database/repositories/poi_repository.dart';

class PoiProvider with ChangeNotifier {
  final PoiRepository _poiRepository;

  PoiProvider(this._poiRepository);

  final Map<int, List<Poi>> _poiMap = {};

  Future<void> loadPoisForSpecies(int speciesId) async {
    try {
      final poiList = await _poiRepository.getPoisForSpecies(speciesId);
      _poiMap[speciesId] = poiList;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading POIs for species $speciesId: $e');
      }
    }
  }

  List<Poi> getPoisForSpecies(int speciesId) {
    return _poiMap[speciesId] ?? [];
  }

  Future<void> addPoi(BuildContext context, int speciesId, Poi poi) async {
    // Insert the POI in the database
    await _poiRepository.insertPoi(poi);
    // Add the POI to the list of the provider
    _poiMap[speciesId] = _poiMap[speciesId] ?? [];
    _poiMap[speciesId]!.add(poi);
    notifyListeners();

    // (context as Element).markNeedsBuild(); // Force screen to update
  }

  void updatePoi(int speciesId, Poi poi) async {
    await _poiRepository.updatePoi(poi);

    final poiList = _poiMap[speciesId];
    if (poiList != null) {
      final index = poiList.indexWhere((p) => p.id == poi.id);
      if (index != -1) {
        poiList[index] = poi;
        notifyListeners();
      }
    }
  }

  Future<void> removePoi(int speciesId, int poiId) async {
    await _poiRepository.deletePoi(poiId);

    final poiList = _poiMap[speciesId];
    if (poiList != null) {
      poiList.removeWhere((p) => p.id == poiId);
      notifyListeners();
    }
  }
}