import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/editor/editor_page.dart';
import '../features/favorites/favorites_page.dart';
import '../features/files/files_page.dart';
import '../features/home/home_page.dart';
import '../features/settings/settings_page.dart';

/// Index of the currently visible tab in [RootShell].
final shellIndexProvider = StateProvider<int>((ref) => 0);

/// Tab indexes of the navigation destinations (shared with pages that jump
/// to a specific tab, e.g. the home header's settings shortcut).
const homeTabIndex = 0;
const filesTabIndex = 1;
const editorTabIndex = 2;
const favoritesTabIndex = 3;
const settingsTabIndex = 4;

/// App scaffold with navigation for 首页 / 文件 / 编写 / 收藏 / 设置.
class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  static const _pages = [
    HomePage(),
    FilesPage(),
    EditorPage(),
    FavoritesPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellIndexProvider);
    final wide = MediaQuery.sizeOf(context).width >= 600;

    if (wide) {
      // Tablet / landscape: navigation rail on the left.
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (value) =>
                  ref.read(shellIndexProvider.notifier).state = value,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('首页'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: Text('文件'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.edit_outlined),
                  selectedIcon: Icon(Icons.edit),
                  label: Text('编写'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.star_border),
                  selectedIcon: Icon(Icons.star),
                  label: Text('收藏'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('设置'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: IndexedStack(index: index, children: _pages)),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) =>
            ref.read(shellIndexProvider.notifier).state = value,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: '文件',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: '编写',
          ),
          NavigationDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: '收藏',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
