import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/html_entry.dart';

/// Wraps Android SAF file/folder picking behind plain Dart types so the UI
/// never touches the plugin directly.
class FilePickerService {
  const FilePickerService();

  /// Picks a single `.html` / `.htm` file. Returns null when the user
  /// cancelled.
  Future<HtmlEntry?> pickHtmlFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['html', 'htm'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.single;
    if (f.path == null && f.identifier == null) return null;

    final path = f.path ?? f.identifier!;
    int? size;
    try {
      final io = File(path);
      if (await io.exists()) size = await io.length();
    } catch (_) {
      // SAF URIs can't be stat'ed via dart:io; size stays null.
    }
    return HtmlEntry(
      path: path,
      name: f.name,
      openedAt: DateTime.now(),
      size: size ?? f.size,
    );
  }

  /// Picks a project folder and records its name/entry point when possible.
  /// Returns null when the user cancelled.
  Future<ProjectEntry?> pickProjectFolder() async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null || dir.isEmpty) return null;
    return ProjectEntry(
      rootPath: dir,
      name: _leafName(dir),
      openedAt: DateTime.now(),
    );
  }

  /// Picks a `.zip` archive (a website project to import).
  Future<HtmlEntry?> pickZipFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.single;
    if (f.path == null && f.identifier == null) return null;
    final path = f.path ?? f.identifier!;
    int? size;
    try {
      final io = File(path);
      if (await io.exists()) size = await io.length();
    } catch (_) {
      // SAF URIs can't be stat'ed via dart:io; size stays null.
    }
    return HtmlEntry(
      path: path,
      name: f.name,
      openedAt: DateTime.now(),
      size: size ?? f.size,
    );
  }
}

String _leafName(String path) {
  final trimmed = path.endsWith('/') && path.length > 1
      ? path.substring(0, path.length - 1)
      : path;
  final i = trimmed.lastIndexOf('/');
  return i < 0 || i == trimmed.length - 1 ? trimmed : trimmed.substring(i + 1);
}

final filePickerServiceProvider =
    Provider<FilePickerService>((_) => const FilePickerService());
