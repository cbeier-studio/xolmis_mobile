import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:fpdart/fpdart.dart';
import '../data/models/coordinate.dart';
import 'location_service.dart';

/// Implementação do [LocationService] utilizando o pacote `geolocator`.
class GeolocatorServiceImpl implements LocationService {
  @override
  Future<Either<LocationFailure, Coordinate>> getCurrentCoordinate() async {
    try {
      // Verifica se o serviço de localização está habilitado no sistema.
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return left(const LocationServiceDisabledFailure());
      }

      // Verifica as permissões de localização.
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return left(const LocationPermissionDeniedFailure());
        }
      }

      // Caso a permissão tenha sido negada permanentemente.
      if (permission == LocationPermission.deniedForever) {
        return left(const LocationPermissionPermanentlyDeniedFailure());
      }

      // Obtém a posição atual com precisão alta e timeout de 30 segundos.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

      return right(Coordinate(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
      ));
    } on TimeoutException {
      return left(const LocationUnknownFailure('Tempo esgotado ao obter localização GPS.'));
    } catch (e) {
      return left(LocationUnknownFailure('Erro inesperado: ${e.toString()}'));
    }
  }
}
