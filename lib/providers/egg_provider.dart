import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/nest.dart';
import '../data/database/daos/egg_dao.dart';
import '../generated/l10n.dart';

class EggProvider with ChangeNotifier {
  final EggDao _eggDao;

  EggProvider(this._eggDao);

  final Map<int, List<Egg>> _eggMap = {};

  // Load list of eggs for a nest ID
  Future<void> loadEggForNest(int nestId) async {
    try {
      final eggList = await _eggDao.getEggsForNest(nestId);
      _eggMap[nestId] = eggList;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading eggs for nest $nestId: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  // Get an egg for a nest from the list
  List<Egg> getEggForNest(int nestId) {
    return _eggMap[nestId] ?? [];
  }

  // Get list of eggs by species
  Future<List<Egg>> getEggsBySpecies(String speciesName) async {
    return await _eggDao.getEggsBySpecies(speciesName);
  }

  // Check if the egg field number already exists
  Future<bool> eggFieldNumberExists(String fieldNumber) async {
    return await _eggDao.eggFieldNumberExists(fieldNumber);
  }

  Future<int> getNextSequentialNumber(String nestFieldNumber) async {
    return await _eggDao.getNextSequentialNumber(nestFieldNumber);
  }

  // Insert egg into database and to the list
  Future<void> addEgg(BuildContext context, int nestId, Egg egg) async {
    if (await eggFieldNumberExists(egg.fieldNumber!)) {
      throw Exception(S.current.errorEggAlreadyExists);
    }

    // Insert the egg in the database
    egg.nestId = nestId;
    await _eggDao.insertEgg(egg); // Usar o repositório

    // Add the egg to the list of the provider
    _eggMap[nestId] = await _eggDao.getEggsForNest(nestId);
    // _eggMap[nestId] = _eggMap[nestId] ?? [];
    // _eggMap[nestId]!.add(egg);

    notifyListeners();
  }

  // Update egg in the database and the list
  Future<void> updateEgg(Egg egg) async {
    await _eggDao.updateEgg(egg);

    _eggMap[egg.nestId!] = await _eggDao.getEggsForNest(egg.nestId!);

    notifyListeners();
  }

  // Remove egg from database and from list
  Future<void> removeEgg(int nestId, int eggId) async {
    await _eggDao.deleteEgg(eggId);

    _eggMap[nestId] = await _eggDao.getEggsForNest(nestId);
    // final eggList = _eggMap[nestId];
    // if (eggList != null) {
    //   eggList.removeWhere((e) => e.id == eggId);
    // }
    notifyListeners();
  }
}