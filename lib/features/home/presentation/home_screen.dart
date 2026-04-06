import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neo_button.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../attendance/presentation/attendance_history_provider.dart';
import '../../attendance/presentation/attendance_provider.dart';
import '../../auth/presentation/auth_provider.dart';

/// Main home screen shown after authentication.
/// El FAB "+" marca asistencia directamente y muestra popup de éxito.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// true = próxima marcación es Entrada, false = Salida.
  /// Se alterna automáticamente tras cada marcación exitosa.
  bool _isEntryMode = true;

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(attendanceHistoryProvider);
    final user = ref.watch(authProvider).user;
    final actionState = ref.watch(attendanceActionProvider);

    final initials = _getInitials(user?.name ?? user?.email ?? 'U');

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(context, initials, user?.name ?? 'Usuario'),
                _buildFilterChips(context, ref, historyState.filter),
                Expanded(
                  child: _buildAttendanceList(
                      context, historyState.groupedByDay),
                ),
              ],
            ),
          ),

          // ── Processing overlay ──
          if (actionState.status == AttendanceActionStatus.securing)
            _buildProcessingOverlay(actionState.message ?? 'Procesando...'),
        ],
      ),
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

  Widget _buildAppBar(
      BuildContext context, String initials, String name) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pulse',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                ),
              ],
            ),
          ),

          // Profile button
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 46,
              height: 46,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Chips ─────────────────────────────────────────────────────────

  Widget _buildFilterChips(BuildContext context, WidgetRef ref,
      AttendanceTimeFilter currentFilter) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AttendanceTimeFilter.values.where((f) => f != AttendanceTimeFilter.custom).map((filter) {
                  final isSelected = filter == currentFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => ref
                          .read(attendanceHistoryProvider.notifier)
                          .setFilter(filter),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryAccent
                              : AppColors.inputFill,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryAccent
                                : AppColors.inputBorder,
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryAccent
                                        .withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          filter.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Calendar filter button
          Container(
            decoration: BoxDecoration(
              color: currentFilter == AttendanceTimeFilter.custom ? AppColors.primaryAccent.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  locale: const Locale('es', 'ES'),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primaryAccent,
                          onPrimary: Colors.white,
                          surface: AppColors.backgroundEnd,
                          onSurface: AppColors.textPrimary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (range != null) {
                  ref.read(attendanceHistoryProvider.notifier).setCustomDateRange(range);
                }
              },
              icon: Icon(
                Icons.calendar_month_rounded,
                color: currentFilter == AttendanceTimeFilter.custom ? AppColors.primaryAccent : AppColors.textSecondary,
              ),
              tooltip: 'Filtrar por fecha',
            ),
          ),
        ],
      ),
    );
  }

  // ── Attendance List ──────────────────────────────────────────────────────

  Widget _buildAttendanceList(
      BuildContext context,
      Map<DateTime, List<AttendanceRecord>> groupedByDay) {
    if (groupedByDay.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded,
                size: 56,
                color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(
              'Sin registros en este período',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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

// ── Day Section ─────────────────────────────────────────────────────────────

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.records,
  });

  final DateTime day;
  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dayLabel;
    if (day == today) {
      dayLabel = 'Hoy';
    } else if (day == yesterday) {
      dayLabel = 'Ayer';
    } else {
      dayLabel = DateFormat('EEEE, d MMM', 'es').format(day);
      dayLabel = dayLabel[0].toUpperCase() + dayLabel.substring(1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day label
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Text(
                dayLabel,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: AppColors.inputBorder,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${records.length}',
                  style: TextStyle(
                    color: AppColors.primaryAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Record cards
        ...records.map((record) => _AttendanceCard(record: record)),
      ],
    );
  }
}

// ── Attendance Card ──────────────────────────────────────────────────────────

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final isEntry = record.type == AttendanceType.entry;
    final color =
        isEntry ? AppColors.success : AppColors.secondaryAccent;
    final icon = isEntry
        ? Icons.login_rounded
        : Icons.logout_rounded;
    final label = isEntry ? 'Entrada' : 'Salida';
    final timeStr =
        DateFormat('HH:mm').format(record.dateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.glassPanel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.glassShadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),

                const SizedBox(width: 12),

                // Label
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                  ),
                ),

                // Time
                Text(
                  timeStr,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
