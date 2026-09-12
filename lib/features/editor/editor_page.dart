import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../app/root_shell.dart';
import '../../core/services/file_picker_service.dart';
import '../../data/models/html_entry.dart';
import '../../storage/editor_storage.dart';
import '../../widgets/developer_fab.dart';
import '../../widgets/pixel_card.dart';
import '../developer/console_bootstrap.dart';
import '../developer/console_controller.dart';
import '../developer/console_model.dart';
import '../developer/developer_page.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_model.dart';
import '../viewer/viewer_page.dart';

/// Which pane the editor shows on narrow screens.
enum EditorTab { code, preview }

/// Handwritten HTML editor: a code area with live WebView preview.
///
/// Narrow (phone) layout stacks 编写 / 预览 behind a segmented button, while
/// wide (tablet / desktop ≥700dp) splits code and preview side by side — the
/// same responsive rule as the viewer page.
class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key});

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  late final EditorStorage _storage;
  late final TextEditingController _codeController;
  final FocusNode _codeFocus = FocusNode();
  Timer? _saveDebounce;

  WebViewController? _controller;
  bool _initScheduled = false;
  bool _previewInitFailed = false;
  String? _previewInitError;
  bool _previewDirty = true;
  EditorTab _tab = EditorTab.code;

  @override
  void initState() {
    super.initState();
    _storage = ref.read(editorStorageProvider);
    _codeController = TextEditingController(text: _storage.loadDraft());
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _storage.saveDraft(_codeController.text);
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  /// Marks the preview stale and autosaves the draft (debounced).
  void _onCodeChanged() {
    _previewDirty = true;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 800), () {
      _storage.saveDraft(_codeController.text);
    });
  }

  /// WebView startup is deferred until the editor tab is actually visible:
  /// the root shell keeps every tab alive in an IndexedStack, and the preview
  /// must not spin up platform channels for pages that are offstage.
  void _schedulePreviewInitIfNeeded() {
    if (ref.watch(shellIndexProvider) != editorTabIndex) return;
    if (_controller != null || _previewInitFailed || _initScheduled) return;
    _initScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPreview());
  }

  Future<void> _initPreview() async {
    final settings = ref.read(settingsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

    try {
      final controller = WebViewController.fromPlatformCreationParams(
        AndroidWebViewControllerCreationParams(),
      );
      await controller.setJavaScriptMode(
        settings.javascript
            ? JavaScriptMode.unrestricted
            : JavaScriptMode.disabled,
      );
      await controller.addJavaScriptChannel(
        'Console',
        onMessageReceived: (message) =>
            ref.read(consoleProvider.notifier).addRaw(message.message),
      );
      await controller.setBackgroundColor(
        dark ? const Color(0xFF101411) : const Color(0xFFF5F3EA),
      );
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            final isLocal =
                !url.startsWith('http://') && !url.startsWith('https://');
            if (isLocal || ref.read(settingsProvider).allowNetwork) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onPageStarted: (_) {
            if (!mounted) return;
            // Console entries belong to the document currently loading.
            ref.read(consoleProvider.notifier).clear();
          },
          onPageFinished: (_) async {
            if (!mounted) return;
            if (ref.read(settingsProvider).javascript) {
              try {
                await controller.runJavaScript(consoleBootstrapJs);
              } catch (_) {
                // Injection races page teardown from time to time.
              }
            }
          },
        ),
      );
      if (!mounted) return;
      setState(() => _controller = controller);
      await _runPreview();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewInitFailed = true;
        _previewInitError = e.toString();
      });
    }
  }

  /// (Re)loads the current draft into the preview WebView.
  Future<void> _runPreview() async {
    final controller = _controller;
    if (controller == null) return;
    var code = _codeController.text;
    if (code.trim().isEmpty) {
      code =
          '<!DOCTYPE html><html><head><meta charset="utf-8"></head><body></body></html>';
    }
    try {
      await controller.loadHtmlString(code);
      if (mounted) setState(() => _previewDirty = false);
    } catch (_) {
      // loadHtmlString can race page teardown on dispose; ignore.
    }
  }

  Future<void> _onRunPressed() async {
    if (!mounted) return;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    if (!wide && _tab == EditorTab.code) {
      setState(() => _tab = EditorTab.preview);
    }
    await _runPreview();
  }

  void _switchTab(EditorTab tab) {
    setState(() => _tab = tab);
    if (tab == EditorTab.preview && _previewDirty) {
      _runPreview();
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _importHtml() async {
    if (_codeController.text.trim().isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('导入 HTML'),
          content: const Text('导入会替换编辑器里的当前内容，继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('继续导入'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final entry = await ref.read(filePickerServiceProvider).pickHtmlFile();
    if (entry == null) return;
    if (entry.path.startsWith('content://')) {
      _toast('这个文件来自系统文件选择器（SAF），暂时无法读取内容。');
      return;
    }
    try {
      final bytes = await File(entry.path).readAsBytes();
      final content = utf8
          .decode(bytes, allowMalformed: true)
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n');
      _codeController.text = content;
      _toast('已导入 ${entry.name}');
      if (mounted) {
        final wide = MediaQuery.sizeOf(context).width >= 700;
        if (wide || _tab == EditorTab.preview) {
          await _runPreview();
        }
      }
    } catch (e) {
      _toast('读取文件失败：$e');
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final pasted = data?.text;
    if (pasted == null || pasted.isEmpty) {
      _toast('剪贴板里没有文本。');
      return;
    }
    final value = _codeController.value;
    final start =
        value.selection.start < 0 ? value.text.length : value.selection.start;
    final end =
        value.selection.end < 0 ? value.text.length : value.selection.end;
    _codeController.value = TextEditingValue(
      text: value.text.replaceRange(start, end, pasted),
      selection: TextSelection.collapsed(offset: start + pasted.length),
    );
    _toast('已粘贴 ${pasted.length} 个字符');
  }

  Future<void> _insertTemplate() async {
    if (_codeController.text.trim().isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('插入示例模板'),
          content: const Text('插入会替换编辑器里的当前内容，继续吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('继续'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    _codeController.text = editorStarterTemplate;
    if (mounted) {
      final wide = MediaQuery.sizeOf(context).width >= 700;
      if (wide || _tab == EditorTab.preview) {
        await _runPreview();
      }
    }
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _codeController.text));
    _toast('已复制全部代码');
  }

  Future<void> _clearEditor() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空编辑器'),
        content: const Text('手写的内容将从草稿中移除，确定清空吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (proceed != true) return;
    _codeController.clear();
    _toast('编辑器已清空');
  }

  Future<void> _saveAsFile() async {
    final code = _codeController.text;
    if (code.trim().isEmpty) {
      _toast('编辑器是空的，先写点代码吧。');
      return;
    }
    final rawName = await showDialog<String>(
      context: context,
      builder: (_) => _SaveAsDialog(defaultName: _defaultSaveName()),
    );
    if (rawName == null) return;
    final name = _sanitizeFileName(rawName);

    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/handwritten');
      await dir.create(recursive: true);
      final file = File('${dir.path}/$name');
      await file.writeAsString(code, flush: true);

      if (!mounted) return;
      _toast('已保存到 handwritten/$name');
      await openHtmlViewer(
        context,
        ref,
        HtmlEntry(
          path: file.path,
          name: name,
          openedAt: DateTime.now(),
          size: file.lengthSync(),
        ),
      );
    } catch (e) {
      _toast('保存失败：$e');
    }
  }

  String _defaultSaveName() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return 'page-${now.year}${two(now.month)}${two(now.day)}'
        '-${two(now.hour)}${two(now.minute)}${two(now.second)}.html';
  }

  String _sanitizeFileName(String raw) {
    var name = raw.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
    if (name.isEmpty || name == '-') name = _defaultSaveName();
    final lower = name.toLowerCase();
    if (!lower.endsWith('.html') && !lower.endsWith('.htm')) {
      name = '$name.html';
    }
    return name;
  }

  Future<void> _openDeveloperMode() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DeveloperPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Apply JavaScript mode changes made in settings while editing.
    ref.listen<Settings>(settingsProvider, (previous, next) {
      if (previous?.javascript != next.javascript) {
        _controller?.setJavaScriptMode(
          next.javascript
              ? JavaScriptMode.unrestricted
              : JavaScriptMode.disabled,
        );
      }
    });

    final colors = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final previewVisible = wide || _tab == EditorTab.preview;
    _schedulePreviewInitIfNeeded();

    return Scaffold(
      appBar: AppBar(title: const Text('手写 HTML')),
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildToolbar(context),
                        Expanded(child: _buildCodeField(settings)),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _buildPreviewPane()),
                ],
              )
            : Column(
                children: [
                  Material(
                    color: colors.surface,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                      child: SegmentedButton<EditorTab>(
                        segments: const [
                          ButtonSegment(
                            value: EditorTab.code,
                            icon: Icon(Icons.edit_note),
                            label: Text('Code'),
                          ),
                          ButtonSegment(
                            value: EditorTab.preview,
                            icon: Icon(Icons.visibility_outlined),
                            label: Text('Preview'),
                          ),
                        ],
                        selected: {_tab},
                        onSelectionChanged: (selection) =>
                            _switchTab(selection.first),
                      ),
                    ),
                  ),
                  if (_tab == EditorTab.code) _buildToolbar(context),
                  Expanded(
                    child: IndexedStack(
                      index: _tab == EditorTab.code ? 0 : 1,
                      children: [
                        _buildCodeField(settings),
                        _buildPreviewPane(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: previewVisible
          ? DeveloperFab(
              errorCount: ref.watch(
                consoleProvider.select(
                  (messages) => messages
                      .where((m) => m.level == ConsoleLevel.error)
                      .length,
                ),
              ),
              onPressed: _openDeveloperMode,
            )
          : null,
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              tooltip: '运行预览',
              icon: const Icon(Icons.play_arrow),
              onPressed: _onRunPressed,
            ),
            IconButton(
              tooltip: '导入 HTML 文件',
              icon: const Icon(Icons.file_open),
              onPressed: _importHtml,
            ),
            IconButton(
              tooltip: '粘贴代码',
              icon: const Icon(Icons.content_paste),
              onPressed: _pasteFromClipboard,
            ),
            IconButton(
              tooltip: '插入示例模板',
              icon: const Icon(Icons.article_outlined),
              onPressed: _insertTemplate,
            ),
            IconButton(
              tooltip: '复制全部',
              icon: const Icon(Icons.copy),
              onPressed: _copyAll,
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
              tooltip: '清空',
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearEditor,
            ),
            IconButton(
              tooltip: '保存为文件',
              icon: const Icon(Icons.save_outlined),
              onPressed: _saveAsFile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeField(Settings settings) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: TextField(
        controller: _codeController,
        focusNode: _codeFocus,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: settings.codeFontSize,
          height: 1.6,
          color: colors.onSurface,
        ),
        decoration: const InputDecoration(
          hintText: '在这里写下你的 HTML 代码...',
          contentPadding: EdgeInsets.all(14),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPreviewPane() {
    if (_previewInitFailed) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: PixelCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber,
                  size: 48,
                  color: Color(0xFFD9483F),
                ),
                const SizedBox(height: 14),
                Text(
                  '预览初始化失败。',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _previewInitError ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null) {
      // The editor tab has never been visible, so no preview exists yet; a
      // static placeholder keeps the offstage IndexedStack animation-free.
      if (!_initScheduled) return const SizedBox.shrink();
      return const Center(child: CircularProgressIndicator());
    }
    return WebViewWidget(controller: controller);
  }
}

/// Save-as-file dialog: a single file-name field with a sensible default.
class _SaveAsDialog extends StatefulWidget {
  const _SaveAsDialog({required this.defaultName});

  final String defaultName;

  @override
  State<_SaveAsDialog> createState() => _SaveAsDialogState();
}

class _SaveAsDialogState extends State<_SaveAsDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.defaultName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('保存手写页面'),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '文件名',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _nameController.text),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
