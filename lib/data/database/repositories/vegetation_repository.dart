import '../../models/inventory.dart';
import '../daos/vegetation_dao.dart';

class VegetationRepository {
  final VegetationDao _vegetationDao;

  VegetationRepository(this._vegetationDao);

  Future<int?> insertVegetation(Vegetation vegetation) {
    return _vegetationDao.insertVegetation(vegetation);
  }

  Future<void> updateVegetation(Vegetation vegetation) {
    return _vegetationDao.updateVegetation(vegetation);
  }

  Future<void> deleteVegetation(int? vegetationId) {
    return _vegetationDao.deleteVegetation(vegetationId);
  }

  Future<List<Vegetation>> getVegetationByInventory(String inventoryId) {
    return _vegetationDao.getVegetationByInventory(inventoryId);
  }
}