import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/file_picker_service.dart';
import '../../core/services/zip_service.dart';
import '../viewer/viewer_page.dart';
import 'history_controllers.dart';
import 'project_files_page.dart';

/// Opens the "打开 HTML" bottom sheet: pick a single file or a project
/// folder (Android SAF). Records the pick into recents/projects and shows
/// feedback.
Future<void> showOpenHtmlSheet(BuildContext context, WidgetRef ref) async {
  final picker = ref.read(filePickerServiceProvider);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '打开 HTML',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            Text(
              '选择单个文件或整个项目文件夹',
              style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('选择 HTML 文件'),
              subtitle: const Text('.html / .htm'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                final entry = await picker.pickHtmlFile();
                if (entry == null) return;
                if (context.mounted) {
                  await openHtmlViewer(context, ref, entry);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('选择项目文件夹'),
              subtitle: const Text('包含 index.html 的网站目录'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                final project = await picker.pickProjectFolder();
                if (project == null) return;
                await ref
                    .read(projectsProvider.notifier)
                    .recordOpen(project);
                if (context.mounted) {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProjectFilesPage(project: project),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('导入 ZIP 项目'),
              subtitle: const Text('解压 website.zip 并打开 index.html'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onTap: () => _importZip(context, ref, sheetContext),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Picks a ZIP, extracts it into the working directory, records the project
/// and opens its entry HTML in the viewer.
Future<void> _importZip(
  BuildContext context,
  WidgetRef ref,
  BuildContext sheetContext,
) async {
  Navigator.pop(sheetContext);
  final picker = ref.read(filePickerServiceProvider);
  final zip = await picker.pickZipFile();
  if (zip == null) return;
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    final result = await ref
        .read(zipProjectServiceProvider)
        .importZip(zip);
    await ref.read(projectsProvider.notifier).recordOpen(result.project);
    if (context.mounted) {
      await openHtmlViewer(context, ref, result.entry);
    }
  } catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.toString())));
  }
}
