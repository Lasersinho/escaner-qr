import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neo_button.dart';
import 'attendance_provider.dart';

/// Main attendance screen shown after authentication.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  bool _hasScanned = false;

  void _markAttendance() {
    if (_hasScanned) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Marcación'),
        content: const Text('¿Desea registrar su asistencia en este momento?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _hasScanned = true);
              ref.read(attendanceActionProvider.notifier).processScan('manual_attendance');
            },
            child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    ref.read(attendanceActionProvider.notifier).reset();
    setState(() => _hasScanned = false);
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(attendanceActionProvider);

    // Listen for state changes to show dialogs
    ref.listen<AttendanceActionState>(attendanceActionProvider, (prev, next) {
      if (next.status == AttendanceActionStatus.success) {
        _showSuccessDialog(next.formattedTime ?? '--:--');
      } else if (next.status == AttendanceActionStatus.failure) {
        _showErrorDialog(next.errorMessage ?? 'Error desconocido');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0FAFB), Color(0xFFFBFBFC)],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: GlassCard(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryAccent.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: AppColors.primaryAccent.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.touch_app_rounded,
                                  size: 64,
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'Registro de Asistencia',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Su ubicación será validada para confirmar su asistencia.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 48),
                              SizedBox(
                                width: double.infinity,
                                child: NeoButton(
                                  label: 'Marcar Asistencia',
                                  onPressed: _hasScanned ? null : _markAttendance,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Processing overlay ──
          if (actionState.status == AttendanceActionStatus.securing)
            _buildProcessingOverlay(actionState.message ?? 'Procesando...'),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inputBorder),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.glassShadow,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Asistencia',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
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
                    'Registro Exitoso',
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
