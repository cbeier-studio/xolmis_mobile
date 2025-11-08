import 'package:flutter/foundation.dart';

import '../data/models/specimen.dart';
import '../data/database/daos/specimen_dao.dart';
import '../generated/l10n.dart';

class SpecimenProvider with ChangeNotifier {
  final SpecimenDao _specimenDao;

  SpecimenProvider(this._specimenDao);

  List<Specimen> _specimens = [];
  List<Specimen> get specimens => _specimens;
  // Get list of pending specimens
  List<Specimen> get pendingSpecimens => _specimens.where((specimen) => specimen.isPending).toList();
  // Get list of archived specimens
  List<Specimen> get archivedSpecimens => _specimens.where((specimen) => !specimen.isPending).toList();

  int get specimensCount => pendingSpecimens.length;

  // Load list of all specimens
  Future<void> fetchSpecimens() async {
    _specimens = await _specimenDao.getSpecimens();
    notifyListeners();
  }

  // Get list of specimens by species
  Future<List<Specimen>> getSpecimensBySpecies(String speciesName) async {
    return await _specimenDao.getSpecimensBySpecies(speciesName);
  }

  // Get specimen data by ID
  Future<Specimen> getSpecimenById(int specimenId) async {
    return await _specimenDao.getSpecimenById(specimenId);
  }

  // Check if the specimen field number already exists
  Future<bool> specimenFieldNumberExists(String fieldNumber) async {
    return await _specimenDao.specimenFieldNumberExists(fieldNumber);
  }

  Future<int> getNextSequentialNumber(String acronym, int ano, int mes) async {
    return await _specimenDao.getNextSequentialNumber(acronym, ano, mes);
  }

  // Add specimen to the database and the list
  Future<void> addSpecimen(Specimen specimen) async {
    if (await specimenFieldNumberExists(specimen.fieldNumber)) {
      throw Exception(S.current.errorSpecimenAlreadyExists);
    }

    await _specimenDao.insertSpecimen(specimen);
    _specimens.add(specimen);
    notifyListeners();
  }

  // Add imported specimen to the database and the list
  Future<bool> importSpecimen(Specimen specimen) async {
    try {
      await _specimenDao.importSpecimen(specimen);
      _specimens.add(specimen);
      notifyListeners();

      return true;
    } catch (error) {
      if (kDebugMode) {
        print('Error importing specimen: $error');
      }
      return false;
    }
  }

  // Update specimen in the database and the list
  Future<void> updateSpecimen(Specimen specimen) async {
    await _specimenDao.updateSpecimen(specimen);

    final index = _specimens.indexWhere((n) => n.id == specimen.id);
    if (index != -1) {
      _specimens[index] = specimen;
      notifyListeners();
    } else {
      if (kDebugMode) {
        print('Specimen not found in the list');
      }
    }
  }

  // Remove specimen from database and from list
  Future<void> removeSpecimen(Specimen specimen) async {
    if (specimen.id == null || specimen.id! <= 0) {
      throw ArgumentError('Invalid specimen ID: ${specimen.id}');
    }

    await _specimenDao.deleteSpecimen(specimen.id!);
    _specimens.remove(specimen);
    notifyListeners();
  }

  // Get list of distinct localities for autocomplete
  Future<List<String>> getDistinctLocalities() {
    return _specimenDao.getDistinctLocalities();
  }
}