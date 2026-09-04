import 'dart:io';
import 'package:material_ui/material_ui.dart';
import '../data/models/app_image.dart';
import '../data/daos/app_image_dao.dart';

/// Manages image records linked to field entities and keeps listeners updated.
class AppImageProvider with ChangeNotifier {
  final AppImageDao _appImageDao;
  List<AppImage> _images = [];

  AppImageProvider(this._appImageDao);

  /// Returns the images currently loaded into memory.
  List<AppImage> get images => _images;

  /// Notifies listeners without changing provider state.
  void refreshState() {
    notifyListeners();
  }

  /// Loads all images associated with a vegetation record.
  Future<List<AppImage>> fetchImagesForVegetation(int vegetationId, {bool notify = true}) async {
    final result = await _appImageDao.getImagesForVegetation(vegetationId);
    if (notify) {
      _images = result;
      notifyListeners();
    }
    return result;
  }

  /// Persists [appImage] for a vegetation record and refreshes the local cache.
  Future<void> addImageToVegetation(AppImage appImage, int vegetationId) async {
    await _appImageDao.insertImageToVegetation(appImage, vegetationId);
    await fetchImagesForVegetation(vegetationId);
  }

  /// Loads all images associated with a nest revision.
  Future<List<AppImage>> fetchImagesForNestRevision(int revisionId, {bool notify = true}) async {
    final result = await _appImageDao.getImagesForNestRevision(revisionId);
    if (notify) {
      _images = result;
      notifyListeners();
    }
    return result;
  }

  /// Persists [appImage] for a nest revision and refreshes the local cache.
  Future<void> addImageToNestRevision(AppImage appImage, int revisionId) async {
    await _appImageDao.insertImageToNestRevision(appImage, revisionId);
    await fetchImagesForNestRevision(revisionId);
  }

  /// Loads all images associated with an egg record.
  Future<List<AppImage>> fetchImagesForEgg(int eggId, {bool notify = true}) async {
    final result = await _appImageDao.getImagesForEgg(eggId);
    if (notify) {
      _images = result;
      notifyListeners();
    }
    return result;
  }

  /// Persists [appImage] for an egg record and refreshes the local cache.
  Future<void> addImageToEgg(AppImage appImage, int eggId) async {
    await _appImageDao.insertImageToEgg(appImage, eggId);
    await fetchImagesForEgg(eggId);
  }

  /// Loads all images associated with a specimen record.
  Future<List<AppImage>> fetchImagesForSpecimen(int specimenId, {bool notify = true}) async {
    final result = await _appImageDao.getImagesForSpecimen(specimenId);
    if (notify) {
      _images = result;
      notifyListeners();
    }
    return result;
  }

  /// Persists [appImage] for a specimen record and refreshes the local cache.
  Future<void> addImageToSpecimen(AppImage appImage, int specimenId) async {
    await _appImageDao.insertImageToSpecimen(appImage, specimenId);
    await fetchImagesForSpecimen(specimenId);
  }

  /// Updates an existing image record in storage and in memory.
  Future<void> updateImage(AppImage appImage) async {
    await _appImageDao.updateImage(appImage);
    final index = _images.indexWhere((img) => img.id == appImage.id);
    if (index != -1) {
      _images[index] = appImage;
    }
    notifyListeners();
  }

  /// Deletes an image record and removes the underlying file when it exists.
  Future<void> deleteImage(int appImageId) async {
    final imagePath = _images.firstWhere((image) => image.id == appImageId).imagePath;
    await _appImageDao.deleteImage(appImageId);
    _images.removeWhere((image) => image.id == appImageId);

    // Delete the image file from the device storage
    final imageFile = File(imagePath);
    if (await imageFile.exists()) {
      await imageFile.delete();
    }

    notifyListeners();
  }
}