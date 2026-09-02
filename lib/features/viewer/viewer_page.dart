import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../core/services/share_service.dart';
import '../../core/utils/format_utils.dart';
import '../../data/models/html_entry.dart';
import '../../widgets/pixel_button.dart';
import '../../widgets/pixel_card.dart';
import '../../widgets/pixel_progress.dart';
import '../developer/console_bootstrap.dart';
import '../developer/console_controller.dart';
import '../developer/console_model.dart';
import '../developer/developer_page.dart';
import '../files/history_controllers.dart';
import '../settings/settings_controller.dart';
import '../settings/settings_model.dart';
import '../source/source_page.dart';

/// Files above this size ask for confirmation before previewing.
const _largeFileThreshold = 2 * 1024 * 1024;

/// Opens [entry] in the HTML viewer.
///
/// Guards against oversized files, records the open into recents, then pushes
/// [ViewerPage].
Future<void> openHtmlViewer(
  BuildContext context,
  WidgetRef ref,
  HtmlEntry entry,
) async {
  if ((entry.size ?? 0) > _largeFileThreshold) {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Large HTML detected'),
        content: Text('This file is ${formatFileSize(entry.size)}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Open anyway'),
          ),
        ],
      ),
    );
    if (proceed != true) return;
  }

  await ref.read(recentsProvider.notifier).recordOpen(entry);
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => ViewerPage(entry: entry)),
  );
}

/// HTML preview page: a WebView wired to a local file, with refresh,
/// in-page back/forward, fullscreen, favorite toggle and file-change
/// detection.
class ViewerPage extends ConsumerStatefulWidget {
  const ViewerPage({super.key, required this.entry});

  final HtmlEntry entry;

