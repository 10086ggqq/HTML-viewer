import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/settings/settings_model.dart';

/// Root [SharedPreferences] instance.
///
/// Always overridden in `main()` with the real instance so that storage
/// access stays synchronous after startup.
final prefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('prefsProvider must be overridden in main()');
});

/// Persists [Settings] as a single JSON blob.
class SettingsStorage {
  SettingsStorage(this._prefs);

  static const _key = 'htmlviewer.settings';

  final SharedPreferences _prefs;

  Settings load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const Settings();
    try {
      return Settings.fromJsonString(raw);
    } catch (_) {
      // Corrupted entry: fall back to defaults.
      return const Settings();
    }
  }

  Future<void> save(Settings settings) =>
      _prefs.setString(_key, settings.toJsonString());
}
