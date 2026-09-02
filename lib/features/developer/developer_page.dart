import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/utils/format_utils.dart';
import '../../widgets/pixel_card.dart';
import '../../widgets/pixel_empty_state.dart';
import 'console_controller.dart';
import 'console_model.dart';

/// Developer Mode: Minecraft-styled debug console.
///
/// Shows JS logs / warnings / errors and resource failures captured from the
/// preview WebView. Entries can be copied; long lists stay lazy.
class DeveloperPage extends ConsumerWidget {
  const DeveloperPage({super.key, this.initialTab = 'Console'});

  final String initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(consoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Mode'),
        actions: [
          IconButton(
            tooltip: '清空',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: messages.isEmpty
                ? null
                : () => ref.read(consoleProvider.notifier).clear(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(context),
          Expanded(
            child: messages.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      PixelCard(
                        padding: EdgeInsets.all(24),
                        child: PixelEmptyState(
                          icon: Icon(Icons.terminal, size: 56),
                          title: '这里静悄悄。',
                          subtitle: '网页的日志和错误会出现在这里。',
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    itemCount: messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) =>
                        _ConsoleTile(message: messages[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            for (final (label, enabled) in [
              ('HTML', false),
              ('CSS', false),
              ('JS', false),
              ('Console', true),
            ])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _TabChip(label: label, selected: enabled),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? colors.primaryContainer : Colors.transparent,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ConsoleTile extends StatelessWidget {
  const _ConsoleTile({required this.message});

  final ConsoleMessage message;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (message.level) {
      ConsoleLevel.log => (Icons.chevron_right, McColors.grass, 'LOG'),
      ConsoleLevel.warning => (Icons.warning_amber, McColors.gold, 'WARNING'),
      ConsoleLevel.error => (Icons.error_outline, McColors.redstone, 'ERROR'),
    };

    return PixelCard(
      padding: const EdgeInsets.all(10),
      color: message.level == ConsoleLevel.error
          ? Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF241416)
              : const Color(0xFFFDEEEC)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onLongPress: () async {
          await Clipboard.setData(ClipboardData(text: message.text));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('已复制这条日志')));
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12.5,
                      height: 1.45,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '[$label] ${formatRelativeTime(message.time, DateTime.now())}'
                    ' · 长按复制',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
