import 'package:flutter/material.dart';

import '../data/models/specimen.dart';
import '../data/database/repositories/specimen_repository.dart';

class SpecimenProvider with ChangeNotifier {
  final SpecimenRepository _specimenRepository;

  SpecimenProvider(this._specimenRepository);

  List<Specimen> _specimens = [];

  List<Specimen> get specimens => _specimens;

  int get specimensCount => specimens.length;

  Future<void> fetchSpecimens() async {
    _specimens = await _specimenRepository.getSpecimens();
    notifyListeners();
  }

  Future<bool> specimenFieldNumberExists(String fieldNumber) async {
    return await _specimenRepository.specimenFieldNumberExists(fieldNumber);
  }

  Future<void> addSpecimen(Specimen specimen) async {
    if (await specimenFieldNumberExists(specimen.fieldNumber!)) {
      throw Exception('Já existe um espécime com este número de campo.');
    }

    await _specimenRepository.insertSpecimen(specimen);
    await fetchSpecimens();
  }

  Future<void> updateSpecimen(Specimen specimen) async {
    await _specimenRepository.updateSpecimen(specimen);
    await fetchSpecimens();
    notifyListeners();
  }

  Future<void> removeSpecimen(Specimen specimen) async {
    await _specimenRepository.deleteSpecimen(specimen.id!);
    await fetchSpecimens();
  }

  Future<List<String>> getDistinctLocalities() {
    return _specimenRepository.getDistinctLocalities();
  }
}