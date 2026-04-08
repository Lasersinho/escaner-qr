import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

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

  // 3. Clave segura para el UUID persistido
  static const String _deviceUuidKey = 'device_uuid';

  // 4. Almacenamiento seguro para guardar el UUID la primera vez que se instala la app.
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // 5. Constructor privado
  DeviceIdentityService._internal();

  // 6. Getter de factoría para fácil consumo (Dependency Injection nativo)
  factory DeviceIdentityService() {
    return _instance;
  }

  /// Extrae rigurosamente la huella del Hardware actual.
  /// Si no existe UUID persistido, lo genera, lo guarda y lo devuelve.
  Future<String> getDeviceIdentifier() async {
    // Optimización O(1): Retorno inmediato sin ir a las API nativas si ya tenemos el dato
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      return _cachedDeviceId!;
    }

    try {
      final storedUuid = await _secureStorage.read(key: _deviceUuidKey);
      if (storedUuid != null && storedUuid.isNotEmpty) {
        _cachedDeviceId = storedUuid;
        return _cachedDeviceId!;
      }

      // Intentamos obtener un identificador de hardware para auditoría/diagnóstico,
      // pero la fuente segura principal para login será un UUID persistido.
      String? hardwareId;
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        hardwareId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        hardwareId = iosInfo.identifierForVendor;
      }

      if (hardwareId == null || hardwareId.trim().isEmpty) {
        hardwareId = null;
      }

      final generatedUuid = const Uuid().v4();
      await _secureStorage.write(key: _deviceUuidKey, value: generatedUuid);
      _cachedDeviceId = generatedUuid;

      if (hardwareId != null) {
        print('DeviceIdentityService: hardwareId=$hardwareId persisted uuid=$_cachedDeviceId');
      } else {
        print('DeviceIdentityService: no hardwareId available, generated uuid=$_cachedDeviceId');
      }

      return _cachedDeviceId!;
    } on DeviceIdentityException {
      rethrow;
    } catch (e) {
      throw DeviceIdentityException(
        'Quiebre de Seguridad en extracción nativa o persistencia: ${e.toString()}',
      );
    }
  }
}
