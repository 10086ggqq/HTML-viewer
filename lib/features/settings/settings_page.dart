import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../widgets/pixel_card.dart';
import '../files/history_controllers.dart';
import 'settings_controller.dart';
import 'settings_model.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SettingsSection(
            title: '外观',
            children: [
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('主题模式'),
                subtitle: Text(
                  switch (settings.themeMode) {
                    AppThemeMode.system => '跟随系统',
                    AppThemeMode.light => '浅色',
                    AppThemeMode.dark => '深色',
                  },
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeModeSheet(context, ref),
              ),
              const Divider(height: 1, indent: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minecraft UI 强度',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<PixelStrength>(
                      segments: const [
                        ButtonSegment(
                          value: PixelStrength.standard,
                          label: Text('标准'),
                          icon: Icon(Icons.crop_square),
                        ),
                        ButtonSegment(
                          value: PixelStrength.pixel,
                          label: Text('像素'),
                          icon: Icon(Icons.grid_on),
                        ),
                      ],
                      selected: {settings.uiStrength},
                      onSelectionChanged: (selection) =>
                          notifier.setUiStrength(selection.first),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 12),
              SwitchListTile(
                secondary: const Icon(Icons.font_download),
                title: const Text('像素字体'),
                subtitle: const Text('标题使用像素字体（Press Start 2P）'),
                value: settings.pixelFont,
                onChanged: notifier.setPixelFont,
              ),
              const Divider(height: 1, indent: 12),
              SwitchListTile(
                secondary: const Icon(Icons.bolt),
                title: const Text('动画效果'),
                subtitle: const Text('按钮按压与页面过渡动画'),
                value: settings.animations,
                onChanged: notifier.setAnimations,
              ),
              const Divider(height: 1, indent: 12),
              ListTile(
                leading: const Icon(Icons.rounded_corner),
                title: const Text('圆角大小'),
                trailing: Text('${settings.cornerRadius.round()}'),
              ),
              Slider(
                value: settings.cornerRadius,
                min: 0,
                max: 16,
                divisions: 16,
                label: '${settings.cornerRadius.round()}',
                onChanged: (value) => notifier.setCornerRadius(value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Web',
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.javascript),
                title: const Text('JavaScript'),
                subtitle: const Text('允许网页运行 JavaScript'),
                value: settings.javascript,
                onChanged: notifier.setJavascript,
              ),
              const Divider(height: 1, indent: 12),
              SwitchListTile(
                secondary: const Icon(Icons.public),
                title: const Text('外部网络访问'),
                subtitle: const Text('允许网页跳转到 http(s) 地址'),
                value: settings.allowNetwork,
                onChanged: notifier.setAllowNetwork,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: '文件',
            children: [
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('最近文件数量'),
                subtitle: Text('最多记住 ${settings.recentLimit} 个文件'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showRecentLimitSheet(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: '数据',
            children: [
              ListTile(
                leading: const Icon(Icons.history_toggle_off),
                title: const Text('清除最近记录'),
                onTap: () => _confirm(
                  context,
                  message: '清除全部最近打开记录？',
                  onConfirmed: () => ref.read(recentsProvider.notifier).clear(),
                ),
              ),
              const Divider(height: 1, indent: 12),
              ListTile(
                leading: const Icon(Icons.star_border),
                title: const Text('清除收藏'),
                onTap: () => _confirm(
                  context,
                  message: '清空全部收藏？',
                  onConfirmed: () =>
                      ref.read(favoritesProvider.notifier).clear(),
                ),
              ),
              const Divider(height: 1, indent: 12),
              ListTile(
                leading: const Icon(Icons.folder_delete_outlined),
                title: const Text('清除项目缓存'),
                subtitle: const Text('删除已导入的 ZIP 解压文件'),
                onTap: () => _confirm(
                  context,
                  message: '删除所有已解压的 ZIP 项目？项目记录会保留，'
                      '但需要重新导入才能打开。',
                  onConfirmed: () => _clearProjectCache(context),
                ),
              ),
              const Divider(height: 1, indent: 12),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text('导出设置'),
                subtitle: const Text('把当前设置保存为 JSON 文件'),
                onTap: () => _exportSettings(context, ref),
              ),
              const Divider(height: 1, indent: 12),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('导入设置'),
                subtitle: const Text('从之前导出的 JSON 恢复设置'),
                onTap: () => _importSettings(context, ref),
              ),
              const Divider(height: 1, indent: 12),
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text('恢复默认设置'),
                onTap: () => _confirm(
                  context,
                  message: '把所有设置恢复为默认值？',
                  onConfirmed: () => notifier.resetToDefaults(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: '阅读',
            children: [
              ListTile(
                leading: const Icon(Icons.text_fields),
                title: const Text('代码字体大小'),
                trailing: Text('${settings.codeFontSize.round()}'),
              ),
              Slider(
                value: settings.codeFontSize,
                min: 9,
                max: 24,
                divisions: 15,
                label: '${settings.codeFontSize.round()}',
                onChanged: (value) =>
                    notifier.setCodeFontSize(value),
              ),
              const Divider(height: 1, indent: 12),
              SwitchListTile(
                secondary: const Icon(Icons.wrap_text),
                title: const Text('自动换行'),
                value: settings.codeWordWrap,
                onChanged: notifier.setCodeWordWrap,
              ),
              const Divider(height: 1, indent: 12),
              SwitchListTile(
                secondary: const Icon(Icons.format_list_numbered),
                title: const Text('显示行号'),
                value: settings.showLineNumbers,
                onChanged: notifier.setShowLineNumbers,
              ),
              const Divider(height: 1, indent: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '默认打开页面',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    SegmentedButton<ViewerTab>(
                      segments: const [
                        ButtonSegment(
                          value: ViewerTab.preview,
                          label: Text('Preview'),
                        ),
                        ButtonSegment(
                          value: ViewerTab.source,
                          label: Text('Source'),
                        ),
                      ],
                      selected: {settings.defaultViewerTab},
                      onSelectionChanged: (selection) =>
                          notifier.setDefaultViewerTab(selection.first),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SettingsSection(
            title: '关于',
            children: [
              ListTile(
                leading: Icon(Icons.info),
                title: Text('版本'),
                trailing: Text('v1.1.0'),
              ),
              Divider(height: 1, indent: 12),
              ListTile(
                leading: Icon(Icons.terrain),
                title: Text('HTMLViewer'),
                subtitle: Text('Craft your web.'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRecentLimitSheet(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    final current = ref.read(settingsProvider).recentLimit;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  '最近文件数量',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              for (final limit in const [5, 10, 20, 50])
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text('$limit 个'),
                  trailing: limit == current
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    notifier.setRecentLimit(limit);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String message,
    required VoidCallback onConfirmed,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认操作'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      onConfirmed();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('已完成')));
      }
    }
  }

  Future<void> _clearProjectCache(BuildContext context) async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/projects');
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('清除失败：$e')));
      }
    }
  }

  Future<void> _exportSettings(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final settings = ref.read(settingsProvider);
      final json = const JsonEncoder.withIndent('  ')
          .convert(settings.toJson());
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/htmlviewer-settings.json');
      await file.writeAsString(json);
      await Share.shareXFiles(
        [XFile(file.path, name: 'htmlviewer-settings.json')],
        subject: 'HTMLViewer 设置',
      );
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('导出失败：$e')));
    }
  }

  Future<void> _importSettings(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (picked == null || picked.files.isEmpty) return;
      final path = picked.files.single.path;
      if (path == null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('无法读取所选文件（SAF 限制）')),
          );
        return;
      }
      final content = await File(path).readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      await ref.read(settingsProvider.notifier).importFrom(map);
      if (context.mounted) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('设置已导入')));
      }
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('导入失败：文件格式不正确')),
        );
    }
  }

  void _showThemeModeSheet(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    final current = ref.read(settingsProvider).themeMode;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  '主题模式',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              for (final mode in AppThemeMode.values)
                ListTile(
                  leading: Icon(
                    switch (mode) {
                      AppThemeMode.system => Icons.brightness_auto,
                      AppThemeMode.light => Icons.light_mode,
                      AppThemeMode.dark => Icons.dark_mode,
                    },
                  ),
                  title: Text(
                    switch (mode) {
                      AppThemeMode.system => '跟随系统',
                      AppThemeMode.light => '浅色',
                      AppThemeMode.dark => '深色',
                    },
                  ),
                  trailing:
                      mode == current ? const Icon(Icons.check) : null,
                  onTap: () {
                    notifier.setThemeMode(mode);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PixelCard(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
