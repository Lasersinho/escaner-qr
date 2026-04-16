import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/neo_button.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/domain/user.dart';

/// Profile screen – shows user info and logout action.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.fullName ?? 'Usuario';
    final email = user?.email ?? '—';
    final initials = _getInitials(name);

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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildAvatar(context, initials),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 22, color: context.colors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 36),
                      _buildInfoCard(context, user),
                      const SizedBox(height: 24),
                      _buildSettingsCard(context, ref),
                      const SizedBox(height: 32),
                      NeoButton(
                        label: 'Cerrar Sesión',
                        onPressed: () {
                          ref.read(authProvider.notifier).logout();
                        },
                      ),
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
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: context.colors.textPrimary),
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
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Avatar ───────────────────────────────────────────────────────────────

  Widget _buildAvatar(BuildContext context, String initials) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colors.primaryAccent, context.colors.secondaryAccent],
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
    );
  }

  // ── Info Card ─────────────────────────────────────────────────────────────

  Widget _buildInfoCard(BuildContext context, User? user) {
    final document = user?.document;
    final userId = user?.id;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusPanel),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.colors.glassPanel,
            borderRadius: BorderRadius.circular(AppTokens.radiusPanel),
            border: Border.all(color: context.colors.glassBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: context.colors.glassShadow,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Información Personal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              if (document != null && document.isNotEmpty) ...[
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Documento',
                  value: document,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: context.colors.glassBorder, height: 1),
                ),
              ],
              if ((document == null || document.isEmpty) &&
                  (userId == null || userId.isEmpty)) ...[
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
          ),
        ),
      ),
    );
  }

  // ── Settings Card ──────────────────────────────────────────────────────────

  Widget _buildSettingsCard(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // Para simplificar la UI, si es system no mostramos toggle apagado, evaluamos 
    // su estado visual real basado en Brightness del context
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusPanel),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.colors.glassPanel,
            borderRadius: BorderRadius.circular(AppTokens.radiusPanel),
            border: Border.all(color: context.colors.glassBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: context.colors.glassShadow,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajustes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
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
            ],
          ),
        ),
      ),
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
            color:
                context.colors.primaryAccent.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: context.colors.primaryAccent, size: 18),
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
