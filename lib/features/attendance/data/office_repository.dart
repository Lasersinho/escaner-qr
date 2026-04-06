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

import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../domain/office.dart';

class OfficeRepository {
  OfficeRepository({required DioClient dioClient}) : _dio = dioClient.instance;

  final Dio _dio;

  /// Devuelve la lista de todas las oficinas registradas.
  Future<List<Office>> getOffices() async {
    try {
      print('Fetching offices from API...');
      final response = await _dio.get('headquarters');
      print('Response received: ${response.data}');

      final List data = response.data as List;
      final offices = data.map((json) => Office.fromJson(json)).toList();
      print('Parsed offices: $offices');
      return offices;
    } on DioException catch (e) {
      print('DioException in getOffices: ${e.message}, response: ${e.response?.data}');
      throw Exception('Error al obtener oficinas: ${e.message}');
    } catch (e) {
      print('Unexpected error in getOffices: $e');
      throw Exception('Error al obtener oficinas: $e');
    }
  }
}
