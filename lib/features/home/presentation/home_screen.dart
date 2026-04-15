import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../attendance/domain/attendance_record.dart';
import '../../attendance/presentation/attendance_history_provider.dart';
import '../../attendance/presentation/attendance_provider.dart';
import '../../auth/presentation/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  bool _isProcessing = false;

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

    // Determine type using the latest real record, not the filtered view.
    final historyState = ref.read(attendanceHistoryProvider);
    final latestRecord = historyState.latestRecord;
    final lastType = latestRecord?.type ?? AttendanceType.exit;
    final nextType = lastType == AttendanceType.entry ? 2 : 1;

    print('[DEBUG] _markAttendance: allRecords.length=${historyState.allRecords.length}');
    if (latestRecord != null) {
      print('[DEBUG] _markAttendance: lastType=${latestRecord.type}');
    }
    print('[DEBUG] _markAttendance: nextType=$nextType');

    // If marking exit, find the token from today's entry
    String? existingToken;
    if (nextType == 2) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Find today's entry record
      final todayEntries = ref.read(attendanceHistoryProvider).allRecords.where((record) =>
          record.type == AttendanceType.entry &&
          record.dateTime.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          record.dateTime.isBefore(todayEnd.add(const Duration(seconds: 1)))
      ).toList();

      if (todayEntries.isNotEmpty) {
        // Use the token from the most recent entry
        existingToken = todayEntries.first.token;
        print('[DEBUG] _markAttendance: Using existing token from today\'s entry: $existingToken');
      }
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
    final typeToAdd = state.type == 2 ? AttendanceType.exit : AttendanceType.entry;
    print('[DEBUG] _handleSuccess: adding record of type $typeToAdd to local history');

    ref.read(attendanceHistoryProvider.notifier).addRecord(
          AttendanceRecord(
            id: 'now_${now.millisecondsSinceEpoch}',
            type: typeToAdd,
            dateTime: now,
            employeeId: user?.id ?? 'usr_001',
            officeName: state.officeName,
          ),
        );

    _showSuccessDialog(state.formattedTime ?? '--:--', state.officeName ?? 'Sede');
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
      backgroundColor: AppColors.backgroundStart,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, user?.name ?? 'Usuario', historyState),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await ref.read(attendanceHistoryProvider.notifier).fetchHistory();
                    },
                    color: AppColors.primaryAccent,
                    backgroundColor: AppColors.backgroundStart,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        _buildHistoryList(historyState),
                        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
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
            child: _buildFAB(
              historyState.latestRecord == null ||
              historyState.latestRecord!.type == AttendanceType.exit
            ),
          ),

          if (actionState.status == AttendanceActionStatus.securing)
            _buildProcessingOverlay(actionState.message ?? 'Procesando...'),
        ],
      ),
    ),
  );
}

  Widget _buildHeader(BuildContext context, String userName, AttendanceHistoryState historyState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryAccent.withOpacity(0.1),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Historial',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          _buildFilterPill(historyState),
        ],
      ),
    );
  }

  Widget _buildFilterPill(AttendanceHistoryState historyState) {
    return PopupMenuButton<AttendanceTimeFilter>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 40),
      onSelected: (filter) {
        if (filter == AttendanceTimeFilter.custom) {
          _selectCustomDateRange();
        } else {
          ref.read(attendanceHistoryProvider.notifier).setFilter(filter);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: AttendanceTimeFilter.today, child: Text('Hoy')),
        const PopupMenuItem(value: AttendanceTimeFilter.week, child: Text('Esta Semana')),
        const PopupMenuItem(value: AttendanceTimeFilter.month, child: Text('Este Mes')),
        const PopupMenuItem(value: AttendanceTimeFilter.custom, child: Text('Fechas Específicas')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primaryAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              historyState.filter.label,
              style: const TextStyle(
                color: AppColors.primaryAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryAccent, size: 18),
          ],
        ),
      ),
    );
  }

  // Removed _buildFilterSection as it was moved to AppBar

  Widget _buildHistoryList(AttendanceHistoryState state) {
    final grouped = state.groupedByDay;
    if (grouped.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text('No hay registros en este periodo', style: TextStyle(color: AppColors.textSecondary)),
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
                  isToday ? 'Hoy' : DateFormat('EEEE, d MMMM', 'es_ES').format(date),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ...records.map((r) => _buildHistoryCard(r)),
            ],
          );
        },
        childCount: dayKeys.length,
      ),
    );
  }

  Widget _buildHistoryCard(AttendanceRecord record) {
    final isEntry = record.type == AttendanceType.entry;
    final timeStr = DateFormat('hh:mm a').format(record.dateTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryAccent.withOpacity(0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withOpacity(0.04),
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
              color: (isEntry ? AppColors.success : AppColors.secondaryAccent).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isEntry ? Icons.login_rounded : Icons.logout_rounded,
              color: isEntry ? AppColors.success : AppColors.secondaryAccent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEntry ? 'Entrada' : 'Salida',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  record.officeName ?? 'Ubicación desconocida',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(bool isNextEntry) {
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
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.fabGradientStart, AppColors.fabGradientEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryAccent.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.touch_app_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectCustomDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryAccent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      ref.read(attendanceHistoryProvider.notifier).setCustomDateRange(range);
    }
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '¡Marcación exitosa!', 
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.w800, 
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
                      children: [
                        const TextSpan(text: 'Registrada a las '),
                        TextSpan(text: time, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const TextSpan(text: '\nen '),
                        TextSpan(text: office, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Genial, gracias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_rounded, color: AppColors.error, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '¡Ups, algo falló!', 
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.w800, 
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message.replaceFirst('Exception: ', '').replaceFirst('AttendanceException: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Entendido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
