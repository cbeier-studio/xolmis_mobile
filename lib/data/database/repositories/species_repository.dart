import '../../models/inventory.dart';
import '../../database/daos/species_dao.dart';

class SpeciesRepository {
  final SpeciesDao _speciesDao;

  SpeciesRepository(this._speciesDao);

  Future<int?> insertSpecies(String inventoryId, Species species) {
    return _speciesDao.insertSpecies(inventoryId, species);
  }

  Future<void> deleteSpeciesFromInventory(String inventoryId, String speciesName) {
    return _speciesDao.deleteSpeciesFromInventory(inventoryId, speciesName);
  }

  Future<Species> getSpeciesById(int id) {
    return _speciesDao.getSpeciesById(id);
  }

  Future<List<Species>> getSpeciesByInventory(String inventoryId) {
    return _speciesDao.getSpeciesByInventory(inventoryId);
  }

  Future<List<Species>> getAllRecordsBySpecies(String speciesName) {
    return _speciesDao.getAllRecordsBySpecies(speciesName);
  }

  Future<void> deleteSpecies(int? speciesId) {
    return _speciesDao.deleteSpecies(speciesId);
  }

  // Future<Species?> getSpeciesByNameAndInventoryId(String name, String inventoryId) {
  //   return _speciesDao.getSpeciesByNameAndInventoryId(name, inventoryId);
  // }

  Future<void> updateSpecies(Species species) {
    return _speciesDao.updateSpecies(species);
  }
}