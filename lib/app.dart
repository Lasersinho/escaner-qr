import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/home/presentation/profile_screen.dart';
import 'features/attendance/presentation/scanner_screen.dart';
import 'core/theme/app_page_transitions.dart';

/// Root application widget containing theme and router configuration.
class OfficeFlowApp extends ConsumerWidget {
  const OfficeFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'OfficeFlow',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}

// ── GoRouter ────────────────────────────────────────────────────────────────

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _AuthRefreshListenable(ref, authProvider),
    redirect: (context, state) {
      final isAuthenticated =
          authState.status == AuthStatus.authenticated;
      final isOnLogin = state.matchedLocation == '/login';

      if (isAuthenticated && isOnLogin) return '/home';
      if (!isAuthenticated && !isOnLogin) return '/login';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => AppPageTransitions.fadeScale(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => AppPageTransitions.fadeScale(
          key: state.pageKey,
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => AppPageTransitions.slideUp(
          key: state.pageKey,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/scanner',
        pageBuilder: (context, state) => AppPageTransitions.fadeScale(
          key: state.pageKey,
          child: const ScannerScreen(),
        ),
      ),
    ],
  );
});

/// Bridges Riverpod changes to [GoRouter.refreshListenable].
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref, StateNotifierProvider<AuthNotifier, AuthState> provider) {
    ref.listen<AuthState>(provider, (_, _) {
      notifyListeners();
    });
  }
}

