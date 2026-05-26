import 'package:flutter/material.dart';

import '../data/models/specimen.dart';
import '../data/daos/specimen_dao.dart';
import '../generated/l10n.dart';

/// Manages specimen records loaded from the local database.
class SpecimenProvider with ChangeNotifier {
  final SpecimenDao _specimenDao;

  SpecimenProvider(this._specimenDao);

  List<Specimen> _specimens = [];

  /// All specimen records currently loaded in memory.
  List<Specimen> get specimens => _specimens;

  /// Specimens that are still marked as pending.
  List<Specimen> get pendingSpecimens => _specimens.where((specimen) => specimen.isPending).toList();

  /// Specimens that are no longer pending.
  List<Specimen> get archivedSpecimens => _specimens.where((specimen) => !specimen.isPending).toList();

  /// The number of pending specimens.
  int get specimensCount => pendingSpecimens.length;

  /// Loads all specimen records from persistent storage.
  Future<void> fetchSpecimens() async {
    _specimens = await _specimenDao.getSpecimens();
    notifyListeners();
  }

  /// Returns all specimens matching [speciesName].
  Future<List<Specimen>> getSpecimensBySpecies(String speciesName) async {
    return await _specimenDao.getSpecimensBySpecies(speciesName);
  }

  /// Returns the specimen identified by [specimenId].
  Future<Specimen> getSpecimenById(int specimenId) async {
    return await _specimenDao.getSpecimenById(specimenId);
  }

  /// Returns whether [fieldNumber] is already in use by another specimen.
  Future<bool> specimenFieldNumberExists(String fieldNumber) async {
    return await _specimenDao.specimenFieldNumberExists(fieldNumber);
  }

  /// Returns the next sequential specimen number for the given identifier parts.
  Future<int> getNextSequentialNumber(String acronym, int ano, int mes) async {
    return await _specimenDao.getNextSequentialNumber(acronym, ano, mes);
  }

  /// Adds a new specimen after validating that its field number is unique.
  Future<void> addSpecimen(Specimen specimen) async {
    if (await specimenFieldNumberExists(specimen.fieldNumber)) {
      throw Exception(S.current.errorSpecimenAlreadyExists);
    }

    await _specimenDao.insertSpecimen(specimen);
    _specimens.add(specimen);
    notifyListeners();
  }

  /// Imports a specimen record that already carries external data.
  ///
  /// Returns `true` on success and `false` if the import fails.
  Future<bool> importSpecimen(Specimen specimen) async {
    try {
      await _specimenDao.importSpecimen(specimen);
      _specimens.add(specimen);
      notifyListeners();

      return true;
    } catch (error) {
      debugPrint('Error importing specimen: $error');
      return false;
    }
  }

  /// Updates a specimen in storage and replaces the cached instance.
  Future<void> updateSpecimen(Specimen specimen) async {
    await _specimenDao.updateSpecimen(specimen);

    final index = _specimens.indexWhere((n) => n.id == specimen.id);
    if (index != -1) {
      _specimens[index] = specimen;
      notifyListeners();
    } else {
      debugPrint('Specimen not found in the list');
    }
  }

  /// Deletes [specimen] from storage and removes it from the cache.
  ///
  /// Throws an [ArgumentError] when the specimen has no valid identifier.
  Future<void> removeSpecimen(Specimen specimen) async {
    if (specimen.id == null || specimen.id! <= 0) {
      throw ArgumentError('Invalid specimen ID: ${specimen.id}');
    }

    await _specimenDao.deleteSpecimen(specimen.id!);
    _specimens.removeWhere((item) => item.id == specimen.id);
    notifyListeners();
  }

  /// Returns distinct specimen localities for autocomplete suggestions.
  Future<List<String>> getDistinctLocalities() {
    return _specimenDao.getDistinctLocalities();
  }
}