import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neo_button.dart';
import '../../auth/presentation/auth_provider.dart';
import 'attendance_provider.dart';

/// Main scanner screen shown after authentication.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _hasScanned = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _hasScanned = true);
    _cameraController.stop();

    ref.read(attendanceActionProvider.notifier).processScan(barcode.rawValue!);
  }

  void _resetScanner() {
    ref.read(attendanceActionProvider.notifier).reset();
    setState(() => _hasScanned = false);
    _cameraController.start();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(attendanceActionProvider);
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.65;

    // Listen for state changes to show dialogs
    ref.listen<AttendanceActionState>(attendanceActionProvider, (prev, next) {
      if (next.status == AttendanceActionStatus.success) {
        _showSuccessDialog(next.formattedTime ?? '--:--');
      } else if (next.status == AttendanceActionStatus.failure) {
        _showErrorDialog(next.errorMessage ?? 'Error desconocido');
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // ── Camera feed ──
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),

          // ── Overlay ──
          _buildOverlay(size, scanAreaSize),

          // ── Top banner ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBanner(context),
          ),

          // ── Bottom actions ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(context),
          ),

          // ── Processing overlay ──
          if (actionState.status == AttendanceActionStatus.processing)
            _buildProcessingOverlay(),
        ],
      ),
    );
  }

  // ── Top Banner ──────────────────────────────────────────────────────────

  Widget _buildTopBanner(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            bottom: 16,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: AppColors.glassPanel,
            border: Border(
              bottom: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.qr_code_scanner_rounded,
                  color: AppColors.primaryAccent, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Escanea QR de Salida',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 18,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom Bar ──────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            top: 16,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: AppColors.glassPanel,
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Apunta la cámara al código QR',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout_rounded,
                    color: AppColors.textSecondary),
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Scan overlay ────────────────────────────────────────────────────────

  Widget _buildOverlay(Size size, double scanAreaSize) {
    return CustomPaint(
      size: size,
      painter: _ScanOverlayPainter(
        scanAreaSize: scanAreaSize,
        borderColor: AppColors.primaryAccent,
      ),
    );
  }

  // ── Processing overlay ──────────────────────────────────────────────────

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: GlassCard(
                width: 200,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryAccent),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Registrando...',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────

  void _showSuccessDialog(String time) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38,
      builder: (_) => Center(
        child: GlassCard(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                'Salida Registrada',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                time,
                style: TextStyle(
                  color: AppColors.primaryAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              NeoButton(
                label: 'Aceptar',
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetScanner();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38,
      builder: (_) => Center(
        child: GlassCard(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.close_rounded,
                    color: AppColors.error, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                'Error al Registrar',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              NeoButton(
                label: 'Reintentar',
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetScanner();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Scan frame painter ──────────────────────────────────────────────────────

class _ScanOverlayPainter extends CustomPainter {
  _ScanOverlayPainter({
    required this.scanAreaSize,
    required this.borderColor,
  });

  final double scanAreaSize;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Dim background
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()
          ..addRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(24)),
          ),
      ),
      bgPaint,
    );

    // Corner brackets
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLen = 32.0;
    final r = 12.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + cornerLen)
        ..lineTo(rect.left, rect.top + r)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + r, rect.top)
        ..lineTo(rect.left + cornerLen, rect.top),
      cornerPaint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLen, rect.top)
        ..lineTo(rect.right - r, rect.top)
        ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + r)
        ..lineTo(rect.right, rect.top + cornerLen),
      cornerPaint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - cornerLen)
        ..lineTo(rect.left, rect.bottom - r)
        ..quadraticBezierTo(
            rect.left, rect.bottom, rect.left + r, rect.bottom)
        ..lineTo(rect.left + cornerLen, rect.bottom),
      cornerPaint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cornerLen, rect.bottom)
        ..lineTo(rect.right - r, rect.bottom)
        ..quadraticBezierTo(
            rect.right, rect.bottom, rect.right, rect.bottom - r)
        ..lineTo(rect.right, rect.bottom - cornerLen),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
