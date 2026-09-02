import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/html_entry.dart';
import 'settings_storage.dart';

/// Persists recently opened HTML files and project folders.
class RecentStorage {
  RecentStorage(this._prefs);

  static const _filesKey = 'htmlviewer.recent.files';
  static const _projectsKey = 'htmlviewer.recent.projects';
  static const int defaultLimit = 20;

  final SharedPreferences _prefs;

  List<HtmlEntry> loadFiles({int limit = defaultLimit}) =>
      decodeList<HtmlEntry>(_prefs.getString(_filesKey), HtmlEntry.fromJson)
          .take(limit)
          .toList();

  Future<void> saveFiles(List<HtmlEntry> files) =>
      _prefs.setString(_filesKey, encodeList(files, (e) => e.toJson()));

  List<ProjectEntry> loadProjects({int limit = defaultLimit}) => decodeList(
      _prefs.getString(_projectsKey), ProjectEntry.fromJson)
      .take(limit)
      .toList();

  Future<void> saveProjects(List<ProjectEntry> projects) =>
      _prefs.setString(_projectsKey, encodeList(projects, (e) => e.toJson()));

  Future<void> clear() async {
    await _prefs.remove(_filesKey);
    await _prefs.remove(_projectsKey);
  }
}

/// Persists favorited HTML files.
class FavoritesStorage {
  FavoritesStorage(this._prefs);

  static const _key = 'htmlviewer.favorites';

  final SharedPreferences _prefs;

  List<HtmlEntry> load() =>
      decodeList<HtmlEntry>(_prefs.getString(_key), HtmlEntry.fromJson);

  Future<void> save(List<HtmlEntry> favorites) =>
      _prefs.setString(_key, encodeList(favorites, (e) => e.toJson()));

  Future<void> clear() => _prefs.remove(_key);
}

/// Shared storage instances backed by the root [SharedPreferences].
final recentStorageProvider = Provider<RecentStorage>(
    (ref) => RecentStorage(ref.watch(prefsProvider)));

final favoritesStorageProvider = Provider<FavoritesStorage>(
    (ref) => FavoritesStorage(ref.watch(prefsProvider)));
