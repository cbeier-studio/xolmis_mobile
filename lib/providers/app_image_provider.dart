import 'dart:io';
import 'package:flutter/material.dart';
import '../data/models/app_image.dart';
import '../data/database/repositories/app_image_repository.dart';

class AppImageProvider with ChangeNotifier {
  final AppImageRepository _appImageRepository;
  List<AppImage> _images = [];

  AppImageProvider(this._appImageRepository);

  List<AppImage> get images => _images;

  Future<List<AppImage>> fetchImagesForVegetation(int vegetationId) async {
    _images = await _appImageRepository.getImagesForVegetation(vegetationId);
    notifyListeners();
    return _images;
  }

  Future<void> addImageToVegetation(AppImage appImage, int vegetationId) async {
    await _appImageRepository.insertImageToVegetation(appImage, vegetationId);
    _images = await _appImageRepository.getImagesForVegetation(vegetationId);
    notifyListeners();
  }

  Future<List<AppImage>> fetchImagesForNestRevision(int revisionId) async {
    _images = await _appImageRepository.getImagesForNestRevision(revisionId);
    notifyListeners();
    return _images;
  }

  Future<void> addImageToNestRevision(AppImage appImage, int revisionId) async {
    await _appImageRepository.insertImageToNestRevision(appImage, revisionId);
    _images = await _appImageRepository.getImagesForNestRevision(revisionId);
    notifyListeners();
  }

  Future<List<AppImage>> fetchImagesForEgg(int eggId) async {
    _images = await _appImageRepository.getImagesForEgg(eggId);
    notifyListeners();
    return _images;
  }

  Future<void> addImageToEgg(AppImage appImage, int eggId) async {
    await _appImageRepository.insertImageToEgg(appImage, eggId);
    _images = await _appImageRepository.getImagesForEgg(eggId);
    notifyListeners();
  }

  Future<List<AppImage>> fetchImagesForSpecimen(int specimenId) async {
    _images = await _appImageRepository.getImagesForSpecimen(specimenId);
    notifyListeners();
    return _images;
  }

  Future<void> addImageToSpecimen(AppImage appImage, int specimenId) async {
    await _appImageRepository.insertImageToSpecimen(appImage, specimenId);
    _images = await _appImageRepository.getImagesForSpecimen(specimenId);
    notifyListeners();
  }

  Future<void> updateImage(AppImage appImage) async {
    await _appImageRepository.updateImage(appImage);
    notifyListeners();
  }

  Future<void> deleteImage(int appImageId) async {
    final imagePath = _images.firstWhere((image) => image.id == appImageId).imagePath;
    await _appImageRepository.deleteImage(appImageId);
    _images.removeWhere((image) => image.id == appImageId);

    // Delete the image file from the device storage
    final imageFile = File(imagePath);
    if (await imageFile.exists()) {
      await imageFile.delete();
    }

    notifyListeners();
  }
}