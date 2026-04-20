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
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRequestingPermissions = false;

  // ── Stagger animations ──
  late final AnimationController _staggerCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _titleFade;
  late final Animation<double> _inputsFade;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _logoSlide;
  late final Animation<Offset> _titleSlide;
  late final Animation<Offset> _inputsSlide;
  late final Animation<Offset> _buttonSlide;

  // ── Background decoration ──
  late final AnimationController _bgCtrl;
  late final Animation<double> _bgAnim;

  @override
  void initState() {
    super.initState();

    // Stagger entrance animation
    _staggerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoFade = _createFade(0.0, 0.35);
    _titleFade = _createFade(0.1, 0.45);
    _inputsFade = _createFade(0.25, 0.65);
    _buttonFade = _createFade(0.4, 0.8);

    _logoSlide = _createSlide(0.0, 0.4);
    _titleSlide = _createSlide(0.1, 0.5);
    _inputsSlide = _createSlide(0.25, 0.7);
    _buttonSlide = _createSlide(0.4, 0.85);

    _staggerCtrl.forward();

    // Subtle background animation
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut),
    );
  }

  Animation<double> _createFade(double start, double end) {
    return CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _createSlide(double start, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _staggerCtrl,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _staggerCtrl.dispose();
    _bgCtrl.dispose();
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
      body: Stack(
        children: [
          // ── Animated background ──
          AnimatedBuilder(
            animation: _bgAnim,
            builder: (context, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: context.colors.backgroundGradient,
                ),
                child: CustomPaint(
                  painter: _BgDecoPainter(
                    progress: _bgAnim.value,
                    color1: context.colors.primaryAccent.withOpacity(0.06),
                    color2: context.colors.secondaryAccent.withOpacity(0.04),
                  ),
                ),
              );
            },
          ),

          // ── Content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlassCard(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Logo ──
                      SlideTransition(
                        position: _logoSlide,
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: Container(
                            width: 80,
                            height: 80,
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
                                  color: context.colors.primaryAccent
                                      .withOpacity(0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.fingerprint_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Title + Subtitle ──
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleFade,
                          child: Column(
                            children: [
                              Text(
                                'OfficeFlow',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      color: context.colors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Control de Asistencia',
                                style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Inputs ──
                      SlideTransition(
                        position: _inputsSlide,
                        child: FadeTransition(
                          opacity: _inputsFade,
                          child: Column(
                            children: [
                              PremiumInput(
                                hint: 'DNI',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 16),
                              PremiumInput(
                                hint: 'Contraseña',
                                controller: _passwordController,
                                obscureText: true,
                                prefixIcon: Icons.lock_outline_rounded,
                                textInputAction: TextInputAction.done,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Error message ──
                      if (authState.status == AuthStatus.error) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: context.colors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: context.colors.error.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: context.colors.error, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  authState.errorMessage ?? 'Error desconocido',
                                  style: TextStyle(
                                    color: context.colors.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // ── Submit ──
                      SlideTransition(
                        position: _buttonSlide,
                        child: FadeTransition(
                          opacity: _buttonFade,
                          child: NeoButton(
                            label: 'Iniciar Sesión',
                            icon: Icons.arrow_forward_rounded,
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _handleLogin,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Version indicator ──
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _buttonFade,
              child: Text(
                'v1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.textDisabled,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints subtle decorative circles that drift slowly in the background.
class _BgDecoPainter extends CustomPainter {
  _BgDecoPainter({
    required this.progress,
    required this.color1,
    required this.color2,
  });

  final double progress;
  final Color color1;
  final Color color2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    // Top-right circle drifts down
    canvas.drawCircle(
      Offset(
        size.width * 0.85,
        size.height * (0.08 + progress * 0.04),
      ),
      size.width * 0.35,
      paint1,
    );

    // Bottom-left circle drifts up
    canvas.drawCircle(
      Offset(
        size.width * 0.15,
        size.height * (0.92 - progress * 0.04),
      ),
      size.width * 0.30,
      paint2,
    );

    // Center-right accent
    canvas.drawCircle(
      Offset(
        size.width * (0.7 + progress * 0.05),
        size.height * 0.55,
      ),
      size.width * 0.18,
      Paint()..color = color1.withOpacity(0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _BgDecoPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
