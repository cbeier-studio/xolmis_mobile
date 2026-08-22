import "package:fpdart/fpdart.dart";
import "../data/models/coordinate.dart";

/// Representa as falhas possíveis ao tentar obter a localização.
sealed class LocationFailure {
  const LocationFailure();
}

/// A permissão de localização foi negada pelo usuário.
class LocationPermissionDeniedFailure extends LocationFailure {
  const LocationPermissionDeniedFailure();
}

/// A permissão de localização foi negada permanentemente (deve ser habilitada nas configurações).
class LocationPermissionPermanentlyDeniedFailure extends LocationFailure {
  const LocationPermissionPermanentlyDeniedFailure();
}

/// O serviço de localização (GPS) está desativado no dispositivo.
class LocationServiceDisabledFailure extends LocationFailure {
  const LocationServiceDisabledFailure();
}

/// Ocorreu um erro desconhecido ao tentar obter a localização.
class LocationUnknownFailure extends LocationFailure {
  final String message;
  const LocationUnknownFailure(this.message);
}

/// Interface para o serviço de localização do aplicativo.
abstract class LocationService {
  /// Captura pontual da posição atual do GPS.
  ///
  /// Retorna um [Either] contendo [Coordinate] em caso de sucesso
  /// ou uma [LocationFailure] descrevendo o erro ocorrido.
  Future<Either<LocationFailure, Coordinate>> getCurrentCoordinate();
}
