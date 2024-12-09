import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/models/nest.dart';
import '../data/database/repositories/nest_revision_repository.dart';

class NestRevisionProvider with ChangeNotifier {
  final NestRevisionRepository _nestRevisionRepository;

  NestRevisionProvider(this._nestRevisionRepository);

  final Map<int, List<NestRevision>> _nestRevisionMap = {};

  // Load list of nest revisions for a nest ID
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

  // Get a nest revision from the list
  List<NestRevision> getRevisionForNest(int nestId) {
    return _nestRevisionMap[nestId] ?? [];
  }

  // Add nest revision to the database and the list
  Future<void> addNestRevision(BuildContext context, int nestId, NestRevision nestRevision) async {
    // Insert the nest revision data in the database
    nestRevision.nestId = nestId;
    await _nestRevisionRepository.insertNestRevision(nestRevision);

    // Add the nest revision to the list of the provider
    _nestRevisionMap[nestId] = await _nestRevisionRepository.getNestRevisionsForNest(nestId);

    notifyListeners();
  }

  // Update nestRevision in the database and the list
  Future<void> updateNestRevision(NestRevision nestRevision) async {
    await _nestRevisionRepository.updateNestRevision(nestRevision);

    _nestRevisionMap[nestRevision.nestId!] = await _nestRevisionRepository.getNestRevisionsForNest(nestRevision.nestId!);

    notifyListeners();
  }

  // Remove nest revision from database and from list
  Future<void> removeNestRevision(int nestId, int nestRevisionId) async {
    await _nestRevisionRepository.deleteNestRevision(nestRevisionId);

    _nestRevisionMap[nestId] = await _nestRevisionRepository.getNestRevisionsForNest(nestId);
    notifyListeners();
  }
}