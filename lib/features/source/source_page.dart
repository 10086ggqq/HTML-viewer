import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/html_entry.dart';
import '../../widgets/pixel_card.dart';
import 'code_highlighter.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_model.dart';

/// A single search hit.
class _Match {
  const _Match(this.line, this.start, this.length);

  final int line;
  final int start;
  final int length;
}

/// Standalone source viewer page (reached from long-press "查看源代码").
class SourcePage extends ConsumerWidget {
  const SourcePage({super.key, required this.entry});

  final HtmlEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SourceView(entry: entry),
    );
  }
}

/// Read-only code viewer: syntax highlighting, line-number gutter, in-file
/// search with jump navigation, text selection (copy / select-all), font
/// size steps and a word-wrap toggle.
///
/// Rows are built lazily through [ListView.builder] so large files stay
/// smooth; files over [CodeHighlighter.maxHighlightedChars] render as plain
/// text.
class SourceView extends ConsumerStatefulWidget {
  const SourceView({super.key, required this.entry});

  final HtmlEntry entry;

  @override
  ConsumerState<SourceView> createState() => _SourceViewState();
}

class _SourceViewState extends ConsumerState<SourceView> {
  static const _highlighter = CodeHighlighter();

  List<List<CodeToken>>? _lines;
  String? _error;

