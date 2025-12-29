import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/nest.dart';
import '../data/daos/nest_revision_dao.dart';
import 'nest_provider.dart';

class NestRevisionProvider with ChangeNotifier {
  final NestRevisionDao _nestRevisionDao;

  NestRevisionProvider(this._nestRevisionDao);

  final Map<int, List<NestRevision>> _nestRevisionMap = {};

  void refreshState() {
    notifyListeners();
  }

  // Load list of nest revisions for a nest ID
  Future<void> loadRevisionForNest(int nestId) async {
    try {
      final revisionList = await _nestRevisionDao.getNestRevisionsForNest(nestId);
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
    await _nestRevisionDao.insertNestRevision(nestRevision);

    final nestProvider = Provider.of<NestProvider>(context, listen: false);
    nestProvider.nests.firstWhere((nest) => nest.id == nestId).revisionsList?.add(nestRevision); 

    // Add the nest revision to the list of the provider
    _nestRevisionMap[nestId] = await _nestRevisionDao.getNestRevisionsForNest(nestId);

    notifyListeners();
  }

  // Update nestRevision in the database and the list
  Future<void> updateNestRevision(BuildContext context, NestRevision nestRevision) async {
    await _nestRevisionDao.updateNestRevision(nestRevision);

    final nestProvider = Provider.of<NestProvider>(context, listen: false);
    nestProvider.nests.firstWhere((nest) => nest.id == nestRevision.nestId).revisionsList?.removeWhere((r) => r.id == nestRevision.id);
    nestProvider.nests.firstWhere((nest) => nest.id == nestRevision.nestId).revisionsList?.add(nestRevision);

    _nestRevisionMap[nestRevision.nestId!] = await _nestRevisionDao.getNestRevisionsForNest(nestRevision.nestId!);

    notifyListeners();
  }

  // Remove nest revision from database and from list
  Future<void> removeNestRevision(BuildContext context, int nestId, int nestRevisionId) async {
    await _nestRevisionDao.deleteNestRevision(nestRevisionId);

    final nestProvider = Provider.of<NestProvider>(context, listen: false);
    nestProvider.nests.firstWhere((nest) => nest.id == nestId).revisionsList?.removeWhere((r) => r.id == nestRevisionId);

    _nestRevisionMap[nestId] = await _nestRevisionDao.getNestRevisionsForNest(nestId);
    notifyListeners();
  }
}