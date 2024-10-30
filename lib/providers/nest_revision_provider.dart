import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/nest.dart';
import '../data/database/repositories/nest_revision_repository.dart';

class NestRevisionProvider with ChangeNotifier {
  final NestRevisionRepository _nestRevisionRepository;

  NestRevisionProvider(this._nestRevisionRepository);

  final Map<int, List<NestRevision>> _nestRevisionMap = {};
  GlobalKey<AnimatedListState>? revisionListKey;

  Future<void> loadRevisionForNest(int nestId) async {
    try {
      final revisionList = await _nestRevisionRepository.getNestRevisionsForNest(nestId);
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
    // Insert the nest revision data in the database
    nestRevision.nestId = nestId;
    await _nestRevisionRepository.insertNestRevision(nestRevision);

    // Add the nest revision to the list of the provider
    _nestRevisionMap[nestId] = _nestRevisionMap[nestId] ?? [];
    _nestRevisionMap[nestId]!.add(nestRevision);

    revisionListKey?.currentState?.insertItem(
        getRevisionForNest(nestId).length - 1);
    notifyListeners();

    // (context as Element).markNeedsBuild(); // Force screen to update
  }

  Future<void> removeNestRevision(int nestId, int nestRevisionId) async {
    await _nestRevisionRepository.deleteNestRevision(nestRevisionId);

    final revisionList = _nestRevisionMap[nestId];
    if (revisionList != null) {
      // listKey.currentState?.removeItem(index, (context, animation) => Container());
      revisionList.removeWhere((r) => r.id == nestRevisionId);
    }
    notifyListeners();
  }
}