import 'package:flutter/material.dart';

/// Returns a lightened copy of [color]. [amount] ranges from 0 to 1.
Color lighten(Color color, [double amount = 0.25]) => _shift(color, amount);

/// Returns a darkened copy of [color]. [amount] ranges from 0 to 1.
Color darken(Color color, [double amount = 0.25]) => _shift(color, -amount);

Color _shift(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}
