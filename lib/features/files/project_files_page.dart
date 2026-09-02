import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/share_service.dart';
import '../../core/utils/format_utils.dart';
import '../../data/models/html_entry.dart';
import '../../widgets/pixel_card.dart';
import '../../widgets/pixel_icon.dart';
import '../../widgets/pixel_empty_state.dart';
import '../viewer/viewer_page.dart';
import 'file_entry_tile.dart';

/// Browses a project folder like a chest full of items: folders descend,
/// HTML files open in the viewer, other files show details.
class ProjectFilesPage extends ConsumerStatefulWidget {
  const ProjectFilesPage({super.key, required this.project});

  final ProjectEntry project;

  @override
  ConsumerState<ProjectFilesPage> createState() => _ProjectFilesPageState();
}

class _ProjectFilesPageState extends ConsumerState<ProjectFilesPage> {
  late Directory _dir;
  final List<Directory> _stack = [];

  @override
  void initState() {
    super.initState();
    _dir = Directory(widget.project.rootPath);
  }

  void _open(Directory dir) {
    setState(() {
      _stack.add(_dir);
      _dir = dir;
    });
  }

  Future<void> _back() async {
    if (_stack.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _dir = _stack.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final exists = _dir.existsSync();
    final entities = <FileSystemEntity>[];
    if (exists) {
      entities.addAll(_dir.listSync(followLinks: false));
      entities.sort(_compareEntities);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          title: Text(
            _isRoot ? widget.project.name : _dir.uri.pathSegments.last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            IconButton(
              tooltip: '分享项目 (ZIP)',
              icon: const Icon(Icons.share),
              onPressed: _shareProject,
            ),
            IconButton(
              tooltip: '刷新',
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: !exists
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  PixelCard(
                    padding: EdgeInsets.all(24),
                    child: PixelEmptyState(
                      icon: Icon(Icons.folder_off, size: 56),
                      title: '这个区块已经不存在了。',
                      subtitle: '项目文件夹可能已被移动或删除。',
                    ),
                  ),
                ],
              )
            : entities.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      PixelCard(
                        padding: EdgeInsets.all(24),
                        child: PixelEmptyState(
                          icon: PixelIcon(art: PixelArt.chest, size: 64),
                          title: '箱子还是空的。',
                          subtitle: '这个文件夹里什么都没有。',
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: entities.length,
                    itemBuilder: (context, index) {
                      final entity = entities[index];
                      if (entity is Directory) {
                        return _FolderTile(
                          name: entity.uri.pathSegments.last,
                          onTap: () => _open(entity),
                        );
                      }
                      final file = entity as File;
                      final entry = HtmlEntry(
                        path: file.path,
                        name: file.uri.pathSegments.last,
                        openedAt: DateTime.now(),
                      );
                      final isHtml = const ['html', 'htm']
                          .contains(entry.extension);
                      return FileEntryTile(
                        entry: entry,
                        showTime: false,
                        trailing: _isHtmlBadge(entry, isHtml),
                        onTap: isHtml
                            ? () => openHtmlViewer(context, ref, entry)
                            : () => _showFileInfo(entry, file),
                        onLongPress: () => showEntryActionsSheet(
                          context,
                          ref,
                          entry: entry,
                          onRemoved: () {},
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget? _isHtmlBadge(HtmlEntry entry, bool isHtml) {
    if (!isHtml) return null;
    final colors = Theme.of(context).colorScheme;
    int? size;
    try {
      size = File(entry.path).lengthSync();
    } catch (_) {}
    return Text(
      size == null ? '' : formatFileSize(size),
      style: TextStyle(
        fontSize: 12,
        color: colors.onSurfaceVariant,
      ),
    );
  }

  void _showFileInfo(HtmlEntry entry, File file) {
    int? size;
    try {
      size = file.lengthSync();
    } catch (_) {}
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(entry.name),
        content: Text(
          '类型：${entry.extension.isEmpty ? '未知' : entry.extension.toUpperCase()}'
          '\n大小：${size == null ? '—' : formatFileSize(size)}'
          '\n\n${entry.folder}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareProject() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(shareServiceProvider).shareProject(widget.project);
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  bool get _isRoot => _dir.path == widget.project.rootPath;

  int _compareEntities(FileSystemEntity a, FileSystemEntity b) {
    final aDir = a is Directory;
    final bDir = b is Directory;
    if (aDir != bDir) return aDir ? -1 : 1;
    return a.uri.pathSegments.last
        .toLowerCase()
        .compareTo(b.uri.pathSegments.last.toLowerCase());
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return PixelCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Row(
          children: [
            PixelIcon(
              art: PixelArt.barrel,
              size: 38,
              semanticLabel: '文件夹 $name',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
