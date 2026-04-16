import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Theme Provider ────────────────────────────────────────────────────────────

const _kThemeModeKey = 'app_theme_mode';

/// Estado del modo de tema: light, dark o system.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  final _storage = const FlutterSecureStorage();

  Future<void> _load() async {
    final raw = await _storage.read(key: _kThemeModeKey);
    state = switch (raw) {
      'light'  => ThemeMode.light,
      'dark'   => ThemeMode.dark,
      _        => ThemeMode.system,
    };
  }

  /// Alterna entre light y dark (si estaba en system, primero detecta el actual).
  Future<void> toggle(BuildContext context) async {
    final currentBrightness = Theme.of(context).brightness;
    final isCurrentlyDark = currentBrightness == Brightness.dark;

    final next = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    await _storage.write(
      key: _kThemeModeKey,
      value: next == ThemeMode.dark ? 'dark' : 'light',
    );

    // Actualizar la barra de estado del sistema
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness:
            next == ThemeMode.dark ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
      ),
    );
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _storage.write(
      key: _kThemeModeKey,
      value: switch (mode) {
        ThemeMode.dark   => 'dark',
        ThemeMode.light  => 'light',
        ThemeMode.system => 'system',
      },
    );
  }
}
