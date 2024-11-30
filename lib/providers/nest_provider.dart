import 'package:flutter/material.dart';

import '../data/models/nest.dart';
import '../data/database/repositories/nest_repository.dart';
import '../generated/l10n.dart';

class NestProvider with ChangeNotifier {
  final NestRepository _nestRepository;

  NestProvider(this._nestRepository);

  List<Nest> _nests = [];

  List<Nest> get nests => _nests;

  List<Nest> get activeNests => _nests.where((nest) => nest.isActive).toList();

  List<Nest> get inactiveNests => _nests.where((nest) => !nest.isActive).toList();

  int get nestsCount => activeNests.length;

  Future<void> fetchNests() async {
    _nests = await _nestRepository.getNests();
    notifyListeners();
  }

  Future<bool> nestFieldNumberExists(String fieldNumber) async {
    return await _nestRepository.nestFieldNumberExists(fieldNumber);
  }

  Future<void> addNest(Nest nest) async {
    if (await nestFieldNumberExists(nest.fieldNumber!)) {
      throw Exception(S.current.errorNestAlreadyExists);
    }

    await _nestRepository.insertNest(nest);
    _nests.add(nest);
    notifyListeners();
  }

  Future<void> updateNest(Nest nest) async {
    await _nestRepository.updateNest(nest);

    final index = _nests.indexWhere((n) => n.id == nest.id);
    if (index != -1) {
      _nests[index] = nest;
      notifyListeners();
    } else {
      print('Nest not found in the list');
    }
  }

  Future<void> removeNest(Nest nest) async {
    if (nest.id == null || nest.id! <= 0) {
      throw ArgumentError('Invalid nest ID: ${nest.id}');
    }

    await _nestRepository.deleteNest(nest.id!);
    _nests.remove(nest);
    notifyListeners();
  }

  Future<int> getNextSequentialNumber(String acronym, int ano, int mes) async {
    return await _nestRepository.getNextSequentialNumber(acronym, ano, mes);
  }

  Future<List<String>> getDistinctLocalities() {
    return _nestRepository.getDistinctLocalities();
  }

  Future<List<String>> getDistinctSupports() {
    return _nestRepository.getDistinctSupports();
  }

}