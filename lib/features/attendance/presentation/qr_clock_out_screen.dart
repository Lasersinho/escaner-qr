import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
import '../data/location_security_service.dart';
import '../data/device_identity_service.dart';

// Diferenciación clara de los estados permitidos por la pantalla
enum ScannerValidationState {
  verifying,
  outOfRange,
  mockedLocation,
  readyToScan,
  error,
}

class QRClockOutScreen extends StatefulWidget {
  const QRClockOutScreen({super.key});

  @override
  State<QRClockOutScreen> createState() => _QRClockOutScreenState();
}

class _QRClockOutScreenState extends State<QRClockOutScreen> {
  final LocationSecurityService _locationService = LocationSecurityService();
  final MobileScannerController _scannerController = MobileScannerController();

  ScannerValidationState _currentState = ScannerValidationState.verifying;
  String _errorMessage = '';
  double? _currentDistance;

  // Límite de la Geo-cerca
  static const double maxAllowedDistanceInMeters = 100.0;

  @override
  void initState() {
    super.initState();
    // Ejecuta la validación de seguridad inmediatamente al entrar a la pantalla
    _verifyLocationAndInitScanner();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  /// Consulta al servicio de negocio y cambia el estado de la UI
  /// basado en las métricas y la flag [isMocked].
  Future<void> _verifyLocationAndInitScanner() async {
    setState(() {
      _currentState = ScannerValidationState.verifying;
      _errorMessage = '';
      _currentDistance = null;
    });

    try {
      final validationResult = await _locationService.validateCurrentLocation();
      _currentDistance = validationResult.distance;

      // 1ª Regla: Bloquear ubicaciones simuladas para anti-spoofing
      if (validationResult.isMocked) {
        setState(() => _currentState = ScannerValidationState.mockedLocation);
        return;
      }

      // 2ª Regla: Bloquear fuera del radio de 100m
      if (validationResult.distance > maxAllowedDistanceInMeters) {
        setState(() => _currentState = ScannerValidationState.outOfRange);
        return;
      }

      // 3ª Todo legítimo: Transicionar al modo escáner
      setState(() => _currentState = ScannerValidationState.readyToScan);

    } on LocationSecurityException catch (e) {
      setState(() {
        _currentState = ScannerValidationState.error;
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _currentState = ScannerValidationState.error;
        _errorMessage = 'Falló de manera imprevista la obtención de tus satélites. Reintentando puede ayudar.';
      });
    }
  }

  /// Evento callback que extrae la información del QR leído
  Future<void> _onQRDetected(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String qrCode = barcodes.first.rawValue!;
      
      // Detenemos la cámara para prevenir callbacks repetitivos inmediatos
      _scannerController.stop();

      try {
        // [NUEVO] Device Binding Strategy: Extraer el Hardware ID con Zero Trust
        // Instancia el Singleton en O(1) e invoca getDeviceIdentifier
        final String deviceId = await DeviceIdentityService().getDeviceIdentifier();

        // Empaquetado final para la API backend
        final payload = {
          'qr_code': qrCode,
          'device_id': deviceId,
          // 'timestamp': DateTime.now().toIso8601String(),
        };

        debugPrint('🛡️ PAYLOAD SEGURO PREPARADO: $payload');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sincronizando ID...\nEnviando: $qrCode'),
            backgroundColor: Colors.blueGrey.shade800,
          ),
        );

        // [IMPLEMENTACIÓN SOLICITADA] Envío nativo de JSON usando Dio
        final dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.frioteam.com/v1', // URL de tu backend
            connectTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json', // Firma esencial del JSON
              'Accept': 'application/json',
              // 'Authorization': 'Bearer $token_del_usuario_logueado', 
            },
          ),
        );

        // Dio codificará automáticamente el "payload" a un String JSON
        final response = await dio.post(
          '/attendance/clock-out',
          data: payload, 
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
               content: Text('✅ Salida registrada exitosamente en nuestros servidores.'),
               backgroundColor: Colors.green,
            ),
          );
          // Redirigir o volver al menú
          Navigator.pop(context, true);
        } else {
           throw Exception('Respuesta inesperada del servidor: ${response.statusCode}');
        }

      } on DioException catch (dioError) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fallo de red: ${dioError.message}'),
            backgroundColor: Colors.orange.shade900,
          ),
        );
        _scannerController.start(); // Reiniciar cámara para reintentar
      } on DeviceIdentityException catch (e) {
        // Quiebre del flujo: Si no hay Binding, rechazar totalmente el intento
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Violación de Dispositivo: ${e.message}'),
            backgroundColor: Colors.red.shade900,
          ),
        );
        
        // Reanudamos cámara para que intente de nuevo en caso de fallo intermitente
        _scannerController.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marcación Inteligente', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          // Animación suave de transición entre el loader, error y cámara
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _buildBodyContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_currentState) {
      case ScannerValidationState.verifying:
        return _buildVerifyingView();
      case ScannerValidationState.outOfRange:
        return _buildErrorState(
          icon: Icons.location_off_rounded,
          title: 'Fuera de Rango (Geo-Fence)',
          message: 'Te encuentras a ${_currentDistance?.toStringAsFixed(1)} metros de las coordenadas preestablecidas.\nAcércate al radio de $maxAllowedDistanceInMeters metros para autorizar tu salida.',
          color: Colors.redAccent,
        );
      case ScannerValidationState.mockedLocation:
        return _buildErrorState(
          icon: Icons.warning_rounded,
          title: 'Ubicación Falsa Detectada',
          message: 'Hemos detectado que estás utilizando un simulador de ubicación (Fake GPS). Apágalo de inmediato por políticas de la empresa.',
          color: Colors.orange.shade800,
        );
      case ScannerValidationState.error:
        return _buildErrorState(
          icon: Icons.satellite_alt_rounded,
          title: 'Problemas de Satélite',
          message: _errorMessage,
          color: Colors.red,
        );
      case ScannerValidationState.readyToScan:
        return _buildReadyToScan();
    }
  }

  // ============== VISTAS MODULARES ============== //

  Widget _buildVerifyingView() {
    return Center(
      key: const ValueKey('verifying'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(),
          SizedBox(height: 32),
          Text(
            'Auditoría GPS en Curso...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Comprobando seguridad y proximidad a oficinas.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Center(
      key: ValueKey(title),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 90, color: color),
          const SizedBox(height: 24),
          Text(
             title,
             style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
             textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
             message,
             style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
             textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _verifyLocationAndInitScanner,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Comprobar de Nuevo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildReadyToScan() {
    return Column(
      key: const ValueKey('scanner'),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
             color: Colors.green.shade50,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.verified_user_rounded, color: Colors.green),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Seguridad Aprobada. A menos de 100m, Fake GPS Apagado.',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onQRDetected,
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Enfoca el reloj checador digital QR\npara procesar la salida.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
      ],
    );
  }
}
