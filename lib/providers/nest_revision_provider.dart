import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../data/models/nest.dart';
import '../data/daos/nest_revision_dao.dart';
import 'nest_provider.dart';

/// Manages nest revisions grouped by nest identifier.
class NestRevisionProvider with ChangeNotifier {
  final NestRevisionDao _nestRevisionDao;

  NestRevisionProvider(this._nestRevisionDao);

  final Map<int, List<NestRevision>> _nestRevisionMap = {};

  /// Notifies listeners without changing provider state.
  void refreshState() {
    notifyListeners();
  }

  /// Loads all revisions associated with [nestId] into the cache.
  Future<void> loadRevisionForNest(int nestId) async {
    try {
      final revisionList = await _nestRevisionDao.getNestRevisionsForNest(nestId);
      _nestRevisionMap[nestId] = revisionList;
    } catch (e) {
      debugPrint('Error loading revisions for nest $nestId: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Returns the cached revisions for [nestId].
  List<NestRevision> getRevisionForNest(int nestId) {
    return _nestRevisionMap[nestId] ?? [];
  }

  /// Persists [nestRevision] for [nestId] and refreshes related provider state.
  Future<void> addNestRevision(BuildContext context, int nestId, NestRevision nestRevision) async {
    // Insert the nest revision data in the database
    nestRevision.nestId = nestId;
    await _nestRevisionDao.insertNestRevision(nestRevision);

    // Add the nest revision to the list of the provider
    final fullList = await _nestRevisionDao.getNestRevisionsForNest(nestId);
    _nestRevisionMap[nestId] = fullList;

    final nestProvider = Provider.of<NestProvider>(context, listen: false);
    final nestIndex = nestProvider.nests.indexWhere((nest) => nest.id == nestId);
    if (nestIndex != -1) {
      final nest = nestProvider.nests[nestIndex];
      nest.revisionsList = fullList; 
      nest.revisionCount = fullList.length;
      nest.updateLastNestStatus();
      nestProvider.refreshState();
    }

    notifyListeners();
  }

  /// Updates a nest revision in storage and synchronizes cached nest details.
  Future<void> updateNestRevision(BuildContext context, NestRevision nestRevision) async {
    await _nestRevisionDao.updateNestRevision(nestRevision);

    final nestId = nestRevision.nestId!;
    final fullList = await _nestRevisionDao.getNestRevisionsForNest(nestId);
    _nestRevisionMap[nestId] = fullList;

    final nestProvider = Provider.of<NestProvider>(context, listen: false);
    final nestIndex = nestProvider.nests.indexWhere((nest) => nest.id == nestId);
    if (nestIndex != -1) {
      final nest = nestProvider.nests[nestIndex];
      nest.revisionsList = fullList;
      nest.updateLastNestStatus();
      nestProvider.refreshState();
    }

    notifyListeners();
  }

  /// Deletes a nest revision from storage and refreshes the cached nest data.
  Future<void> removeNestRevision(BuildContext context, int nestId, int nestRevisionId) async {
    await _nestRevisionDao.deleteNestRevision(nestRevisionId);

    final fullList = await _nestRevisionDao.getNestRevisionsForNest(nestId);
    _nestRevisionMap[nestId] = fullList;

    final nestProvider = Provider.of<NestProvider>(context, listen: false);
    final nestIndex = nestProvider.nests.indexWhere((nest) => nest.id == nestId);
    if (nestIndex != -1) {
      final nest = nestProvider.nests[nestIndex];
      nest.revisionsList = fullList;
      nest.revisionCount = fullList.length;
      nest.updateLastNestStatus();
      nestProvider.refreshState();
    }

    notifyListeners();
  }
}