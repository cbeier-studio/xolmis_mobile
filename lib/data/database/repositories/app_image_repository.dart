import '../../models/app_image.dart';
import '../daos/app_image_dao.dart';

class AppImageRepository {
  final AppImageDao _appImageDao;

  AppImageRepository(this._appImageDao);

  Future<void> insertImageToVegetation(AppImage appImage, int vegetationId) {
    return _appImageDao.insertImageToVegetation(appImage, vegetationId);
  }

  Future<List<AppImage>> getImagesForVegetation(int vegetationId) {
    return _appImageDao.getImagesForVegetation(vegetationId);
  }

  Future<void> insertImageToNestRevision(AppImage appImage, int revisionId) {
    return _appImageDao.insertImageToNestRevision(appImage, revisionId);
  }

  Future<List<AppImage>> getImagesForNestRevision(int revisionId) {
    return _appImageDao.getImagesForNestRevision(revisionId);
  }

  Future<void> insertImageToEgg(AppImage appImage, int eggId) {
    return _appImageDao.insertImageToEgg(appImage, eggId);
  }

  Future<List<AppImage>> getImagesForEgg(int eggId) {
    return _appImageDao.getImagesForEgg(eggId);
  }

  Future<void> insertImageToSpecimen(AppImage appImage, int specimenId) {
    return _appImageDao.insertImageToSpecimen(appImage, specimenId);
  }

  Future<List<AppImage>> getImagesForSpecimen(int specimenId) {
    return _appImageDao.getImagesForSpecimen(specimenId);
  }

  Future<void> updateImage(AppImage appImage) {
    return _appImageDao.updateImage(appImage);
  }

  Future<void> deleteImage(int appImageId) {
    return _appImageDao.deleteImage(appImageId);
  }
}