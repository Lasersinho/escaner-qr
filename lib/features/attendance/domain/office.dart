/// ═══════════════════════════════════════════════════════════════════════════
/// 📍  MODELO DE OFICINA — Representa una sede/oficina con coordenadas GPS
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Este modelo es la entidad central para la validación de proximidad.
/// Cada oficina tiene un nombre, sus coordenadas y un radio permitido
/// para marcar asistencia desde allí.
///
///   solo necesitas crear un factory `Office.fromJson(Map<String, dynamic>)`
///   que mapee los campos de la BD a este modelo. El resto de la app
///   ya consume este modelo directamente.
/// ═══════════════════════════════════════════════════════════════════════════

class Office {
  const Office({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.allowedRadiusMeters = 300.0, // Radio por defecto: 300 metros
    this.address,
  });

  /// Identificador único de la oficina (PK en la base de datos).
  final int id;

  /// Nombre legible de la oficina (ej: "Sede Principal Lima").
  final String name;

  /// Latitud de la ubicación de la oficina.
  final double latitude;

  /// Longitud de la ubicación de la oficina.
  final double longitude;

  /// Radio máximo en metros dentro del cual se permite marcar asistencia.
  /// Por defecto son 300 metros. Cada oficina puede tener su propio radio
  /// (ej: una oficina grande podría tener 500m, una pequeña 100m).
  final double allowedRadiusMeters;

  /// Dirección textual de la oficina (opcional, para mostrar en UI).
  final String? address;

  factory Office.fromJson(Map<String, dynamic> json) {
    return Office(
      id: json['Identifier'] as int,
      name: json['Description'] as String,
      latitude: (json['Latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['Longitude'] as num?)?.toDouble() ?? 0.0,
      allowedRadiusMeters: (json['Distance'] as num?)?.toDouble() ?? 300.0,
      address: json['Description'] as String?, // Usar Description como address
    );
  }
  //   return Office(
  //     id: json['id'] as String,
  //     name: json['name'] as String,
  //     latitude: (json['latitude'] as num).toDouble(),
  //     longitude: (json['longitude'] as num).toDouble(),
  //     allowedRadiusMeters: (json['allowed_radius_meters'] as num?)?.toDouble() ?? 300.0,
  //     address: json['address'] as String?,
  //   );
  // }
  //
  // Map<String, dynamic> toJson() => {
  //   'id': id,
  //   'name': name,
  //   'latitude': latitude,
  //   'longitude': longitude,
  //   'allowed_radius_meters': allowedRadiusMeters,
  //   'address': address,
  // };
  // ─────────────────────────────────────────────────────────────────────────

  @override
  String toString() =>
      'Office(id: $id, name: "$name", lat: $latitude, lng: $longitude, radio: ${allowedRadiusMeters}m)';
}
