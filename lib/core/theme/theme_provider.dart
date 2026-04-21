import 'dart:ui' as ui;
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
    final mode = switch (raw) {
      'light'  => ThemeMode.light,
      'dark'   => ThemeMode.dark,
      _        => ThemeMode.system,
    };
    state = mode;
    _updateSystemUI(mode);
  }

  void _updateSystemUI(ThemeMode mode) {
    final isDark = mode == ThemeMode.dark ||
        (mode == ThemeMode.system &&
            ui.PlatformDispatcher.instance.platformBrightness ==
                Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
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

    _updateSystemUI(next);
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
    _updateSystemUI(mode);
  }
}
