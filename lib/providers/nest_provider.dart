import 'package:flutter/foundation.dart';

import '../data/models/nest.dart';
import '../data/database/repositories/nest_repository.dart';
import '../generated/l10n.dart';

class NestProvider with ChangeNotifier {
  final NestRepository _nestRepository;

  NestProvider(this._nestRepository);
  // List of all nests
  List<Nest> _nests = [];
  List<Nest> get nests => _nests;
  // Get list of active nests
  List<Nest> get activeNests => _nests.where((nest) => nest.isActive).toList();
  // Get list of inactive nests
  List<Nest> get inactiveNests => _nests.where((nest) => !nest.isActive).toList();
  // Get number of active nests
  int get nestsCount => activeNests.length;

  // Load list of all nests
  Future<void> fetchNests() async {
    _nests = await _nestRepository.getNests();
    notifyListeners();
  }

  // Check if nest field number already exists
  Future<bool> nestFieldNumberExists(String fieldNumber) async {
    return await _nestRepository.nestFieldNumberExists(fieldNumber);
  }

  // Add nest to the database and to the list
  Future<void> addNest(Nest nest) async {
    if (await nestFieldNumberExists(nest.fieldNumber!)) {
      throw Exception(S.current.errorNestAlreadyExists);
    }

    await _nestRepository.insertNest(nest);
    _nests.add(nest);
    notifyListeners();
  }

  // Update nest in the database and the list
  Future<void> updateNest(Nest nest) async {
    await _nestRepository.updateNest(nest);

    final index = _nests.indexWhere((n) => n.id == nest.id);
    if (index != -1) {
      _nests[index] = nest;
      notifyListeners();
    } else {
      if (kDebugMode) {
        print('Nest not found in the list');
      }
    }
  }

  // Remove nest from database and from list
  Future<void> removeNest(Nest nest) async {
    if (nest.id == null || nest.id! <= 0) {
      throw ArgumentError('Invalid nest ID: ${nest.id}');
    }

    await _nestRepository.deleteNest(nest.id!);
    _nests.remove(nest);
    notifyListeners();
  }

  // Get the next field number
  Future<int> getNextSequentialNumber(String acronym, int ano, int mes) async {
    return await _nestRepository.getNextSequentialNumber(acronym, ano, mes);
  }

  // Get list of distinct localities for autocomplete
  Future<List<String>> getDistinctLocalities() {
    return _nestRepository.getDistinctLocalities();
  }

  // Get list of distinct nest supports for autocomplete
  Future<List<String>> getDistinctSupports() {
    return _nestRepository.getDistinctSupports();
  }

}