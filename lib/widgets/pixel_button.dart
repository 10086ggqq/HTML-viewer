import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/color_utils.dart';
import '../features/settings/settings_controller.dart';

enum PixelButtonVariant { primary, tonal, outlined }

/// A Minecraft-style button: flat face, light top/left bevel, dark
/// bottom/right bevel and a dark frame around it.
///
/// Pressing scales it down to 0.96 (disabled together with the animation
/// setting).
class PixelButton extends ConsumerStatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PixelButtonVariant.primary,
    this.icon,
    this.expanded = false,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final PixelButtonVariant variant;
  final IconData? icon;
  final bool expanded;
  final double height;

  @override
  ConsumerState<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends ConsumerState<PixelButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;

    final (bg, fg, bevelLight, bevelDark, frame) = switch (widget.variant) {
      PixelButtonVariant.primary => (
          scheme.primary,
          scheme.onPrimary,
          lighten(scheme.primary, 0.22),
          darken(scheme.primary, 0.26),
          darken(scheme.primary, 0.5),
        ),
      PixelButtonVariant.tonal => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          lighten(scheme.primaryContainer, 0.12),
          darken(scheme.primaryContainer, 0.14),
          darken(scheme.primaryContainer, 0.35),
        ),
      PixelButtonVariant.outlined => (
          Colors.transparent,
          scheme.primary,
          null,
          null,
          scheme.outline,
        ),
    };

    final disabledBg = scheme.surfaceContainerHighest;

    Widget content = Container(
      height: widget.height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: enabled ? bg : disabledBg,
        border: bevelLight == null
            ? Border.all(color: frame, width: 1.5)
            : Border(
                top: BorderSide(color: bevelLight, width: 2),
                left: BorderSide(color: bevelLight, width: 2),
                bottom: BorderSide(color: bevelDark!, width: 3),
                right: BorderSide(color: bevelDark, width: 3),
              ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 19,
                color: enabled ? fg : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: TextStyle(
                color: enabled ? fg : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );

    if (bevelLight != null) {
      // Dark outer frame wrapping the bevel, like Minecraft UI buttons.
      content = Container(
        decoration: BoxDecoration(
          color: enabled ? frame : scheme.outline,
        ),
        padding: const EdgeInsets.all(1.5),
        child: content,
      );
    }

    if (widget.expanded) {
      content = SizedBox(width: double.infinity, child: content);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () {
        if (_pressed) setState(() => _pressed = false);
      },
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed && settings.animations ? 0.96 : 1.0,
        duration:
            settings.animations ? const Duration(milliseconds: 90) : Duration.zero,
        child: content,
      ),
    );
  }
}
