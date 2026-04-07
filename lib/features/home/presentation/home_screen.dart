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

    // Determine type based on the last record if available, or default to entry
    final history = ref.read(attendanceHistoryProvider).allRecords;
    final lastType = history.isNotEmpty ? history.first.type : AttendanceType.exit;
    final nextType = lastType == AttendanceType.entry ? 2 : 1;

    ref.read(attendanceActionProvider.notifier).processAttendance(type: nextType);
  }

  void _handleSuccess(AttendanceActionState state) {
    final user = ref.read(authProvider).user;
    final now = DateTime.now();

    // Add to history list immediately
    ref.read(attendanceHistoryProvider.notifier).addRecord(
          AttendanceRecord(
            id: 'now_${now.millisecondsSinceEpoch}',
            type: state.message?.contains('salida') == true
                ? AttendanceType.exit
                : AttendanceType.entry,
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
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, user?.name ?? 'Usuario'),
              _buildFilterSection(historyState),
              _buildHistoryList(historyState),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),

          // Floating Action Button with Pulse
          Positioned(
            bottom: 24,
            right: 24,
            child: _buildFAB(),
          ),

          if (actionState.status == AttendanceActionStatus.securing)
            _buildProcessingOverlay(actionState.message ?? 'Procesando...'),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, String userName) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.backgroundStart,
      elevation: 0,
      centerTitle: false,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        centerTitle: false,
        title: const Text(
          'Historial',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24),
          child: GestureDetector(
            onTap: () => context.push('/profile'),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primaryAccent.withOpacity(0.1),
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(AttendanceHistoryState state) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: AttendanceTimeFilter.values.map((filter) {
              final isSelected = state.filter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilterChip(
                  label: Text(filter == AttendanceTimeFilter.today ? 'Hoy' : 
                             filter == AttendanceTimeFilter.week ? 'Semana' :
                             filter == AttendanceTimeFilter.month ? 'Mes' : 'Fecha'),
                  selected: isSelected,
                  onSelected: (_) {
                    if (filter == AttendanceTimeFilter.custom) {
                      _selectCustomDateRange();
                    } else {
                      ref.read(attendanceHistoryProvider.notifier).setFilter(filter);
                    }
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primaryAccent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                  elevation: 0,
                  pressElevation: 0,
                  side: BorderSide(
                    color: isSelected ? Colors.transparent : AppColors.primaryAccent.withOpacity(0.1),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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

  Widget _buildFAB() {
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
          width: 72,
          height: 72,
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
              size: 36,
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
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: GlassCard(
            width: 300,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
                const SizedBox(height: 16),
                const Text('¡Hecho!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Marcación registrada a las $time', textAlign: TextAlign.center),
                Text('en $office', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                NeoButton(label: 'Cerrar', onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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
