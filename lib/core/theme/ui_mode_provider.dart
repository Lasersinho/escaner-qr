import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kUiModeKey = 'app_ui_mode_simplified';

/// Provider for managing the UI mode (Simplified = true, Premium = false).
/// Starts with Premium mode (false) by default.
final uiModeProvider = StateNotifierProvider<UiModeNotifier, bool>((ref) {
  return UiModeNotifier();
});

class UiModeNotifier extends StateNotifier<bool> {
  UiModeNotifier() : super(false) {
    _load();
  }

  final _storage = const FlutterSecureStorage();

  Future<void> _load() async {
    final raw = await _storage.read(key: _kUiModeKey);
    state = raw == 'true';
  }

  /// Toggles the UI Mode between Simplified and Premium.
  Future<void> toggle() async {
    state = !state;
    await _storage.write(key: _kUiModeKey, value: state.toString());
  }

  /// Set a specific mode directly.
  Future<void> setSimplifiedMode(bool isSimplified) async {
    state = isSimplified;
    await _storage.write(key: _kUiModeKey, value: state.toString());
  }
}
