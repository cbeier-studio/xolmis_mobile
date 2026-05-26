import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/nest.dart';
import '../data/daos/egg_dao.dart';
import '../generated/l10n.dart';

/// Manages egg records grouped by nest and keeps UI listeners synchronized.
class EggProvider with ChangeNotifier {
  final EggDao _eggDao;

  EggProvider(this._eggDao);

  final Map<int, List<Egg>> _eggMap = {};

  /// Notifies listeners without reloading any data.
  void refreshState() {
    notifyListeners();
  }

  /// Returns all eggs stored in the database.
  ///
  /// An empty list is returned if loading fails.
  Future<List<Egg>> getAllEggs() async {
    try {
      final eggList = await _eggDao.getAllEggs();
      return eggList;
    } catch (e) {
      debugPrint('Error loading all eggs: $e');
      return [];
    }
  }

  /// Loads all eggs associated with [nestId] into the in-memory cache.
  Future<void> loadEggForNest(int nestId) async {
    try {
      final eggList = await _eggDao.getEggsForNest(nestId);
      _eggMap[nestId] = eggList;
    } catch (e) {
      debugPrint('Error loading eggs for nest $nestId: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Returns the cached eggs for [nestId].
  List<Egg> getEggForNest(int nestId) {
    return _eggMap[nestId] ?? [];
  }

  /// Returns all egg records matching [speciesName].
  Future<List<Egg>> getEggsBySpecies(String speciesName) async {
    return await _eggDao.getEggsBySpecies(speciesName);
  }

  /// Returns whether [fieldNumber] is already in use by another egg record.
  Future<bool> eggFieldNumberExists(String fieldNumber) async {
    return await _eggDao.eggFieldNumberExists(fieldNumber);
  }

  /// Returns the next sequential egg number for a nest field number prefix.
  Future<int> getNextSequentialNumber(String nestFieldNumber) async {
    return await _eggDao.getNextSequentialNumber(nestFieldNumber);
  }

  /// Adds [egg] to [nestId] after validating its field number uniqueness.
  Future<void> addEgg(BuildContext context, int nestId, Egg egg) async {
    if (await eggFieldNumberExists(egg.fieldNumber!)) {
      throw Exception(S.current.errorEggAlreadyExists);
    }

    // Insert the egg in the database
    egg.nestId = nestId;
    await _eggDao.insertEgg(egg);

    // Add the egg to the list of the provider
    _eggMap[nestId] = await _eggDao.getEggsForNest(nestId);

    notifyListeners();
  }

  /// Updates an egg record in persistent storage and refreshes the nest cache.
  Future<void> updateEgg(Egg egg) async {
    await _eggDao.updateEgg(egg);

    _eggMap[egg.nestId!] = await _eggDao.getEggsForNest(egg.nestId!);

    notifyListeners();
  }

  /// Removes an egg record from the database and refreshes the nest cache.
  Future<void> removeEgg(int nestId, int eggId) async {
    await _eggDao.deleteEgg(eggId);

    _eggMap[nestId] = await _eggDao.getEggsForNest(nestId);

    notifyListeners();
  }
}