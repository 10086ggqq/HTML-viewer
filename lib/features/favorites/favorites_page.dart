import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/pixel_card.dart';
import '../../widgets/pixel_empty_state.dart';
import '../../widgets/pixel_icon.dart';
import '../files/file_entry_tile.dart';
import '../files/history_controllers.dart';
import '../viewer/viewer_page.dart';

/// Favorites page ("收藏箱"): starred HTML files with long-press actions.
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('收藏')),
      body: favorites.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                PixelCard(
                  padding: EdgeInsets.all(24),
                  child: PixelEmptyState(
                    icon: PixelIcon(art: PixelArt.chest, size: 64),
                    title: '箱子还是空的。',
                    subtitle: '把你常用的网页放进收藏箱吧。',
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final entry = favorites[index];
                return FileEntryTile(
                  entry: entry,
                  trailing: Icon(
                    Icons.star,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  onTap: () => openHtmlViewer(context, ref, entry),
                  onLongPress: () => showEntryActionsSheet(
                    context,
                    ref,
                    entry: entry,
                    onRemoved: () => ref
                        .read(favoritesProvider.notifier)
                        .remove(entry.path),
                  ),
                );
              },
            ),
    );
  }
}
