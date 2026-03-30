import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neo_button.dart';
import 'attendance_provider.dart';

/// Main scanner screen shown after authentication.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> with TickerProviderStateMixin {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  late final AnimationController _flashController;
  late final Animation<double> _flashAnimation;

  late final AnimationController _scanLineController;
  late final Animation<double> _scanLineAnimation;

  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );
    
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _flashController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _hasScanned = true);
    
    // Stop scanner to yield camera resources
    await _cameraController.stop();

    // Trigger flash effect
    await _flashController.forward();
    await _flashController.reverse();

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
          /*
          MobileScanner(
            controller: _cameraController,
            onDetect: _onDetect,
          ),

          // ── Overlay ──
          _buildOverlay(size, scanAreaSize),
          */

          // ── Botón de Simulación de Marcación ──
          Center(
            child: SizedBox(
              width: 250,
              child: NeoButton(
                label: 'Simular Marcación',
                onPressed: () {
                  if (_hasScanned) return;
                  setState(() => _hasScanned = true);
                  
                  // Trigger flash effect
                  _flashController.forward().then((_) {
                    _flashController.reverse();
                  });

                  ref.read(attendanceActionProvider.notifier).processScan('test_codigo_qr');
                },
              ),
            ),
          ),

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

          // ── Flash Effect ──
          AnimatedBuilder(
            animation: _flashAnimation,
            builder: (context, child) {
              return IgnorePointer(
                child: Container(
                  color: Colors.white.withValues(alpha: _flashAnimation.value * 0.8),
                ),
              );
            },
          ),

          // ── Processing overlay ──
          if (actionState.status == AttendanceActionStatus.securing)
            _buildProcessingOverlay(actionState.message ?? 'Procesando...'),
        ],
      ),
    );
  }

  // ── Top Banner ──────────────────────────────────────────────────────────

  Widget _buildTopBanner(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 20,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            border: const Border(
              bottom: BorderSide(color: Colors.white24, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded,
                        color: AppColors.primaryAccent, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Escanea QR de Salida',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Coloca el código en el recuadro',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Seguridad de Validación Activa',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
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
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            top: 20,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            border: const Border(
              top: BorderSide(color: Colors.white24, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Volver',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: IconButton(
                  onPressed: () => _cameraController.toggleTorch(),
                  icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white, size: 24),
                  tooltip: 'Linterna',
                  color: Colors.white,
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Scan overlay ────────────────────────────────────────────────────────

  Widget _buildOverlay(Size size, double scanAreaSize) {
    return AnimatedBuilder(
      animation: _scanLineAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: _ScanOverlayPainter(
            scanAreaSize: scanAreaSize,
            borderColor: AppColors.primaryAccent,
            scanLinePosition: _scanLineAnimation.value,
          ),
        );
      },
    );
  }

  // ── Processing overlay ──────────────────────────────────────────────────

  Widget _buildProcessingOverlay(String message) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: Center(
              child: GlassCard(
                width: 220,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.3)),
                      ),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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
      barrierColor: Colors.black87.withValues(alpha: 0.6),
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: Material(
            type: MaterialType.transparency,
            child: Center(
              child: GlassCard(
                width: 320,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                   Container(
                     padding: const EdgeInsets.all(20),
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: AppColors.success.withValues(alpha: 0.15),
                       border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 2),
                       boxShadow: [
                         BoxShadow(
                           color: AppColors.success.withValues(alpha: 0.2),
                           blurRadius: 20,
                           spreadRadius: 5,
                         ),
                       ],
                     ),
                     child: const Icon(Icons.check_rounded,
                         color: AppColors.success, size: 48),
                   ),
                  const SizedBox(height: 24),
                  const Text(
                    'Salida Registrada',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                       color: AppColors.primaryAccent.withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.primaryAccent,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: NeoButton(
                      label: 'Aceptar',
                      onPressed: () {
                        Navigator.of(context).pop();
                        _resetScanner();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          ), // Material
        ), // Transform.scale
      ), // TweenAnimationBuilder
    ); // showDialog
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87.withValues(alpha: 0.6),
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: Material(
            type: MaterialType.transparency,
            child: Center(
              child: GlassCard(
                width: 320,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 2),
                      boxShadow: [
                         BoxShadow(
                           color: AppColors.error.withValues(alpha: 0.2),
                           blurRadius: 20,
                           spreadRadius: 5,
                         ),
                       ],
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.error, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Error al Registrar',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: NeoButton(
                      label: 'Reintentar',
                      onPressed: () {
                        Navigator.of(context).pop();
                        _resetScanner();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          ), // Material
        ), // Transform.scale
      ), // TweenAnimationBuilder
    ); // showDialog
  }
}

// ── Scan frame painter ──────────────────────────────────────────────────────

class _ScanOverlayPainter extends CustomPainter {
  _ScanOverlayPainter({
    required this.scanAreaSize,
    required this.borderColor,
    required this.scanLinePosition,
  });

  final double scanAreaSize;
  final Color borderColor;
  final double scanLinePosition;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Dim background (darker for better contrast)
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);
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
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const cornerLen = 35.0;
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

    // Automated scanning line
    final scanLineY = rect.top + (rect.height * scanLinePosition);
    final scanLinePaint = Paint()
      ..color = borderColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Add a glow effect to the scan line
    final glowPaint = Paint()
      ..color = borderColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawLine(
        Offset(rect.left + 10, scanLineY), Offset(rect.right - 10, scanLineY), glowPaint);
    canvas.drawLine(
        Offset(rect.left + 10, scanLineY), Offset(rect.right - 10, scanLineY), scanLinePaint);
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) {
    return oldDelegate.scanLinePosition != scanLinePosition;
  }
}
