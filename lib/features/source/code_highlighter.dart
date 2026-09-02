import 'package:flutter/painting.dart';
import 'package:highlight/highlight.dart' as hl;

/// A single colored run of code text.
class CodeToken {
  const CodeToken(this.text, this.color);

  final String text;
  final Color color;
}

/// Syntax highlighting for the source viewer.
///
/// Wraps the pure-Dart `highlight` package and flattens its node tree into
/// per-line token lists, using a Minecraft-flavored dark palette (XP lime,
/// diamond cyan, gold, redstone red).
class CodeHighlighter {
  const CodeHighlighter();

  /// Files larger than this many characters are rendered without
  /// highlighting to keep parsing off the UI hot path.
  static const int maxHighlightedChars = 500 * 1024;

  /// Maps a file extension to a highlight.js language id, or null for plain
  /// text.
  String? languageFor(String extension) {
    switch (extension) {
      case 'html':
      case 'htm':
      case 'xml':
        return 'html';
      case 'css':
        return 'css';
      case 'js':
      case 'mjs':
        return 'javascript';
      case 'json':
        return 'json';
      case 'md':
        return 'markdown';
      default:
        return null;
    }
  }

  /// Highlights [content] and returns one token list per line.
  List<List<CodeToken>> highlight(String content, String? language) {
    final lines = _splitLines(content);
    if (language == null || content.length > maxHighlightedChars) {
      return lines
          .map((line) => [CodeToken(line, CodePalette.plain)])
          .toList(growable: false);
    }

    final result = hl.highlight.parse(content, language: language);
    final tokens = <_RawToken>[];
    for (final node in result.nodes ?? <hl.Node>[]) {
      _walk(node, null, tokens);
    }

    // Split the flat token stream into lines.
    final out = <List<CodeToken>>[<CodeToken>[]];
    for (final token in tokens) {
      var text = token.text;
      while (true) {
        final i = text.indexOf('\n');
        if (i < 0) {
          if (text.isNotEmpty) {
            out.last.add(CodeToken(text, _colorFor(token.className)));
          }
          break;
        }
        if (i > 0) {
          out.last.add(CodeToken(
            text.substring(0, i),
            _colorFor(token.className),
          ));
        }
        out.add(<CodeToken>[]);
        text = text.substring(i + 1);
      }
    }
    return out;
  }

  List<String> _splitLines(String content) => content.split('\n');

  void _walk(hl.Node node, String? inheritedClass, List<_RawToken> out) {
    final className = node.className ?? inheritedClass;
    final value = node.value;
    if (value != null) {
      out.add(_RawToken(value, className));
      return;
    }
    final children = node.children;
    if (children == null) return;
    for (final child in children) {
      _walk(child, className, out);
    }
  }

  Color _colorFor(String? className) =>
      className == null ? CodePalette.plain : (CodePalette.map[className] ?? CodePalette.plain);
}

class _RawToken {
  const _RawToken(this.text, this.className);

  final String text;
  final String? className;
}

/// Minecraft-flavored code colors over dark stone.
class CodePalette {
  const CodePalette._();

  static const plain = Color(0xFFE4E7E0);

  static final Map<String, Color> map = {
    // Shared
    'comment': Color(0xFF6E7A6A),
    'quote': Color(0xFF6E7A6A),
    'string': Color(0xFFA8E85C), // XP lime
    'keyword': Color(0xFF3EC7C0), // diamond
    'number': Color(0xFFF2C14E), // gold
    'literal': Color(0xFFF2C14E),
    'symbol': Color(0xFF3EC7C0),
    'regexp': Color(0xFFD9483F), // redstone
    'title': Color(0xFF3EC7C0),
    'function': Color(0xFF3EC7C0),
    'built_in': Color(0xFF3EC7C0),
    'type': Color(0xFF3EC7C0),
    'variable': Color(0xFFE4E7E0),
    'attribute': Color(0xFFF2C14E),
    'meta': Color(0xFF8A948A),

    // HTML
    'tag': Color(0xFF8A948A),
    'name': Color(0xFFE8642B), // orange, like the HTML file badge
    'attr': Color(0xFFF2C14E),

    // CSS
    'selector-tag': Color(0xFFE8642B),
    'selector-class': Color(0xFFF2C14E),
    'selector-id': Color(0xFF3EC7C0),
    'selector-attr': Color(0xFFF2C14E),
    'selector-pseudo': Color(0xFF3EC7C0),
    'property': Color(0xFFF2C14E),
  };
}
