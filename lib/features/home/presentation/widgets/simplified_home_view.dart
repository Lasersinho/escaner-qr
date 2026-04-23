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

class SimplifiedHomeView extends ConsumerStatefulWidget {
  const SimplifiedHomeView({super.key});

  @override
  ConsumerState<SimplifiedHomeView> createState() => _SimplifiedHomeViewState();
}

class _SimplifiedHomeViewState extends ConsumerState<SimplifiedHomeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  bool _isProcessing = false;
  DateTime _selectedDate = DateTime.now();
  bool _showCalendar = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
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
    final timestamp = state.serverTimestamp ?? DateTime.now();

    // Add to history list immediately using the server timestamp,
    // NOT DateTime.now(), to avoid showing the wrong time when
    // the device clock is out of sync.
    final typeToAdd =
        state.type == 2 ? AttendanceType.exit : AttendanceType.entry;
    print(
        '[DEBUG] _handleSuccess: adding record of type $typeToAdd to local history');

    ref.read(attendanceHistoryProvider.notifier).addRecord(
          AttendanceRecord(
            id: 'now_${timestamp.millisecondsSinceEpoch}',
            type: typeToAdd,
            dateTime: timestamp,
            employeeId: user?.id ?? 'usr_001',
            officeName: state.officeName,
          ),
        );

    // Re-sync with the server in the background so the optimistic
    // local record is replaced with the real server data.
    ref.read(attendanceHistoryProvider.notifier).fetchHistory();

    _showSuccessDialog(
        state.formattedTime ?? '--:--', state.officeName ?? 'Sede');
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(attendanceHistoryProvider);
    final actionState = ref.watch(attendanceActionProvider);
    final user = ref.watch(authProvider).user;

    // Listen to success/failure
    ref.listen<AttendanceActionState>(attendanceActionProvider, (prev, next) {
      if (next.status == AttendanceActionStatus.success) {
        setState(() => _isProcessing = false);
        _handleSuccess(next);
      } else if (next.status == AttendanceActionStatus.failure) {
        setState(() => _isProcessing = false);
        _showErrorDialog(next.errorMessage ?? 'Error desconocido');
      }
    });

    return Scaffold(
      backgroundColor: context.colors.backgroundStart,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, user?.name ?? 'Usuario', historyState),
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
                            if (DateUtils.isSameDay(date, DateTime.now())) {
                              ref
                                  .read(attendanceHistoryProvider.notifier)
                                  .setFilter(AttendanceTimeFilter.today);
                            } else {
                              ref
                                  .read(attendanceHistoryProvider.notifier)
                                  .setCustomDateRange(
                                    DateTimeRange(start: date, end: date),
                                  );
                            }
                          },
                        )
                      : const SizedBox(width: double.infinity, height: 0),
                ),
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
                        _buildHistoryList(context, historyState),
                        const SliverPadding(
                            padding: EdgeInsets.only(bottom: 100)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Floating Action Button with Pulse
            Positioned(
              bottom: 24,
              right: 24,
              child: _buildFAB(() {
                // BUG FIX #3: Mismo problema en el FAB — calcular el tipo correcto
                // basándose en el último registro de HOY, no en allRecords (que
                // incluye histórico de otros días y puede dar el tipo incorrecto).
                final now = DateTime.now();
                final todayStart = DateTime(now.year, now.month, now.day);
                final todayRecords = historyState.allRecords
                    .where((r) => !r.dateTime.isBefore(todayStart))
                    .toList()
                  ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
                final lastTodayType =
                    todayRecords.isNotEmpty ? todayRecords.first.type : null;
                return lastTodayType == AttendanceType.entry ? 2 : 1;
              }()),
            ),

            if (actionState.status == AttendanceActionStatus.securing)
              _buildProcessingOverlay(actionState.message ?? 'Procesando...'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName,
      AttendanceHistoryState historyState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Asistencias',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 28,
              letterSpacing: -1,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showCalendar = !_showCalendar;
                  });
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _showCalendar
                        ? context.colors.primaryAccent
                        : context.colors.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color:
                        _showCalendar ? Colors.white : context.colors.primaryAccent,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Hero(
                  tag: 'profile_avatar',
                  child: Material(
                    type: MaterialType.transparency,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: context.colors.primaryAccent.withOpacity(0.1),
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Removed _buildFilterSection as it was moved to AppBar

  Widget _buildHistoryList(BuildContext context, AttendanceHistoryState state) {
    final grouped = state.groupedByDay;
    if (grouped.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text('No hay registros en este periodo',
              style: TextStyle(color: context.colors.textSecondary)),
        ),
      );
    }

    final dayKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final date = dayKeys[index];
          final records = grouped[date]!;
          final isToday = DateUtils.isSameDay(date, DateTime.now());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Text(
                  isToday
                      ? 'Hoy'
                      : DateFormat('EEEE, d MMMM', 'es_ES').format(date),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...records.map((r) => _buildHistoryCard(context, r)),
            ],
          );
        },
        childCount: dayKeys.length,
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, AttendanceRecord record) {
    final isEntry = record.type == AttendanceType.entry;
    final timeStr = DateFormat('hh:mm a').format(record.dateTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.colors.primaryAccent.withOpacity(0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.glassShadow.withOpacity(0.04), // Dynamic shadow
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isEntry ? context.colors.success : context.colors.secondaryAccent)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isEntry ? Icons.login_rounded : Icons.logout_rounded,
              color: isEntry ? context.colors.success : context.colors.secondaryAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEntry ? 'Entrada' : 'Salida',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  record.officeName ?? 'Ubicación desconocida',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(int nextType) {
    // nextType: 1 = próxima acción es ENTRADA, 2 = próxima acción es SALIDA
    final isNextEntry = nextType == 1;
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _isProcessing ? 1.0 : _pulseAnim.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _markAttendance,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isNextEntry
                  ? [context.colors.fabGradientStart, context.colors.fabGradientEnd]
                  : [
                      context.colors.secondaryAccent,
                      context.colors.secondaryAccent.withOpacity(0.7)
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: (isNextEntry
                        ? context.colors.primaryAccent
                        : context.colors.secondaryAccent)
                    .withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isNextEntry ? Icons.login_rounded : Icons.logout_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.colors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_circle_rounded,
                        color: context.colors.success, size: 48),
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
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: context.colors.primaryAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 4.0),
                        child: Text('Genial, gracias',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.3)),
                      ),
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
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.colors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_rounded,
                        color: context.colors.error, size: 48),
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
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: context.colors.primaryAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 4.0),
                        child: Text('Entendido',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                height: 1.3)),
                      ),
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

  Widget _buildProcessingOverlay(String message) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

