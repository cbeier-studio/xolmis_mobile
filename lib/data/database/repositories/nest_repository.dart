import '../../models/nest.dart';
import '../../database/daos/nest_dao.dart';

class NestRepository {
  final NestDao _nestDao;

  NestRepository(this._nestDao);

  Future<void> insertNest(Nest nest) {
    return _nestDao.insertNest(nest);
  }

  Future<List<Nest>> getNests() {
    return _nestDao.getNests();
  }

  Future<int?> updateNest(Nest nest) {
    return _nestDao.updateNest(nest);
  }

  Future<void> deleteNest(int nestId) {
    return _nestDao.deleteNest(nestId);
  }

  Future<bool> nestFieldNumberExists(String fieldNumber) {
    return _nestDao.nestFieldNumberExists(fieldNumber);
  }
}