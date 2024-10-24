import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/nest.dart';
import '../models/database_helper.dart';

class NestRevisionProvider with ChangeNotifier {
  final Map<int, List<NestRevision>> _nestRevisionMap = {};
  GlobalKey<AnimatedListState>? revisionListKey;

  Future<void> loadRevisionForNest(int nestId) async {
    try {
      final revisionList = await DatabaseHelper().getNestRevisionsForNest(nestId);
      _nestRevisionMap[nestId] = revisionList;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading revisions for nest $nestId: $e');
      }
    } finally {
      notifyListeners();
    }
  }

  List<NestRevision> getRevisionForNest(int nestId) {
    return _nestRevisionMap[nestId] ?? [];
  }

  Future<void> addNestRevision(BuildContext context, int nestId, NestRevision nestRevision) async {
    // Insert the vegetation data in the database
    await DatabaseHelper().insertNestRevision(nestRevision);

    // Add the POI to the list of the provider
    _nestRevisionMap[nestId] = _nestRevisionMap[nestId] ?? [];
    _nestRevisionMap[nestId]!.add(nestRevision);

    revisionListKey?.currentState?.insertItem(
        getRevisionForNest(nestId).length - 1);
    notifyListeners();

    // (context as Element).markNeedsBuild(); // Force screen to update
  }

  Future<void> removeNestRevision(int nestId, int nestRevisionId) async {
    await DatabaseHelper().deleteNestRevision(nestRevisionId);

    final revisionList = _nestRevisionMap[nestId];
    if (revisionList != null) {
      // listKey.currentState?.removeItem(index, (context, animation) => Container());
      revisionList.removeWhere((r) => r.id == nestRevisionId);
    }
    notifyListeners();
  }
}