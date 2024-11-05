import '../daos/specimen_dao.dart';
import '../../models/specimen.dart';

class SpecimenRepository {
  final SpecimenDao _specimenDao;

  SpecimenRepository(this._specimenDao);

  Future<int> insertSpecimen(Specimen specimen) {
    return _specimenDao.insertSpecimen(specimen);
  }

  Future<List<Specimen>> getSpecimens() {
    return _specimenDao.getSpecimens();
  }

  Future<int?> updateSpecimen(Specimen specimen) {
    return _specimenDao.updateSpecimen(specimen);
  }

  Future<void> deleteSpecimen(int specimenId) {
    return _specimenDao.deleteSpecimen(specimenId);
  }

  Future<bool> specimenFieldNumberExists(String fieldNumber) {
    return _specimenDao.specimenFieldNumberExists(fieldNumber);
  }

  Future<List<String>> getDistinctLocalities() {
    return _specimenDao.getDistinctLocalities();
  }
}