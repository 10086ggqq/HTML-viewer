import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/root_shell.dart';
import '../../core/services/share_service.dart';
import '../../data/models/html_entry.dart';
import '../../widgets/pixel_button.dart';
import '../../widgets/pixel_card.dart';
import '../../widgets/pixel_empty_state.dart';
import '../../widgets/pixel_icon.dart';
import '../files/file_entry_tile.dart';
import '../files/history_controllers.dart';
import '../files/open_html_flow.dart';
import '../files/project_files_page.dart';
import '../viewer/viewer_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentsProvider);
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _Header(),
            const SizedBox(height: 20),
            _OpenHtmlCard(
              onOpen: () => showOpenHtmlSheet(context, ref),
            ),
            const SizedBox(height: 28),
            _SectionTitle(title: '最近打开'),
            const SizedBox(height: 10),
            if (recents.isEmpty)
              const _FootprintEmptyCard()
            else
              ...recents.take(5).map(
                    (entry) => FileEntryTile(
                      entry: entry,
                      onTap: () => openHtmlViewer(context, ref, entry),
                      onLongPress: () => showEntryActionsSheet(
                        context,
                        ref,
                        entry: entry,
                        onRemoved: () => ref
                            .read(recentsProvider.notifier)
                            .remove(entry.path),
                      ),
                    ),
                  ),
            const SizedBox(height: 28),
            _SectionTitle(title: '我的项目'),
            const SizedBox(height: 10),
            if (projects.isEmpty)
              PixelCard(
                padding: const EdgeInsets.all(24),
                child: PixelEmptyState(
                  icon: const PixelIcon(art: PixelArt.grassBlock, size: 64),
                  title: '还没有世界。',
                  subtitle: '打开一个 HTML 文件，开始创建你的第一个网页世界。',
                  action: PixelButton(
                    label: '打开 HTML',
                    icon: Icons.add,
                    onPressed: () => showOpenHtmlSheet(context, ref),
                  ),
                ),
              )
            else
              ...projects.map(
                (project) => _ProjectTile(project: project),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HTMLViewer',
                style:
                    text.headlineMedium?.copyWith(color: colors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                'Your HTML crafting table',
                style: text.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '设置',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () =>
              ref.read(shellIndexProvider.notifier).state = 3,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _OpenHtmlCard extends StatelessWidget {
  const _OpenHtmlCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return PixelCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              const PixelFileIcon(
                badge: '</>',
                color: Color(0xFFE8642B),
                size: 52,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '打开 HTML',
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '选择 .html / .htm 文件或项目文件夹',
                      style: text.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PixelButton(
            label: '打开 HTML',
            icon: Icons.folder_open,
            expanded: true,
            onPressed: onOpen,
          ),
        ],
      ),
    );
  }
}

class _FootprintEmptyCard extends StatelessWidget {
  const _FootprintEmptyCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return PixelCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.history, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '这里还没有留下脚印。',
              style:
                  text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectTile extends ConsumerWidget {
  const _ProjectTile({required this.project});

  final ProjectEntry project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return PixelCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProjectFilesPage(project: project),
            ),
          );
        },
        onLongPress: () {
          showModalBottomSheet<void>(
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
                      project.name,
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.share),
                    title: const Text('分享项目 (ZIP)'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      try {
                        await ref
                            .read(shareServiceProvider)
                            .shareProject(project);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.folder_open),
                    title: const Text('查看路径'),
                    subtitle: Text(
                      project.rootPath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.pop(sheetContext),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('删除记录'),
                    onTap: () {
                      ref
                          .read(projectsProvider.notifier)
                          .remove(project.rootPath);
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: Row(
          children: [
            const PixelIcon(art: PixelArt.chest, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    project.rootPath,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
