import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/html_entry.dart';
import '../../storage/history_storage.dart';
import '../settings/settings_controller.dart';

/// Recently opened HTML files, newest first, capped by the user's
/// recentLimit setting.
final recentsProvider =
    NotifierProvider<RecentsNotifier, List<HtmlEntry>>(RecentsNotifier.new);

class RecentsNotifier extends Notifier<List<HtmlEntry>> {
  static const maxEntries = 20;

  late final RecentStorage _storage;

  @override
  List<HtmlEntry> build() {
    _storage = ref.watch(recentStorageProvider);
    final limit = ref.watch(settingsProvider.select((s) => s.recentLimit));
    return _storage.loadFiles(limit: limit);
  }

  /// Records an open event: moves the entry to the front and refreshes its
  /// timestamp, dropping the oldest when over the cap.
  Future<void> recordOpen(HtmlEntry entry) async {
    final limit = ref.read(settingsProvider).recentLimit;
    final next = [
      entry,
      ...state.where((e) => e.path != entry.path),
    ].take(limit).toList();
    state = next;
    await _storage.saveFiles(next);
  }

  Future<void> remove(String path) async {
    final next = state.where((e) => e.path != path).toList();
    state = next;
    await _storage.saveFiles(next);
  }

  Future<void> clear() async {
    state = [];
    await _storage.saveFiles([]);
  }
}

/// Favorited HTML files.
final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<HtmlEntry>>(
        FavoritesNotifier.new);

class FavoritesNotifier extends Notifier<List<HtmlEntry>> {
  late final FavoritesStorage _storage;

  @override
  List<HtmlEntry> build() {
    _storage = ref.watch(favoritesStorageProvider);
    return _storage.load();
  }

  bool isFavorite(String path) => state.any((e) => e.path == path);

  Future<void> toggle(HtmlEntry entry) async {
    final next = isFavorite(entry.path)
        ? state.where((e) => e.path != entry.path).toList()
        : [entry, ...state];
    state = next;
    await _storage.save(next);
  }

  Future<void> remove(String path) async {
    final next = state.where((e) => e.path != path).toList();
    state = next;
    await _storage.save(next);
  }

  Future<void> clear() async {
    state = [];
    await _storage.save([]);
  }
}

/// Recently opened project folders, newest first.
final projectsProvider =
    NotifierProvider<ProjectsNotifier, List<ProjectEntry>>(
        ProjectsNotifier.new);

class ProjectsNotifier extends Notifier<List<ProjectEntry>> {
  static const maxEntries = 12;

  late final RecentStorage _storage;

  @override
  List<ProjectEntry> build() {
    _storage = ref.watch(recentStorageProvider);
    return _storage.loadProjects(limit: maxEntries);
  }

  Future<void> recordOpen(ProjectEntry entry) async {
    final next = [
      entry,
      ...state.where((e) => e.rootPath != entry.rootPath),
    ].take(maxEntries).toList();
    state = next;
    await _storage.saveProjects(next);
  }

  Future<void> remove(String rootPath) async {
    final next = state.where((e) => e.rootPath != rootPath).toList();
    state = next;
    await _storage.saveProjects(next);
  }
}
