import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../attendance/domain/attendance_record.dart';
import '../../../attendance/presentation/attendance_history_provider.dart';
import '../../../attendance/presentation/attendance_provider.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../../shared/widgets/premium_calendar_widget.dart';
import '../../../../shared/widgets/animated_status_card.dart';
import '../../../../shared/widgets/attendance_timeline_card.dart';
import '../../../../shared/widgets/stagger_list.dart';

class PremiumHomeView extends ConsumerStatefulWidget {
  const PremiumHomeView({super.key});

  @override
  ConsumerState<PremiumHomeView> createState() => _PremiumHomeViewState();
}

class _PremiumHomeViewState extends ConsumerState<PremiumHomeView>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  DateTime _selectedDate = DateTime.now();
  bool _showCalendar = false;
  late final AnimationController _headerFadeCtrl;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFade =
        CurvedAnimation(parent: _headerFadeCtrl, curve: Curves.easeOut);
    _headerFadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendanceHistoryProvider.notifier).setCustomDateRange(
            DateTimeRange(start: _selectedDate, end: _selectedDate),
          );
    });
  }

  @override
  void dispose() {
    _headerFadeCtrl.dispose();
    super.dispose();
  }

  // ── Attendance type logic (unchanged) ─────────────────────────────────────

  int _computeNextType(List<AttendanceRecord> allRecords) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayRecords = allRecords
        .where((r) => !r.dateTime.isBefore(todayStart))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final lastTodayType =
        todayRecords.isNotEmpty ? todayRecords.first.type : null;
    return lastTodayType == AttendanceType.entry ? 2 : 1;
  }

  void _markAttendance() {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // BUG FIX #1: Usar allRecords (NO filteredRecords) para determinar el tipo
    // de la próxima marcación. filteredRecords depende del filtro activo del
    // calendario, que puede estar apuntando a un día sin registros,
    // causando que el fallback incorrecto de 'exit' dispare una entrada falsa.
    final allRecords = ref.read(attendanceHistoryProvider).allRecords;

    // Encontrar el registro más reciente del DÍA DE HOY en todos los records,
    // independientemente del filtro activo en la UI.
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final todayRecords = allRecords
        .where((r) => !r.dateTime.isBefore(todayStart))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime)); // descendente

    // Si no hay registros de hoy → la próxima acción es ENTRADA (type=1)
    // Si el último registro de hoy fue una ENTRADA → la próxima es SALIDA (type=2)
    // Si el último registro de hoy fue una SALIDA → la próxima es ENTRADA (type=1)
    final lastTodayType =
        todayRecords.isNotEmpty ? todayRecords.first.type : null;
    final nextType = lastTodayType == AttendanceType.entry ? 2 : 1;

    print(
        '[DEBUG] _markAttendance: todayRecords.length=${todayRecords.length}');
    if (todayRecords.isNotEmpty) {
      print(
          '[DEBUG] _markAttendance: lastTodayType=${todayRecords.first.type} at ${todayRecords.first.dateTime}');
    }
    print('[DEBUG] _markAttendance: nextType=$nextType');

    // BUG FIX #2: Buscar el token de la entrada de HOY en todayRecords
    // (ya ordenados por fecha descendente), garantizando el más reciente primero.
    String? existingToken;
    if (nextType == 2) {
      // El token de la sesión activa es el de la última ENTRADA de hoy
      final latestTodayEntry = todayRecords.firstWhere(
        (r) => r.type == AttendanceType.entry,
        orElse: () => todayRecords.first, // Fallback seguro
      );
      existingToken = latestTodayEntry.token;
      print('[DEBUG] _markAttendance: Token found in history: $existingToken');
      // Si el token del record es null (e.g. registro local sin token),
      // el provider caerá al SecureStorage como segunda línea de defensa.
    }

    ref.read(attendanceActionProvider.notifier).processAttendance(
          type: nextType,
          existingToken: existingToken,
        );
  }

  void _handleSuccess(AttendanceActionState state) {
    print('[DEBUG] _handleSuccess: status=${state.status}, type=${state.type}');
    final user = ref.read(authProvider).user;
    final now = DateTime.now();

    // Add to history list immediately
    final typeToAdd =
        state.type == 2 ? AttendanceType.exit : AttendanceType.entry;
    print(
        '[DEBUG] _handleSuccess: adding record of type $typeToAdd to local history');

    ref.read(attendanceHistoryProvider.notifier).addRecord(
          AttendanceRecord(
            id: 'now_${now.millisecondsSinceEpoch}',
            type: typeToAdd,
            dateTime: now,
            employeeId: user?.id ?? 'usr_001',
            officeName: state.officeName,
          ),
        );

    // Dismiss the processing bottom sheet if it's showing
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    _showSuccessDialog(
        state.formattedTime ?? '--:--', state.officeName ?? 'Sede');
  }

  // ── Status data helpers ──────────────────────────────────────────────────

  /// Returns the latest entry record from today that doesn't have a matching exit.
  AttendanceRecord? _getActiveEntry(List<AttendanceRecord> allRecords) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayRecords = allRecords
        .where((r) => !r.dateTime.isBefore(todayStart))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    if (todayRecords.isEmpty) return null;
    // If the most recent action today is an entry, the user is "active"
    if (todayRecords.first.type == AttendanceType.entry) {
      return todayRecords.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(attendanceHistoryProvider);
    final actionState = ref.watch(attendanceActionProvider);
    final user = ref.watch(authProvider).user;
    final allRecords = historyState.allRecords;

    // Compute status
    final activeEntry = _getActiveEntry(allRecords);
    final isActive = activeEntry != null;
    final nextType = _computeNextType(allRecords);

    // Listen to success/failure
    ref.listen<AttendanceActionState>(attendanceActionProvider, (prev, next) {
      if (next.status == AttendanceActionStatus.success) {
        setState(() => _isProcessing = false);
        _handleSuccess(next);
      } else if (next.status == AttendanceActionStatus.failure) {
        setState(() => _isProcessing = false);
        // Dismiss bottom sheet if showing
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        _showErrorDialog(next.errorMessage ?? 'Error desconocido');
      } else if (next.status == AttendanceActionStatus.securing &&
          prev?.status != AttendanceActionStatus.securing) {
        // Show processing bottom sheet
        _showProcessingBottomSheet(next.message ?? 'Procesando...');
      }
    });

    // Update bottom sheet message when it changes
    ref.listen<AttendanceActionState>(attendanceActionProvider, (prev, next) {
      if (next.status == AttendanceActionStatus.securing &&
          prev?.status == AttendanceActionStatus.securing &&
          next.message != prev?.message) {
        // Update the message — we rebuild via setState
        setState(() {});
      }
    });

    return Scaffold(
      backgroundColor: context.colors.backgroundStart,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            FadeTransition(
              opacity: _headerFade,
              child: _buildHeader(
                  context, user?.name ?? 'Usuario', historyState),
            ),

            // ── Calendar (togglable) ──
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showCalendar
                  ? PremiumCalendarWidget(
                      initialDate: _selectedDate,
                      markedDates: historyState.allRecords
                          .map((r) => r.dateTime)
                          .toList(),
                      onDaySelected: (date) {
                        setState(() {
                          _selectedDate = date;
                          _showCalendar = false;
                        });
                        ref
                            .read(attendanceHistoryProvider.notifier)
                            .setCustomDateRange(
                              DateTimeRange(start: date, end: date),
                            );
                      },
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),

            // ── Body ──
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(attendanceHistoryProvider.notifier)
                      .fetchHistory();
                },
                color: context.colors.primaryAccent,
                backgroundColor: context.colors.backgroundStart,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── Status Hero Card ──
                    SliverToBoxAdapter(
                      child: AnimatedStatusCard(
                        userName: user?.fullName ?? 'Usuario',
                        isActive: isActive,
                        activeSince: activeEntry?.dateTime,
                        officeName: activeEntry?.officeName,
                        nextActionLabel: nextType == 1
                            ? 'Marcar Entrada'
                            : 'Marcar Salida',
                        nextActionIcon: nextType == 1
                            ? Icons.login_rounded
                            : Icons.logout_rounded,
                        onActionPressed: _markAttendance,
                        isProcessing: _isProcessing,
                      ),
                    ),

                    // ── Filter chips ──
                    SliverToBoxAdapter(
                      child: _buildFilterChips(context, historyState),
                    ),

                    // ── History Timeline ──
                    _buildTimelineList(context, historyState),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, String userName,
      AttendanceHistoryState historyState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OfficeFlow',
                style: TextStyle(
                  color: context.colors.primaryAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Asistencias',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _HeaderIconButton(
                icon: Icons.calendar_month_rounded,
                isActive: _showCalendar,
                onTap: () {
                  setState(() {
                    _showCalendar = !_showCalendar;
                  });
                },
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Hero(
                  tag: 'profile_avatar',
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        context.colors.primaryAccent.withOpacity(0.1),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: context.colors.primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Filter Chips ──────────────────────────────────────────────────────────

  Widget _buildFilterChips(
      BuildContext context, AttendanceHistoryState historyState) {
    final currentFilter = historyState.filter;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'Hoy',
            isSelected: currentFilter == AttendanceTimeFilter.today,
            onTap: () => ref
                .read(attendanceHistoryProvider.notifier)
                .setFilter(AttendanceTimeFilter.today),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Semana',
            isSelected: currentFilter == AttendanceTimeFilter.week,
            onTap: () => ref
                .read(attendanceHistoryProvider.notifier)
                .setFilter(AttendanceTimeFilter.week),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Mes',
            isSelected: currentFilter == AttendanceTimeFilter.month,
            onTap: () => ref
                .read(attendanceHistoryProvider.notifier)
                .setFilter(AttendanceTimeFilter.month),
          ),
          if (currentFilter == AttendanceTimeFilter.custom) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: DateFormat('dd MMM', 'es')
                  .format(historyState.customDateRange?.start ?? DateTime.now()),
              isSelected: true,
              onTap: () {
                setState(() => _showCalendar = true);
              },
            ),
          ],
        ],
      ),
    );
  }

  // ── History Timeline ──────────────────────────────────────────────────────

  Widget _buildTimelineList(
      BuildContext context, AttendanceHistoryState state) {
    final grouped = state.groupedByDay;
    if (grouped.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 64,
                color: context.colors.textDisabled,
              ),
              const SizedBox(height: 16),
              Text(
                'Sin registros',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No hay asistencias en este periodo',
                style: TextStyle(
                  color: context.colors.textDisabled,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dayKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final date = dayKeys[index];
          final records = grouped[date]!
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          final isToday = DateUtils.isSameDay(date, DateTime.now());

          return StaggerItem(
            index: index,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Day header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Row(
                    children: [
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.primaryAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'HOY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        )
                      else
                        Text(
                          DateFormat('EEEE, d MMMM', 'es_ES')
                              .format(date)
                              .replaceFirstMapped(
                                RegExp(r'^.'),
                                (m) => m.group(0)!.toUpperCase(),
                              ),
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      const Spacer(),
                      // Record count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              context.colors.primaryAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${records.length}',
                          style: TextStyle(
                            color: context.colors.primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Timeline cards ──
                ...records.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final record = entry.value;
                  return AttendanceTimelineCard(
                    record: record,
                    isFirst: idx == 0,
                    isLast: idx == records.length - 1,
                  );
                }),
              ],
            ),
          );
        },
        childCount: dayKeys.length,
      ),
    );
  }

  // ── Processing Bottom Sheet ───────────────────────────────────────────────

  void _showProcessingBottomSheet(String message) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProcessingSheet(message: message),
    );
  }

  // ── Success Dialog ────────────────────────────────────────────────────────

  void _showSuccessDialog(String time, String office) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: context.colors.glassPanel,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.success.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: context.colors.glassShadow.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Animated check ──
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (_, value, child) => Transform.scale(
                      scale: value,
                      child: child,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.colors.success.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle_rounded,
                          color: context.colors.success, size: 48),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¡Marcación exitosa!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.colors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 15,
                          color: context.colors.textSecondary,
                          height: 1.5),
                      children: [
                        const TextSpan(text: 'Registrada a las '),
                        TextSpan(
                            text: time,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary)),
                        const TextSpan(text: '\nen '),
                        TextSpan(
                            text: office,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primaryAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Genial, gracias',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
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
      barrierDismissible: true,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: context.colors.glassPanel,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.error.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: context.colors.glassShadow.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (_, value, child) => Transform.scale(
                      scale: value,
                      child: child,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.colors.error.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.error_rounded,
                          color: context.colors.error, size: 48),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '¡Ups, algo falló!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: context.colors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message
                        .replaceFirst('Exception: ', '')
                        .replaceFirst('AttendanceException: ', ''),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        color: context.colors.textSecondary,
                        height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primaryAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Entendido',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ─────────────────────────────────────────────────────────

/// A styled icon button for the header area.
class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? context.colors.primaryAccent
              : context.colors.primaryAccent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : context.colors.primaryAccent,
          size: 22,
        ),
      ),
    );
  }
}

/// A small filter chip for time range selection.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primaryAccent
              : context.colors.primaryAccent.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? null
              : Border.all(
                  color: context.colors.primaryAccent.withOpacity(0.15)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.colors.primaryAccent,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// A polished processing bottom sheet with animated indicator.
class _ProcessingSheet extends StatefulWidget {
  const _ProcessingSheet({required this.message});
  final String message;

  @override
  State<_ProcessingSheet> createState() => _ProcessingSheetState();
}

class _ProcessingSheetState extends State<_ProcessingSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
      decoration: BoxDecoration(
        color: colors.glassPanel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textDisabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),

          // ── Pulsing ring ──
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnim.value,
                      child: Opacity(
                        opacity: _opacityAnim.value,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.primaryAccent,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primaryAccent.withOpacity(0.12),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation(colors.primaryAccent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Por favor no cierres la aplicación',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
