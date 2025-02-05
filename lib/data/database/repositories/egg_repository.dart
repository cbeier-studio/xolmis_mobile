import '../../models/nest.dart';
import '../../database/daos/egg_dao.dart';

class EggRepository {
  final EggDao _eggDao;

  EggRepository(this._eggDao);

  Future<void> insertEgg(Egg egg) {
    return _eggDao.insertEgg(egg);
  }

  Future<List<Egg>> getEggsForNest(int nestId) {
    return _eggDao.getEggsForNest(nestId);
  }

  Future<List<Egg>> getEggsBySpecies(String speciesName) {
    return _eggDao.getEggsBySpecies(speciesName);
  }

  Future<void> updateEgg(Egg egg) {
    return _eggDao.updateEgg(egg);
  }

  Future<void> deleteEgg(int eggId) {
    return _eggDao.deleteEgg(eggId);
  }

  Future<bool> eggFieldNumberExists(String fieldNumber) {
    return _eggDao.eggFieldNumberExists(fieldNumber);
  }

  Future<int> getNextSequentialNumber(String nestFieldNumber) {
    return _eggDao.getNextSequentialNumber(nestFieldNumber);
  }
}