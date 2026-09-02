import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../storage/settings_storage.dart';
import 'settings_model.dart';

/// Global settings state, persisted through [SettingsStorage].
final settingsProvider =
    NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<Settings> {
  late final SettingsStorage _storage;

  @override
  Settings build() {
    _storage = SettingsStorage(ref.read(prefsProvider));
    return _storage.load();
  }

  Future<void> _update(Settings next) async {
    state = next;
    await _storage.save(next);
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setPixelFont(bool value) =>
      _update(state.copyWith(pixelFont: value));

  Future<void> setAnimations(bool value) =>
      _update(state.copyWith(animations: value));

  Future<void> setUiStrength(PixelStrength value) =>
      _update(state.copyWith(uiStrength: value));

  Future<void> setCornerRadius(double value) =>
      _update(state.copyWith(cornerRadius: value));

  Future<void> setJavascript(bool value) =>
      _update(state.copyWith(javascript: value));

  Future<void> setAllowNetwork(bool value) =>
      _update(state.copyWith(allowNetwork: value));

  Future<void> setRecentLimit(int value) =>
      _update(state.copyWith(recentLimit: value));

  /// Replaces all settings from an imported map.
  Future<void> importFrom(Map<String, dynamic> json) =>
      _update(Settings.fromJson(json));

  Future<void> resetToDefaults() => _update(const Settings());

  Future<void> setCodeFontSize(double value) =>
      _update(state.copyWith(codeFontSize: value.clamp(9.0, 24.0)));

  Future<void> setCodeWordWrap(bool value) =>
      _update(state.copyWith(codeWordWrap: value));

  Future<void> setShowLineNumbers(bool value) =>
      _update(state.copyWith(showLineNumbers: value));

  Future<void> setDefaultViewerTab(ViewerTab value) =>
      _update(state.copyWith(defaultViewerTab: value));
}
