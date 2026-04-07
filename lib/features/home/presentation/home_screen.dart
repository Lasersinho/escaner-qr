import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neo_button.dart';
<<<<<<< HEAD
import '../../attendance/domain/attendance_record.dart';
import '../../attendance/presentation/attendance_history_provider.dart';
import '../../attendance/presentation/attendance_provider.dart';
import '../../auth/presentation/auth_provider.dart';

/// Main home screen shown after authentication.
/// El FAB "+" marca asistencia directamente y muestra popup de éxito.
=======
import '../../attendance/presentation/attendance_provider.dart';
import '../../auth/presentation/auth_provider.dart';

/// Pantalla principal ultra-rápida: Login → Botón → Éxito.
>>>>>>> c50bce96a2b650b7ba796c1d65fa46c0df400070
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}
<<<<<<< HEAD

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// true = próxima marcación es Entrada, false = Salida.
  /// Se alterna automáticamente tras cada marcación exitosa.
  bool _isEntryMode = true;

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(attendanceHistoryProvider);
    final user = ref.watch(authProvider).user;
    final actionState = ref.watch(attendanceActionProvider);
=======
>>>>>>> c50bce96a2b650b7ba796c1d65fa46c0df400070

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _hasMarked = false;
  bool _isEntryMode = true;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _markAttendance() {
    if (_hasMarked) return;
    setState(() => _hasMarked = true);
    ref.read(attendanceActionProvider.notifier).processScan('manual_attendance');
  }

  void _resetState() {
    ref.read(attendanceActionProvider.notifier).reset();
    setState(() {
       _hasMarked = false;
       _isEntryMode = !_isEntryMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(attendanceActionProvider);
    final user = ref.watch(authProvider).user;
    final greeting = _buildGreeting(user?.name ?? 'Usuario');

    // Listen for state changes → show dialogs
    ref.listen<AttendanceActionState>(attendanceActionProvider, (prev, next) {
      if (next.status == AttendanceActionStatus.success) {
        _showSuccessDialog(next.formattedTime ?? '--:--');
      } else if (next.status == AttendanceActionStatus.failure) {
        _showErrorDialog(next.errorMessage ?? 'Error desconocido');
      }
    });

    // Escuchar cambios de estado → popups
    ref.listen<AttendanceActionState>(attendanceActionProvider, (prev, next) {
      if (next.status == AttendanceActionStatus.success) {
        _showSuccessDialog(next.formattedTime ?? '--:--');
        
        // Insert mock record in the history to show visually
        final now = DateTime.now();
        ref.read(attendanceHistoryProvider.notifier).addRecord(
          AttendanceRecord(
            id: 'mock_${now.millisecondsSinceEpoch}',
            type: _isEntryMode ? AttendanceType.entry : AttendanceType.exit,
            dateTime: now,
            employeeId: 'usr_001',
          ),
        );
      } else if (next.status == AttendanceActionStatus.failure) {
        _showErrorDialog(next.errorMessage ?? 'Error desconocido');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      body: Stack(
        children: [
          // ── Background gradient ──
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
                _buildTopBar(context, user?.name ?? 'Usuario'),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Greeting ──
                            Text(
                              greeting,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // ── Live clock ──
                            _LiveClock(),
                            const SizedBox(height: 48),

                            // ── Big Pulse Button ──
                            AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _hasMarked ? 1.0 : _pulseAnim.value,
                                  child: child,
                                );
                              },
                              child: GestureDetector(
                                onTap: _hasMarked ? null : _markAttendance,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _hasMarked
                                          ? [
                                              AppColors.textSecondary
                                                  .withOpacity(0.3),
                                              AppColors.textSecondary
                                                  .withOpacity(0.2),
                                            ]
                                          : [
                                              AppColors.primaryAccent,
                                              const Color(0xFF00A8AE),
                                            ],
                                    ),
                                    boxShadow: _hasMarked
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: AppColors.primaryAccent
                                                  .withOpacity(0.4),
                                              blurRadius: 40,
                                              spreadRadius: 8,
                                              offset: const Offset(0, 8),
                                            ),
                                            BoxShadow(
                                              color: AppColors.primaryAccent
                                                  .withOpacity(0.15),
                                              blurRadius: 80,
                                              spreadRadius: 20,
                                            ),
                                          ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.touch_app_rounded,
                                        color: _hasMarked
                                            ? Colors.white54
                                            : Colors.white,
                                        size: 56,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'MARCAR',
                                        style: TextStyle(
                                          color: _hasMarked
                                              ? Colors.white54
                                              : Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // ── Instruction text ──
                            Text(
                              _hasMarked
                                  ? 'Procesando tu asistencia...'
                                  : 'Pulsa para registrar tu asistencia',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                                fontWeight:
                                    _hasMarked ? FontWeight.w500 : FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                          ],
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
<<<<<<< HEAD
      // FAB "+" marca asistencia directamente
      floatingActionButton: _buildFab(context),
    );
  }

  // ── Marcar asistencia directo ───────────────────────────────────────────

  void _onFabPressed() {
    ref.read(attendanceActionProvider.notifier).processScan('manual_attendance', type: _isEntryMode ? 1 : 2);
  }

  void _resetAction() {
    ref.read(attendanceActionProvider.notifier).reset();
  }

  // ── AppBar ───────────────────────────────────────────────────────────────
=======
    );
  }

  // ── Top Bar ─────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, String name) {
    final initials = _getInitials(name);
>>>>>>> c50bce96a2b650b7ba796c1d65fa46c0df400070

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Logo / Title
          const Expanded(
            child: Text(
              'Pulse',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Profile avatar
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryAccent,
                    AppColors.secondaryAccent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: GlassCard(
                width: 220,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primaryAccent.withOpacity(0.3)),
                      ),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryAccent),
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
      barrierColor: Colors.black87.withOpacity(0.6),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isEntryMode ? '¡Entrada Registrada!' : '¡Salida Registrada!',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withOpacity(0.1),
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
                    const SizedBox(height: 12),
                    Text(
                      _isEntryMode
                          ? 'Tu registro de entrada fue exitoso'
                          : 'Tu registro de salida fue exitoso',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: NeoButton(
                        label: 'Aceptar',
                        onPressed: () {
                          Navigator.of(context).pop();
                          _resetState();
                        },
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87.withOpacity(0.6),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error.withOpacity(0.15),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.4),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withOpacity(0.2),
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
                        color: AppColors.error.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppColors.error.withOpacity(0.1)),
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
                          _resetState();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
<<<<<<< HEAD
          ],
        ),
      );
    }

    final days = groupedByDay.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final records = groupedByDay[day]!;
        return _DaySection(day: day, records: records);
      },
    );
  }

  // ── FAB ──────────────────────────────────────────────────────────────────

  Widget _buildFab(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.fabGradientStart, AppColors.fabGradientEnd],
        ),
      ),
      child: FloatingActionButton(
        onPressed: _onFabPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        tooltip: _isEntryMode ? 'Marcar Entrada' : 'Marcar Salida',
        child: const Icon(Icons.touch_app_rounded,
            color: Colors.white, size: 30),
=======
          ),
        ),
