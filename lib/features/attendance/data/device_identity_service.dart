import 'dart:io';
import 'package:android_id/android_id.dart';
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
  /// Si existe un identificador de dispositivo estable, derive un UUID consistente
  /// y úselo como el ID único del teléfono incluso después de reinstalar.
  Future<String> getDeviceIdentifier() async {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      print('DeviceIdentityService: using cached device id=$_cachedDeviceId');
      return _cachedDeviceId!;
    }

    try {
      final storedUuid = await _secureStorage.read(key: _deviceUuidKey);
      if (storedUuid != null && storedUuid.isNotEmpty) {
        _cachedDeviceId = storedUuid;
        print('DeviceIdentityService: recovered persisted uuid=$_cachedDeviceId');
        return _cachedDeviceId!;
      }

      final stableDeviceId = await _getStableDeviceId();
      if (stableDeviceId != null && stableDeviceId.isNotEmpty) {
        final derivedUuid = _deriveUuidFromDeviceId(stableDeviceId);
        await _secureStorage.write(key: _deviceUuidKey, value: derivedUuid);
        _cachedDeviceId = derivedUuid;
        print('DeviceIdentityService: derived uuid=$_cachedDeviceId from stableDeviceId=$stableDeviceId');
        return _cachedDeviceId!;
      }

      final generatedUuid = const Uuid().v4();
      await _secureStorage.write(key: _deviceUuidKey, value: generatedUuid);
      _cachedDeviceId = generatedUuid;
      print('DeviceIdentityService: no stable device id available, generated uuid=$_cachedDeviceId');
      return _cachedDeviceId!;
    } on DeviceIdentityException {
      rethrow;
    } catch (e) {
      final msg = 'Quiebre de Seguridad en extracción nativa o persistencia: ${e.toString()}';
      print('DeviceIdentityService ERROR: $msg');
      throw DeviceIdentityException(msg);
    }
  }

  Future<String?> _getStableDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidId = await const AndroidId().getId();
        print('DeviceIdentityService: android_id=$androidId');
        return androidId;
      } else if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        final stableId = iosInfo.identifierForVendor;
        print('DeviceIdentityService: ios stable id=$stableId');
        return stableId;
      }
      print('DeviceIdentityService: no stable device id available for platform');
      return null;
    } catch (e) {
      print('DeviceIdentityService: failed to read stable device id: ${e.toString()}');
      return null;
    }
  }

  String _deriveUuidFromDeviceId(String deviceId) {
    return const Uuid().v5(Uuid.NAMESPACE_URL, deviceId);
  }
}
