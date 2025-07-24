import '../daos/inventory_dao.dart';
import '../../models/inventory.dart';

class InventoryRepository {
  final InventoryDao _inventoryDao;

  InventoryRepository(this._inventoryDao);

  Future<bool> insertInventory(Inventory inventory) {
    return _inventoryDao.insertInventory(inventory);
  }

  Future<bool> importInventory(Inventory inventory) {
    return _inventoryDao.importInventory(inventory);
  }

  Future<void> deleteInventory(String? inventoryId) {
    return _inventoryDao.deleteInventory(inventoryId);
  }

  Future<void> updateInventory(Inventory inventory) {
    return _inventoryDao.updateInventory(inventory);
  }

  Future<void> updateInventoryElapsedTime(String inventoryId, double elapsedTime) {
    return _inventoryDao.updateInventoryElapsedTime(inventoryId, elapsedTime);
  }

  Future<void> updateInventoryCurrentInterval(String inventoryId, int currentInterval) {
    return _inventoryDao.updateInventoryCurrentInterval(inventoryId, currentInterval);
  }

  Future<void> updateInventoryIntervalsWithoutSpecies(String inventoryId, int intervalsWithoutSpecies) {
    return _inventoryDao.updateInventoryIntervalsWithoutSpecies(inventoryId, intervalsWithoutSpecies);
  }

  Future<void> updateInventoryCurrentIntervalSpeciesCount(String inventoryId, int speciesCount) {
    return _inventoryDao.updateInventoryCurrentIntervalSpeciesCount(inventoryId, speciesCount);
  }

  Future<void> changeInventoryId(String oldId, String newId) {
    return _inventoryDao.changeInventoryId(oldId, newId);
  }

  Future<bool> inventoryIdExists(String id) {
    return _inventoryDao.inventoryIdExists(id);
  }

  Future<int> getActiveInventoriesCount() {
    return _inventoryDao.getActiveInventoriesCount();
  }

  Future<List<Inventory>> getInventories() {
    return _inventoryDao.getInventories();
  }

  Future<Inventory> getInventoryById(String id) {
    return _inventoryDao.getInventoryById(id);
  }

  Future<int> getNextSequentialNumber(String? local, String observer, int ano, int mes, int dia, String? typeChar) {
    return _inventoryDao.getNextSequentialNumber(local, observer, ano, mes, dia, typeChar);
  }

  Future<List<String>> getDistinctLocalities() {
    return _inventoryDao.getDistinctLocalities();
  }
}