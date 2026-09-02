import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:htmlviewer/data/models/html_entry.dart';
import 'package:htmlviewer/features/files/history_controllers.dart';
import 'package:htmlviewer/features/settings/settings_controller.dart';
import 'package:htmlviewer/features/settings/settings_model.dart';
import 'package:htmlviewer/storage/settings_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [prefsProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

HtmlEntry _entry(String name, {String? path, int? size}) => HtmlEntry(
      path: path ?? '/storage/emulated/0/web/$name',
      name: name,
      openedAt: DateTime.now(),
      size: size,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecentsNotifier', () {
    test('records opens newest-first and dedupes by path', () async {
      final container = await _container();

      await container
          .read(recentsProvider.notifier)
          .recordOpen(_entry('a.html'));
      await container
          .read(recentsProvider.notifier)
          .recordOpen(_entry('b.html'));
      await container
          .read(recentsProvider.notifier)
          .recordOpen(_entry('a.html'));

      final recents = container.read(recentsProvider);
      expect(recents.length, 2);
      expect(recents.first.name, 'a.html');
      expect(recents.last.name, 'b.html');
    });

    test('caps at 20 entries', () async {
      final container = await _container();
      final notifier = container.read(recentsProvider.notifier);
      for (var i = 0; i < 25; i++) {
        await notifier.recordOpen(_entry('f$i.html'));
      }
      expect(container.read(recentsProvider).length, 20);
      expect(container.read(recentsProvider).first.name, 'f24.html');
    });

    test('persists across container restarts', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final first = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      await first
          .read(recentsProvider.notifier)
          .recordOpen(_entry('persist.html'));
      first.dispose();

      final second = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);
      expect(second.read(recentsProvider).single.name, 'persist.html');
    });

    test('remove deletes only the target entry', () async {
      final container = await _container();
      final notifier = container.read(recentsProvider.notifier);
      await notifier.recordOpen(_entry('keep.html'));
      await notifier.recordOpen(_entry('drop.html'));
      await notifier.remove('/storage/emulated/0/web/drop.html');

      final recents = container.read(recentsProvider);
      expect(recents.length, 1);
      expect(recents.single.name, 'keep.html');
    });
  });

  group('FavoritesNotifier', () {
    test('toggle adds then removes', () async {
      final container = await _container();
      final notifier = container.read(favoritesProvider.notifier);

      await notifier.toggle(_entry('x.html'));
      expect(notifier.isFavorite('/storage/emulated/0/web/x.html'), isTrue);

      await notifier.toggle(_entry('x.html'));
      expect(container.read(favoritesProvider), isEmpty);
    });
  });

  group('HtmlEntry', () {
    test('extension and folder parsing', () {
      final e = _entry('index.html');
      expect(e.extension, 'html');
      expect(e.folder, '/storage/emulated/0/web');

      expect(_entry('noext').extension, '');
      expect(_entry('weird.').extension, '');
    });

    test('JSON roundtrip', () {
      final e = _entry('a.htm', size: 123);
      final restored = HtmlEntry.fromJson(e.toJson());
      expect(restored.path, e.path);
      expect(restored.name, e.name);
      expect(restored.size, 123);
    });
  });

  group('Settings.javascript', () {
    test('roundtrips through JSON', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container
          .read(settingsProvider.notifier)
          .setJavascript(false);
      expect(container.read(settingsProvider).javascript, isFalse);

      // A fresh container reads the persisted value.
      final second = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);
      expect(second.read(settingsProvider).javascript, isFalse);
    });
  });

  group('Settings phase 7 fields', () {
    test('allowNetwork and recentLimit roundtrip through JSON', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      await notifier.setAllowNetwork(false);
      await notifier.setRecentLimit(50);
      expect(container.read(settingsProvider).allowNetwork, isFalse);
      expect(container.read(settingsProvider).recentLimit, 50);

      final second = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(second.dispose);
      expect(second.read(settingsProvider).allowNetwork, isFalse);
      expect(second.read(settingsProvider).recentLimit, 50);
    });

    test('resetToDefaults restores factory values', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      await notifier.setAllowNetwork(false);
      await notifier.setRecentLimit(5);
      await notifier.setJavascript(false);
      await notifier.resetToDefaults();

      final s = container.read(settingsProvider);
      expect(s.allowNetwork, isTrue);
      expect(s.recentLimit, 20);
      expect(s.javascript, isTrue);
      expect(s.themeMode, AppThemeMode.system);
    });

    test('importFrom applies an exported settings map', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [prefsProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      await container.read(settingsProvider.notifier).importFrom({
        'themeMode': 'dark',
        'allowNetwork': false,
        'recentLimit': 10,
      });

      final s = container.read(settingsProvider);
      expect(s.themeMode, AppThemeMode.dark);
      expect(s.allowNetwork, isFalse);
      expect(s.recentLimit, 10);
      // Unspecified fields fall back to defaults.
      expect(s.javascript, isTrue);
    });
  });
}
