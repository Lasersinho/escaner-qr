import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../data/location_security_service.dart';

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

  /// Evento que se dispara en cuanto la API detecta un QR válido.
  void _onQRDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String qrCode = barcodes.first.rawValue!;
      
      // Detenemos la cámara para no spamear envíos al detectar repetidamente en 1 segundo
      _scannerController.stop();

      // Log/Acción en consola solicitada
      debugPrint('🛡️ [SEGURIDAD APROBADA] Código de Salida: $qrCode');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Salida Registrada Correctamente: $qrCode'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      
      // Regresión opcional tras éxito: Navigator.pop(context, qrCode);
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
