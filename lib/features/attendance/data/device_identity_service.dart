import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// Excepción crítica del sistema de Autenticación.
class DeviceIdentityException implements Exception {
  final String message;
  DeviceIdentityException(this.message);
  @override
  String toString() => message;
}

/// Servicio orientado a Seguridad (Singleton) para la estrategia Device Binding.
/// Optimiza el acceso al puente nativo almacenando el identificador físicamente en memoria de sesión.
class DeviceIdentityService {
  // 1. Instancia única compartida (Singleton Múltiple)
  static final DeviceIdentityService _instance = DeviceIdentityService._internal();

  // 2. Caché local volatil donde guardaremos el Hardware ID verificado
  String? _cachedDeviceId;

  // 3. Constructor privado
  DeviceIdentityService._internal();

  // 4. Getter de factoría para fácil consumo (Dependency Injection nativo)
  factory DeviceIdentityService() {
    return _instance;
  }

  /// Extrae rigurosamente la huella del Hardware actual.
  /// Aplica el principio <Zero Trust>: Si falla la extracción, el acceso se quiebra devolviendo exc.
  Future<String> getDeviceIdentifier() async {
    // Optimización O(1): Retorno inmediato sin ir a las API nativas si ya tenemos el dato
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      return _cachedDeviceId!;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      String? hardwareId;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // NOTA ARQUITECTÓNICA: Dependiendo de la versión exacta de device_info_plus,
        // .id puede apuntar al Build.ID (compartido entre modelos) o a la constante de hardware.
        // Si precisas el `android_id` estricto (Settings.Secure.ANDROID_ID), 
        // normalmente requieres hoy en día la librería complementaria `android_id`.
        // Para este contexto, extraemos un identificador con device_info_plus:
        hardwareId = androidInfo.serialNumber != 'unknown' ? androidInfo.serialNumber : androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        hardwareId = iosInfo.identifierForVendor; // Clásico IDFV
      } else {
        throw DeviceIdentityException('Plataforma no soportada para Device Binding.');
      }

      // Validación Zero-Trust: Denegación Absoluta ante comportamientos extraños del SO
      if (hardwareId == null || hardwareId.trim().isEmpty) {
         throw DeviceIdentityException('Hardware fantasma detectado. El OS ocultó sistemáticamente la información de IDFV o AndroidID.');
      }

      // Caché Exitoso. Persiste el Hardware ID en memoria mientras la app viva.
      _cachedDeviceId = hardwareId;
      return _cachedDeviceId!;

    } on DeviceIdentityException {
      // Relanzar nuestras propias excepciones sin envolverlas
      rethrow;
    } catch (e) {
      // Bloqueo estricto si hay fallos nativos esotéricos o permisos denegados críticos
      throw DeviceIdentityException(
        'Quiebre de Seguridad en extracción nativa: Incapaz de acceder a los registros del Dispositivo.',
      );
    }
  }
}
