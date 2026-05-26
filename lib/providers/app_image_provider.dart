import 'dart:io';
import 'package:flutter/material.dart';
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
  Future<List<AppImage>> fetchImagesForVegetation(int vegetationId) async {
    _images = await _appImageDao.getImagesForVegetation(vegetationId);
    notifyListeners();
    return _images;
  }

  /// Persists [appImage] for a vegetation record and refreshes the local cache.
  Future<void> addImageToVegetation(AppImage appImage, int vegetationId) async {
    await _appImageDao.insertImageToVegetation(appImage, vegetationId);
    _images = await _appImageDao.getImagesForVegetation(vegetationId);
    notifyListeners();
  }

  /// Loads all images associated with a nest revision.
  Future<List<AppImage>> fetchImagesForNestRevision(int revisionId) async {
    _images = await _appImageDao.getImagesForNestRevision(revisionId);
    notifyListeners();
    return _images;
  }

  /// Persists [appImage] for a nest revision and refreshes the local cache.
  Future<void> addImageToNestRevision(AppImage appImage, int revisionId) async {
    await _appImageDao.insertImageToNestRevision(appImage, revisionId);
    _images = await _appImageDao.getImagesForNestRevision(revisionId);
    notifyListeners();
  }

  /// Loads all images associated with an egg record.
  Future<List<AppImage>> fetchImagesForEgg(int eggId) async {
    _images = await _appImageDao.getImagesForEgg(eggId);
    notifyListeners();
    return _images;
  }

  /// Persists [appImage] for an egg record and refreshes the local cache.
  Future<void> addImageToEgg(AppImage appImage, int eggId) async {
    await _appImageDao.insertImageToEgg(appImage, eggId);
    _images = await _appImageDao.getImagesForEgg(eggId);
    notifyListeners();
  }

  /// Loads all images associated with a specimen record.
  Future<List<AppImage>> fetchImagesForSpecimen(int specimenId) async {
    _images = await _appImageDao.getImagesForSpecimen(specimenId);
    notifyListeners();
    return _images;
  }

  /// Persists [appImage] for a specimen record and refreshes the local cache.
  Future<void> addImageToSpecimen(AppImage appImage, int specimenId) async {
    await _appImageDao.insertImageToSpecimen(appImage, specimenId);
    _images = await _appImageDao.getImagesForSpecimen(specimenId);
    notifyListeners();
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