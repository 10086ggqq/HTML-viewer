import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/format_utils.dart';
import '../../widgets/pixel_card.dart';
import '../../widgets/pixel_empty_state.dart';
import '../../widgets/pixel_icon.dart';
import 'file_entry_tile.dart';
import 'history_controllers.dart';
import 'open_html_flow.dart';
import '../viewer/viewer_page.dart';

enum FileSort { name, time, size, type }

/// File management page over recorded entries (recents ∪ favorites):
/// search, sort, and long-press actions.
class FilesPage extends ConsumerStatefulWidget {
  const FilesPage({super.key});

  @override
  ConsumerState<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends ConsumerState<FilesPage> {
  FileSort _sort = FileSort.time;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final recents = ref.watch(recentsProvider);
    final favorites = ref.watch(favoritesProvider);

    // Union, favorites first (deduped by path).
    final entries = [
      ...favorites,
      ...recents.where((e) => !favorites.contains(e)),
    ];

    final filtered = _applyQuery(entries);
    final sorted = _applySort(filtered);

    return Scaffold(
      appBar: AppBar(
        title: const Text('文件'),
        actions: [
          PopupMenuButton<FileSort>(
            tooltip: '排序',
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: FileSort.time,
                child: Text('按修改时间'),
              ),
              PopupMenuItem(value: FileSort.name, child: Text('按名称')),
              PopupMenuItem(value: FileSort.size, child: Text('按大小')),
              PopupMenuItem(value: FileSort.type, child: Text('按类型')),
            ],
          ),
          IconButton(
            tooltip: '打开 HTML',
            icon: const Icon(Icons.folder_open),
            onPressed: () => showOpenHtmlSheet(context, ref),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索文件名或路径',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
          ),
          Expanded(
            child: sorted.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      PixelCard(
                        padding: EdgeInsets.all(24),
                        child: PixelEmptyState(
                          icon: PixelIcon(art: PixelArt.chest, size: 64),
                          title: '这里还没有文件。',
                          subtitle: '打开 HTML 文件后，可以在这里浏览和管理它们。',
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final entry = sorted[index];
                      final isFav = ref
                          .read(favoritesProvider.notifier)
                          .isFavorite(entry.path);
                      return FileEntryTile(
                        entry: entry,
                        trailing: isFav
                            ? Icon(
                                Icons.star,
                                size: 18,
                                color:
                                    Theme.of(context).colorScheme.secondary,
                              )
                            : Text(
                                formatFileSize(entry.size),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                        onTap: () => openHtmlViewer(context, ref, entry),
                        onLongPress: () => showEntryActionsSheet(
                          context,
                          ref,
                          entry: entry,
                          onRemoved: () {
                            ref
                                .read(recentsProvider.notifier)
                                .remove(entry.path);
                            ref
                                .read(favoritesProvider.notifier)
                                .remove(entry.path);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _applyQuery(List<dynamic> entries) {
    if (_query.isEmpty) return entries;
    final q = _query.toLowerCase();
    return entries
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.path.toLowerCase().contains(q))
        .toList();
  }

  List<dynamic> _applySort(List<dynamic> entries) {
    final list = [...entries];
    switch (_sort) {
      case FileSort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case FileSort.time:
        list.sort((a, b) => b.openedAt.compareTo(a.openedAt));
      case FileSort.size:
        list.sort((a, b) => (b.size ?? -1).compareTo(a.size ?? -1));
      case FileSort.type:
        list.sort((a, b) => a.extension.compareTo(b.extension));
    }
    return list;
  }
}
