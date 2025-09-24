import '../daos/specimen_dao.dart';
import '../../models/specimen.dart';

class SpecimenRepository {
  final SpecimenDao _specimenDao;

  SpecimenRepository(this._specimenDao);

  Future<int> insertSpecimen(Specimen specimen) {
    return _specimenDao.insertSpecimen(specimen);
  }

  Future<bool> importSpecimen(Specimen specimen) {
    return _specimenDao.importSpecimen(specimen);
  }

  Future<List<Specimen>> getSpecimens() {
    return _specimenDao.getSpecimens();
  }

  Future<Specimen> getSpecimenById(int specimenId) {
    return _specimenDao.getSpecimenById(specimenId);
  }

  Future<List<Specimen>> getSpecimensByType(SpecimenType type) {
    return _specimenDao.getSpecimensByType(type);
  }

  Future<List<Specimen>> getSpecimensBySpecies(String speciesName) {
    return _specimenDao.getSpecimensBySpecies(speciesName);
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

  Future<int> getNextSequentialNumber(String acronym, int ano, int mes) {
    return _specimenDao.getNextSequentialNumber(acronym, ano, mes);
  }

  Future<List<String>> getDistinctLocalities() {
    return _specimenDao.getDistinctLocalities();
  }
}