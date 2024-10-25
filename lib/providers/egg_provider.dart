import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/nest.dart';
import '../models/database_helper.dart';

class EggProvider with ChangeNotifier {
  final Map<int, List<Egg>> _eggMap = {};
  GlobalKey<AnimatedListState>? eggListKey;

  Future<void> loadEggForNest(int nestId) async {
    try {
      final eggList = await DatabaseHelper().getEggsForNest(nestId);
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

  Future<void> addEgg(BuildContext context, int nestId, Egg egg) async {
    // Insert the egg in the database
    egg.nestId = nestId;
    await DatabaseHelper().insertEgg(egg);

    // Add the egg to the list of the provider
    _eggMap[nestId] = _eggMap[nestId] ?? [];
    _eggMap[nestId]!.add(egg);

    eggListKey?.currentState?.insertItem(
        getEggForNest(nestId).length - 1);
    notifyListeners();

    // (context as Element).markNeedsBuild(); // Force screen to update
  }

  Future<void> removeEgg(int nestId, int eggId) async {
    await DatabaseHelper().deleteEgg(eggId);

    final eggList = _eggMap[nestId];
    if (eggList != null) {
      // listKey.currentState?.removeItem(index, (context, animation) => Container());
      eggList.removeWhere((e) => e.id == eggId);
    }
    notifyListeners();
  }
}