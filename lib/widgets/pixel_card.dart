import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../features/settings/settings_controller.dart';
import '../features/settings/settings_model.dart';

/// A rectangular border whose corners are chamfered like 8-bit UI panels.
class PixelBorder extends ShapeBorder {
  const PixelBorder({this.notch = 6, this.side = BorderSide.none});

  /// Chamfer size of each corner in logical pixels.
  final double notch;
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return getOuterPath(rect.deflate(side.strokeInset));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final n = notch.clamp(0.0, rect.shortestSide / 2);
    return Path()
      ..moveTo(rect.left + n, rect.top)
      ..lineTo(rect.right - n, rect.top)
      ..lineTo(rect.right, rect.top + n)
      ..lineTo(rect.right, rect.bottom - n)
      ..lineTo(rect.right - n, rect.bottom)
      ..lineTo(rect.left + n, rect.bottom)
      ..lineTo(rect.left, rect.bottom - n)
      ..lineTo(rect.left, rect.top + n)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.solid && side.width > 0) {
      canvas.drawPath(getOuterPath(rect), side.toPaint());
    }
  }

  @override
  ShapeBorder scale(double t) =>
      PixelBorder(notch: notch * t, side: side.scale(t));
}

/// A card container styled after Minecraft panels.
///
/// Its corner style reacts to the appearance settings:
/// - [PixelStrength.pixel] — chamfered "pixel" corners.
/// - [PixelStrength.standard] — regular rounded corners.
class PixelCard extends ConsumerWidget {
  const PixelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final cardColor = color ?? (dark ? McColors.darkCard : McColors.lightCard);
    final outline = theme.colorScheme.outline;

    final ShapeBorder shape;
    if (settings.uiStrength == PixelStrength.pixel) {
      shape = PixelBorder(
        notch: settings.cornerRadius,
        side: BorderSide(color: outline, width: 1.5),
      );
    } else {
      shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(settings.cornerRadius),
        side: BorderSide(color: outline, width: 1),
      );
    }

    return Container(
      margin: margin,
      child: DecoratedBox(
        decoration: ShapeDecoration(color: cardColor, shape: shape),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
