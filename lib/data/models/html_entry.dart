import 'dart:convert';

/// A user-opened HTML file record (recents & favorites share this shape).
class HtmlEntry {
  const HtmlEntry({
    required this.path,
    required this.name,
    required this.openedAt,
    this.size,
  });

  /// Real file path or SAF content URI — whatever the picker returned.
  final String path;
  final String name;
  final DateTime openedAt;
  final int? size;

  /// Lowercase extension without the dot, empty when none.
  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  /// Parent directory shown in lists (best effort for path-like strings).
  String get folder {
    final i = path.lastIndexOf('/');
    return i <= 0 ? path : path.substring(0, i);
  }

  HtmlEntry copyWith({DateTime? openedAt, int? size}) => HtmlEntry(
        path: path,
        name: name,
        openedAt: openedAt ?? this.openedAt,
        size: size ?? this.size,
      );

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'openedAt': openedAt.toIso8601String(),
        'size': size,
      };

  factory HtmlEntry.fromJson(Map<String, dynamic> json) => HtmlEntry(
        path: json['path'] as String,
        name: json['name'] as String,
        openedAt:
            DateTime.tryParse(json['openedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
        size: (json['size'] as num?)?.toInt(),
      );

  @override
  bool operator ==(Object other) => other is HtmlEntry && other.path == path;

  @override
  int get hashCode => path.hashCode;
}

/// A user-opened HTML project (a folder expected to contain HTML files).
class ProjectEntry {
  const ProjectEntry({
    required this.rootPath,
    required this.name,
    required this.openedAt,
  });

  final String rootPath;
  final String name;
  final DateTime openedAt;

  ProjectEntry copyWith({DateTime? openedAt}) => ProjectEntry(
        rootPath: rootPath,
        name: name,
        openedAt: openedAt ?? this.openedAt,
      );

  Map<String, dynamic> toJson() => {
        'rootPath': rootPath,
        'name': name,
        'openedAt': openedAt.toIso8601String(),
      };

  factory ProjectEntry.fromJson(Map<String, dynamic> json) => ProjectEntry(
        rootPath: json['rootPath'] as String,
        name: json['name'] as String,
        openedAt:
            DateTime.tryParse(json['openedAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
      );

  @override
  bool operator ==(Object other) =>
      other is ProjectEntry && other.rootPath == rootPath;

  @override
  int get hashCode => rootPath.hashCode;
}

/// Encodes/decodes a list of JSON-mappable items stored as one string.
List<T> decodeList<T>(
  String? raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  } catch (_) {
    return [];
  }
}

String encodeList<T>(List<T> items, Map<String, dynamic> Function(T) toJson) =>
    jsonEncode(items.map(toJson).toList(growable: false));
