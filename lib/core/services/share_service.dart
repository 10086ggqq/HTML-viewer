import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/html_entry.dart';
import 'zip_service.dart';

/// Android share sheet integration for files and project folders.
///
/// Folders can't be shared directly, so they are zipped first (see
/// [ZipProjectService.exportProject]).
class ShareService {
  const ShareService(this._zip);

  final ZipProjectService _zip;

  /// Shares a single HTML file (or any file with a real path).
  Future<void> shareFile(HtmlEntry entry) async {
    if (entry.path.startsWith('content://')) {
      // content:// URIs are shareable as-is by the system.
      await Share.shareXFiles([XFile(entry.path)]);
      return;
    }
    await Share.shareXFiles(
      [XFile(entry.path, name: entry.name)],
      subject: entry.name,
    );
  }

  /// Shares a project folder as a ZIP archive.
  Future<void> shareProject(ProjectEntry project) async {
    final zip = await _zip.exportProject(project);
    await Share.shareXFiles(
      [XFile(zip.path, name: '${project.name}.zip')],
      subject: '${project.name}.zip',
    );
  }
}

final shareServiceProvider = Provider<ShareService>(
  (ref) => ShareService(ref.watch(zipProjectServiceProvider)),
);
