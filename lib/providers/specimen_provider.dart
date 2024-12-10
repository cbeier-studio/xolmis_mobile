import 'package:flutter/foundation.dart';

import '../data/models/specimen.dart';
import '../data/database/repositories/specimen_repository.dart';
import '../generated/l10n.dart';

class SpecimenProvider with ChangeNotifier {
  final SpecimenRepository _specimenRepository;

  SpecimenProvider(this._specimenRepository);

  List<Specimen> _specimens = [];
  List<Specimen> get specimens => _specimens;

  int get specimensCount => specimens.length;

  // Load list of all specimens
  Future<void> fetchSpecimens() async {
    _specimens = await _specimenRepository.getSpecimens();
    notifyListeners();
  }

  // Check if the specimen field number already exists
  Future<bool> specimenFieldNumberExists(String fieldNumber) async {
    return await _specimenRepository.specimenFieldNumberExists(fieldNumber);
  }

  Future<int> getNextSequentialNumber(String acronym, int ano, int mes) async {
    return await _specimenRepository.getNextSequentialNumber(acronym, ano, mes);
  }

  // Add specimen to the database and the list
  Future<void> addSpecimen(Specimen specimen) async {
    if (await specimenFieldNumberExists(specimen.fieldNumber)) {
      throw Exception(S.current.errorSpecimenAlreadyExists);
    }

    await _specimenRepository.insertSpecimen(specimen);
    _specimens.add(specimen);
    notifyListeners();
  }

  // Update specimen in the database and the list
  Future<void> updateSpecimen(Specimen specimen) async {
    await _specimenRepository.updateSpecimen(specimen);

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

    await _specimenRepository.deleteSpecimen(specimen.id!);
    _specimens.remove(specimen);
    notifyListeners();
  }

  // Get list of distinct localities for autocomplete
  Future<List<String>> getDistinctLocalities() {
    return _specimenRepository.getDistinctLocalities();
  }
}