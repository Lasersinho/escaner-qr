import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/neo_button.dart';
import '../../../shared/widgets/premium_input.dart';
import 'auth_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Full-screen login screen with a Glass-Neo-Minimalism aesthetic.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  bool _isRequestingPermissions = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _isRequestingPermissions = true);

    try {
      // Regla de Negocio: Se deben conceder todos los accesos nativos para entrar
      final Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
      ].request();

      final bool locGranted = statuses[Permission.location]?.isGranted ?? false;

      if (!locGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Operación Denegada: Requerimos permisos de GPS obligatoriamente para tu sesión.'),
            backgroundColor: context.colors.error,
          ),
        );
        return; // Aborta inicio de sesión
      }

      if (!mounted) return;
      ref.read(authProvider.notifier).login(
            email: email,
            password: password,
          );
    } finally {
      if (mounted) setState(() => _isRequestingPermissions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating || _isRequestingPermissions;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: context.colors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: GlassCard(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Logo placeholder ──
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              context.colors.primaryAccent,
                              context.colors.secondaryAccent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.primaryAccent.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Title ──
                      Text(
                        'Pulse',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: context.colors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Email ──
                      PremiumInput(
                        hint: 'DNI',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 16),

                      // ── Password ──
                      PremiumInput(
                        hint: 'Contraseña',
                        controller: _passwordController,
                        obscureText: true,
                        prefixIcon: Icons.lock_outline_rounded,
                        textInputAction: TextInputAction.done,
                      ),

                      // ── Error message ──
                      if (authState.status == AuthStatus.error) ...[
                        const SizedBox(height: 12),
                        Text(
                          authState.errorMessage ?? 'Error desconocido',
                          style: TextStyle(
                            color: context.colors.error,
                            fontSize: 13,
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ── Submit ──
                      NeoButton(
                        label: 'Entrar',
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _handleLogin,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
