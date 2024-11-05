import '../daos/inventory_dao.dart';
import '../../models/inventory.dart';

class InventoryRepository {
  final InventoryDao _inventoryDao;

  InventoryRepository(this._inventoryDao);

  Future<bool> insertInventory(Inventory inventory) {
    return _inventoryDao.insertInventory(inventory);
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
}