  bool _searchVisible = false;
  String _query = '';
  List<_Match> _matches = [];
  int _current = -1;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final path = widget.entry.path;
    if (path.startsWith('content://')) {
      setState(() => _error = '这个文件来自系统文件选择器（SAF），暂时无法查看源码。');
      return;
    }
    final file = File(path);
    if (!file.existsSync()) {
      setState(() => _error = '这个区块已经不存在了。文件可能已被移动或删除。');
      return;
    }
    try {
      final bytes = await file.readAsBytes();
      final content = utf8
          .decode(bytes, allowMalformed: true)
          .replaceAll('\t', '  ')
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n');
      final language = _highlighter.languageFor(widget.entry.extension);
      final lines = await _computeHighlights(content, language);
      setState(() {
        _lines = lines;
        _error = null;
        _runSearch(_query);
      });
    } catch (e) {
      setState(() => _error = '读取文件失败：$e');
    }
  }

  /// Runs highlighting outside the current frame to keep navigation smooth
  /// for medium-sized files.
  Future<List<List<CodeToken>>> _computeHighlights(
    String content,
    String? language,
  ) async {
    return _highlighter.highlight(content, language);
  }

  void _runSearch(String query) {
    final lines = _lines;
    if (lines == null) return;
    _matches = [];
    _current = -1;
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      for (var line = 0; line < lines.length; line++) {
        final text = _plainText(lines[line]).toLowerCase();
        var idx = 0;
        while ((idx = text.indexOf(q, idx)) != -1) {
          _matches.add(_Match(line, idx, q.length));
          idx += q.length;
        }
      }
      if (_matches.isNotEmpty) _current = 0;
    }
    if (_current >= 0) {
      _scrollToLine(_matches[_current].line);
    }
  }

  String _plainText(List<CodeToken> tokens) =>
      tokens.map((t) => t.text).join();

  void _scrollToLine(int line) {
    if (!_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLine(line));
      return;
    }
    final settings = ref.read(settingsProvider);
    final lineHeight = settings.codeFontSize * 1.6;
    final target =
        (line * lineHeight - _scrollController.position.viewportDimension / 3)
            .clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _stepMatch(int delta) {
    if (_matches.isEmpty) return;
    setState(() {
      _current = (_current + delta + _matches.length) % _matches.length;
    });
    _scrollToLine(_matches[_current].line);
  }

  Future<void> _copyAll() async {
    final lines = _lines;
    if (lines == null) return;
    await Clipboard.setData(
      ClipboardData(text: lines.map(_plainText).join('\n')),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('已复制全部源码')));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Column(
      children: [
        _buildToolbar(context, settings),
        if (_searchVisible) _buildSearchBar(context),
        Expanded(child: _buildBody(context, settings)),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, Settings settings) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              tooltip: '搜索',
              icon: Icon(
                _searchVisible ? Icons.search_off : Icons.search,
              ),
              onPressed: () {
                setState(() {
                  _searchVisible = !_searchVisible;
                  if (!_searchVisible) {
                    _query = '';
                    _matches = [];
                    _current = -1;
                  }
                });
                if (_searchVisible) _searchFocus.requestFocus();
              },
            ),
            IconButton(
              tooltip: '减小字体',
              icon: const Icon(Icons.text_decrease),
              onPressed: () => ref
                  .read(settingsProvider.notifier)
                  .setCodeFontSize(settings.codeFontSize - 1),
            ),
            IconButton(
              tooltip: '增大字体',
              icon: const Icon(Icons.text_increase),
              onPressed: () => ref
                  .read(settingsProvider.notifier)
                  .setCodeFontSize(settings.codeFontSize + 1),
            ),
            IconButton(
              tooltip: settings.codeWordWrap ? '关闭自动换行' : '开启自动换行',
              icon: Icon(
                settings.codeWordWrap
                    ? Icons.wrap_text
                    : Icons.swap_horiz_rounded,
              ),
              onPressed: () => ref
                  .read(settingsProvider.notifier)
                  .setCodeWordWrap(!settings.codeWordWrap),
            ),
            IconButton(
              tooltip: settings.showLineNumbers ? '隐藏行号' : '显示行号',
              icon: const Icon(Icons.format_list_numbered),
              onPressed: () => ref
                  .read(settingsProvider.notifier)
                  .setShowLineNumbers(!settings.showLineNumbers),
            ),
            IconButton(
              tooltip: '复制全部',
              icon: const Icon(Icons.copy),
              onPressed: _copyAll,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: _searchFocus,
              decoration: InputDecoration(
                isDense: true,
                hintText: '搜索代码...',
                counterText: '',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: const TextStyle(fontSize: 14),
              maxLength: 200,
              onSubmitted: (value) {
                setState(() {
                  _query = value;
                  _runSearch(value);
                });
              },
              onChanged: (value) => _query = value,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _matches.isEmpty
                ? '0'
                : '${_current + 1}/${_matches.length}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          IconButton(
            tooltip: '上一个',
            icon: const Icon(Icons.keyboard_arrow_up),
            onPressed: _matches.isEmpty ? null : () => _stepMatch(-1),
          ),
          IconButton(
            tooltip: '下一个',
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: _matches.isEmpty ? null : () => _stepMatch(1),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, Settings settings) {
    final lines = _lines;
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: PixelCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber,
                    size: 48, color: Color(0xFFD9483F)),
                const SizedBox(height: 14),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (lines == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final listView = ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: lines.length,
      itemBuilder: (context, index) => _buildRow(
        context,
        settings,
        index,
        lines[index],
      ),
    );

    if (settings.codeWordWrap) {
      return SelectionArea(child: listView);
    }

    // No word wrap: whole-body horizontal scrolling sized to the longest
    // line (monospace, so character count × measured char width).
    final charWidth = _measureCharWidth(settings.codeFontSize);
    var maxLen = 40;
    for (final line in lines) {
      final len = _plainText(line).length;
      if (len > maxLen) maxLen = len;
    }
    final gutter = settings.showLineNumbers
        ? (lines.length.toString().length * charWidth + 20)
        : 0.0;

    return SelectionArea(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: gutter + maxLen * charWidth + 32,
          child: listView,
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    Settings settings,
    int index,
    List<CodeToken> tokens,
  ) {
    final colors = Theme.of(context).colorScheme;
    final fontSize = settings.codeFontSize;
    final lineHasCurrent =
        _current >= 0 && _matches[_current].line == index;

    final code = RichText(
      text: TextSpan(
        children: _buildSpans(index, tokens, fontSize),
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          height: 1.6,
          color: CodePalette.plain,
        ),
      ),
      softWrap: settings.codeWordWrap,
    );

    return Container(
      color: lineHasCurrent
          ? colors.primaryContainer.withValues(alpha: 0.35)
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (settings.showLineNumbers)
            SizedBox(
              width: _measureCharWidth(fontSize) *
                      (linesCountDigits(settings)) +
                  12,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: fontSize,
                  height: 1.6,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(child: code),
        ],
      ),
    );
  }

  int linesCountDigits(Settings settings) {
    final lines = _lines;
    if (lines == null || lines.isEmpty) return 1;
    return lines.length.toString().length;
  }

  /// Merges syntax tokens with search-match highlight backgrounds.
  List<InlineSpan> _buildSpans(
    int lineIndex,
    List<CodeToken> tokens,
    double fontSize,
  ) {
    final lineMatches =
        _matches.where((m) => m.line == lineIndex).toList(growable: false);

    final spans = <InlineSpan>[];
    var offset = 0;
    for (final token in tokens) {
      final text = token.text;
      if (lineMatches.isEmpty) {
        spans.add(TextSpan(text: text, style: TextStyle(color: token.color)));
        offset += text.length;
        continue;
      }

      // Split this token around overlapping matches.
      var pos = 0;
      while (pos < text.length) {
        var chunkEnd = text.length;
        _Match? hit;
        for (final m in lineMatches) {
          if (offset + pos < m.start + m.length &&
              offset + pos >= m.start) {
            hit = m;
            chunkEnd = (m.start + m.length - offset).clamp(0, text.length);
            break;
          }
          if (m.start > offset + pos && m.start - offset < chunkEnd) {
            chunkEnd = m.start - offset;
          }
        }
        final chunk = text.substring(pos, chunkEnd);
        if (chunk.isNotEmpty) {
          final isCurrent = hit != null && _matches.indexOf(hit) == _current;
          spans.add(TextSpan(
            text: chunk,
            style: TextStyle(
              color: token.color,
              background: isCurrent
                  ? (Paint()
                    ..color = const Color(0xFFF2C14E).withValues(alpha: 0.5))
                  : hit != null
                      ? (Paint()
                        ..color = const Color(0xFF3EC7C0).withValues(
                            alpha: 0.28))
                      : null,
            ),
          ));
        }
        pos = chunkEnd;
      }
      offset += text.length;
    }
    return spans.isEmpty ? [const TextSpan(text: '')] : spans;
  }

  double _measureCharWidth(double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: '0' * 16,
        style: TextStyle(fontFamily: 'monospace', fontSize: fontSize),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width / 16;
  }
}
