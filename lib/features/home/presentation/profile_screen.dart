import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/ui_mode_provider.dart';
import '../../../shared/widgets/neo_button.dart';
import '../../../shared/widgets/stagger_list.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/domain/user.dart';
import '../../attendance/presentation/attendance_history_provider.dart';
import '../../attendance/domain/attendance_record.dart';

/// Profile screen – shows user info, stats, settings and logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final historyState = ref.watch(attendanceHistoryProvider);
    final name = user?.fullName ?? 'Usuario';
    final email = user?.email ?? '—';
    final initials = _getInitials(name);

    // Compute stats
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthRecords = historyState.allRecords
        .where((r) => !r.dateTime.isBefore(monthStart))
        .toList();
    final monthEntries =
        monthRecords.where((r) => r.type == AttendanceType.entry).length;

    // Days worked this month (unique days with entries)
    final daysWorked = <String>{};
    for (final r in monthRecords) {
      if (r.type == AttendanceType.entry) {
        daysWorked
            .add('${r.dateTime.year}-${r.dateTime.month}-${r.dateTime.day}');
      }
    }

    return Scaffold(
      backgroundColor: context.colors.backgroundStart,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: context.colors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // ── Avatar ──
                      StaggerItem(
                        index: 0,
                        child: _buildAvatar(context, initials),
                      ),
                      const SizedBox(height: 16),

                      // ── Name ──
                      StaggerItem(
                        index: 1,
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontSize: 22,
                                color: context.colors.textPrimary,
                              ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ── Email ──
                      StaggerItem(
                        index: 2,
                        child: Text(
                          email,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: context.colors.textSecondary,
                                  ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Stats Cards ──
                      StaggerItem(
                        index: 3,
                        child: _buildStatsRow(
                            context, monthEntries, daysWorked.length),
                      ),

                      const SizedBox(height: 24),

                      // ── Info Card ──
                      StaggerItem(
                        index: 4,
                        child: _buildInfoCard(context, user),
                      ),
                      const SizedBox(height: 16),

                      // ── Settings Card ──
                      StaggerItem(
                        index: 5,
                        child: _buildSettingsCard(context, ref),
                      ),

                      const SizedBox(height: 28),

                      // ── Logout ──
                      StaggerItem(
                        index: 7,
                        child: NeoButton(
                          label: 'Cerrar Sesión',
                          icon: Icons.logout_rounded,
                          variant: NeoButtonVariant.danger,
                          onPressed: () {
                            ref.read(authProvider.notifier).logout();
                          },
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.primaryAccent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: context.colors.textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              'Mi Perfil',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          // Spacer for symmetry
          const SizedBox(width: 56),
        ],
      ),
    );
  }

  // ── Avatar ───────────────────────────────────────────────────────────────

  Widget _buildAvatar(BuildContext context, String initials) {
    return Hero(
      tag: 'profile_avatar',
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.colors.primaryAccent,
              context.colors.secondaryAccent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: context.colors.primaryAccent.withOpacity(0.40),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    ),
  );
}

  // ── Stats Row ─────────────────────────────────────────────────────────────

  Widget _buildStatsRow(
      BuildContext context, int totalEntries, int daysWorked) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.login_rounded,
            value: '$totalEntries',
            label: 'Entradas\neste mes',
            color: context.colors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.calendar_today_rounded,
            value: '$daysWorked',
            label: 'Días\ntrabajados',
            color: context.colors.primaryAccent,
          ),
        ),
      ],
    );
  }

  // ── Info Card ─────────────────────────────────────────────────────────────

  Widget _buildInfoCard(BuildContext context, User? user) {
    final document = user?.document;

    return _SectionCard(
      title: 'Información Personal',
      children: [
        if (user?.name != null && user!.name.isNotEmpty)
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Nombre',
            value: user.name,
          ),
        if (user?.lastname != null && user!.lastname.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: context.colors.divider, height: 1),
          ),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Apellido',
            value: user.lastname,
          ),
        ],
        if (document != null && document.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: context.colors.divider, height: 1),
          ),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Documento',
            value: document,
          ),
        ],
        if ((document == null || document.isEmpty) &&
            (user?.name == null || user!.name.isEmpty)) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Información no disponible',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Settings Card ──────────────────────────────────────────────────────────

  Widget _buildSettingsCard(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _SectionCard(
      title: 'Ajustes',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.primaryAccent.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: context.colors.primaryAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo Oscuro',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDark ? 'Activado' : 'Desactivado',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          letterSpacing: 0.3,
                          color: context.colors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isDark,
              activeColor: context.colors.primaryAccent,
              onChanged: (_) {
                ref.read(themeModeProvider.notifier).toggle(context);
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Divider(color: context.colors.divider, height: 1),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.primaryAccent.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.view_agenda_rounded,
                color: context.colors.primaryAccent,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo Simplificado',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Interfaz clásica y robusta',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          letterSpacing: 0.3,
                          color: context.colors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: ref.watch(uiModeProvider),
              activeColor: context.colors.primaryAccent,
              onChanged: (_) {
                ref.read(uiModeProvider.notifier).toggle();
              },
            ),
          ],
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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

// ── Stat Card Widget ────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.glassShadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Card Widget ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.cardSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusPanel),
        border: Border.all(
          color: context.colors.primaryAccent.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.glassShadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.2,
                ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ── Info Row Widget ──────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: context.colors.primaryAccent.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: context.colors.primaryAccent, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? context.colors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
