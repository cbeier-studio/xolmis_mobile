import 'package:flutter/material.dart';

import '../data/models/inventory.dart';
import '../data/daos/poi_dao.dart';

/// Manages points of interest linked to species records.
class PoiProvider with ChangeNotifier {
  final PoiDao _poiDao;

  int _allPoisCount = 0;

  PoiProvider(this._poiDao);

  /// Returns the total number of POIs currently known in storage.
  int get allPoisCount => _allPoisCount;

  final Map<int, List<Poi>> _poiMap = {};

  /// Notifies listeners without changing provider state.
  void refreshState() {
    notifyListeners();
  }

  /// More efficient method that only gets the count of POIs.
  Future<void> fetchPoisCount() async {
    _allPoisCount = await _poiDao.countAllPois();
    notifyListeners();
  }

  /// Loads all POIs associated with [speciesId] into the in-memory cache.
  Future<void> loadPoisForSpecies(int speciesId) async {
    try {
      final poiList = await _poiDao.getPoisForSpecies(speciesId);
      _poiMap[speciesId] = poiList;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading POIs for species $speciesId: $e');
    }
  }

  /// Returns the cached POIs for [speciesId].
  List<Poi> getPoisForSpecies(int speciesId) {
    return _poiMap[speciesId] ?? [];
  }

  /// Persists [poi] for [speciesId] and updates the local cache.
  Future<void> addPoi(BuildContext context, int speciesId, Poi poi) async {
    // Insert the POI in the database
    await _poiDao.insertPoi(poi);
    // Add the POI to the list of the provider
    _poiMap[speciesId] = _poiMap[speciesId] ?? [];
    _poiMap[speciesId]!.add(poi);
    notifyListeners();
  }

  /// Updates a POI in storage and replaces the cached item when present.
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

  /// Deletes a POI from storage and removes it from the cached species list.
  Future<void> removePoi(int speciesId, int poiId) async {
    await _poiDao.deletePoi(poiId);

    final poiList = _poiMap[speciesId];
    if (poiList != null) {
      poiList.removeWhere((p) => p.id == poiId);
      notifyListeners();
    }
  }
}