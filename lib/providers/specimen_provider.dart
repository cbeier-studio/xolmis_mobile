import 'package:flutter/material.dart';
import '../models/specimen.dart';
import '../models/database_helper.dart';

class SpecimenProvider with ChangeNotifier {
  List<Specimen> _specimens = [];
  DatabaseHelper _dbHelper = DatabaseHelper();

  List<Specimen> get specimens => _specimens;

  int get specimensCount => specimens.length;

  Future<void> fetchSpecimens() async {
    _specimens = await _dbHelper.getSpecimens();
    notifyListeners();
  }

  Future<bool> specimenFieldNumberExists(String fieldNumber) async {
    return await DatabaseHelper().specimenFieldNumberExists(fieldNumber);
  }

  Future<void> addSpecimen(Specimen specimen) async {
    if (await specimenFieldNumberExists(specimen.fieldNumber!)) {
      throw Exception('Já existe um espécime com este número de campo.');
    }

    await _dbHelper.insertSpecimen(specimen);
    await fetchSpecimens();
  }

  Future<void> updateSpecimen(Specimen specimen) async {
    await _dbHelper.updateSpecimen(specimen);
    await fetchSpecimens();
    notifyListeners();
  }

  Future<void> removeSpecimen(Specimen specimen) async {
    await _dbHelper.deleteSpecimen(specimen.id!);
    await fetchSpecimens();
  }

// ... outros métodos para atualizar, excluir, etc. ...
}