  @override
  ConsumerState<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends ConsumerState<ViewerPage>
    with WidgetsBindingObserver {
  WebViewController? _controller;
  DateTime? _lastModified;

  int _progress = 0;
  bool _loading = true;
  bool _fileMissing = false;
  String? _errorDescription;
  bool _fullscreen = false;
  bool _updatePromptShown = false;
  late ViewerTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = ref.read(settingsProvider).defaultViewerTab;
    WidgetsBinding.instance.addObserver(this);
    _initController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool get _isContentUri => widget.entry.path.startsWith('content://');

  Future<void> _initController() async {
    final settings = ref.read(settingsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

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
        onProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _progress = progress;
            if (progress >= 100) _loading = false;
          });
        },
        onNavigationRequest: (request) {
          // Local documents (file/content) always load; external http(s)
          // navigation is gated by the "allow network" setting.
          final url = request.url;
          final isLocal = !url.startsWith('http://') &&
              !url.startsWith('https://');
          if (isLocal || ref.read(settingsProvider).allowNetwork) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
        onPageStarted: (_) {
          if (!mounted) return;
          // Console entries belong to the document currently loading.
          ref.read(consoleProvider.notifier).clear();
          setState(() {
            _loading = true;
            _progress = 0;
            _errorDescription = null;
          });
        },
        onPageFinished: (_) async {
          // Inject the console hooks as soon as the document exists; pages
          // that log during later scripts are caught from here on.
          if (mounted) {
            await _injectConsoleHook(controller);
            setState(() => _loading = false);
          }
        },
        onWebResourceError: (error) {
          if (!mounted) return;
          if (error.isForMainFrame != true) {
            // Sub-resource failure (image/css/js): surface in the console.
            final what = error.url?.isNotEmpty == true
                ? Uri.tryParse(error.url!)?.pathSegments.isNotEmpty == true
                    ? Uri.parse(error.url!).pathSegments.last
                    : error.url!
                : 'resource';
            ref.read(consoleProvider.notifier).add(
                  ConsoleLevel.warning,
                  '$what failed to load — ${error.description}',
                );
            return;
          }
          ref.read(consoleProvider.notifier).add(
                ConsoleLevel.error,
                error.description,
              );
          setState(() {
            _loading = false;
            _errorDescription = error.description;
          });
        },
      ),
    );

    if (!_isContentUri) {
      final file = File(widget.entry.path);
      if (!file.existsSync()) {
        setState(() => _fileMissing = true);
        return;
      }
      _lastModified = file.lastModifiedSync();
    }

    try {
      if (_isContentUri) {
        await controller.loadRequest(Uri.parse(widget.entry.path));
      } else {
        await controller.loadFile(widget.entry.path);
      }
      setState(() => _controller = controller);
    } catch (e) {
      setState(() => _errorDescription = e.toString());
    }
  }

  /// Injects console-capturing hooks; a no-op when JavaScript is disabled.
  Future<void> _injectConsoleHook(WebViewController controller) async {
    if (!ref.read(settingsProvider).javascript) return;
    try {
      await controller.runJavaScript(consoleBootstrapJs);
    } catch (_) {
      // Injection races page teardown from time to time; it is retried on
      // the next onPageFinished.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed ||
        _updatePromptShown ||
        _isContentUri) {
      return;
    }
    final file = File(widget.entry.path);
    if (!file.existsSync()) return;
    final modified = file.lastModifiedSync();
    if (_lastModified != null && modified.isAfter(_lastModified!)) {
      _lastModified = modified;
      _promptReload();
    }
  }

  void _promptReload() {
    _updatePromptShown = true;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('发现文件已更新'),
        actions: [
          TextButton(
            onPressed: () {
              _updatePromptShown = false;
              Navigator.pop(dialogContext);
            },
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () {
              _updatePromptShown = false;
              Navigator.pop(dialogContext);
              _reload();
            },
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Future<void> _reload() async {
    final controller = _controller;
    if (controller == null) {
      await _initController();
      return;
    }
    if (!_isContentUri) {
      final file = File(widget.entry.path);
      if (!file.existsSync()) {
        setState(() => _fileMissing = true);
        return;
      }
      _lastModified = file.lastModifiedSync();
    }
    setState(() {
      _fileMissing = false;
      _errorDescription = null;
      _loading = true;
      _progress = 0;
    });
    await controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    // Apply JavaScript mode changes made in settings while viewing.
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final controller = _controller;
        if (controller != null && await controller.canGoBack()) {
          await controller.goBack();
        } else {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: _fullscreen
            ? null
            : AppBar(
                title: Text(
                  widget.entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  IconButton(
                    tooltip: '刷新',
                    icon: const Icon(Icons.refresh),
                    onPressed: _reload,
                  ),
                  IconButton(
                    tooltip: _fullscreen ? '退出全屏' : '全屏',
                    icon: Icon(
                      _fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    ),
                    onPressed: () => setState(() => _fullscreen = !_fullscreen),
                  ),
                  PopupMenuButton<String>(
                    tooltip: '更多',
                    onSelected: (action) async {
                      switch (action) {
                        case 'forward':
                          final controller = _controller;
                          if (controller != null &&
                              await controller.canGoForward()) {
                            await controller.goForward();
                          }
                        case 'favorite':
                          await ref
                              .read(favoritesProvider.notifier)
                              .toggle(widget.entry);
                        case 'share':
                          try {
                            await ref
                                .read(shareServiceProvider)
                                .shareFile(widget.entry);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                            }
                          }
                        case 'path':
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(content: Text(widget.entry.path)),
                              );
                          }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'forward',
                        child: ListTile(
                          leading: Icon(Icons.arrow_forward),
                          title: Text('前进'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share),
                          title: Text('分享'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'favorite',
                        child: ListTile(
                          leading: Icon(
                            ref
                                    .read(favoritesProvider.notifier)
                                    .isFavorite(widget.entry.path)
                                ? Icons.star
                                : Icons.star_border,
                          ),
                          title: const Text('收藏'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'path',
                        child: ListTile(
                          leading: Icon(Icons.folder_open),
                          title: Text('查看路径'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        body: Builder(
          builder: (context) {
            final wide =
                MediaQuery.sizeOf(context).width >= 700 && !_fullscreen;
            return Column(
              children: [
                if (!_fullscreen)
                  Material(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                      child: SegmentedButton<ViewerTab>(
                        segments: const [
                          ButtonSegment(
                            value: ViewerTab.preview,
                            icon: Icon(Icons.visibility_outlined),
                            label: Text('Preview'),
                          ),
                          ButtonSegment(
                            value: ViewerTab.source,
                            icon: Icon(Icons.code),
                            label: Text('Source'),
                          ),
                        ],
                        selected: {_tab},
                        onSelectionChanged: (selection) =>
                            setState(() => _tab = selection.first),
                      ),
                    ),
                  ),
                Expanded(
                  child: wide
                      ? Row(
                          children: [
                            Expanded(child: _buildBody(context)),
                            const VerticalDivider(width: 1),
                            Expanded(
                              child: SourceView(entry: widget.entry),
                            ),
                          ],
                        )
                      : IndexedStack(
                          index: _tab == ViewerTab.preview ? 0 : 1,
                          children: [
                            _buildBody(context),
                            SourceView(entry: widget.entry),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: _fullscreen
            ? FloatingActionButton.small(
                backgroundColor: colors.surfaceContainerHighest,
                foregroundColor: colors.onSurface,
                onPressed: () => setState(() => _fullscreen = false),
                child: const Icon(Icons.fullscreen_exit),
              )
            : _DeveloperFab(
                errorCount: ref.watch(
                  consoleProvider.select(
                    (messages) => messages
                        .where((m) => m.level == ConsoleLevel.error)
                        .length,
                  ),
                ),
                onPressed: _openDeveloperMode,
              ),
      ),
    );
  }

  Future<void> _openDeveloperMode() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DeveloperPage()),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_fileMissing) {
      return _ErrorView(
        icon: Icons.folder_off,
        title: '这个区块已经不存在了。',
        description: '文件可能已被移动或删除。',
        onReload: _reload,
      );
    }
    if (_errorDescription != null) {
      return _ErrorView(
        icon: Icons.warning_amber,
        title: '这个区块加载失败了。',
        description: _errorDescription!,
        onReload: _reload,
        onConsole: _openDeveloperMode,
      );
    }
    final controller = _controller;
    return Stack(
      children: [
        if (controller != null)
          Positioned.fill(child: WebViewWidget(controller: controller)),
        if (_loading || controller == null)
          Positioned.fill(
            child: LoadingWorldView(progress: _progress),
          ),
      ],
    );
  }
}

/// Minecraft-style chunk-load failure view with a reload button and an
/// optional shortcut into the developer console.
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.icon,
    required this.title,
    required this.description,
    required this.onReload,
    this.onConsole,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onReload;
  final VoidCallback? onConsole;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: PixelCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: colors.error),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style:
                    text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              PixelButton(
                label: '重新加载',
                icon: Icons.refresh,
                onPressed: onReload,
              ),
              if (onConsole != null) ...[
                const SizedBox(height: 8),
                PixelButton(
                  label: '查看 Console',
                  icon: Icons.terminal,
                  variant: PixelButtonVariant.tonal,
                  onPressed: onConsole,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Minecraft-style `</>` floating button that opens Developer Mode; shows a
/// redstone badge while the console holds errors.
class _DeveloperFab extends StatelessWidget {
  const _DeveloperFab({required this.errorCount, required this.onPressed});

  final int errorCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return FloatingActionButton(
      backgroundColor: dark ? const Color(0xFF181D19) : Colors.white,
      foregroundColor: colors.onSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: dark
              ? const Color(0xFF39423A)
              : const Color(0xFFC9C2AD),
          width: 2,
        ),
      ),
      onPressed: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Center(
            child: Text(
              '</>',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: Color(0xFFE8642B),
              ),
            ),
          ),
          if (errorCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFFD9483F),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 14,
                  minHeight: 14,
                ),
                child: Text(
                  errorCount > 9 ? '9+' : '$errorCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
