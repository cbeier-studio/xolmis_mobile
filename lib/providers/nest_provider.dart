import 'package:flutter/material.dart';

import '../data/models/nest.dart';
import '../data/database/repositories/nest_repository.dart';

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
      throw Exception('Já existe um ninho com este número de campo.');
    }

    await _nestRepository.insertNest(nest);
    await fetchNests();
  }

  Future<void> updateNest(Nest nest) async {
    await _nestRepository.updateNest(nest);
    await fetchNests();
    notifyListeners();
  }

  Future<void> removeNest(Nest nest) async {
    await _nestRepository.deleteNest(nest.id!);
    await fetchNests();
  }

}