/// ═══════════════════════════════════════════════════════════════════════════
/// 🏢  REPOSITORIO DE OFICINAS — Fuente de datos de sedes disponibles
/// ═══════════════════════════════════════════════════════════════════════════
///
/// Hoy: Devuelve una lista hardcodeada con la oficina actual.
/// Mañana: Conectar a Supabase / Firebase / API REST para obtener
///         las oficinas dinámicamente.
///
/// Para escalar:
///   1. Inyectar un DioClient o SupabaseClient en el constructor.
///   2. Reemplazar el contenido de getOffices() con la llamada a la BD.
///   3. Opcionalmente cachear en local con Hive/SharedPreferences.
/// ═══════════════════════════════════════════════════════════════════════════

import '../domain/office.dart';

class OfficeRepository {

  /// Devuelve la lista de todas las oficinas registradas.
  ///
  /// ┌──────────────────────────────────────────────────────────────────────┐
  /// │  CUANDO CONECTES LA BD:                                             │
  /// │                                                                     │
  /// │  Future<List<Office>> getOffices() async {                          │
  /// │    final response = await _dio.get('/offices');                     │
  /// │    final List data = response.data as List;                        │
  /// │    return data.map((json) => Office.fromJson(json)).toList();       │
  /// │  }                                                                  │
  /// └──────────────────────────────────────────────────────────────────────┘
  Future<List<Office>> getOffices() async {
    // ── DATOS HARDCODEADOS (reemplazar por llamada a BD) ──
    return const [
      Office(
        id: 'office_001',
        name: 'Oficina Principal',
        latitude: -12.127896175289106,
        longitude: -77.02650619107756,
        allowedRadiusMeters: 300.0,
        address: 'Lima, Perú',
      ),
      // ── AGREGAR MÁS OFICINAS AQUÍ ──
      // Office(
      //   id: 'office_002',
      //   name: 'Sucursal Norte',
      //   latitude: -12.0000,
      //   longitude: -77.0000,
      //   allowedRadiusMeters: 200.0,
      //   address: 'Los Olivos, Lima',
      // ),
    ];
  }
}