>>>>>>> c50bce96a2b650b7ba796c1d65fa46c0df400070
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
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: GlassCard(
                width: 220,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.primaryAccent.withOpacity(0.3)),
                      ),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryAccent),
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
    final isEntry = _isEntryMode;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87.withOpacity(0.6),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Ícono de check (colores editables en app_colors.dart) ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.successCircleBg,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.successCircleBg.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: AppColors.successIcon, size: 48),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isEntry
                          ? '¡Entrada Registrada!'
                          : '¡Salida Registrada!',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withOpacity(0.1),
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
                    const SizedBox(height: 12),
                    Text(
                      isEntry
                          ? 'Tu registro de entrada fue exitoso'
                          : 'Tu registro de salida fue exitoso',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: NeoButton(
                        label: 'Aceptar',
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Alternar entrada/salida para la próxima vez
                          setState(() => _isEntryMode = !_isEntryMode);
                          _resetAction();
                        },
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87.withOpacity(0.6),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.errorCircleBg,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.errorCircleBg.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: AppColors.errorIcon, size: 48),
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
                        color: AppColors.error.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppColors.error.withOpacity(0.1)),
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
                          _resetAction();
                        },
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

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _buildGreeting(String name) {
    final hour = DateTime.now().hour;
    final firstName = name.split(' ').first;
    if (hour < 12) return 'Buenos días, $firstName';
    if (hour < 18) return 'Buenas tardes, $firstName';
    return 'Buenas noches, $firstName';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'[\s._@]+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }
}

// ── Live Clock Widget ──────────────────────────────────────────────────────

class _LiveClock extends StatefulWidget {
  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late String _time;

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Update every second
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      _updateTime();
      return true;
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    if (mounted) {
      setState(() => _time = '$hh:$mm:$ss');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _time,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }
}
