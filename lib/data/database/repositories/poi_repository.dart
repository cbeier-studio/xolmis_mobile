import '../../models/inventory.dart';
import '../daos/poi_dao.dart';

class PoiRepository {
  final PoiDao _poiDao;

  PoiRepository(this._poiDao);

  Future<void> insertPoi(Poi poi) {
    return _poiDao.insertPoi(poi);
  }

  Future<List<Poi>> getPoisForSpecies(int speciesId) {
    return _poiDao.getPoisForSpecies(speciesId);
  }

  Future<void> updatePoi(Poi poi) {
    return _poiDao.updatePoi(poi);
  }

  Future<void> deletePoi(int poiId) {
    return _poiDao.deletePoi(poiId);
  }
}