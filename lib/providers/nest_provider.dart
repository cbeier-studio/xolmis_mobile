import 'package:flutter/material.dart';
import '../models/nest.dart';
import '../models/database_helper.dart';

class NestProvider with ChangeNotifier {
  List<Nest> _nests = [];
  DatabaseHelper _dbHelper = DatabaseHelper();

  List<Nest> get nests => _nests;

  List<Nest> get activeNests =>
      _nests.where((nest) => nest.isActive).toList();

  List<Nest> get inactiveNests =>
      _nests.where((nest) => !nest.isActive).toList();

  int get nestsCount => activeNests.length;

  Future<void> fetchNests() async {
    _nests = await _dbHelper.getNests();
    notifyListeners();
  }

  Future<bool> nestFieldNumberExists(String fieldNumber) async {
    return await DatabaseHelper().nestFieldNumberExists(fieldNumber);
  }

  Future<void> addNest(Nest nest) async {
    if (await nestFieldNumberExists(nest.fieldNumber!)) {
      throw Exception('Já existe um ninho com este número de campo.');
    }

    await _dbHelper.insertNest(nest);
    await fetchNests();
  }

  Future<void> updateNest(Nest nest) async {
    await _dbHelper.updateNest(nest);
    await fetchNests();
    notifyListeners();
  }

  Future<void> removeNest(Nest nest) async {
    await _dbHelper.deleteNest(nest.id!);
    await fetchNests();
  }

// ... outros métodos para atualizar, excluir, etc. ...
}