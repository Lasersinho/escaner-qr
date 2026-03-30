import 'package:geolocator/geolocator.dart';

class LocationValidationResult {
  final double distance;
  final bool isMocked;

  const LocationValidationResult({
    required this.distance,
    required this.isMocked,
  });
}

class LocationSecurityException implements Exception {
  final String message;
  LocationSecurityException(this.message);
  @override
  String toString() => message;
}

/// Servicio que encapsula la validación de seguridad geográfica.
/// Asume que los permisos nativos (Android/iOS) ya fueron concedidos con anterioridad.
class LocationSecurityService {
  // Coordenadas fijas de la oficina central (Lima, Perú aprox)
  static const double officeLat = -12.127896175289106;
  static const double officeLng = -77.02650619107756;

  /// Obtiene la ubicación actual con precisión máxima, calcula su distancia a la oficina
  /// y detecta el uso de aplicaciones de simulación de ubicación (Fake GPS).
  Future<LocationValidationResult> validateCurrentLocation() async {
    try {
      // 1. Obtener coordenadas actuales con la mayor precisión posible del hardware
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );

      // 2. Calcular la distancia métrica en línea recta
      final double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        officeLat,
        officeLng,
      );

      // 3. Retornar los resultados purificados
      return LocationValidationResult(
        distance: distanceInMeters,
        isMocked: position.isMocked, // Propiedad vital de Anti-Spoofing en Geolocator
      );
    } catch (e) {
      throw LocationSecurityException(
        'Error al obtener las coordenadas. Verifica que el sensor GPS de tu dispositivo esté activo.',
      );
    }
  }
}
