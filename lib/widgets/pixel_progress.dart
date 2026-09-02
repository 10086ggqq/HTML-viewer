import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Minecraft XP-bar style progress indicator.
///
/// Dark track with a pixel frame and a lime-green fill that grows left to
/// right. Pure [Container] based — no images.
class PixelProgress extends StatelessWidget {
  const PixelProgress({super.key, required this.value, this.height = 14});

  /// Progress between 0.0 and 1.0.
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final track = dark ? const Color(0xFF0A0D0A) : const Color(0xFF26241E);
    final frame = dark ? McColors.darkOutline : const Color(0xFF3A382E);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: track,
        border: Border.all(color: frame, width: 2),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: v,
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFA8E85C), Color(0xFF7CC93A)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen "Loading World..." overlay with the XP bar, used while the
/// WebView renders the first chunks of a page.
class LoadingWorldView extends StatelessWidget {
  const LoadingWorldView({
    super.key,
    required this.progress,
    this.status = 'Preparing HTML chunk...',
  });

  /// 0..100 page load progress.
  final int progress;
  final String status;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colors.surface.withValues(alpha: 0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Loading World...',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 220,
              child: PixelProgress(value: progress / 100),
            ),
            const SizedBox(height: 12),
            Text(
              status,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
