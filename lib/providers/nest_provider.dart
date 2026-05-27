import 'package:flutter/material.dart';
import 'package:xolmis/core/core_consts.dart';

import '../data/models/nest.dart';
import '../data/daos/nest_dao.dart';
import '../generated/l10n.dart';

/// Manages nest records and their cached summaries/details.
class NestProvider with ChangeNotifier {
  final NestDao _nestDao;

  NestProvider(this._nestDao);

  /// All nests currently loaded in memory.
  List<Nest> _nests = [];

  /// Returns every cached nest.
  List<Nest> get nests => _nests;

  /// Active nests that are still being monitored.
  List<Nest> get activeNests => _nests.where((nest) => nest.isActive).toList();

  /// Inactive nests whose monitoring has ended.
  List<Nest> get inactiveNests => _nests.where((nest) => !nest.isActive).toList();

  /// Nests whose fate is recorded as successful.
  List<Nest> get successNests => _nests.where((nest) => nest.nestFate == NestFateType.fatSuccess).toList();

  /// Number of active nests.
  int get nestsCount => activeNests.length;

  /// Number of inactive nests.
  int get inactiveNestsCount => inactiveNests.length;

  /// Total number of cached nests.
  int get allNestsCount => nests.length;

  /// Number of successful nests.
  int get successNestsCount => successNests.length;

  bool _isLoading = false;
  /// Whether the provider is currently fetching nest data.
  bool get isLoading => _isLoading;

  /// Notifies listeners without changing provider state.
  void refreshState() {
    notifyListeners();
  }

  /// Loads lightweight nest summaries without nested child collections.
  Future<void> fetchNestsSummary() async {
    _isLoading = true;
    notifyListeners();

    try {
      final nestsFromDb = await _nestDao.getNestsSummary();
      // Merge with existing in-memory state
      for (var dbNest in nestsFromDb) {
        int? index = _nests.indexWhere((n) => n.id == dbNest.id);
        if (index != -1) {
          // Update counts only
          _nests[index].revisionCount = dbNest.revisionCount;
          _nests[index].eggCount = dbNest.eggCount;
        } else {
          _nests.add(dbNest);
        }
      }
    } catch (e) {
      debugPrint('Error fetching nests summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads complete details for a single nest.
  ///
  /// This is typically used by detail screens and statistics flows that need
  /// revisions and eggs.
  Future<void> loadNestDetails(int nestId) async {
    try {
      final fullNest = await _nestDao.getNestWithDetails(nestId);
      final index = _nests.indexWhere((n) => n.id == nestId);
      if (index != -1) {
        _nests[index] = fullNest;
      } else {
        _nests.add(fullNest);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading nest details: $e');
    }
  }

  /// Loads the full list of nests from persistent storage.
  Future<void> fetchNests() async {
    _nests = await _nestDao.getNests();
    notifyListeners();
  }

  /// Returns all nests matching [speciesName].
  Future<List<Nest>> getNestsBySpecies(String speciesName) async {
    return await _nestDao.getNestsBySpecies(speciesName);
  }

  /// Returns the nest identified by [nestId].
  Future<Nest> getNestById(int nestId) async {
    return await _nestDao.getNestById(nestId);
  }

  /// Returns whether [fieldNumber] is already in use by another nest.
  Future<bool> nestFieldNumberExists(String fieldNumber) async {
    return await _nestDao.nestFieldNumberExists(fieldNumber);
  }

  /// Returns the local numeric ID for the nest identified by [fieldNumber].
  Future<int?> getNestIdByFieldNumber(String fieldNumber) async {
    return await _nestDao.getNestIdByFieldNumber(fieldNumber);
  }

  /// Adds a new nest after validating that its field number is unique.
  Future<void> addNest(Nest nest) async {
    if (await nestFieldNumberExists(nest.fieldNumber!)) {
      throw Exception(S.current.errorNestAlreadyExists);
    }

    await _nestDao.insertNest(nest);
    _nests.add(nest);
    notifyListeners();
  }

  /// Imports an externally sourced nest record.
  ///
  /// When [updateExisting] is `false`, imports that collide by field number are
  /// skipped by the DAO and this method returns `false` for that record.
  /// Returns `true` when the import succeeds and `false` otherwise.
  Future<bool> importNest(
    Nest nest, {
    bool updateExisting = true,
  }) async {
    try {
      final success = await _nestDao.importNest(
        nest,
        updateExisting: updateExisting,
      );
      if (!success) {
        return false;
      }

      final index = _nests.indexWhere((n) => n.id == nest.id);
      if (index != -1) {
        _nests[index] = nest;
      } else {
        _nests.add(nest);
      }
      notifyListeners();

      return true;
    } catch (error) {
      debugPrint('Error importing nest: $error');
      return false;
    }
  }

  /// Updates a nest in storage and replaces the cached instance.
  Future<void> updateNest(Nest nest) async {
    await _nestDao.updateNest(nest);

    final index = _nests.indexWhere((n) => n.id == nest.id);
    if (index != -1) {
      _nests[index] = nest;
      notifyListeners();
    } else {
      debugPrint('Nest with id ${nest.id} not found in the memory list to update.');
    }
  }

  /// Deletes [nest] from storage and removes it from the in-memory list.
  ///
  /// Throws an [ArgumentError] when the nest has no valid identifier.
  Future<void> removeNest(Nest nest) async {
    if (nest.id == null || nest.id! <= 0) {
      throw ArgumentError('Invalid nest ID: ${nest.id}');
    }

    await _nestDao.deleteNest(nest.id!);
    _nests.removeWhere((item) => item.id == nest.id);
    notifyListeners();
  }

  /// Returns the next sequential nest number for the given identifier parts.
  Future<int> getNextSequentialNumber(String acronym, int ano, int mes) async {
    return await _nestDao.getNextSequentialNumber(acronym, ano, mes);
  }

  /// Returns distinct nest localities for autocomplete suggestions.
  Future<List<String>> getDistinctLocalities() {
    return _nestDao.getDistinctLocalities();
  }

  /// Returns distinct nest supports for autocomplete suggestions.
  Future<List<String>> getDistinctSupports() {
    return _nestDao.getDistinctSupports();
  }

  /// Returns distinct species names available in nest records.
  Future<List<String>> getUniqueSpeciesNames() {
    return _nestDao.getUniqueSpeciesNames();
  }

}