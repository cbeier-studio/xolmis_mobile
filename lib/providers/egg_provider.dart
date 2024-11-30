import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/nest.dart';
import '../data/database/repositories/egg_repository.dart';
import '../generated/l10n.dart';

class EggProvider with ChangeNotifier {
  final EggRepository _eggRepository;

  EggProvider(this._eggRepository);

  final Map<int, List<Egg>> _eggMap = {};

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

  List<Egg> getEggForNest(int nestId) {
    return _eggMap[nestId] ?? [];
  }

  Future<bool> eggFieldNumberExists(String fieldNumber) async {
    return await _eggRepository.eggFieldNumberExists(fieldNumber);
  }

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