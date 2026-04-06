/// ═══════════════════════════════════════════════════════════════════════════
/// 📍  SERVICIO DE PROXIMIDAD — Valida si el usuario está cerca de una oficina
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Este es el CORE de la lógica de geolocalización.
///
/// Recibe: la posición GPS actual del usuario.
/// Devuelve: un ProximityResult con:
///   - isWithinRange: bool → ¿está dentro del radio permitido?
///   - nearestOffice: Office → la oficina más cercana
///   - distanceMeters: double → distancia en metros a esa oficina
///
/// Usa la fórmula de Haversine (vía Geolocator.distanceBetween) para
/// calcular la distancia en línea recta entre dos puntos geográficos.
/// ═══════════════════════════════════════════════════════════════════════════

import 'package:geolocator/geolocator.dart';

import '../domain/office.dart';
import 'office_repository.dart';

// ── Resultado de la validación de proximidad ────────────────────────────────

class ProximityResult {
  const ProximityResult({
    required this.isWithinRange,
    required this.nearestOffice,
    required this.distanceMeters,
    required this.isMocked,
    required this.latitude,
    required this.longitude,
  });

  /// true si el usuario está dentro del radio permitido de [nearestOffice].
  final bool isWithinRange;

  /// La oficina más cercana al usuario (puede estar dentro o fuera del radio).
  final Office nearestOffice;

  /// Distancia en metros entre el usuario y [nearestOffice].
  final double distanceMeters;

  /// true si el sistema operativo detectó que la ubicación es falsa (Fake GPS).
  final bool isMocked;

  /// Latitud del usuario.
  final double latitude;

  /// Longitud del usuario.
  final double longitude;

  /// Distancia formateada legible para mostrar en UI.
  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  @override
  String toString() =>
      'ProximityResult(dentro: $isWithinRange, oficina: "${nearestOffice.name}", '
      'distancia: ${formattedDistance}, mock: $isMocked)';
}

// ── Excepciones ─────────────────────────────────────────────────────────────

class ProximityException implements Exception {
  final String message;
  const ProximityException(this.message);

  @override
  String toString() => message;
}

// ── Servicio ────────────────────────────────────────────────────────────────

class ProximityService {
  ProximityService({required this.officeRepository});

  final OfficeRepository officeRepository;

  /// Función principal: obtiene GPS del usuario, compara contra TODAS las
  /// oficinas y devuelve si está en rango de la más cercana.
  ///
  /// Flujo:
  ///   1. Obtener coordenadas GPS del dispositivo
  ///   2. Cargar lista de oficinas desde el repositorio
  ///   3. Calcular distancia a cada oficina
  ///   4. Encontrar la más cercana
  ///   5. Comparar contra su radio permitido
  ///   6. Devolver resultado con booleano + oficina + distancia
  Future<ProximityResult> validateProximity() async {
    // ── Paso 1: Obtener ubicación actual del dispositivo ──
    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      throw const ProximityException(
        'No se pudo obtener tu ubicación. '
        'Verifica que el GPS esté activado y tengas señal.',
      );
    }

    // ── Paso 2: Cargar oficinas desde el repositorio ──
    final offices;
    try {
      print('Loading offices from repository...');
      offices = await officeRepository.getOffices();
      print('Offices loaded: $offices');
    } catch (e) {
      print('Error loading offices: $e');
      throw const ProximityException(
        'No se pudieron cargar las oficinas desde el servidor. '
        'Verifica tu conexión a internet.',
      );
    }
    if (offices.isEmpty) {
      throw const ProximityException(
        'No hay oficinas registradas en el sistema. '
        'Contacta al administrador.',
      );
    }

    // ── Paso 3: Calcular distancia a CADA oficina ──
    Office? closestOffice;
    double closestDistance = double.infinity;

    for (final office in offices) {
      final double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        office.latitude,
        office.longitude,
      );

      if (distance < closestDistance) {
        closestDistance = distance;
        closestOffice = office;
      }
    }

    // ── Paso 4: Verificar si está dentro del radio de la más cercana ──
    final bool withinRange =
        closestDistance <= closestOffice!.allowedRadiusMeters;

    // ── Paso 5: Devolver resultado completo ──
    return ProximityResult(
      isWithinRange: withinRange,
      nearestOffice: closestOffice,
      distanceMeters: closestDistance,
      isMocked: position.isMocked,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
