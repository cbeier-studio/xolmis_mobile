import 'package:flutter/foundation.dart';

import '../data/models/nest.dart';
import '../data/database/daos/nest_dao.dart';
import '../generated/l10n.dart';

class NestProvider with ChangeNotifier {
  final NestDao _nestDao;

  NestProvider(this._nestDao);
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
    _nests = await _nestDao.getNests();
    notifyListeners();
  }

  // Get list of nests by species
  Future<List<Nest>> getNestsBySpecies(String speciesName) async {
    return await _nestDao.getNestsBySpecies(speciesName);
  }

  // Get nest data by ID
  Future<Nest> getNestById(int nestId) async {
    return await _nestDao.getNestById(nestId);
  }

  // Check if nest field number already exists
  Future<bool> nestFieldNumberExists(String fieldNumber) async {
    return await _nestDao.nestFieldNumberExists(fieldNumber);
  }

  // Add nest to the database and to the list
  Future<void> addNest(Nest nest) async {
    if (await nestFieldNumberExists(nest.fieldNumber!)) {
      throw Exception(S.current.errorNestAlreadyExists);
    }

    await _nestDao.insertNest(nest);
    _nests.add(nest);
    notifyListeners();
  }

  // Add imported nest to the database and the list
  Future<bool> importNest(Nest nest) async {
    try {
      await _nestDao.importNest(nest);
      _nests.add(nest);
      notifyListeners();

      return true;
    } catch (error) {
      if (kDebugMode) {
        print('Error importing nest: $error');
      }
      return false;
    }
  }

  // Update nest in the database and the list
  Future<void> updateNest(Nest nest) async {
    await _nestDao.updateNest(nest);

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

    await _nestDao.deleteNest(nest.id!);
    _nests.remove(nest);
    notifyListeners();
  }

  // Get the next field number
  Future<int> getNextSequentialNumber(String acronym, int ano, int mes) async {
    return await _nestDao.getNextSequentialNumber(acronym, ano, mes);
  }

  // Get list of distinct localities for autocomplete
  Future<List<String>> getDistinctLocalities() {
    return _nestDao.getDistinctLocalities();
  }

  // Get list of distinct nest supports for autocomplete
  Future<List<String>> getDistinctSupports() {
    return _nestDao.getDistinctSupports();
  }

}