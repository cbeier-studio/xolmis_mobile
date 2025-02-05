import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/nest.dart';
import '../data/database/repositories/egg_repository.dart';
import '../generated/l10n.dart';

class EggProvider with ChangeNotifier {
  final EggRepository _eggRepository;

  EggProvider(this._eggRepository);

  final Map<int, List<Egg>> _eggMap = {};

  // Load list of eggs for a nest ID
  Future<void> loadEggForNest(int nestId) async {
    try {
      final eggList = await _eggRepository.getEggsForNest(nestId);
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
    return await _eggRepository.getEggsBySpecies(speciesName);
  }

  // Check if the egg field number already exists
  Future<bool> eggFieldNumberExists(String fieldNumber) async {
    return await _eggRepository.eggFieldNumberExists(fieldNumber);
  }

  Future<int> getNextSequentialNumber(String nestFieldNumber) async {
    return await _eggRepository.getNextSequentialNumber(nestFieldNumber);
  }

  // Insert egg into database and to the list
  Future<void> addEgg(BuildContext context, int nestId, Egg egg) async {
    if (await eggFieldNumberExists(egg.fieldNumber!)) {
      throw Exception(S.current.errorEggAlreadyExists);
    }

    // Insert the egg in the database
    egg.nestId = nestId;
    await _eggRepository.insertEgg(egg); // Usar o repositório

    // Add the egg to the list of the provider
    _eggMap[nestId] = await _eggRepository.getEggsForNest(nestId);
    // _eggMap[nestId] = _eggMap[nestId] ?? [];
    // _eggMap[nestId]!.add(egg);

    notifyListeners();
  }

  // Update egg in the database and the list
  Future<void> updateEgg(Egg egg) async {
    await _eggRepository.updateEgg(egg);

    _eggMap[egg.nestId!] = await _eggRepository.getEggsForNest(egg.nestId!);

    notifyListeners();
  }

  // Remove egg from database and from list
  Future<void> removeEgg(int nestId, int eggId) async {
    await _eggRepository.deleteEgg(eggId);

    _eggMap[nestId] = await _eggRepository.getEggsForNest(nestId);
    // final eggList = _eggMap[nestId];
    // if (eggList != null) {
    //   eggList.removeWhere((e) => e.id == eggId);
    // }
    notifyListeners();
  }
}