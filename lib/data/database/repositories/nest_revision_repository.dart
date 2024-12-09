import '../../models/nest.dart';
import '../daos/nest_revision_dao.dart';

class NestRevisionRepository {
  final NestRevisionDao _nestRevisionDao;

  NestRevisionRepository(this._nestRevisionDao);

  Future<void> insertNestRevision(NestRevision nestRevision) {
    return _nestRevisionDao.insertNestRevision(nestRevision);
  }

  Future<List<NestRevision>> getNestRevisionsForNest(int nestId) {
    return _nestRevisionDao.getNestRevisionsForNest(nestId);
  }

  Future<void> updateNestRevision(NestRevision nestRevision) {
    return _nestRevisionDao.updateNestRevision(nestRevision);
  }

  Future<void> deleteNestRevision(int nestRevisionId) {
    return _nestRevisionDao.deleteNestRevision(nestRevisionId);
  }
}