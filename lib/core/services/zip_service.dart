import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/html_entry.dart';

/// Result of importing a ZIP project.
class ZipImportResult {
  const ZipImportResult({required this.project, required this.entry});

  final ProjectEntry project;
  final HtmlEntry entry;
}

/// Thrown when a ZIP archive holds no HTML file at all.
class NoHtmlInZipException implements Exception {
  const NoHtmlInZipException();

  @override
  String toString() => '压缩包里没有找到任何 HTML 文件。';
}

/// Imports ZIP website projects and exports project folders back to ZIP.
///
/// Extracted projects live under `<documents>/projects/<name>/` (the app's
/// private working directory, so no storage permission is needed).
class ZipProjectService {
  const ZipProjectService();

  Future<Directory> _projectsRoot() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/projects');
    await dir.create(recursive: true);
    return dir;
  }

  /// Extracts [zip] into the working directory and resolves the entry HTML.
  ///
  /// An existing project of the same name is replaced wholesale.
  Future<ZipImportResult> importZip(HtmlEntry zip) async {
    if (zip.path.startsWith('content://')) {
      throw const UnsupportedZipSourceException();
    }
    final bytes = await File(zip.path).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final name = zip.name.toLowerCase().endsWith('.zip')
        ? zip.name.substring(0, zip.name.length - 4)
        : zip.name;
    final root = await _projectsRoot();
    final target = Directory('${root.path}/$name');
    if (target.existsSync()) {
      target.deleteSync(recursive: true);
    }
    await target.create(recursive: true);

    for (final file in archive.files) {
      if (!file.isFile) continue;
      // Zip-slip guard: reject entries escaping the target directory.
      final safeName = file.name.replaceAll('\\', '/');
      if (safeName.startsWith('/') || safeName.contains('..')) continue;
      final data = file.content as List<int>?;
      if (data == null) continue;
      final outFile = File('${target.path}/$safeName');
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(data);
    }

    final entryFile = findEntryPoint(target);
    if (entryFile == null) {
      target.deleteSync(recursive: true);
      throw const NoHtmlInZipException();
    }

    return ZipImportResult(
      project: ProjectEntry(
        rootPath: target.path,
        name: name,
        openedAt: DateTime.now(),
      ),
      entry: HtmlEntry(
        path: entryFile.path,
        name: entryFile.uri.pathSegments.last,
        openedAt: DateTime.now(),
        size: await entryFile.length(),
      ),
    );
  }

  /// Packs [project] into a ZIP inside the temp directory and returns it.
  Future<File> exportProject(ProjectEntry project) async {
    final root = Directory(project.rootPath);
    if (!root.existsSync()) {
      throw const ProjectNotFoundException();
    }

    final archive = Archive();
    _addDirectory(archive, root, '');

    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/${project.name}.zip');
    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw Exception('打包项目失败。');
    }
    await file.writeAsBytes(encoded);
    return file;
  }

  void _addDirectory(Archive archive, Directory dir, String prefix) {
    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is Directory) {
        _addDirectory(archive, entity, '$prefix${entity.uri.pathSegments.last}/');
      } else if (entity is File) {
        final bytes = entity.readAsBytesSync();
        final name = '$prefix${entity.uri.pathSegments.last}';
        archive.addFile(ArchiveFile(name, bytes.length, bytes));
      }
    }
  }
}

/// Thrown when the picked ZIP is only reachable through a content:// URI.
class UnsupportedZipSourceException implements Exception {
  const UnsupportedZipSourceException();

  @override
  String toString() => '这个压缩包来自系统文件选择器，暂时无法读取内容。';
}

/// Thrown when a project folder no longer exists on disk.
class ProjectNotFoundException implements Exception {
  const ProjectNotFoundException();

  @override
  String toString() => '这个项目文件夹已经不存在了。';
}

final zipProjectServiceProvider =
    Provider<ZipProjectService>((_) => const ZipProjectService());

/// Resolves the project entry: root `index.html` first, then the
/// shallowest `index.html`, then the shallowest HTML file.
File? findEntryPoint(Directory root) {
  final rootIndex = File('${root.path}/index.html');
  if (rootIndex.existsSync()) return rootIndex;

  final htmlFiles = <File>[];
  _collectHtml(root, htmlFiles, depth: 0);
  if (htmlFiles.isEmpty) return null;

  File? bestIndex;
  var bestIndexDepth = 1 << 30;
  File? bestAny;
  var bestAnyDepth = 1 << 30;
  for (final f in htmlFiles) {
    final depth = f.parent.path.length;
    if (f.uri.pathSegments.last == 'index.html' && depth < bestIndexDepth) {
      bestIndex = f;
      bestIndexDepth = depth;
    }
    if (depth < bestAnyDepth) {
      bestAny = f;
      bestAnyDepth = depth;
    }
  }
  return bestIndex ?? bestAny;
}

void _collectHtml(Directory dir, List<File> out, {required int depth}) {
  if (depth > 6) return; // sanity cap
  for (final entity in dir.listSync(followLinks: false)) {
    if (entity is Directory) {
      _collectHtml(entity, out, depth: depth + 1);
    } else if (entity is File) {
      final lower = entity.path.toLowerCase();
      if (lower.endsWith('.html') || lower.endsWith('.htm')) out.add(entity);
    }
  }
}
