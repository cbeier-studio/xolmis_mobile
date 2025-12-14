import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/inventory.dart';
import '../data/daos/poi_dao.dart';

class PoiProvider with ChangeNotifier {
  final PoiDao _poiDao;

  PoiProvider(this._poiDao);

  final Map<int, List<Poi>> _poiMap = {};

  void refreshState() {
    notifyListeners();
  }

  // Load list of POIs for a species ID
  Future<void> loadPoisForSpecies(int speciesId) async {
    try {
      final poiList = await _poiDao.getPoisForSpecies(speciesId);
      _poiMap[speciesId] = poiList;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading POIs for species $speciesId: $e');
      }
    }
  }

  // Get a POI list for a species
  List<Poi> getPoisForSpecies(int speciesId) {
    return _poiMap[speciesId] ?? [];
  }

  // Add POI to the database and the list
  Future<void> addPoi(BuildContext context, int speciesId, Poi poi) async {
    // Insert the POI in the database
    await _poiDao.insertPoi(poi);
    // Add the POI to the list of the provider
    _poiMap[speciesId] = _poiMap[speciesId] ?? [];
    _poiMap[speciesId]!.add(poi);
    notifyListeners();
  }

  // Update POI in the database and the list
  void updatePoi(int speciesId, Poi poi) async {
    await _poiDao.updatePoi(poi);

    final poiList = _poiMap[speciesId];
    if (poiList != null) {
      final index = poiList.indexWhere((p) => p.id == poi.id);
      if (index != -1) {
        poiList[index] = poi;
        notifyListeners();
      }
    }
  }

  // Remove POI from database and from list
  Future<void> removePoi(int speciesId, int poiId) async {
    await _poiDao.deletePoi(poiId);

    final poiList = _poiMap[speciesId];
    if (poiList != null) {
      poiList.removeWhere((p) => p.id == poiId);
      notifyListeners();
    }
  }
}