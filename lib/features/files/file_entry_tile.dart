import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/share_service.dart';
import '../../core/utils/format_utils.dart';
import '../../data/models/html_entry.dart';
import '../../widgets/pixel_card.dart';
import '../../widgets/pixel_icon.dart';
import '../source/source_page.dart';
import 'history_controllers.dart';

/// Maps a file extension to a pixel icon (badge text + accent color).
(String, Color) iconForExtension(String ext) {
  switch (ext) {
    case 'html':
    case 'htm':
      return ('</>', const Color(0xFFE8642B));
    case 'css':
      return ('#', const Color(0xFF3B7DD8));
    case 'js':
    case 'mjs':
      return ('JS', const Color(0xFFC9A227));
    case 'png':
    case 'jpg':
    case 'jpeg':
    case 'gif':
    case 'webp':
    case 'svg':
      return ('IMG', const Color(0xFF4E8A2E));
    default:
      return ('</>', const Color(0xFF8A8F84));
  }
}

/// A single file row: pixel icon, name, folder, relative time.
class FileEntryTile extends StatelessWidget {
  const FileEntryTile({
    super.key,
    required this.entry,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.showTime = true,
  });

  final HtmlEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final (badge, accent) = iconForExtension(entry.extension);

    return PixelCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Row(
          children: [
            PixelFileIcon(badge: badge, color: accent, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.folder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (trailing != null)
              trailing!
            else if (showTime)
              Text(
                formatRelativeTime(entry.openedAt, DateTime.now()),
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

/// Long-press action sheet shared by recent/favorite/file lists.
Future<void> showEntryActionsSheet(
  BuildContext context,
  WidgetRef ref, {
  required HtmlEntry entry,
  required void Function() onRemoved,
}) {
  final favorites = ref.read(favoritesProvider.notifier);
  final isFav = favorites.isFavorite(entry.path);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              entry.name,
              style: Theme.of(sheetContext).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ListTile(
            leading: Icon(isFav ? Icons.star : Icons.star_border),
            title: Text(isFav ? '取消收藏' : '收藏'),
            onTap: () {
              favorites.toggle(entry);
              Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('分享'),
            onTap: () async {
              Navigator.pop(sheetContext);
              try {
                await ref.read(shareServiceProvider).shareFile(entry);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('查看源代码'),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SourcePage(entry: entry),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('查看路径'),
            subtitle: Text(
              entry.path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.pop(sheetContext),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('删除记录'),
            onTap: () {
              onRemoved();
              Navigator.pop(sheetContext);
            },
          ),
        ],
      ),
    ),
  );
}
